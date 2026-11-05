import AVFoundation
import Combine
import UIKit

/// Um bipe disparado: o microfone fica em silêncio durante ele (medido pela hora em que o som foi CAPTADO,
/// não pela hora em que o bloco de áudio chegou ao app) e, com "Sons no vídeo", o bipe é somado ao áudio do clipe.
private struct BeepWindow {
    let start: Double  // hora do relógio do aparelho em que o bipe foi disparado
    let muteEnd: Double  // fim do silêncio no microfone
    let samples: [Float]?  // bipe a somar ao clipe (só com "Sons no vídeo")
}

/// Motor do Ei Clip (etapa 1): câmera traseira 1080p30 + microfone, anel retroativo de vídeo codificado,
/// gravação num arquivo único e salvamento no álbum "Ei Clip".
///
/// Filas: `sessionQueue` (abrir/fechar a captura), `videoQueue`/`audioQueue` (entrega de amostras),
/// `controlQueue` (iniciar gravação). Todo o estado compartilhado fica protegido por `lock`.
final class CaptureEngine: NSObject, ObservableObject {
    // MARK: Estado para a tela (alterado só na fila principal)
    @Published private(set) var isOpen = false
    @Published private(set) var isRecording = false
    @Published private(set) var bufferSec: Double = 0
    @Published private(set) var recordSec: Double = 0
    @Published private(set) var message = ""
    @Published private(set) var testRunning = false
    /// v0.2.0/0.2.2: o que a voz faz (desligada, só mede, ou comando "Ei Clip" que liga e para a gravação).
    @Published private(set) var voiceMode: VoiceMode = .off
    /// v0.3.11: vira true por 1,2 s quando um "Ei Clip" é aceito (o botão de voz acende em verde, como no web app).
    @Published private(set) var voiceHeard = false
    /// Preferência "Comando de voz" (v0.3.7), como no web app: ligada, a voz acompanha a câmera
    /// (liga ao abrir e ao reabrir; desliga ao fechar). Guardada no aparelho; começa ligada.
    @Published var voiceEnabled: Bool = (UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool) ?? true {
        didSet {
            UserDefaults.standard.set(voiceEnabled, forKey: "voiceEnabled")
            log("voz", "Comando de voz: \(voiceEnabled ? "ligado" : "desligado") (preferência)")
            if isOpen && !testRunning { setVoiceMode(voiceEnabled ? .command : .off) }
        }
    }
    /// v0.2.5: qual das 3 palavras age no modo comando (guardada no aparelho; a tela final de Ajustes é a etapa 3).
    @Published var voiceWord: WakeWord = WakeWord.parse(UserDefaults.standard.string(forKey: "voiceWord")) ?? WakeWord.defaultWord {
        didSet {
            UserDefaults.standard.set(voiceWord.rawValue, forKey: "voiceWord")
            voiceProbe.activeWord = voiceWord
            log("voz", "palavra de ativação: \(voiceWord.label)")
        }
    }
    @Published var windowSec: Int = 15 {
        didSet { applyWindow() }
    }
    /// Ajustes > Sons > "Sons de gravação": bipe de início e de fim (ligado por padrão, como no web app).
    @Published var beepEnabled: Bool = (UserDefaults.standard.object(forKey: "beepEnabled") as? Bool) ?? true {
        didSet {
            UserDefaults.standard.set(beepEnabled, forKey: "beepEnabled")
            log("sons", "Sons de gravação: \(beepEnabled ? "ligados" : "desligados")")
        }
    }
    /// Ajustes > Sons > "Sons no vídeo": o bipe também fica gravado no clipe (desligado por padrão, como no web app).
    @Published var beepInClip: Bool = UserDefaults.standard.bool(forKey: "beepInClip") {
        didSet {
            UserDefaults.standard.set(beepInClip, forKey: "beepInClip")
            log("sons", "Sons no vídeo: \(beepInClip ? "ligados" : "desligados")")
        }
    }

    // MARK: Configuração (etapa 1: 1080p30, qualidade padrão)
    private let quality = VideoQuality.p1080
    private let fps = 30
    private let imageLevel = ImageQuality.standard

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
    private let orientation = OrientationSensor(log: { Diagnostics.shared.log($0, $1) })

    // MARK: Estado compartilhado (protegido por `lock`)
    private let lock = NSLock()
    private var ring = ReplayBuffer<CMSampleBuffer>(windowSec: 15)
    private var recording = false
    private var activeWriter: ClipWriter?
    private var videoFormat: CMFormatDescription?
    private var audioFormat: CMFormatDescription?
    private var opened = false
    /// v0.1.8: a câmera foi fechada porque o app foi para o segundo plano (reabre sozinha ao voltar).
    private var reopenOnReturn = false
    private var openToken = 0
    private var peak = PeakTracker()
    private var lastVideoTs: Int64 = 0
    private var beepWindows: [BeepWindow] = []
    private var stopRequested = false
    private var recStartUptime: TimeInterval = 0
    /// v0.2.2: quando o último comando de voz foi executado (trava de 3 s entre comandos, como no web app).
    private var lastVoiceActionUptime: TimeInterval = -100
    private var encoder: VideoEncoder?
    private var cVideoFrames = 0
    private var cDropped = 0
    private var cEncoded = 0
    private var cEncoderErrors = 0
    private var cAudioBuffers = 0
    private var cAudioCopyFails = 0
    private var firstDropLogged = false
    // Diagnóstico (v0.1.5): quantas aberturas desde que o app abriu e quando a atual começou.
    private var openCount = 0
    private var openedAtUptime: TimeInterval = 0
    // Diagnóstico (v0.3.10): dados só para o painel (não mudam o comportamento).
    private let launchedAtUptime = ProcessInfo.processInfo.systemUptime
    private var deliveredFormat = "-"
    private var lastClipText = "-"
    private var fpsSampleFrames = 0
    private var fpsSampleAt: TimeInterval = 0
    private var fpsLast = 0.0

    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
        LaunchLog.record()  // v0.3.10: Diagnóstico mostra os últimos inícios do app
        voiceProbe.onState = { [weak self] on in
            // A sonda parou (botão, câmera fechada, sem permissão, erro): a voz fica desligada.
            if !on { DispatchQueue.main.async { self?.voiceMode = .off } }
        }
        voiceProbe.stateProvider = { [weak self] in self?.wakeState() ?? .idle }
        voiceProbe.onWake = { [weak self] kind, wasRecording in self?.voiceWake(kind, wasRecording: wasRecording) }
        voiceProbe.activeWord = voiceWord
        installObservers()
        DispatchQueue.main.async { [weak self] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in self?.tick() }
        }
    }

    private func log(_ tag: String, _ text: String) {
        Diagnostics.shared.log(tag, text)
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return body()
    }

    // MARK: - Abrir

    /// Abre a câmera e o microfone. Devolve falso se algo falhou (o motivo vai para o Diagnóstico).
    func openCamera() async -> Bool {
        if withLock({ opened }) { return true }
        let started = Date()
        log("câmera", "abrindo… (\(quality.rawValue)p\(fps), buffer \(windowSec) s)")

        let camOK = await AVCaptureDevice.requestAccess(for: .video)
        let micOK = await AVCaptureDevice.requestAccess(for: .audio)
        let photos = await PhotoSaver.requestAccess()
        log("permissões", "câmera=\(camOK) microfone=\(micOK) fotos=\(photos.rawValue)")
        guard camOK else {
            flash("Sem permissão de câmera. Libere em Ajustes.")
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
            DispatchQueue.main.async {
                self.isOpen = true
                UIApplication.shared.isIdleTimerDisabled = true
                // v0.3.7: a voz liga junto com a câmera (menos no teste de aberturas, que não deve ser perturbado).
                if self.voiceEnabled && !self.testRunning { self.setVoiceMode(.command) }
            }
        } else {
            log("câmera", "FALHOU ao abrir (\(ms) ms)")
            flash("Não foi possível abrir a câmera.")
        }
        return ok
    }

    private func configureAndStart(withMic: Bool) -> Bool {
        withLock {
            ring = ReplayBuffer<CMSampleBuffer>(windowSec: Double(windowSec))
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
        session.sessionPreset = .hd1920x1080
        session.automaticallyConfiguresApplicationAudioSession = false

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            log("câmera", "ERRO: câmera traseira indisponível (o sistema não devolveu o aparelho)")
            resetSession()
            return false
        }
        guard let videoInput = try? AVCaptureDeviceInput(device: camera), session.canAddInput(videoInput) else {
            session.commitConfiguration()
            log("câmera", "ERRO: não foi possível usar a câmera traseira (entrada recusada pela sessão)")
            resetSession()
            return false
        }
        session.addInput(videoInput)

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

        do {
            try camera.lockForConfiguration()
            let frame = CMTime(value: 1, timescale: CMTimeScale(fps))
            camera.activeVideoMinFrameDuration = frame
            camera.activeVideoMaxFrameDuration = frame
            camera.unlockForConfiguration()
        } catch {
            log("câmera", "aviso: não foi possível fixar \(fps) fps: \(error.localizedDescription)")
        }
        let dims = CMVideoFormatDescriptionGetDimensions(camera.activeFormat.formatDescription)
        log("câmera", "formato ativo \(dims.width)x\(dims.height), \(fps) fps pedidos")
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
        DispatchQueue.main.async {
            self.voiceHeard = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { self.voiceHeard = false }
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
        DispatchQueue.main.async {
            self.isOpen = false
            self.bufferSec = 0
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
            flash("Aguarde 1 segundo e tente de novo.")
            return
        }
        guard let vfd = videoFormat else {
            lock.unlock()
            log("gravação", "não iniciou: sem formato de vídeo")
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(clipFileName())
        let offset = CMSampleBufferGetPresentationTimeStamp(selection.video[0].payload)
        let writer: ClipWriter
        do {
            // A tela é sempre em pé; o giro do arquivo vem da posição do aparelho no começo do clipe
            // (em pé = 90°, igual às versões anteriores). Sem recodificar: só a matriz do arquivo.
            let m = snap.hold.fileMatrix
            writer = try ClipWriter(
                url: url, videoFormat: vfd, audioFormat: audioFormat, offset: offset,
                transform: CGAffineTransform(a: m.a, b: m.b, c: m.c, d: m.d, tx: 0, ty: 0))
        } catch {
            lock.unlock()
            log("gravação", "ERRO ao criar o arquivo: \(error)")
            flash("Não foi possível gravar.")
            return
        }
        recording = true
        stopRequested = false
        activeWriter = writer
        recStartUptime = ProcessInfo.processInfo.systemUptime
        let ringSeconds = ring.spanSec()
        ring.clear()
        lock.unlock()

        writer.onLog = { [weak self] message in self?.log("arquivo", message) }
        // v0.1.7: se o arquivo falhar durante a gravação, encerra na hora e avisa (sem esperar o vigia de 30 s).
        writer.onFailed = { [weak self, weak writer] _ in
            guard let self, let writer else { return }
            let stopNow = self.withLock { self.recording && !self.stopRequested && self.activeWriter === writer }
            guard stopNow else { return }
            self.log("gravação", "o arquivo falhou durante a gravação; encerrando agora")
            Task { await self.stopRecording() }
        }
        writer.begin(video: selection.video.map { $0.payload }, audio: selection.audio.map { $0.payload })
        fireBeep(.start)
        log(
            "gravação",
            "orientação do arquivo: aparelho \(snap.hold.label) → giro de \(snap.hold.fileRotationDegrees)° (\(snap.readingText))")
        log(
            "gravação",
            "INÍCIO · pré-tempo pedido=\(windowSec) s · real=\(String(format: "%.2f", selection.preSec)) s "
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
        DispatchQueue.main.async { self.isRecording = true }
    }

    func stopRecording() async {
        let writer: ClipWriter? = withLock { () -> ClipWriter? in
            guard recording, !stopRequested else { return nil }
            stopRequested = true
            return activeWriter
        }
        guard let writer else { return }
        let encoder = withLock { self.encoder }
        var stopBeepFired = false
        if beepEnabled && beepInClip {
            // Bipe de fim DENTRO do clipe: toca agora e o arquivo só é encerrado quando ele terminar.
            fireBeep(.stop)
            stopBeepFired = true
            try? await Task.sleep(nanoseconds: UInt64((beepDuration(.stop) + 0.1) * 1_000_000_000))
        }
        encoder?.complete()  // entrega os quadros que ainda estavam no codificador, ainda para o arquivo
        let elapsed = withLock { () -> Double in
            recording = false
            activeWriter = nil
            ring.discardUntil(lastVideoTs)  // o fim deste clipe não pode reaparecer no começo do próximo
            return ProcessInfo.processInfo.systemUptime - recStartUptime
        }
        if !stopBeepFired { fireBeep(.stop) }
        DispatchQueue.main.async {
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
            let vTrack = await describeTrack(asset, .video)
            let aTrack = await describeTrack(asset, .audio)
            log("arquivo", "trilhas · vídeo: \(vTrack) · áudio: \(aTrack)")
            // v0.3.8: giro gravado no arquivo e tamanho com que a imagem aparece (conferir com a orientação do início).
            let rotation = await describeVideoRotation(asset)
            log("arquivo", "vídeo no arquivo: \(rotation)")
            do {
                let detail = try await PhotoSaver.save(url)
                log("Rolo", "OK · \(detail)")
                flash("Clipe salvo no álbum Ei Clip.")
                try? FileManager.default.removeItem(at: url)
            } catch {
                log("Rolo", "ERRO ao salvar: \(error.localizedDescription) (arquivo mantido em \(url.lastPathComponent))")
                flash("Não foi possível salvar nas Fotos.")
            }
        }
    }

    // MARK: - Buffer e interface

    private func applyWindow() {
        let seconds = Double(windowSec)
        withLock {
            ring.windowSec = seconds
            ring.trim()
        }
        log("buffer", "janela = \(windowSec) s")
    }

    private func tick() {
        let (span, recSec, isRec) = withLock { () -> (Double, Double, Bool) in
            (
                ring.spanSec(),
                recording ? ProcessInfo.processInfo.systemUptime - recStartUptime : 0,
                recording
            )
        }
        // O anel guarda a janela + 3 s de folga (para sempre haver keyframe); a tela mostra no máximo a janela.
        bufferSec = isRec ? 0 : min(span, Double(windowSec))
        recordSec = recSec
    }

    private func flash(_ text: String) {
        DispatchQueue.main.async {
            self.message = text
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if self.message == text { self.message = "" }
            }
        }
    }

    // MARK: - Teste de aberturas (critério "a" da etapa 1)

    /// Abre e fecha a câmera `times` vezes e anota, a cada abertura, se o microfone nasceu mudo.
    func runOpenTest(times: Int = 20) async {
        guard !testRunning, !withLock({ recording }) else { return }
        DispatchQueue.main.async { self.testRunning = true }
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
        DispatchQueue.main.async { self.testRunning = false }
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
                DispatchQueue.main.async {
                    let state = UIApplication.shared.applicationState
                    let name = state == .active ? "ativo" : (state == .inactive ? "inativo" : "segundo plano")
                    self?.log("sessão", "INTERROMPIDA (motivo \(reason)) · app \(name)")
                }
            })
        observers.append(
            center.addObserver(forName: .AVCaptureSessionInterruptionEnded, object: session, queue: nil) { [weak self] _ in
                self?.log("sessão", "interrupção terminou")
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

// MARK: - Painel do Diagnóstico (v0.3.10)

extension CaptureEngine {
    /// Tudo que o painel do Diagnóstico mostra, de uma vez. Chamar na fila principal (lê o estado do app e do Diagnóstico).
    func diagnosticsSnapshot() -> DiagSnapshot {
        var s = DiagSnapshot()
        let now = ProcessInfo.processInfo.systemUptime
        let v = ProcessInfo.processInfo.operatingSystemVersion

        s.appVersion = Diagnostics.appVersion
        s.device = "\(Diagnostics.machineName) · iOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        s.appState = DiagSystemInfo.appStateName(UIApplication.shared.applicationState)
        s.appOpenSec = Int(now - launchedAtUptime)
        let thermal = DiagSystemInfo.thermal()
        s.thermal = thermal.text
        s.thermalSevere = thermal.severe
        s.recording = isRecording
        s.message = message

        // Voz
        s.voiceEnabled = voiceEnabled
        s.voiceWord = voiceWord.label
        switch voiceMode {
        case .off: s.voiceMode = "desligada"
        case .measure: s.voiceMode = "só medir (não grava)"
        case .command: s.voiceMode = "comando (\(voiceWord.label) liga e para a gravação)"
        }

        // Pedido e ajustes
        s.requested = "\(quality.rawValue)p · \(fps) fps · padrão"
        s.codec = "H.264 (hardware) · \(videoBitrate(quality, fps: fps, level: imageLevel) / 1_000_000) Mbps"
        s.windowSec = windowSec
        s.beepOn = beepEnabled
        s.beepInClip = beepInClip

        // Captura (sob o trava do motor)
        withLock { () -> Void in
            s.cameraOpen = opened
            s.openCount = openCount
            s.cameraOpenSec = opened ? now - openedAtUptime : 0
            s.framesIn = cVideoFrames
            s.framesEncoded = cEncoded
            s.dropped = cDropped
            s.encoderErrors = cEncoderErrors
            s.audioBlocks = cAudioBuffers
            s.audioCopyFails = cAudioCopyFails
            s.micPeak = peak.peak
            s.bufferSec = ring.spanSec()
            s.bufferVideoFrames = ring.video.count
            s.bufferAudioBlocks = ring.audio.count
            s.delivered = opened ? deliveredFormat : "-"
            s.lastClip = lastClipText
            if let fd = audioFormat { s.audioFormat = describeAudioFormat(fd) }
            // Quadros codificados por segundo, medidos entre duas leituras do painel (mínimo 0,9 s entre elas).
            if !opened {
                fpsLast = 0
                fpsSampleAt = 0
            } else if fpsSampleAt == 0 {
                fpsSampleAt = now
                fpsSampleFrames = cEncoded
            } else if now - fpsSampleAt >= 0.9 {
                fpsLast = Double(max(0, cEncoded - fpsSampleFrames)) / (now - fpsSampleAt)
                fpsSampleAt = now
                fpsSampleFrames = cEncoded
            }
            s.fpsOut = fpsLast
        }

        // Áudio e orientação
        s.audioSession = AudioSessionConfig.describe()
        let hold = orientation.snapshot()
        s.holdLabel = hold.hold.label
        s.holdReading = hold.readingText
        s.fileRotationDegrees = hold.hold.fileRotationDegrees

        // Permissões
        let cam = DiagSystemInfo.permission(AVCaptureDevice.authorizationStatus(for: .video))
        let mic = DiagSystemInfo.permission(AVCaptureDevice.authorizationStatus(for: .audio))
        let photos = DiagSystemInfo.photos()
        s.permCamera = cam.text
        s.cameraDenied = cam.blocked
        s.permMic = mic.text
        s.micDenied = mic.blocked
        s.permPhotos = photos.text
        s.photosNotFull = photos.notFull

        // Linhas do registro: voz (sem os textos parciais) e ciclo de vida (idas e voltas ao app, câmera fechada/reaberta)
        let lines = Diagnostics.shared.lines
        s.voiceLog = Array(lines.filter { $0.contains("] voz: ") && !$0.contains("parcial") }.suffix(6))
        let lifecycleMarks = ["] app: estado", "] sessão: ", "câmera: fechada", "câmera: reabertura"]
        s.lifecycle = Array(lines.filter { line in lifecycleMarks.contains { line.contains($0) } }.suffix(6))
        s.launches = LaunchLog.text()
        return s
    }
}
