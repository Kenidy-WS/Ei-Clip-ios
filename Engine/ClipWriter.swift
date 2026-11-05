import AVFoundation

enum ClipWriterError: Error, CustomStringConvertible {
    case cannotAddInput(String)
    case startFailed
    case appendFailed(String)

    var description: String {
        switch self {
        case .cannotAddInput(let what): return "não foi possível adicionar entrada de \(what)"
        case .startFailed: return "não foi possível iniciar o arquivo"
        case .appendFailed(let what): return "falha ao gravar \(what)"
        }
    }
}

/// Grava o clipe num MP4 ÚNICO: primeiro o pré-tempo (que já está no anel), depois as amostras ao vivo.
/// O vídeo entra já codificado (H.264, passthrough); o áudio entra como PCM e o próprio arquivo o codifica em AAC.
final class ClipWriter {
    let url: URL
    private let queue = DispatchQueue(label: "ei.clipwriter")
    private let writer: AVAssetWriter
    private let vInput: AVAssetWriterInput
    private let aInput: AVAssetWriterInput?
    private let offset: CMTime

    private var pendingV: [CMSampleBuffer] = []
    private var pendingA: [CMSampleBuffer] = []
    /// Amostras ao vivo que chegaram antes de `begin` (esperam o pré-tempo entrar primeiro).
    private var earlyV: [CMSampleBuffer] = []
    private var earlyA: [CMSampleBuffer] = []
    private var started = false
    private var stopping = false
    private var finished = false
    private var vDone = false
    private var aDone = false
    private var completion: ((Result<URL, Error>) -> Void)?

    private(set) var appendedVideo = 0
    private(set) var appendedAudio = 0
    /// Mensagens para o Diagnóstico (qualquer fila).
    var onLog: ((String) -> Void)?
    /// Avisa assim que o arquivo falha (fila do gravador), sem esperar o pedido de fim.
    var onFailed: ((Error) -> Void)?
    private var failure: Error?

    // Diagnóstico (v0.1.5): só registro, não muda o comportamento da gravação.
    /// Tempos (já deslocados, o clipe começa em 0) das amostras que de fato entraram no arquivo.
    private var vStats = TimelineStats()
    private var aStats = TimelineStats()
    /// Amostras que não puderam ser reajustadas no tempo e foram descartadas.
    private var retimeFailures = 0
    private var finishRequestedAt: TimeInterval = 0

    /// `offset`: instante do keyframe de início; tudo é deslocado para o clipe começar em 0.
    init(url: URL, videoFormat: CMFormatDescription, audioFormat: CMFormatDescription?, offset: CMTime,
         transform: CGAffineTransform) throws {
        try? FileManager.default.removeItem(at: url)
        let w = try AVAssetWriter(outputURL: url, fileType: .mp4)
        w.shouldOptimizeForNetworkUse = false
        // v0.6.12: o arquivo ganha uma parte completa a cada poucos segundos. Se o app fechar no meio de uma gravação longa,
        // o que foi gravado até a última parte continua legível (sem isto, o MP4 só ficaria válido ao parar).
        w.movieFragmentInterval = CMTime(seconds: RecordingFiles.fragmentSeconds, preferredTimescale: 600)

        let v = AVAssetWriterInput(mediaType: .video, outputSettings: nil, sourceFormatHint: videoFormat)
        v.expectsMediaDataInRealTime = false
        v.transform = transform
        guard w.canAdd(v) else { throw ClipWriterError.cannotAddInput("vídeo") }
        w.add(v)

        var a: AVAssetWriterInput?
        if let afd = audioFormat, let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(afd)?.pointee {
            let channels = Int(min(max(asbd.mChannelsPerFrame, 1), 2))
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: asbd.mSampleRate,
                AVNumberOfChannelsKey: channels,
                AVEncoderBitRateKey: channels == 1 ? 128_000 : 192_000,
            ]
            let input = AVAssetWriterInput(mediaType: .audio, outputSettings: settings, sourceFormatHint: afd)
            input.expectsMediaDataInRealTime = false
            if w.canAdd(input) {
                w.add(input)
                a = input
            }
        }

        guard w.startWriting() else { throw w.error ?? ClipWriterError.startFailed }
        w.startSession(atSourceTime: .zero)

        self.url = url
        self.writer = w
        self.vInput = v
        self.aInput = a
        self.offset = offset

        v.requestMediaDataWhenReady(on: queue) { [weak self] in self?.drain() }
        a?.requestMediaDataWhenReady(on: queue) { [weak self] in self?.drain() }
    }

    /// Entrega o pré-tempo (já cortado no keyframe).
    /// As amostras ao vivo que chegaram ANTES daqui ficaram guardadas à parte (`earlyV`/`earlyA`) e entram
    /// depois do pré-tempo, para o arquivo receber os tempos sempre em ordem.
    func begin(video: [CMSampleBuffer], audio: [CMSampleBuffer]) {
        queue.async {
            for sb in video { self.addPending(sb, isVideo: true) }
            for sb in audio { self.addPending(sb, isVideo: false) }
            self.started = true
            self.onLog?("amostras ao vivo que chegaram antes do pré-tempo: vídeo=\(self.earlyV.count) áudio=\(self.earlyA.count)")
            for sb in self.earlyV { self.addPending(sb, isVideo: true) }
            for sb in self.earlyA { self.addPending(sb, isVideo: false) }
            self.earlyV.removeAll()
            self.earlyA.removeAll()
            self.drain()
        }
    }

    func enqueueVideo(_ sb: CMSampleBuffer) {
        queue.async {
            if self.started {
                self.addPending(sb, isVideo: true)
                self.drain()
            } else {
                self.earlyV.append(sb)
            }
        }
    }

    func enqueueAudio(_ sb: CMSampleBuffer) {
        queue.async {
            guard self.aInput != nil else { return }
            if self.started {
                self.addPending(sb, isVideo: false)
                self.drain()
            } else {
                self.earlyA.append(sb)
            }
        }
    }

    /// Encerra o arquivo depois de gravar tudo o que está na fila.
    func finish(_ completion: @escaping (Result<URL, Error>) -> Void) {
        queue.async {
            self.stopping = true
            self.completion = completion
            if let failure = self.failure {
                // O arquivo já falhou antes do pedido de fim: responde na hora.
                self.onLog?("fim pedido com o arquivo já falho; respondendo a falha na hora")
                self.complete(.failure(failure))
                return
            }
            self.finishRequestedAt = ProcessInfo.processInfo.systemUptime
            self.onLog?("finalizando: pendentes vídeo=\(self.pendingV.count) áudio=\(self.pendingA.count), gravados vídeo=\(self.appendedVideo) áudio=\(self.appendedAudio)")
            self.onLog?("estado ao pedir o fim: \(self.stateText())")
            self.drain()
            // Registro do que o arquivo ainda está fazendo (para achar onde trava).
            self.queue.asyncAfter(deadline: .now() + 3) { [weak self] in self?.logStall(after: 3) }
            self.queue.asyncAfter(deadline: .now() + 6) { [weak self] in self?.logStall(after: 6) }
            // Vigias: a gravação nunca pode ser perdida por um arquivo que não fecha.
            self.queue.asyncAfter(deadline: .now() + 10) { [weak self] in self?.watchdogForceClose() }
            self.queue.asyncAfter(deadline: .now() + 30) { [weak self] in self?.watchdogGiveUp() }
        }
    }

    // MARK: - Fila (sempre em `queue`)

    private func pts(_ sb: CMSampleBuffer) -> Double {
        CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sb))
    }

    /// Reajusta o tempo da amostra (o clipe começa em 0) e põe na fila de pendentes.
    private func addPending(_ sb: CMSampleBuffer, isVideo: Bool) {
        guard let r = retimed(sb, offset: offset) else {
            retimeFailures += 1
            return
        }
        if isVideo {
            pendingV.append(r)
        } else {
            pendingA.append(r)
        }
    }

    private func drain() {
        guard !finished else { return }
        if writer.status == .failed {
            fail(writer.error ?? ClipWriterError.appendFailed("arquivo"))
            return
        }
        var progressed = true
        while progressed {
            progressed = false
            let vReady = !vDone && vInput.isReadyForMoreMediaData && !pendingV.isEmpty
            let aReady = !aDone && (aInput?.isReadyForMoreMediaData ?? false) && !pendingA.isEmpty
            if vReady && (!aReady || pts(pendingV[0]) <= pts(pendingA[0])) {
                let sb = pendingV.removeFirst()
                if vInput.append(sb) {
                    appendedVideo += 1
                    vStats.add(pts(sb))
                } else {
                    fail(writer.error ?? ClipWriterError.appendFailed("vídeo"))
                    return
                }
                progressed = true
            } else if aReady, let aInput {
                let sb = pendingA.removeFirst()
                if aInput.append(sb) {
                    appendedAudio += 1
                    aStats.add(pts(sb))
                } else {
                    fail(writer.error ?? ClipWriterError.appendFailed("áudio"))
                    return
                }
                progressed = true
            }
        }
        guard stopping else { return }
        // Cada entrada é encerrada assim que a sua fila acaba (senão uma esperaria a outra e o arquivo nunca fecharia).
        if pendingV.isEmpty && !vDone {
            vInput.markAsFinished()
            vDone = true
        }
        if pendingA.isEmpty && !aDone {
            aInput?.markAsFinished()
            aDone = true
        }
        if vDone && (aInput == nil || aDone) { completeWriting() }
    }

    /// Fecha o arquivo (as entradas já estão encerradas) e avisa quem pediu.
    private func completeWriting() {
        finished = true
        let url = self.url
        let calledAt = ProcessInfo.processInfo.systemUptime
        onLog?(
            "chamando finishWriting (\(msSince(finishRequestedAt)) ms depois do pedido de fim) · "
                + "vídeo gravado: \(vStats.summary) · áudio gravado: \(aStats.summary)")
        writer.finishWriting { [self] in
            queue.async {
                let took = Int((ProcessInfo.processInfo.systemUptime - calledAt) * 1000)
                self.onLog?("finishWriting respondeu em \(took) ms · \(self.stateText())")
                if self.writer.status == .completed {
                    self.complete(.success(url))
                } else {
                    self.complete(.failure(self.writer.error ?? ClipWriterError.appendFailed("finalização")))
                }
            }
        }
    }

    private func complete(_ result: Result<URL, Error>) {
        guard let c = completion else { return }
        completion = nil
        c(result)
    }

    /// 3 s e 6 s depois do pedido de fim, se o arquivo ainda não fechou: registra o estado.
    private func logStall(after seconds: Int) {
        guard completion != nil else { return }
        onLog?("ainda não fechou depois de \(seconds) s · \(stateText())")
    }

    /// 10 s depois de pedir o fim e o arquivo ainda aberto: descarta o que sobrou na fila e fecha com o que já foi gravado.
    private func watchdogForceClose() {
        guard stopping else { return }
        if finished {
            // O fechamento já foi pedido ao sistema e ainda não respondeu: só registra (não há o que forçar).
            if completion != nil {
                onLog?("VIGIA 10 s: finishWriting já foi chamado e ainda não respondeu · \(stateText())")
            }
            return
        }
        onLog?(
            "VIGIA: o arquivo não fechou em 10 s (pendentes vídeo=\(pendingV.count) áudio=\(pendingA.count), "
                + "vDone=\(vDone) aDone=\(aDone), status=\(writer.status.rawValue)). Fechando com o que já foi gravado. "
                + stateText())
        pendingV.removeAll()
        pendingA.removeAll()
        if !vDone {
            vInput.markAsFinished()
            vDone = true
        }
        if !aDone {
            aInput?.markAsFinished()
            aDone = true
        }
        completeWriting()
    }

    /// 30 s e o fechamento ainda não respondeu: avisa o app para não ficar esperando para sempre.
    private func watchdogGiveUp() {
        guard completion != nil else { return }
        onLog?("VIGIA: finishWriting não respondeu em 30 s (status=\(writer.status.rawValue)). \(stateText())")
        complete(.failure(ClipWriterError.appendFailed("fechamento do arquivo (tempo esgotado)")))
    }

    private func fail(_ error: Error) {
        guard !finished else { return }
        onLog?("FALHA do arquivo: \(describe(error)) · \(stateText()) · vídeo gravado: \(vStats.summary) · áudio gravado: \(aStats.summary)")
        finished = true
        failure = error
        writer.cancelWriting()
        onFailed?(error)
        complete(.failure(error))
    }

    // MARK: - Texto para o Diagnóstico

    private func msSince(_ uptime: TimeInterval) -> Int {
        Int((ProcessInfo.processInfo.systemUptime - uptime) * 1000)
    }

    private func describe(_ error: Error?) -> String {
        guard let error else { return "nenhum" }
        let e = error as NSError
        var text = "\(e.domain) \(e.code): \(e.localizedDescription)"
        if let under = e.userInfo[NSUnderlyingErrorKey] as? NSError {
            text += " [causa: \(under.domain) \(under.code)]"
        }
        return text
    }

    /// Estado completo do arquivo e das filas (sempre em `queue`).
    private func stateText() -> String {
        let status: String
        switch writer.status {
        case .unknown: status = "desconhecido"
        case .writing: status = "gravando"
        case .completed: status = "completo"
        case .failed: status = "falhou"
        case .cancelled: status = "cancelado"
        @unknown default: status = "?"
        }
        return "status=\(writer.status.rawValue) (\(status)) erro=\(describe(writer.error)) · "
            + "pendentes vídeo=\(pendingV.count) áudio=\(pendingA.count) · "
            + "gravados vídeo=\(appendedVideo) áudio=\(appendedAudio) · "
            + "aceita mais vídeo=\(vInput.isReadyForMoreMediaData) áudio=\(aInput?.isReadyForMoreMediaData ?? false) · "
            + "vDone=\(vDone) aDone=\(aDone) · áudio no arquivo=\(aInput != nil) · amostras descartadas no tempo=\(retimeFailures)"
    }
}
