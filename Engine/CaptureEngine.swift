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

    // MARK: Estado compartilhado (protegido por `lock`)
    private let lock = NSLock()
    private var ring = ReplayBuffer<CMSampleBuffer>(windowSec: 15)
    private var recording = false
    private var activeWriter: ClipWriter?
    private var videoFormat: CMFormatDescription?
    private var audioFormat: CMFormatDescription?
    private var opened = false
    private var openToken = 0
    private var peak = PeakTracker()
    private var lastVideoTs: Int64 = 0
    private var beepWindows: [BeepWindow] = []
    private var stopRequested = false
    private var recStartUptime: TimeInterval = 0
    private var encoder: VideoEncoder?
    private var cVideoFrames = 0
    private var cDropped = 0
    private var cEncoded = 0
    private var cEncoderErrors = 0
    private var cAudioBuffers = 0
    private var cAudioCopyFails = 0
    private var firstDropLogged = false

    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    override init() {
        super.init()
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
            log("câmera", "aberta em \(ms) ms")
            DispatchQueue.main.async {
                self.isOpen = true
                UIApplication.shared.isIdleTimerDisabled = true
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

    // MARK: - Fechar

    func closeCamera(reason: String) async {
        guard withLock({ opened }) else { return }
        if withLock({ recording }) { await stopRecording() }
        let report = withLock { () -> String in
            opened = false
            return "quadros=\(cVideoFrames) descartados=\(cDropped) codificados=\(cEncoded) "
                + "erros do codificador=\(cEncoderErrors) blocos de áudio=\(cAudioBuffers) pico=\(String(format: "%.4f", peak.peak))"
        }
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
            // Vídeo na vertical (a prévia da etapa 1 é só em pé): gira 90° no arquivo, sem recodificar.
            writer = try ClipWriter(
                url: url, videoFormat: vfd, audioFormat: audioFormat, offset: offset,
                transform: CGAffineTransform(rotationAngle: .pi / 2))
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
        writer.begin(video: selection.video.map { $0.payload }, audio: selection.audio.map { $0.payload })
        fireBeep(.start)
        log(
            "gravação",
            "INÍCIO · pré-tempo pedido=\(windowSec) s · real=\(String(format: "%.2f", selection.preSec)) s "
                + "(anel tinha \(String(format: "%.1f", ringSeconds)) s) · \(selection.video.count) quadros e "
                + "\(selection.audio.count) blocos de áudio de pré-gravação")
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
            flash("Não foi possível salvar o clipe.")
        case .success(let url):
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
            let asset = AVURLAsset(url: url)
            let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
            log(
                "arquivo",
                "pronto: \(String(format: "%.2f", duration)) s (duração do arquivo), "
                    + "\(String(format: "%.1f", Double(size) / 1_000_000)) MB, "
                    + "\(writer.appendedVideo) quadros de vídeo, \(writer.appendedAudio) blocos de áudio")
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
