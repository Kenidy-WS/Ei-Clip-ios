import AVFoundation
import Combine
import Photos
import UIKit

/// Um bipe disparado: o microfone fica em silêncio durante ele (medido pela hora em que o som foi CAPTADO,
/// não pela hora em que o bloco de áudio chegou ao app) e, com "Sons no vídeo", o bipe é somado ao áudio do clipe.
private struct BeepWindow {
    let start: Double  // hora do relógio do aparelho em que o bipe foi disparado
    let muteEnd: Double  // fim do silêncio no microfone
    let samples: [Float]?  // bipe a somar ao clipe (só com "Sons no vídeo")
}

/// Preferências guardadas no aparelho (v0.5.5: regras e chaves no Core, `Preferences`).
private let prefs = Preferences(store: UserDefaults.standard)

/// Motor do Ei Clip (etapa 1): câmera traseira 1080p30 + microfone, anel retroativo de vídeo codificado,
/// gravação num arquivo único e salvamento no álbum "Ei Clip".
///
/// Filas: `sessionQueue` (abrir/fechar a captura), `videoQueue`/`audioQueue` (entrega de amostras),
/// `controlQueue` (iniciar gravação). Todo o estado compartilhado fica protegido por `lock`.
final class CaptureEngine: NSObject, ObservableObject {
    // MARK: Estado para a tela (alterado só na fila principal)
    @Published private(set) var isOpen = false
    @Published private(set) var isRecording = false
    /// v0.7.2: SEM @Published de propósito. O relógio (`tick`) publicava isto a cada 0,5 s e, no iOS 27.0.1, a publicação
    /// na linha principal entrou em impasse com o cálculo de layout do SwiftUI (tela travada na v0.7.0, log de 06/11 14:03).
    /// Agora o `tick` só guarda o valor; a tela lê com o relógio próprio dela (`TimelineView`), sem passar pelo Combine.
    private(set) var bufferSec: Double = 0
    private(set) var recordSec: Double = 0
    @Published private(set) var message = ""
    @Published private(set) var testRunning = false
    /// v0.2.0/0.2.2: o que a voz faz (desligada, só mede, ou comando "Ei Clip" que liga e para a gravação).
    @Published private(set) var voiceMode: VoiceMode = .off
    /// v0.3.11: vira true por 1,2 s quando um "Ei Clip" é aceito (o botão de voz acende em verde, como no web app).
    @Published private(set) var voiceHeard = false
    /// Preferência "Comando de voz" (v0.3.7), como no web app: ligada, a voz acompanha a câmera
    /// (liga ao abrir e ao reabrir; desliga ao fechar). Guardada no aparelho; começa ligada.
    @Published var voiceEnabled: Bool = prefs.voiceEnabled {
        didSet {
            prefs.voiceEnabled = voiceEnabled
            log("voz", "Comando de voz: \(voiceEnabled ? "ligado" : "desligado") (preferência)")
            if isOpen && !testRunning { setVoiceMode(voiceEnabled ? .command : .off) }
        }
    }
    /// v0.2.5: qual das 3 palavras age no modo comando (guardada no aparelho; a tela final de Ajustes é a etapa 3).
    @Published var voiceWord: WakeWord = prefs.voiceWord {
        didSet {
            prefs.voiceWord = voiceWord
            voiceProbe.activeWord = voiceWord
            log("voz", "palavra de ativação: \(voiceWord.label)")
        }
    }
    /// Ajustes > Pré-gravação (15, 30 ou 60 s; 60 s desde a v0.6.5). v0.5.0: guardada no aparelho (antes voltava a 15 s a cada abertura do app).
    @Published var windowSec: Int = prefs.windowSec {
        didSet {
            prefs.windowSec = windowSec
            applyWindow()
        }
    }
    /// v0.6.5: a janela que vale de fato: a pedida, limitada pelo que a memória aguenta na qualidade atual (4K não usa 60 s).
    var effectiveWindowSec: Int { BufferWindow.effective(requested: windowSec, videoBitrate: config.bitrate) }
    /// Ajustes > Sons > "Sons de gravação": bipe de início e de fim (ligado por padrão, como no web app).
    @Published var beepEnabled: Bool = prefs.beepEnabled {
        didSet {
            prefs.beepEnabled = beepEnabled
            log("sons", "Sons de gravação: \(beepEnabled ? "ligados" : "desligados")")
        }
    }
    /// Ajustes > Sons > "Sons no vídeo": o bipe também fica gravado no clipe (desligado por padrão, como no web app).
    @Published var beepInClip: Bool = prefs.beepInClip {
        didSet {
            prefs.beepInClip = beepInClip
            log("sons", "Sons no vídeo: \(beepInClip ? "ligados" : "desligados")")
        }
    }

    /// Ajustes > "Estabilização de imagem" (v0.6.6). Vale na hora com a câmera aberta e parada; gravando, só na próxima abertura.
    @Published var stabilization: Bool = prefs.stabilization {
        didSet {
            prefs.stabilization = stabilization
            withLock {
                chosenConfig.stabilize = stabilization
                if !recording { config.stabilize = stabilization }
            }
            log("imagem", "Estabilização: \(stabilization ? "ligada" : "desligada")")
            applyStabilization()
        }
    }

    /// Ajustes > Câmera > "Espelhar a câmera frontal" (v0.6.28). Só entra na matriz do arquivo no começo de cada clipe; não mexe
    /// na câmera nem na prévia (publicado só em resposta ao toque na chave).
    @Published var mirrorFront: Bool = prefs.mirrorFront {
        didSet {
            prefs.mirrorFront = mirrorFront
            log("imagem", "Espelhar frontal: \(mirrorFront ? "ligado" : "desligado")")
        }
    }

    // MARK: Configuração (v0.5.7: um `CaptureConfig` do Core; o padrão é 1080p30, qualidade padrão, câmera traseira)
    /// O que o usuário escolheu.
    private var chosenConfig: CaptureConfig = prefs.captureChoice.validated()
    /// O que está valendo agora: a escolha reduzida pela reação ao calor (v0.6.2). Só muda com a câmera fechada
    /// (`openCamera` recalcula a cada abertura).
    private(set) var config = prefs.captureChoice.validated()
    /// v0.6.2: reação ao calor (quantos passos de redução estão aplicados).
    private var heat = ThermalGovernor()
    /// Texto do Diagnóstico: "-" ou o que mudou por causa do calor.
    var heatText = "-"
    /// v0.6.2: a câmera está sendo reaberta com outra configuração (a tela da câmera continua na frente, sem piscar o Início).
    /// v0.6.26: SEM @Published de propósito. Cada troca de lente publicava isto (e mudava `.disabled`/`.opacity` de vários
    /// botões de uma vez) justo quando o SwiftUI atualizava a tela fora da linha principal, e a tela travou num impasse
    /// nas v0.6.24 e v0.6.25. A tela não é mais avisada; quem decide bloquear toques é `reconfigureGate`.
    private(set) var isReconfiguring = false
    /// v0.6.20: a trava de verdade (sob `lock`); `isReconfiguring` só espelha para a tela.
    private var reconfigureGate = ReconfigureGate()
    /// v0.6.3: tela escura (preto liso por cima da câmera; a câmera, a gravação e a voz seguem funcionando). Só na fila principal.
    @Published private(set) var screenDimmed = false
    var cameraVisible: Bool { isOpen || isReconfiguring }
    var quality: VideoQuality { config.quality }
    var fps: Int { config.fps }
    var imageLevel: ImageQuality { config.imageLevel }

    // MARK: Captura
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    private let sessionQueue = DispatchQueue(label: "ei.session")
    private let videoQueue = DispatchQueue(label: "ei.video")
    private let audioQueue = DispatchQueue(label: "ei.audio")
    private let controlQueue = DispatchQueue(label: "ei.control")
    private let beep = BeepPlayer()
    /// v0.2.0 (área protegida: voz): escuta o MESMO áudio da captura e registra no Diagnóstico.
    private let voiceProbe = VoiceProbe(log: { Diagnostics.shared.log($0, $1) })
    /// v0.3.8: como o iPhone está segurado; decide só o giro do ARQUIVO, só no começo de cada clipe.
    let orientation = OrientationSensor(log: { Diagnostics.shared.log($0, $1) })

    // MARK: Estado compartilhado (protegido por `lock`)
    private let lock = NSLock()
    var ring = ReplayBuffer<CMSampleBuffer>(windowSec: 15)
    private var recording = false
    private var activeWriter: ClipWriter?
    private var videoFormat: CMFormatDescription?
    var audioFormat: CMFormatDescription?
    var opened = false
    /// v0.1.8: a câmera foi fechada porque o app foi para o segundo plano (reabre sozinha ao voltar).
    private var reopenOnReturn = false
    private var openToken = 0
    var peak = PeakTracker()
    private var lastVideoTs: Int64 = 0
    private var beepWindows: [BeepWindow] = []
    private var stopRequested = false
    private var recStartUptime: TimeInterval = 0
    /// v0.2.2: quando o último comando de voz foi executado (trava de 3 s entre comandos, como no web app).
    private var lastVoiceActionUptime: TimeInterval = -100
    private var encoder: VideoEncoder?
    var cVideoFrames = 0
    var cDropped = 0
    var cEncoded = 0
    var cEncoderErrors = 0
    var cAudioBuffers = 0
    var cAudioCopyFails = 0
    private var firstDropLogged = false
    // Diagnóstico (v0.1.5): quantas aberturas desde que o app abriu e quando a atual começou.
    var openCount = 0
    var openedAtUptime: TimeInterval = 0
    // Diagnóstico (v0.3.10): dados só para o painel (não mudam o comportamento).
    let launchedAtUptime = ProcessInfo.processInfo.systemUptime
    var deliveredFormat = "-"
    var lastClipText = "-"
    /// v0.6.15: quantos clipes foram salvos nas Fotos nesta abertura do app (a tela da câmera atualiza a miniatura quando muda).
    @Published private(set) var savedCount = 0
    /// v0.6.16: miniatura do clipe que acabou de parar e ainda está sendo salvo nas Fotos (aparece na hora no atalho).
    @Published private(set) var pendingThumbnail: UIImage?
    /// v0.6.15: tempo (s) do clipe em que o comando foi dado (o pré-tempo real); a miniatura própria sai daí.
    var lastPreSec = 0.0
    // Espaço livre (v0.6.0): o painel lê estes dois valores; o aviso só sai quando o nível piora.
    var storageText = "-"
    var storageLevel = StorageLevel.ok
    private var storageAlerts = StorageAlertTracker()
    // Bateria (v0.6.1)
    var batteryText = "-"
    var batteryLevel = BatteryLevel.ok
    private var batteryAlerts = BatteryAlertTracker()
    private var storageTick = 0
    /// A gravação foi encerrada por falta de espaço (a mensagem final do salvamento explica o motivo).
    private var stoppedForSpace = false
    var fpsSampleFrames = 0
    var fpsSampleAt: TimeInterval = 0
    var fpsLast = 0.0

    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    /// v0.6.21: vigia da tela principal e dos quadros (só registra no Diagnóstico).
    private var watch: MainThreadWatch?
    /// v0.6.21: leitura do espaço livre fora da tela principal (o iOS pode demorar para responder).
    private let storageQueue = DispatchQueue(label: "ei.storage", qos: .utility)
    private var storageCheckBusy = false

    override init() {
        super.init()
        installLevelFeed()
        LaunchLog.record()  // v0.3.10: Diagnóstico mostra os últimos inícios do app
        voiceProbe.onState = { [weak self] on in
            // A sonda parou (botão, câmera fechada, sem permissão, erro): a voz fica desligada.
            if !on { mainAsync { self?.voiceMode = .off } }
        }
        voiceProbe.stateProvider = { [weak self] in self?.wakeState() ?? .idle }
        voiceProbe.onWake = { [weak self] kind, wasRecording in self?.voiceWake(kind, wasRecording: wasRecording) }
        voiceProbe.activeWord = voiceWord
        installObservers()
        let w = MainThreadWatch(log: { [weak self] tag, text in self?.log(tag, text) }, probe: { [weak self] in self?.watchProbe() ?? WatchProbe() })
        watch = w
        w.start()
        mainAsync { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in self?.tick() }
            self?.evaluateBattery()  // liga a leitura da bateria e mostra o valor no Diagnóstico desde o início
        }
    }

    private func log(_ tag: String, _ text: String) {
        Diagnostics.shared.log(tag, text)
    }

    /// v0.6.21: valores que o vigia lê de outra fila (contadores sob a trava do motor).
    private func watchProbe() -> WatchProbe {
        let (isOpened, frames, encoded, errors, isRecording) = withLock { (opened, cVideoFrames, cEncoded, cEncoderErrors, recording) }
        return WatchProbe(
            opened: isOpened, frames: frames, encoded: encoded, encoderErrors: errors, recording: isRecording, level: levelEnabled)
    }

    func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    // MARK: - Abrir

    /// Abre a câmera e o microfone. Devolve falso se algo falhou (o motivo vai para o Diagnóstico).
    func openCamera() async -> Bool {
        if withLock({ opened }) { return true }
        let started = Date()
        // v0.7.7: o que já estava com problema ao começar (a tela já avisou, ou não cabe avisar de novo). Só o que mudar NESTA
        // abertura gera o aviso logo depois dos pedidos do iOS.
        let issuesAtStart = Set(permissionIssues().map { $0.kind })
        // v0.6.2: a configuração que vale é a escolhida, reduzida pelo que o calor já pediu.
        withLock { config = chosenConfig.lowered(by: heat.appliedSteps).validated() }
        log("câmera", "abrindo… (\(quality.rawValue)p\(fps), buffer \(windowSec) s)")
        // v0.6.0: confere o espaço livre antes de abrir (avisa, mas não impede de abrir).
        withLock {
            storageAlerts.reset()
            batteryAlerts.reset()
        }
        checkStorage()
        checkBattery()

        // v0.7.6: sem limite de tempo. O aviso do iOS é respondido por uma pessoa, e quem decide é ela (na v0.7.5 o app
        // desistia aos 10 s: abria sem microfone e mostrava um aviso por cima do aviso do iOS). O Diagnóstico registra
        // "pedindo…" e "respondida em … ms"; sem a segunda linha, o iPhone não mostrou o aviso.
        let camOK = await askAccess(.video, kind: .camera, name: "câmera")
        let micOK = await askAccess(.audio, kind: .microphone, name: "microfone")
        // v0.7.4: o pedido das Fotos saiu daqui. Em aparelho novo ele podia ficar sem resposta e a câmera nunca abria.
        // Agora ele é feito depois que a câmera abre (`requestPhotos`).
        log("permissões", "câmera=\(camOK) microfone=\(micOK) · Fotos: \(DiagSystemInfo.photos().text) (o pedido vem depois de abrir)")
        guard camOK else {
            flash(Textos.semPermissaoCamera)
            return false
        }

        do {
            try AudioSessionConfig.activate()
        } catch {
            log("áudio", "ERRO ao ativar a sessão: \(error.localizedDescription)")
            flash("Falha na sessão de áudio.")
            return false
        }
        log("áudio", "sessão ativa: \(AudioSessionConfig.describe())")
        beep.prepare()

        let ok = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            sessionQueue.async { cont.resume(returning: self.configureAndStart(withMic: micOK)) }
        }
        let ms = Int(Date().timeIntervalSince(started) * 1000)
        if ok {
            let nth = withLock { () -> Int in
                openCount += 1
                openedAtUptime = ProcessInfo.processInfo.systemUptime
                return openCount
            }
            log("câmera", "aberta em \(ms) ms (abertura nº \(nth) desde que o app abriu)")
            orientation.start()
            mainAsync {
              MainMark.run("abertura") {
                self.isOpen = true
                UIApplication.shared.isIdleTimerDisabled = true
                // v0.3.7: a voz liga junto com a câmera (menos no teste de aberturas, que não deve ser perturbado).
                if self.voiceEnabled && !self.testRunning {
                    PermissionStore.ledger.mark(.speech)  // v0.7.6: o VoiceProbe pede o reconhecimento de voz ao ligar
                    self.notePermissionRequest()
                    self.setVoiceMode(.command)
                }
                self.evaluateThermal()  // v0.6.2: pode ter aberto com o aparelho já quente
                self.requestPhotos(reason: "ao abrir a câmera", delaySec: 1)  // v0.7.4/v0.7.6
                self.watchNewPermissionIssues(baseline: issuesAtStart)  // v0.7.7
              }
            }
        } else {
            log("câmera", "FALHOU ao abrir (\(ms) ms)")
            flash(Textos.naoAbriuCamera)
        }
        return ok
    }

    /// v0.7.6: pede câmera ou microfone ao iOS e ESPERA a resposta, sem limite de tempo. Só chama o sistema quando o estado é
    /// "ainda não pedida" (permitida ou negada já têm resposta). Marca que o app pediu (guardado no aparelho).
    private func askAccess(_ type: AVMediaType, kind: PermissionKind, name: String) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: type) {
        case .authorized: return true
        case .denied, .restricted: return false
        case .notDetermined: break
        @unknown default: break
        }
        PermissionStore.ledger.mark(kind)
        notePermissionRequest()
        log("permissões", "pedindo \(name)…")
        let started = Date()
        let ok = await AVCaptureDevice.requestAccess(for: type)
        notePermissionRequest()
        let ms = Int(Date().timeIntervalSince(started) * 1000)
        log("permissões", "\(name) respondida em \(ms) ms: \(ok ? "permitida" : "negada")")
        return ok
    }

    /// Última vez (uptime) em que o app pediu as Fotos ao sistema; só evita pedidos no mesmo instante (toques seguidos).
    private var lastPhotosAskUptime: Double?

    /// v0.7.4/v0.7.6: pede a permissão das Fotos SEM bloquear nada (nem a abertura da câmera, nem a gravação) e SEM prazo. Chamada
    /// ao abrir a câmera e de novo a cada toque em gravar enquanto o estado for "ainda não pedida": o iOS só mostra o aviso dele
    /// nesse estado. Se o aparelho não mostrar o aviso (visto num iPhone 16, iOS 27.0.1), a câmera e a gravação seguem; o
    /// Diagnóstico fica com "pedindo…" sem "respondido", e o aviso do app (RootView) leva aos Ajustes na vez seguinte. Só salvar
    /// nas Fotos depende da permissão (o arquivo fica guardado e é recuperado depois). Não publica estado da tela.
    /// `delaySec` deixa a tela assentar antes de o aviso do sistema aparecer.
    private func requestPhotos(reason: String, delaySec: Double) {
        let waiting = DiagSystemInfo.photosState() == .notAsked
        if waiting {
            let now = ProcessInfo.processInfo.systemUptime
            let go = withLock { () -> Bool in
                guard PermissionRules.shouldAskNow(lastAskUptime: lastPhotosAskUptime, now: now) else { return false }
                lastPhotosAskUptime = now
                return true
            }
            guard go else { return }
            PermissionStore.ledger.mark(.photos)
            notePermissionRequest()
            log("fotos", "\(reason): pedindo o acesso às Fotos…")
        }
        Task { [weak self] in
            if waiting && delaySec > 0 { try? await Task.sleep(nanoseconds: UInt64(delaySec * 1_000_000_000)) }
            let started = Date()
            let status = await PhotoSaver.requestAccess()
            guard let self else { return }
            if waiting { self.notePermissionRequest() }
            if waiting {
                let ms = Int(Date().timeIntervalSince(started) * 1000)
                self.log("fotos", "\(reason): respondido em \(ms) ms · permissão agora: \(DiagSystemInfo.photos().text) (código \(status.rawValue))")
            }
            await self.recoverLeftovers()  // v0.6.13: só age com a permissão já concedida
        }
    }

    /// Último momento (uptime) em que o app pediu algo ao iOS ou recebeu a resposta; o aviso do app espera esse tempo passar.
    private var lastPermRequestUptime: Double = 0

    private func notePermissionRequest() {
        let now = ProcessInfo.processInfo.systemUptime
        withLock { lastPermRequestUptime = now }
    }

    /// v0.7.7: o microfone está liberado? Só lê o estado do iOS (não publica nada). Sem ele a câmera abre sem áudio e o
    /// comando de voz não recebe som.
    var micAllowed: Bool { AVCaptureDevice.authorizationStatus(for: .audio) == .authorized }

    /// v0.7.7: depois que a câmera abre, espera os avisos do iOS terminarem e, se algo foi negado ou ficou sem resposta NESTA
    /// abertura, pede à tela o aviso único (com "Abrir Ajustes"). Espera sem prazo de desistência para os pedidos (só observa);
    /// limita a 60 s de vigia. Só mostra com o app ativo há 2 s e sem pedido novo nos últimos 3 s, para nunca cair por cima do
    /// aviso do iOS. Gravando ou com a câmera fechada, não mostra (o ícone e o aviso rápido de gravar cobrem esse caso).
    private func watchNewPermissionIssues(baseline: Set<PermissionKind>) {
        Task { [weak self] in
            var calm = 0
            for _ in 0..<120 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                guard let self else { return }
                let (open, rec, lastReq) = self.withLock { (self.opened, self.recording, self.lastPermRequestUptime) }
                if !open || rec { return }
                let active = await MainActor.run { UIApplication.shared.applicationState == .active }
                let quiet = ProcessInfo.processInfo.systemUptime - lastReq > 3
                calm = (active && quiet) ? calm + 1 : 0
                guard calm >= 4 else { continue }
                let fresh = self.permissionIssues().filter { !baseline.contains($0.kind) }
                if fresh.isEmpty { return }
                self.log("permissões", "aviso depois dos pedidos do iOS: \(fresh.map { "\($0.kind.rawValue)=\($0.problem)" }.joined(separator: ", "))")
                mainAsync {
                    NotificationCenter.default.post(name: .eiClipPermissionNotice, object: nil, userInfo: ["issues": fresh])
                }
                return
            }
        }
    }

    /// v0.7.5: o que fazer com as Fotos quando o usuário toca em gravar (regra pura no Core).
    func photosActionForRecording() -> PhotosAction {
        PermissionRules.photosAction(DiagSystemInfo.photosState())
    }

    /// v0.7.6: o que está desligado ou sem resposta, para o aviso único antes de abrir a câmera. Só lê; nada é publicado.
    func permissionIssues() -> [PermissionIssue] {
        PermissionRules.issues(in: PermissionStore.statuses(voiceEnabled: voiceEnabled))
    }

    private func configureAndStart(withMic: Bool) -> Bool {
        withLock {
            ring = ReplayBuffer<CMSampleBuffer>(windowSec: Double(effectiveWindowSec))
            recording = false
            activeWriter = nil
            videoFormat = nil
            audioFormat = nil
            peak.reset()
            lastVideoTs = 0
            beepWindows.removeAll()
            stopRequested = false
            cVideoFrames = 0
            cDropped = 0
            cEncoded = 0
            cEncoderErrors = 0
            cAudioBuffers = 0
            cAudioCopyFails = 0
            firstDropLogged = false
        }

        // Sobra de uma abertura que falhou? Limpa antes de montar (senão `canAddInput` recusa a câmera).
        if !session.inputs.isEmpty || !session.outputs.isEmpty {
            log("câmera", "aviso: sessão com restos de uma abertura anterior; limpando")
            resetSession()
        }

        session.beginConfiguration()
        switch config.quality {
        case .p720: session.sessionPreset = .hd1280x720
        case .p1080: session.sessionPreset = .hd1920x1080
        case .p2160: session.sessionPreset = .hd4K3840x2160
        }
        session.automaticallyConfiguresApplicationAudioSession = false

        // v0.7.9: no iPhone com ultra-angular, a traseira usa a câmera combinada (0,5×, 1× e 2× são pontos de zoom do mesmo
        // aparelho, sem reabrir). Se o aparelho não oferecer, ou a sessão recusar, entra a câmera simples de antes (reserva).
        let combined = (config.position == .back && hasUltraWide) ? pickCombinedCamera() : nil
        func legacyCamera() -> AVCaptureDevice? {
            let wantUltra = config.position == .back && config.lens.usesUltraWideDevice
            let ultra = wantUltra ? AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) : nil
            if wantUltra && ultra == nil {
                log("câmera", "aviso: lente ultra-angular indisponível; usando a principal")
                withLock { config.lens = .wide }
                mainAsync { self.lens = .wide }
            }
            return ultra ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: config.position == .front ? .front : .back)
        }
        var candidate: AVCaptureDevice? = combined?.device ?? legacyCamera()
        var combinedMainNow: Double? = combined?.main
        var inputTry: AVCaptureDeviceInput? = candidate.flatMap { try? AVCaptureDeviceInput(device: $0) }
        if combinedMainNow != nil, !(inputTry.map { session.canAddInput($0) } ?? false) {
            log("lente", "aviso: a sessão recusou a câmera combinada; usando a câmera simples (reserva)")
            combinedMainNow = nil
            candidate = legacyCamera()
            inputTry = candidate.flatMap { try? AVCaptureDeviceInput(device: $0) }
        }
        guard let camera = candidate else {
            session.commitConfiguration()
            log("câmera", "ERRO: câmera traseira indisponível (o sistema não devolveu o aparelho)")
            resetSession()
            return false
        }
        guard let videoInput = inputTry, session.canAddInput(videoInput) else {
            session.commitConfiguration()
            log("câmera", "ERRO: não foi possível usar a câmera traseira (entrada recusada pela sessão)")
            resetSession()
            return false
        }
        session.addInput(videoInput)
        withLock { combinedMain = combinedMainNow }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        guard session.canAddOutput(videoOutput) else {
            session.commitConfiguration()
            log("câmera", "ERRO: não foi possível adicionar a saída de vídeo")
            resetSession()
            return false
        }
        session.addOutput(videoOutput)
        applyStabilization(connection: videoOutput.connection(with: .video))

        if withMic, let mic = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: mic), session.canAddInput(audioInput)
        {
            session.addInput(audioInput)
            audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
            if session.canAddOutput(audioOutput) {
                session.addOutput(audioOutput)
            } else {
                log("áudio", "ERRO: não foi possível adicionar a saída de áudio")
            }
        } else {
            log("áudio", "sem microfone (sem permissão ou indisponível): o clipe sairá sem som")
        }
        session.commitConfiguration()

        // v0.6.11: confere se o formato aceita os quadros pedidos (pedir uma taxa fora do alcance derruba o app).
        let size = config.quality.size
        let infos = camera.formats.map { (f: AVCaptureDevice.Format) -> FormatInfo in
            let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
            let lo = f.videoSupportedFrameRateRanges.map(\.minFrameRate).min() ?? 0
            let hi = f.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
            return FormatInfo(width: Int(d.width), height: Int(d.height), minFps: lo, maxFps: hi)
        }
        let wantedFps = config.fps
        let effectiveFps = FormatPicker.effectiveFps(infos, width: size.width, height: size.height, requested: wantedFps)
        if effectiveFps != wantedFps {
            log("câmera", "aviso: formato \(size.width)x\(size.height) não aceita \(wantedFps) fps; usando \(effectiveFps)")
            withLock { config.fps = effectiveFps }
            flash(Textos.fpsIndisponivel(wantedFps))
        }
        do {
            try camera.lockForConfiguration()
            if let index = FormatPicker.pick(infos, width: size.width, height: size.height, fps: effectiveFps) {
                let current = camera.activeFormat
                let cd = CMVideoFormatDescriptionGetDimensions(current.formatDescription)
                let fits = Int(cd.width) == size.width && Int(cd.height) == size.height
                    && current.videoSupportedFrameRateRanges.contains {
                        Double(effectiveFps) >= $0.minFrameRate - 0.01 && Double(effectiveFps) <= $0.maxFrameRate + 0.01
                    }
                if !fits { camera.activeFormat = camera.formats[index] }
            }
            let frame = CMTime(value: 1, timescale: CMTimeScale(effectiveFps))
            camera.activeVideoMinFrameDuration = frame
            camera.activeVideoMaxFrameDuration = frame
            let zoom = min(max(1, withLock { LensZoom.factor(for: config.lens, mainFactor: combinedMainNow) }), camera.activeFormat.videoMaxZoomFactor)
            camera.videoZoomFactor = zoom
            camera.unlockForConfiguration()
        } catch {
            log("câmera", "aviso: não foi possível fixar \(fps) fps: \(error.localizedDescription)")
        }
        let dims = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
        log("câmera", "formato ativo \(dims.width)x\(dims.height), \(fps) fps pedidos")
        if let main = combinedMainNow {
            let lensesText = Lens.allCases.map { "\($0.label)=\(String(format: "%.1f", LensZoom.factor(for: $0, mainFactor: main)))" }.joined(separator: " · ")
            log("lente", "câmera combinada em uso (\(camera.deviceType.rawValue)): \(lensesText); zoom máximo do formato \(String(format: "%.1f", camera.activeFormat.videoMaxZoomFactor))")
        }
        withLock { deliveredFormat = "\(dims.width)x\(dims.height)" }

        let enc = VideoEncoder(bitrate: videoBitrate(quality, fps: fps, level: imageLevel), fps: fps)
        var errorLogs = 0
        enc.onError = { [weak self] msg in
            guard let self else { return }
            self.withLock { self.cEncoderErrors += 1 }
            errorLogs += 1
            if errorLogs <= 5 { self.log("codificador", "ERRO: \(msg)") }
        }
        enc.onChunk = { [weak self] sb in self?.handleEncoded(sb) }
        let token = withLock { () -> Int in
            encoder = enc
            opened = true
            openToken += 1
            return openToken
        }

        session.startRunning()
        guard session.isRunning else {
            log("câmera", "ERRO: a sessão não iniciou")
            withLock {
                opened = false
                encoder = nil
            }
            enc.close()
            resetSession()
            return false
        }

        sessionQueue.asyncAfter(deadline: .now() + 3) { [weak self] in self?.reportAfterThreeSeconds(token: token) }
        return true
    }

    /// Para a sessão e tira todas as entradas/saídas (sempre na `sessionQueue`).
    private func resetSession() {
        session.stopRunning()
        session.beginConfiguration()
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        audioOutput.setSampleBufferDelegate(nil, queue: nil)
        for input in session.inputs { session.removeInput(input) }
        for output in session.outputs { session.removeOutput(output) }
        session.commitConfiguration()
    }

    private func reportAfterThreeSeconds(token: Int) {
        let snapshot = withLock { () -> (Bool, Float, Int, Int, Int, Int, Int, Int, Double, Int) in
            let keys = ring.video.filter { $0.isKey }.count
            return (
                openToken == token && opened, peak.peak, cVideoFrames, cDropped, cEncoded, cEncoderErrors,
                cAudioBuffers, cAudioCopyFails, ring.spanSec(), keys
            )
        }
        guard snapshot.0 else { return }
        let silent = isMicSilent(peak: snapshot.1)
        log(
            "áudio", "após 3 s: pico do microfone = \(String(format: "%.4f", snapshot.1)) "
                + (silent ? "→ MUDO" : "→ ok") + " (limite \(micSilentPeakThreshold))")
        log("áudio", "blocos recebidos=\(snapshot.6), cópias que falharam=\(snapshot.7)")
        log(
            "vídeo",
            "após 3 s: quadros=\(snapshot.2) descartados=\(snapshot.3) codificados=\(snapshot.4) "
                + "erros do codificador=\(snapshot.5) · anel: \(String(format: "%.1f", snapshot.8)) s, \(snapshot.9) keyframes")
        log("áudio", "sessão após 3 s: \(AudioSessionConfig.describe())")
    }

    // MARK: - Voz (v0.2.0 sonda, v0.2.2 comando)

    /// Escolhe o que a voz faz. Só liga com a câmera aberta (é o áudio dela que o reconhecedor escuta).
    func setVoiceMode(_ mode: VoiceMode) {
        guard mode != .off else {
            voiceProbe.stop(reason: "desligada pelo botão")
            voiceMode = .off
            return
        }
        guard withLock({ opened }) else {
            log("voz", "a voz só liga com a câmera aberta")
            return
        }
        voiceProbe.commandEnabled = (mode == .command)
        voiceProbe.start()  // sem efeito se já estiver escutando
        voiceMode = mode
        log("voz", mode == .command ? "modo: COMANDO (\(voiceWord.label) liga e para a gravação)" : "modo: só medir (não grava)")
    }

    /// O que o detector da palavra de ativação precisa saber da gravação (chamado na fila da voz).
    private func wakeState() -> WakeState {
        withLock {
            let rec = recording
            let ms = rec ? (ProcessInfo.processInfo.systemUptime - recStartUptime) * 1000 : 0
            return WakeState(recording: rec, recordingMs: ms, finalizing: rec && stopRequested)
        }
    }

    /// "Ei Clip" reconhecido no modo comando: liga a gravação se estava parada, ou para se estava gravando.
    /// Confere o estado de novo aqui (pode ter mudado desde que o texto chegou) e respeita 3 s entre comandos.
    private func voiceWake(_ kind: WakeKind, wasRecording: Bool) {
        let now = ProcessInfo.processInfo.systemUptime
        let ignoredBecause: String? = withLock { () -> String? in
            if recording != wasRecording { return "o estado da gravação mudou" }
            if recording && stopRequested { return "a gravação já está sendo encerrada" }
            if now - lastVoiceActionUptime < 3.0 { return "menos de 3 s desde o comando anterior" }
            lastVoiceActionUptime = now
            return nil
        }
        if let why = ignoredBecause {
            log("voz", "COMANDO ignorado (\(kind.label)): \(why)")
            return
        }
        mainAsync {
            self.voiceHeard = true
            mainAsyncAfter(1.2) { self.voiceHeard = false }
        }
        if wasRecording {
            log("voz", "COMANDO: parar a gravação (\(kind.label))")
            Task { await self.stopRecording() }
        } else {
            log("voz", "COMANDO: iniciar a gravação (\(kind.label))")
            startRecording()
        }
    }

    // MARK: - Reabrir ao voltar (v0.1.8)

    /// Chamado quando o app volta a ficar ativo. Reabre a câmera só se ela foi fechada pelo segundo plano.
    func reopenAfterReturn() async {
        let shouldOpen = withLock { () -> Bool in
            let flag = reopenOnReturn
            reopenOnReturn = false
            return flag && !opened && !testRunning
        }
        guard shouldOpen else { return }
        log("câmera", "reabertura automática ao voltar para o app")
        _ = await openCamera()
    }

    // MARK: - Fechar

    /// `reopenOnReturn`: só o segundo plano pede; fechar pelo botão ou pelo teste nunca reabre sozinho.
    func closeCamera(reason: String, reopenOnReturn: Bool = false) async {
        guard withLock({ opened }) else { return }
        if reopenOnReturn { withLock { self.reopenOnReturn = true } }
        if withLock({ recording }) { await stopRecording() }
        let report = withLock { () -> String in
            opened = false
            return "quadros=\(cVideoFrames) descartados=\(cDropped) codificados=\(cEncoded) "
                + "erros do codificador=\(cEncoderErrors) blocos de áudio=\(cAudioBuffers) pico=\(String(format: "%.4f", peak.peak))"
        }
        voiceProbe.stop(reason: "câmera fechada")
        orientation.stop()
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                self.resetSession()
                cont.resume()
            }
        }
        let enc = withLock { () -> VideoEncoder? in
            let e = encoder
            encoder = nil
            ring.clear()
            videoFormat = nil
            audioFormat = nil
            return e
        }
        enc?.close()
        log("câmera", "fechada (\(reason)). \(report)")
        mainAsync {
            self.isOpen = false
            self.bufferSec = 0
            self.screenDimmed = false  // v0.6.3: câmera fechada, a tela volta ao normal
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Amostras

    private func handleVideo(_ sb: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sb) else { return }
        let enc = withLock { () -> VideoEncoder? in
            cVideoFrames += 1
            return encoder
        }
        let duration = CMTime(value: 1, timescale: CMTimeScale(fps))
        enc?.encode(pixelBuffer, pts: CMSampleBufferGetPresentationTimeStamp(sb), duration: duration)
    }

    private func handleDropped(_ sb: CMSampleBuffer) {
        let shouldLog = withLock { () -> Bool in
            cDropped += 1
            if firstDropLogged { return false }
            firstDropLogged = true
            return true
        }
        if shouldLog {
            let reason = CMGetAttachment(sb, key: kCMSampleBufferAttachmentKey_DroppedFrameReason, attachmentModeOut: nil)
            log("vídeo", "primeiro quadro descartado: motivo=\(String(describing: reason))")
        }
    }

    /// Quadro H.264 pronto (qualquer fila): vai para o anel, ou para o arquivo se estiver gravando.
    private func handleEncoded(_ sb: CMSampleBuffer) {
        let ts = Int64((CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sb)) * 1e6).rounded())
        let key = isKeyFrame(sb)
        var writer: ClipWriter?
        lock.lock()
        cEncoded += 1
        lastVideoTs = ts
        if videoFormat == nil { videoFormat = CMSampleBufferGetFormatDescription(sb) }
        if recording {
            writer = activeWriter
        } else {
            ring.pushVideo(Chunk(ts: ts, isKey: key, payload: sb))
        }
        lock.unlock()
        writer?.enqueueVideo(sb)
    }

    private func handleAudio(_ sb: CMSampleBuffer) {
        guard let format = CMSampleBufferGetFormatDescription(sb) else { return }
        let level = audioPeak(sb)
        guard let copy = deepCopyAudio(sb) else {
            withLock { cAudioCopyFails += 1 }
            return
        }
        let pts = CMSampleBufferGetPresentationTimeStamp(sb)
        let ts = Int64((CMTimeGetSeconds(pts) * 1e6).rounded())
        let sampleRate = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee.mSampleRate ?? 48_000
        let blockStart = CMTimeGetSeconds(pts)
        let blockEnd = blockStart + Double(CMSampleBufferGetNumSamples(sb)) / sampleRate

        // Bipes que se sobrepõem a este bloco: silêncio no microfone (e, se pedido, o bipe somado ao clipe).
        let windows = withLock { beepWindows }.filter { blockEnd > $0.start && blockStart < $0.muteEnd }
        let muted = !windows.isEmpty
        if muted {
            silenceAudio(copy)
            for w in windows {
                if let samples = w.samples {
                    mixBeep(copy, blockStart: blockStart, beepStart: w.start, samples: samples, beepRate: 48_000)
                }
            }
        }

        // v0.2.0: a sonda de voz recebe o mesmo bloco (já com o silêncio do bipe), sem mexer no anel nem no arquivo.
        voiceProbe.append(copy)

        var writer: ClipWriter?
        var firstFormat = false
        lock.lock()
        cAudioBuffers += 1
        if audioFormat == nil {
            audioFormat = format
            firstFormat = true
        }
        if !muted, let level { peak.feed(level) }
        if recording {
            writer = activeWriter
        } else {
            ring.pushAudio(Chunk(ts: ts, isKey: false, payload: copy))
        }
        lock.unlock()
        if firstFormat { log("áudio", "formato do microfone: \(describeAudioFormat(format))") }
        writer?.enqueueAudio(copy)
    }

    /// Dispara o bipe (se "Sons de gravação" estiver ligado): registra a janela de silêncio ANTES de tocar.
    private func fireBeep(_ kind: BeepKind) {
        guard beepEnabled else { return }
        let start = hostNowSeconds()
        let session = AVAudioSession.sharedInstance()
        let latency = session.outputLatency + session.ioBufferDuration
        let inClip = beepInClip
        let window = BeepWindow(
            start: start,
            muteEnd: start + beepDuration(kind) + latency + 0.25,
            samples: inClip ? renderBeep(kind, sampleRate: 48_000) : nil)
        withLock {
            beepWindows.removeAll { $0.muteEnd < start - 2 }
            beepWindows.append(window)
        }
        beep.play(kind)
        log(
            "bipe",
            "\(kind == .start ? "início" : "fim"): microfone em silêncio por \(String(format: "%.2f", window.muteEnd - start)) s "
                + "(latência da saída \(String(format: "%.0f", latency * 1000)) ms) · no vídeo: \(inClip ? "sim" : "não")")
    }

    // MARK: - Gravar

    func startRecording() {
        // v0.7.5: gravar nunca espera pelas Fotos. Sem acesso ainda: pede de novo (o aviso do iOS aparece por cima, a gravação
        // segue); negado: o iOS não mostra o aviso outra vez, então só registra (a tela explica e oferece os Ajustes).
        switch photosActionForRecording() {
        case .none: break
        case .askAgain: requestPhotos(reason: "ao gravar", delaySec: 0)
        case .explainDenied: log("fotos", "ao gravar: acesso às Fotos desligado (\(DiagSystemInfo.photos().text)); o clipe será guardado no app")
        }
        // v0.7.7: sem microfone o clipe sai sem som; avisa na hora, sem alerta nem botões (nada cobre a câmera gravando).
        if !micAllowed {
            log("gravação", "microfone desligado: o clipe sairá sem som")
            flash(Textos.gravandoSemSom)
        }
        controlQueue.async { self.doStartRecording() }
    }

    private func doStartRecording() {
        // v0.3.8: a posição do aparelho é lida UMA vez, aqui, e vale para o clipe inteiro.
        let snap = orientation.snapshot()
        lock.lock()
        guard opened, !recording else {
            lock.unlock()
            return
        }
        let selection: CutSelection<CMSampleBuffer>
        switch ring.selectCut() {
        case .success(let s):
            selection = s
        case .failure(let failure):
            lock.unlock()
            log("gravação", "não iniciou: \(failure == .empty ? "buffer vazio" : "sem keyframe ainda")")
            flash(Textos.aguardeUmSegundo)
            return
        }
        guard let vfd = videoFormat else {
            lock.unlock()
            log("gravação", "não iniciou: sem formato de vídeo")
            return
        }
        let url = RecordingFolder.url().appendingPathComponent(clipFileName())
        let offset = CMSampleBufferGetPresentationTimeStamp(selection.video[0].payload)
        let writer: ClipWriter
        do {
            // A tela é sempre em pé; o giro do arquivo vem da posição do aparelho no começo do clipe
            // (em pé = 90°, igual às versões anteriores). Sem recodificar: só a matriz do arquivo.
            // v0.6.28: a frontal usa o mesmo giro da traseira e, com a chave ligada, sai espelhada.
            let m = snap.hold.fileMatrix(front: config.position == .front, mirrored: prefs.mirrorFront)
            writer = try ClipWriter(
                url: url, videoFormat: vfd, audioFormat: audioFormat, offset: offset,
                transform: CGAffineTransform(a: m.a, b: m.b, c: m.c, d: m.d, tx: 0, ty: 0))
        } catch {
            lock.unlock()
            log("gravação", "ERRO ao criar o arquivo: \(error)")
            flash(Textos.naoIniciouGravacao)
            return
        }
        recording = true
        stopRequested = false
        stoppedForSpace = false
        activeWriter = writer
        recStartUptime = ProcessInfo.processInfo.systemUptime
        let ringSeconds = ring.spanSec()
        ring.clear()
        lock.unlock()

        writer.onLog = { [weak self] message in self?.log("arquivo", message) }
        log("arquivo", "gravando em \(RecordingFiles.folderName)/\(url.lastPathComponent) · partes de \(Int(RecordingFiles.fragmentSeconds)) s")
        // v0.1.7: se o arquivo falhar durante a gravação, encerra na hora e avisa (sem esperar o vigia de 30 s).
        writer.onFailed = { [weak self, weak writer] _ in
            guard let self, let writer else { return }
            let stopNow = self.withLock { self.recording && !self.stopRequested && self.activeWriter === writer }
            guard stopNow else { return }
            self.log("gravação", "o arquivo falhou durante a gravação; encerrando agora")
            Task { await self.stopRecording() }
        }
        withLock { lastPreSec = selection.preSec }
        writer.begin(video: selection.video.map { $0.payload }, audio: selection.audio.map { $0.payload })
        fireBeep(.start)
        log(
            "gravação",
            "orientação do arquivo: aparelho \(snap.hold.label) → giro de \(snap.hold.fileRotationDegrees)°"
                + (config.position == .front ? (prefs.mirrorFront ? " · frontal espelhada" : " · frontal sem espelho") : "")
                + " (\(snap.readingText))")
        log(
            "gravação",
            "INÍCIO · pré-tempo pedido=\(effectiveWindowSec) s · real=\(String(format: "%.2f", selection.preSec)) s "
                + "(anel tinha \(String(format: "%.1f", ringSeconds)) s) · \(selection.video.count) quadros e "
                + "\(selection.audio.count) blocos de áudio de pré-gravação")
        // Diagnóstico (v0.1.5): tempos do pré-tempo entregue ao arquivo (buracos? retrocessos?).
        var preV = TimelineStats()
        var preA = TimelineStats()
        for c in selection.video { preV.add(Double(c.ts - selection.t0) / 1e6) }
        for c in selection.audio { preA.add(Double(c.ts - selection.t0) / 1e6) }
        let (nth, sinceOpen) = withLock { (openCount, ProcessInfo.processInfo.systemUptime - openedAtUptime) }
        log(
            "gravação",
            "pré-gravação · abertura nº \(nth) do app, câmera aberta há \(String(format: "%.1f", sinceOpen)) s · "
                + "vídeo: \(preV.summary) · áudio: \(preA.summary)")
        mainAsync { self.isRecording = true }
    }

    func stopRecording() async {
        let writer: ClipWriter? = withLock { () -> ClipWriter? in
            guard recording, !stopRequested else { return nil }
            stopRequested = true
            return activeWriter
        }
        guard let writer else { return }
        log("gravação", "parada pedida")
        let encoder = withLock { self.encoder }
        var stopBeepFired = false
        if beepEnabled && beepInClip {
            // Bipe de fim DENTRO do clipe: toca agora e o arquivo só é encerrado quando ele terminar.
            fireBeep(.stop)
            stopBeepFired = true
            try? await Task.sleep(nanoseconds: UInt64((beepDuration(.stop) + 0.1) * 1_000_000_000))
        }
        // Entrega os quadros que ainda estavam no codificador, ainda para o arquivo. v0.6.17: fora da fila do Swift e com limite
        // de 3 s; se o codificador demorar, a gravação encerra do mesmo jeito (o botão de parar nunca fica preso).
        let completeStarted = Date()
        let timedOut = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            let finished = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                encoder?.complete()
                finished.signal()
            }
            DispatchQueue.global(qos: .userInitiated).async {
                cont.resume(returning: finished.wait(timeout: .now() + 3) == .timedOut)
            }
        }
        log(
            "gravação",
            "codificador: quadros pendentes entregues em \(Int(Date().timeIntervalSince(completeStarted) * 1000)) ms"
                + (timedOut ? " (passou de 3 s; seguindo sem esperar)" : ""))
        let elapsed = withLock { () -> Double in
            recording = false
            activeWriter = nil
            ring.discardUntil(lastVideoTs)  // o fim deste clipe não pode reaparecer no começo do próximo
            return ProcessInfo.processInfo.systemUptime - recStartUptime
        }
        if !stopBeepFired { fireBeep(.stop) }
        mainAsync {
            self.isRecording = false
            self.recordSec = 0
        }
        log("gravação", "FIM · \(String(format: "%.1f", elapsed)) s gravados ao vivo; finalizando o arquivo…")

        let result = await withCheckedContinuation { (cont: CheckedContinuation<Result<URL, Error>, Never>) in
            writer.finish { cont.resume(returning: $0) }
        }
        switch result {
        case .failure(let error):
            log("gravação", "ERRO ao finalizar o arquivo: \(error)")
            try? FileManager.default.removeItem(at: writer.url)
            flash(Textos.falhaGravacao)
        case .success(let url):
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            let asset = AVURLAsset(url: url)
            let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
            // v0.3.10: taxa real do último clipe (mostra se a qualidade pedida chegou ao arquivo).
            let mbps = duration > 0 ? Double(size) * 8 / duration / 1e6 : 0
            let clipText = String(
                format: "%.1f MB · %.1f s · ≈ %.1f Mbps (vídeo + áudio)", Double(size) / 1_000_000, duration, mbps)
            withLock { lastClipText = clipText }
            log(
                "arquivo",
                "pronto: \(String(format: "%.2f", duration)) s (duração do arquivo), "
                    + "\(String(format: "%.1f", Double(size) / 1_000_000)) MB, "
                    + "\(writer.appendedVideo) quadros de vídeo, \(writer.appendedAudio) blocos de áudio")
            // Diagnóstico (v0.1.5): início e duração de cada trilha no arquivo pronto (conferir com o esperado).
            // v0.6.16: a miniatura sai do arquivo local e aparece no atalho já, enquanto o clipe ainda vai para as Fotos.
            let preSec = withLock { lastPreSec }
            let thumb = await ThumbnailStore.makeImage(from: url, at: preSec + 0.3)
            mainAsync { self.pendingThumbnail = thumb }
            let vTrack = await describeTrack(asset, .video)
            let aTrack = await describeTrack(asset, .audio)
            log("arquivo", "trilhas · vídeo: \(vTrack) · áudio: \(aTrack)")
            // v0.3.8: giro gravado no arquivo e tamanho com que a imagem aparece (conferir com a orientação do início).
            let rotation = await describeVideoRotation(asset)
            log("arquivo", "vídeo no arquivo: \(rotation)")
            do {
                let saved = try await PhotoSaver.saveClip(url)
                let detail = saved.detail
                if let thumb { ThumbnailStore.save(thumb, id: saved.id) }
                mainAsync {
                    self.savedCount += 1
                    mainAsyncAfter(0.8) { self.pendingThumbnail = nil }
                }
                log("Rolo", "OK · \(detail)" + (thumb == nil ? " · sem miniatura própria" : " · miniatura própria"))
                let forSpace = withLock { () -> Bool in
                    let value = stoppedForSpace
                    stoppedForSpace = false
                    return value
                }
                flash(forSpace ? Textos.clipeSalvoPoucoEspaco : Textos.clipeSalvo)
                try? FileManager.default.removeItem(at: url)
            } catch {
                log("Rolo", "ERRO ao salvar: \(error.localizedDescription) (arquivo mantido em \(url.lastPathComponent))")
                flash(Textos.naoSalvouNasFotos)
                mainAsync { self.pendingThumbnail = nil }
            }
        }
        // v0.6.2: se o calor pediu uma redução durante a gravação, ela é aplicada agora.
        mainAsync { self.evaluateThermal() }
    }

    // MARK: - Buffer e interface

    private func applyWindow() {
        let seconds = Double(effectiveWindowSec)
        withLock {
            ring.windowSec = seconds
            ring.trim()
        }
        log("buffer", "janela = \(effectiveWindowSec) s" + (effectiveWindowSec < windowSec ? " (pedido \(windowSec) s; limitada pela memória)" : ""))
    }

    private func tick() {
        MainMark.run("tick") {
            let (span, recSec, isRec) = withLock { () -> (Double, Double, Bool) in
                (
                    ring.spanSec(),
                    recording ? ProcessInfo.processInfo.systemUptime - recStartUptime : 0,
                    recording
                )
            }
            // O anel guarda a janela + 3 s de folga (para sempre haver keyframe); a tela mostra no máximo a janela.
            // v0.6.23: só publica quando o tempo mostrado muda (antes republicava 8 vezes por segundo, igual ou não).
            if let v = PublishRules.timeToPublish(shown: bufferSec, new: isRec ? 0 : min(span, Double(effectiveWindowSec))) { bufferSec = v }
            if let v = PublishRules.timeToPublish(shown: recordSec, new: recSec) { recordSec = v }
            // v0.6.0: a cada 5 s (20 batidas de 0,25 s) confere o espaço livre com a câmera aberta.
            storageTick += 1
            if storageTick % 20 == 0, withLock({ opened }) {
                scheduleStorageCheck()  // v0.6.21: a leitura lenta do espaço livre sai da tela principal
                MainMark.run("bateria") { evaluateBattery() }
            }
        }
    }

    /// v0.6.21: lê o espaço livre numa fila própria (a leitura do iOS pode demorar) e só então confere os níveis na tela
    /// principal, como antes. Se a leitura anterior ainda não terminou, pula esta e registra.
    private func scheduleStorageCheck() {
        let go = withLock { () -> Bool in
            if storageCheckBusy { return false }
            storageCheckBusy = true
            return true
        }
        guard go else {
            log("espaço", "leitura do espaço livre ainda em andamento (pulada)")
            return
        }
        storageQueue.async { [weak self] in
            guard let self else { return }
            let started = ProcessInfo.processInfo.systemUptime
            let free = StorageInfo.freeBytes()
            let ms = Int((ProcessInfo.processInfo.systemUptime - started) * 1000)
            if ms >= 300 { self.log("espaço", "a leitura do espaço livre levou \(ms) ms") }
            mainAsync {
                MainMark.run("espaço") {
                    if let free { self.checkStorage(free: free) }
                }
                self.withLock { self.storageCheckBusy = false }
            }
        }
    }

    // MARK: - Tela escura (v0.6.3)

    /// Escurece ou acende a tela (chamar na fila principal). Não muda o brilho do sistema: a tela fica preta por cima da câmera
    /// (o iPhone 15 é OLED: preto apaga os pixels), e o brilho do usuário nunca fica preso no mínimo se o app fechar.
    func setScreenDimmed(_ on: Bool) {
        if on && !canDimScreen(cameraOpen: isOpen, testRunning: testRunning) { return }
        guard screenDimmed != on else { return }
        screenDimmed = on
        log("tela", on ? "escurecida (câmera, gravação e voz continuam ativas)" : "acesa")
    }

    // MARK: - Recuperação (v0.6.13)

    private var recoveryDone = false

    /// Procura clipes que ficaram na pasta de gravações (o app fechou gravando, ou o salvamento nas Fotos falhou) e os salva no
    /// álbum Ei Clip. Roda uma vez por abertura do app, só com permissão das Fotos já concedida (não pede permissão sozinha).
    func recoverLeftovers() async {
        guard !recoveryDone, !withLock({ recording || activeWriter != nil }) else { return }
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else { return }
        recoveryDone = true
        let fm = FileManager.default
        let folder = RecordingFolder.url()
        let names = ((try? fm.contentsOfDirectory(atPath: folder.path)) ?? []).filter(RecordingFiles.isClipFile).sorted()
        guard !names.isEmpty else {
            log("recuperação", "nada pendente na pasta de gravações")
            return
        }
        log("recuperação", "\(names.count) arquivo(s) na pasta de gravações; conferindo")
        var saved = 0
        for name in names {
            let url = folder.appendingPathComponent(name)
            let bytes = (try? fm.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            guard RecordingFiles.isWorthRecovering(name: name, bytes: bytes) else {
                log("recuperação", "\(name): vazio (\(bytes) bytes); apagado")
                try? fm.removeItem(at: url)
                continue
            }
            let asset = AVURLAsset(url: url)
            let playable = (try? await asset.load(.isPlayable)) ?? false
            let seconds = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
            guard RecordingFiles.isRecoverable(isPlayable: playable, durationSec: seconds) else {
                log("recuperação", "\(name): não abre como vídeo (abre=\(playable), \(String(format: "%.1f", seconds)) s, \(bytes) bytes); apagado")
                try? fm.removeItem(at: url)
                continue
            }
            do {
                let thumb = await ThumbnailStore.makeImage(from: url, at: min(1.0, seconds / 2))
                let savedClip = try await PhotoSaver.saveClip(url)
                let detail = savedClip.detail
                if let thumb { ThumbnailStore.save(thumb, id: savedClip.id) }
                log("recuperação", "\(name): recuperado · \(String(format: "%.1f", seconds)) s, \(bytes / 1_000_000) MB · \(detail)")
                try? fm.removeItem(at: url)
                saved += 1
            } catch {
                log("recuperação", "\(name): não salvou nas Fotos (\(error.localizedDescription)); arquivo mantido para a próxima vez")
                recoveryDone = false
            }
        }
        if saved > 0 { flash(Textos.clipesRecuperados(saved)) }
    }

    // MARK: - Resolução, fluidez e qualidade (v0.6.11)

    /// O que aparece escolhido nos Ajustes (já corrigido: 4K fica em 30 fps).
    @Published private(set) var chosen: CaptureConfig = prefs.captureChoice.validated()

    /// Muda resolução, fluidez e/ou qualidade da imagem (chamar na fila principal; nunca gravando). Guarda a escolha e, com a
    /// câmera aberta, reabre a câmera com ela.
    func choose(quality: VideoQuality? = nil, fps: Int? = nil, level: ImageQuality? = nil) async {
        guard !withLock({ recording }), !testRunning else { return }
        guard beginReconfigure("ajuste de captura") else { return }
        defer { endReconfigure() }
        var raw = prefs.captureChoice
        if let quality { raw.quality = quality }
        if let fps { raw.fps = fps }
        if let level { raw.imageLevel = level }
        prefs.captureChoice = raw
        let changed = withLock { () -> Bool in
            var next = raw.validated()
            next.position = chosenConfig.position
            next.lens = chosenConfig.lens
            next.stabilize = chosenConfig.stabilize
            next = next.validated()
            let different = next != chosenConfig
            chosenConfig = next
            return different
        }
        chosen = withLock { chosenConfig }
        guard changed else { return }
        log("ajustes", "captura escolhida: \(chosen.summary)")
        await reconfigure(reason: "ajuste de captura")
    }

    // MARK: - Lentes (v0.6.10)

    /// A lente escolhida (para o botão destacado).
    @Published private(set) var lens: Lens = .wide

    /// O aparelho tem a lente ultra-angular traseira?
    let hasUltraWide = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil

    /// Fator da lente principal quando a câmera combinada está em uso; nulo no aparelho simples (v0.7.9). Sob a trava.
    private var combinedMain: Double?

    /// Escolhe a câmera combinada (ultra-angular + principal, com ou sem tele) se o aparelho a oferece e o formato pedido
    /// chega ao 2×. Decide pela capacidade informada pelo aparelho, nunca pelo nome do modelo. Nulo = usar a câmera simples.
    private func pickCombinedCamera() -> (device: AVCaptureDevice, main: Double)? {
        let types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera]
        var reason = "o aparelho não oferece câmera combinada"
        let size = config.quality.size
        for type in types {
            guard let device = AVCaptureDevice.default(type, for: .video, position: .back) else { continue }
            guard device.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) else {
                reason = "a combinada não inclui a ultra-angular"
                continue
            }
            let raw = device.virtualDeviceSwitchOverVideoZoomFactors.map { $0.doubleValue }
            guard let main = LensZoom.mainFactor(switchOvers: raw) else {
                reason = "o aparelho não informou o ponto de troca para a lente principal"
                continue
            }
            let infos = device.formats.map { (f: AVCaptureDevice.Format) -> FormatInfo in
                let d = CMVideoFormatDescriptionGetDimensions(f.formatDescription)
                let lo = f.videoSupportedFrameRateRanges.map(\.minFrameRate).min() ?? 0
                let hi = f.videoSupportedFrameRateRanges.map(\.maxFrameRate).max() ?? 0
                return FormatInfo(width: Int(d.width), height: Int(d.height), minFps: lo, maxFps: hi)
            }
            let fpsWanted = FormatPicker.effectiveFps(infos, width: size.width, height: size.height, requested: config.fps)
            guard let index = FormatPicker.pick(infos, width: size.width, height: size.height, fps: fpsWanted) else {
                reason = "a combinada não tem formato \(size.width)x\(size.height)"
                continue
            }
            let maxZoom = Double(device.formats[index].videoMaxZoomFactor)
            guard LensZoom.fits(main: main, maxZoom: maxZoom) else {
                reason = "o formato \(size.width)x\(size.height) só chega a \(String(format: "%.1f", maxZoom))× (o 2× pede \(String(format: "%.1f", main * 2))×)"
                continue
            }
            return (device, main)
        }
        log("lente", "câmera combinada não usada (\(reason)); usando a câmera simples (reserva)")
        return nil
    }

    /// Lentes que os botões oferecem agora.
    var availableLenses: [Lens] { LensRules.available(position: cameraPosition, hasUltraWide: hasUltraWide) }

    /// Texto do Diagnóstico: lente em uso e se o aparelho tem ultra-angular.
    var lensText: String {
        "\(lens.label) · ultra-angular: \(hasUltraWide ? "sim" : "não") · câmera: "
            + (withLock { combinedMain }.map { "combinada (1×=\(String(format: "%.1f", $0)))" } ?? "simples")
    }

    /// Troca de lente (chamar na fila principal). Entre 1× e 2× só muda a aproximação (vale até gravando); com a
    /// ultra-angular a câmera é reaberta (nunca gravando).
    ///
    /// v0.7.3: `@MainActor`. Antes a função `async` rodava fora da linha principal: toques rápidos em 1× ↔ 2× podiam rodar
    /// ao mesmo tempo, terminar fora de ordem e deixar o destaque da lente (`lens`, publicado) diferente do zoom aplicado.
    /// Agora cada toque roda inteiro, um de cada vez, na principal (a troca 1× ↔ 2× não tem pausa no meio).
    @MainActor
    func setLens(_ new: Lens) async {
        guard withLock({ opened }), !testRunning, availableLenses.contains(new) else { return }
        let (old, rec) = withLock { (chosenConfig.lens, recording) }
        guard LensRules.canSwitch(from: old, to: new, recording: rec) else {
            log("lente", "toque \(new.label) ignorado (\(old == new ? "já está nessa lente" : "gravando: só 1× ↔ 2×"))")
            return
        }
        log("lente", "toque: \(old.label) → \(new.label)")
        let reopen = LensRules.needsReopen(from: old, to: new, combined: withLock { combinedMain != nil })
        // v0.6.20: só a troca que reabre a câmera segura a trava (1× ↔ 2× só muda o zoom).
        if reopen {
            guard beginReconfigure("troca de lente") else { return }
        } else if withLock({ reconfigureGate.busy }) {
            return
        }
        defer { if reopen { endReconfigure() } }
        withLock {
            chosenConfig.lens = new
            if !reopen { config.lens = new }
        }
        lens = new
        if reopen {
            await reconfigure(reason: "lente \(new.label)")
            if !withLock({ opened }) {  // v0.6.20: estado real (isOpen é publicado depois, por uma fila assíncrona)
                withLock { chosenConfig.lens = old }
                lens = old
                log("câmera", "a lente \(new.label) não abriu; voltando para \(old.label)")
                await reconfigure(reason: "volta à lente \(old.label)")
            }
        } else {
            let main = withLock { combinedMain }
            sessionQueue.async { [weak self] in self?.applyZoom(LensZoom.factor(for: new, mainFactor: main)) }
        }
    }

    private func applyZoom(_ factor: Double) {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()
            let target = min(max(1, factor), device.activeFormat.videoMaxZoomFactor)
            device.ramp(toVideoZoomFactor: target, withRate: 6)
            device.unlockForConfiguration()
            log("lente", "aproximação \(String(format: "%.1f", target))×")
        } catch {
            log("lente", "não foi possível ajustar a aproximação: \(error.localizedDescription)")
        }
    }

    // MARK: - Câmera frontal (v0.6.9)

    /// Qual câmera está escolhida (para o ícone do botão).
    @Published private(set) var cameraPosition: CameraPosition = .back

    /// Troca entre a câmera traseira e a frontal (chamar na fila principal). Nunca gravando. Se a outra câmera não abrir,
    /// volta para a anterior.
    func switchCamera() async {
        guard withLock({ opened }), !testRunning, !withLock({ recording }) else {
            log("câmera", "troca de câmera ignorada: câmera fechada, gravando ou em teste")
            return
        }
        guard beginReconfigure("troca de câmera") else { return }
        defer { endReconfigure() }
        let previous = withLock { chosenConfig.position }
        let next = withLock { () -> CameraPosition in
            chosenConfig.position = chosenConfig.flipped
            chosenConfig = chosenConfig.validated()
            return chosenConfig.position
        }
        cameraPosition = next
        lens = withLock { chosenConfig.lens }
        await reconfigure(reason: "troca de câmera para \(next == .front ? "frontal" : "traseira")")
        if !withLock({ opened }) {  // v0.6.20: estado real da câmera, não o `isOpen` publicado depois
            withLock { chosenConfig.position = previous }
            cameraPosition = previous
            log("câmera", "a câmera \(next == .front ? "frontal" : "traseira") não abriu; voltando para a anterior")
            await reconfigure(reason: "volta à câmera anterior")
            flash(Textos.frontalNaoAbriu)
        }
    }

    // MARK: - Nível (v0.6.8)

    /// Ajustes > "Nível": mostra a linha de horizonte na câmera.
    @Published var levelEnabled: Bool = prefs.levelEnabled {
        didSet {
            prefs.levelEnabled = levelEnabled
            levelSmoothed = nil
            levelTilt = nil
            log("nível", levelEnabled ? "ligado" : "desligado")
        }
    }
    /// Inclinação suavizada em graus (nula: desligado ou aparelho deitado na mesa). Só na fila principal.
    @Published private(set) var levelTilt: Double?
    private var levelSmoothed: Double?
    /// v0.6.19: contadores do nível (só na fila principal) para o Diagnóstico medir leituras e redesenhos por segundo.
    private var levelReadings = 0
    private var levelPublished = 0
    private var levelWindowStart = Date()

    private func installLevelFeed() {
        orientation.onReading = { [weak self] x, y, z in
            mainAsync {
              MainMark.run("nível") {
                guard let self, self.levelEnabled else { return }
                self.levelReadings += 1
                let elapsed = Date().timeIntervalSince(self.levelWindowStart)
                if elapsed >= 10 {
                    self.log("nível", LevelRules.describeRate(readings: self.levelReadings, published: self.levelPublished, seconds: elapsed))
                    self.levelReadings = 0
                    self.levelPublished = 0
                    self.levelWindowStart = Date()
                }
                guard let raw = LevelRules.tilt(x: x, y: y, z: z) else {
                    self.levelSmoothed = nil
                    if self.levelTilt != nil { self.levelTilt = nil }
                    return
                }
                let value = LevelRules.smoothed(previous: self.levelSmoothed, new: raw)
                self.levelSmoothed = value
                // v0.6.16: cada publicação redesenha a tela da câmera; só publica quando a linha mexe de verdade
                // (v0.6.18: zona morta de 0,2°, em `LevelRules.publishDeadband`).
                guard LevelRules.shouldPublish(shown: self.levelTilt, new: value) else { return }
                self.levelPublished += 1
                self.levelTilt = value
              }
            }
        }
    }

    /// Texto do Diagnóstico.
    var levelText: String {
        levelEnabled ? LevelRules.describe(levelTilt) : "desligado"
    }

    // MARK: - Foco por toque (v0.6.7)

    /// O anel de foco na tela (só na fila principal).
    @Published private(set) var focusMark: FocusMark?
    private var focusCounter = 0
    private var subjectObserver: NSObjectProtocol?

    private var videoDevice: AVCaptureDevice? {
        session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.first { $0.device.hasMediaType(.video) }?.device
    }

    /// Foca e mede a luz no ponto tocado (chamar na fila principal). Quando a cena muda, volta ao automático no centro.
    func focus(devicePoint: CGPoint, screenPoint: CGPoint) {
        guard FocusRules.canFocus(
            cameraOpen: isOpen, dimmed: screenDimmed, testRunning: testRunning, reconfiguring: isReconfiguring)
        else { return }
        let p = FocusRules.clamp(x: Double(devicePoint.x), y: Double(devicePoint.y))
        focusCounter += 1
        focusMark = FocusMark(id: focusCounter, x: Double(screenPoint.x), y: Double(screenPoint.y), at: ProcessInfo.processInfo.systemUptime)
        sessionQueue.async { [weak self] in self?.setFocus(x: p.x, y: p.y, monitorChange: true) }
    }

    func clearFocusMark(_ id: Int) {
        if focusMark?.id == id { focusMark = nil }
    }

    private func setFocus(x: Double, y: Double, monitorChange: Bool) {
        guard let device = videoDevice else { return }
        do {
            try device.lockForConfiguration()
            let point = CGPoint(x: x, y: y)
            var parts: [String] = []
            if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusPointOfInterest = point
                device.focusMode = .continuousAutoFocus
                parts.append("foco")
            }
            if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposurePointOfInterest = point
                device.exposureMode = .continuousAutoExposure
                parts.append("exposição")
            }
            device.isSubjectAreaChangeMonitoringEnabled = monitorChange
            device.unlockForConfiguration()
            log("foco", "\(monitorChange ? "toque" : "automático") em (\(String(format: "%.2f", x)); \(String(format: "%.2f", y))) · \(parts.isEmpty ? "o aparelho não oferece ponto de foco" : parts.joined(separator: " e "))")
        } catch {
            log("foco", "não foi possível ajustar: \(error.localizedDescription)")
        }
        if monitorChange, subjectObserver == nil {
            subjectObserver = NotificationCenter.default.addObserver(
                forName: AVCaptureDevice.subjectAreaDidChangeNotification, object: nil, queue: nil
            ) { [weak self] _ in
                self?.sessionQueue.async {
                    self?.setFocus(x: FocusRules.center.x, y: FocusRules.center.y, monitorChange: false)
                }
            }
        }
    }

    // MARK: - Estabilização (v0.6.6)

    /// Texto do Diagnóstico: o que foi pedido e o modo que o iPhone realmente ativou.
    var stabilizationText = "-"

    /// Aplica a estabilização à conexão de vídeo (na abertura e quando o usuário mexe na chave).
    func applyStabilization(connection: AVCaptureConnection? = nil) {
        let want = withLock { config.stabilize }
        guard let connection = connection ?? videoOutput.connection(with: .video) else {
            withLock { stabilizationText = want ? "ligada (sem conexão ainda)" : "desligada" }
            return
        }
        guard connection.isVideoStabilizationSupported else {
            withLock { stabilizationText = want ? "ligada, mas esta câmera/formato não oferece" : "desligada" }
            return
        }
        connection.preferredVideoStabilizationMode = want ? .auto : .off
        let active = connection.activeVideoStabilizationMode
        let name: String
        switch active {
        case .off: name = "desligado"
        case .standard: name = "padrão"
        case .cinematic: name = "cinemático"
        case .cinematicExtended: name = "cinemático estendido"
        case .auto: name = "automático"
        default: name = "outro"
        }
        withLock { stabilizationText = want ? "ligada (modo ativo: \(name))" : "desligada" }
        log("imagem", "estabilização pedida: \(want ? "sim" : "não") · modo ativo: \(name)")
    }

    // MARK: - Temperatura (v0.6.2)

    /// Reage ao estado térmico (chamar na fila principal): avisa e, se preciso, reduz a qualidade sozinho. A redução reabre a
    /// câmera, então nunca acontece no meio de uma gravação (fica para quando ela terminar).
    func evaluateThermal() {
        let level = DiagSystemInfo.thermalLevel()
        let (action, target, chosen) = withLock { () -> (ThermalAction, CaptureConfig, CaptureConfig) in
            let action = heat.react(level: level, chosen: chosenConfig, recording: recording)
            return (action, chosenConfig.lowered(by: heat.appliedSteps).validated(), chosenConfig)
        }
        if let notice = action.notice {
            let text: String
            switch notice {
            case .reduced: text = Textos.qualidadeReduzida(target.summary)
            case .reducePending: text = Textos.reducaoAdiada
            case .hotAtFloor: text = Textos.quenteNoPiso
            case .critical: text = action.lowerTo != nil ? Textos.muitoQuenteReduzida(target.summary) : Textos.muitoQuente
            }
            log("temperatura", "\(DiagSystemInfo.thermal().text) · aviso: \(notice) · escolhida \(chosen.summary) · valendo \(target.summary)")
            flash(text)
        }
        guard let steps = action.lowerTo else { return }
        withLock { heatText = "\(chosen.summary) → \(target.summary) (\(steps) passo(s))" }
        Task {
            // v0.6.20: se outra reconfiguração está em andamento, espera até 5 s e tenta de novo.
            for _ in 0..<5 {
                if self.withLock({ self.reconfigureGate.tryBegin() }) {
                    mainAsync { self.isReconfiguring = true }
                    await self.reconfigure(reason: "temperatura \(DiagSystemInfo.thermal().text)")
                    self.endReconfigure()
                    return
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            self.log("temperatura", "redução adiada: a câmera seguiu ocupada por 5 s")
        }
    }

    // MARK: Trava da reconfiguração (v0.6.20)

    /// Pega a trava de reconfiguração (um só dono por vez, decidido sob a trava do motor, sem fila assíncrona no meio).
    /// Recusado: registra uma linha, para o Diagnóstico mostrar toques ignorados. Quem pegar deve chamar `endReconfigure()`.
    private func beginReconfigure(_ what: String) -> Bool {
        let ok = withLock { reconfigureGate.tryBegin() }
        if ok {
            mainAsync { self.isReconfiguring = true }
        } else {
            log("câmera", "\(what) ignorado: a câmera já está sendo reconfigurada")
        }
        return ok
    }

    private func endReconfigure() {
        withLock { reconfigureGate.end() }
        mainAsync { self.isReconfiguring = false }
    }

    /// Reabre a câmera com a configuração que vale agora (a voz e o buffer recomeçam, como ao voltar do segundo plano).
    /// Com a câmera fechada não faz nada: a próxima abertura já usa a configuração nova. Nunca roda gravando.
    /// v0.6.20: quem chama segura a trava (`beginReconfigure`) durante a reconfiguração e as voltas.
    func reconfigure(reason: String) async {
        guard withLock({ opened && !recording }) else {
            log("câmera", "reconfiguração (\(reason)) ignorada: câmera fechada ou gravando")
            return
        }
        let started = Date()
        log("câmera", "reconfigurando (\(reason))")
        // v0.6.16: se a reconfiguração demorar, o registro mostra em que ponto parou (a rodada anterior fica salva em arquivo).
        let watchdog = Task { [weak self] in
            for seconds in [4, 10, 20] {
                try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
                if Task.isCancelled { return }
                self?.log("câmera", "reconfiguração (\(reason)) ainda em andamento após \(seconds) s")
            }
        }
        await closeCamera(reason: "reconfiguração: \(reason)")
        log("câmera", "reconfiguração: fechada em \(Int(Date().timeIntervalSince(started) * 1000)) ms; abrindo")
        _ = await openCamera()
        watchdog.cancel()
        log("câmera", "reconfiguração concluída em \(Int(Date().timeIntervalSince(started) * 1000)) ms")
    }

    // MARK: - Bateria (v0.6.1)

    /// Pede a conferência da bateria na fila principal (quem chama pode estar em outra fila).
    func checkBattery() {
        mainAsync { self.evaluateBattery() }
    }

    /// Lê a bateria e avisa quando o nível piora, só com a câmera aberta (chamar na fila principal).
    func evaluateBattery() {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let raw = device.batteryLevel  // -1 quando o sistema não informa
        let percent: Int? = raw < 0 ? nil : Int((raw * 100).rounded())
        let state = device.batteryState
        let charging = state == .charging || state == .full
        let text = BatteryRules.describe(percent: percent, charging: charging)
        let level = percent.map { BatteryRules.level(percent: $0, charging: charging) } ?? .ok
        let warn = withLock { () -> BatteryLevel? in
            batteryText = text
            batteryLevel = level
            return opened ? batteryAlerts.update(percent: percent, charging: charging) : nil
        }
        guard let warn, let percent else { return }
        log("bateria", "\(warn == .critical ? "MUITO BAIXA" : "BAIXA") · \(text)")
        flash(warn == .critical ? Textos.bateriaCritica(percent) : Textos.bateriaBaixa(percent))
    }

    // MARK: - Espaço livre (v0.6.0)

    /// Confere o espaço livre: ao abrir a câmera e a cada 5 s com a câmera aberta (parada ou gravando). Avisa quando o nível
    /// piora e, gravando, encerra e salva o clipe antes que o espaço acabe (salvar nas Fotos também precisa de espaço).
    func checkStorage(free freeRead: Int64? = nil) {
        guard let free = freeRead ?? StorageInfo.freeBytes() else { return }
        let bitrate = videoBitrate(quality, fps: fps, level: imageLevel)
        let level = StorageRules.level(freeBytes: free, videoBitrate: bitrate)
        let minutes = StorageRules.remainingSeconds(freeBytes: free, videoBitrate: bitrate) / 60
        let text = StorageRules.describe(freeBytes: free, videoBitrate: bitrate)
        let (warn, activeRecording, elapsed) = withLock { () -> (StorageLevel?, Bool, Double) in
            storageText = text
            storageLevel = level
            let active = recording && !stopRequested
            let seconds = active ? ProcessInfo.processInfo.systemUptime - recStartUptime : 0
            return (storageAlerts.update(level), active, seconds)
        }
        if let warn {
            log("espaço", "\(warn == .critical ? "QUASE ESGOTADO" : "POUCO") · \(text)")
            flash(warn == .critical ? Textos.espacoCritico(minutes) : Textos.poucoEspaco(minutes))
        }
        guard activeRecording else { return }
        // Gravado até agora (com o pré-tempo): estimativa pela taxa pedida, para errar sempre para o lado seguro.
        let perSecond = Double(StorageRules.bytesPerSecond(videoBitrate: bitrate))
        let recorded = Int64((elapsed + Double(windowSec)) * perSecond)
        if StorageRules.shouldStopRecording(freeBytes: free, recordedBytes: recorded, videoBitrate: bitrate) {
            log("espaço", "ENCERRANDO a gravação para salvar o clipe a tempo · \(text) · gravado ≈ \(recorded / 1_000_000) MB")
            withLock { stoppedForSpace = true }
            flash(Textos.gravacaoEncerradaPorEspaco)
            Task { await self.stopRecording() }
        }
    }

    /// Aviso curto na tela (some em 3 s). Desde a v0.4.1 também é usado pela interface (ex.: "Termine a gravação primeiro.").
    func flash(_ text: String) {
        mainAsync {
            self.message = text
            mainAsyncAfter(3) {
                if self.message == text { self.message = "" }
            }
        }
    }

    // MARK: - Teste de aberturas (critério "a" da etapa 1)

    /// Abre e fecha a câmera `times` vezes e anota, a cada abertura, se o microfone nasceu mudo.
    func runOpenTest(times: Int = 20) async {
        guard !testRunning, !withLock({ recording }) else { return }
        mainAsync { self.testRunning = true }
        await closeCamera(reason: "início do teste")
        log("TESTE", "início: \(times) aberturas seguidas (3,5 s abertas, 1 s fechadas)")
        var silent = 0
        var failed = 0
        for i in 1...times {
            guard await openCamera() else {
                failed += 1
                log("TESTE", "abertura \(i)/\(times): FALHA ao abrir")
                continue
            }
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            let p = withLock { peak.peak }
            let mute = isMicSilent(peak: p)
            if mute { silent += 1 }
            log("TESTE", "abertura \(i)/\(times): pico=\(String(format: "%.4f", p)) \(mute ? "MUDO" : "ok")")
            await closeCamera(reason: "teste \(i)")
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        log("TESTE", "FIM: \(silent) microfones mudos e \(failed) falhas em \(times) aberturas (critério: 0 e 0)")
        mainAsync { self.testRunning = false }
    }

    // MARK: - Eventos do sistema (só registro no Diagnóstico)

    private func installObservers() {
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(forName: .AVCaptureSessionRuntimeError, object: session, queue: nil) { [weak self] n in
                let err = n.userInfo?[AVCaptureSessionErrorKey] as? NSError
                self?.log("sessão", "ERRO de execução: \(err?.localizedDescription ?? "?") (\(err?.code ?? 0))")
            })
        observers.append(
            center.addObserver(forName: .AVCaptureSessionWasInterrupted, object: session, queue: nil) { [weak self] n in
                let reason = n.userInfo?[AVCaptureSessionInterruptionReasonKey] as? Int ?? -1
                mainAsync {
                    let state = UIApplication.shared.applicationState
                    let name = state == .active ? "ativo" : (state == .inactive ? "inativo" : "segundo plano")
                    self?.log("sessão", "INTERROMPIDA (motivo \(reason)) · app \(name)")
                }
            })
        observers.append(
            center.addObserver(forName: .AVCaptureSessionInterruptionEnded, object: session, queue: nil) { [weak self] _ in
                self?.log("sessão", "interrupção terminou")
            })
        // v0.6.2: o estado térmico mudou (normal, morno, quente, crítico).
        observers.append(
            center.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                self?.log("temperatura", "estado térmico: \(DiagSystemInfo.thermal().text)")
                self?.evaluateThermal()
            })
        // v0.6.1: a bateria mudou de percentual ou de estado (ligou ou tirou o carregador).
        observers.append(
            center.addObserver(forName: UIDevice.batteryLevelDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                self?.evaluateBattery()
            })
        observers.append(
            center.addObserver(forName: UIDevice.batteryStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                self?.evaluateBattery()
            })
        observers.append(
            center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] n in
                let type = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
                self?.log("áudio", "interrupção da sessão de áudio (tipo \(type == 1 ? "começou" : "terminou"))")
            })
        observers.append(
            center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil) { [weak self] n in
                let reason = n.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0
                self?.log("áudio", "rota mudou (motivo \(reason)): \(AudioSessionConfig.describe())")
            })
    }
}

// MARK: - Entrega de amostras

extension CaptureEngine: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output === videoOutput {
            handleVideo(sampleBuffer)
        } else if output === audioOutput {
            handleAudio(sampleBuffer)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output === videoOutput { handleDropped(sampleBuffer) }
    }
}
