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
    private var stopping = false
    private var finished = false
    private var vDone = false
    private var aDone = false
    private var completion: ((Result<URL, Error>) -> Void)?

    private(set) var appendedVideo = 0
    private(set) var appendedAudio = 0
    /// Mensagens para o Diagnóstico (qualquer fila).
    var onLog: ((String) -> Void)?

    /// `offset`: instante do keyframe de início; tudo é deslocado para o clipe começar em 0.
    init(url: URL, videoFormat: CMFormatDescription, audioFormat: CMFormatDescription?, offset: CMTime,
         transform: CGAffineTransform) throws {
        try? FileManager.default.removeItem(at: url)
        let w = try AVAssetWriter(outputURL: url, fileType: .mp4)
        w.shouldOptimizeForNetworkUse = false

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
    func begin(video: [CMSampleBuffer], audio: [CMSampleBuffer]) {
        queue.async {
            self.pendingV.append(contentsOf: video.compactMap { retimed($0, offset: self.offset) })
            self.pendingA.append(contentsOf: audio.compactMap { retimed($0, offset: self.offset) })
            self.drain()
        }
    }

    func enqueueVideo(_ sb: CMSampleBuffer) {
        queue.async {
            if let r = retimed(sb, offset: self.offset) { self.pendingV.append(r) }
            self.drain()
        }
    }

    func enqueueAudio(_ sb: CMSampleBuffer) {
        queue.async {
            if self.aInput != nil, let r = retimed(sb, offset: self.offset) { self.pendingA.append(r) }
            self.drain()
        }
    }

    /// Encerra o arquivo depois de gravar tudo o que está na fila.
    func finish(_ completion: @escaping (Result<URL, Error>) -> Void) {
        queue.async {
            self.stopping = true
            self.completion = completion
            self.onLog?("finalizando: pendentes vídeo=\(self.pendingV.count) áudio=\(self.pendingA.count), gravados vídeo=\(self.appendedVideo) áudio=\(self.appendedAudio)")
            self.drain()
            // Vigias: a gravação nunca pode ser perdida por um arquivo que não fecha.
            self.queue.asyncAfter(deadline: .now() + 10) { [weak self] in self?.watchdogForceClose() }
            self.queue.asyncAfter(deadline: .now() + 30) { [weak self] in self?.watchdogGiveUp() }
        }
    }

    // MARK: - Fila (sempre em `queue`)

    private func pts(_ sb: CMSampleBuffer) -> Double {
        CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sb))
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
                } else {
                    fail(writer.error ?? ClipWriterError.appendFailed("vídeo"))
                    return
                }
                progressed = true
            } else if aReady, let aInput {
                let sb = pendingA.removeFirst()
                if aInput.append(sb) {
                    appendedAudio += 1
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
        writer.finishWriting { [self] in
            queue.async {
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

    /// 10 s depois de pedir o fim e o arquivo ainda aberto: descarta o que sobrou na fila e fecha com o que já foi gravado.
    private func watchdogForceClose() {
        guard stopping, !finished else { return }
        onLog?(
            "VIGIA: o arquivo não fechou em 10 s (pendentes vídeo=\(pendingV.count) áudio=\(pendingA.count), "
                + "vDone=\(vDone) aDone=\(aDone), status=\(writer.status.rawValue)). Fechando com o que já foi gravado.")
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
        onLog?("VIGIA: finishWriting não respondeu em 30 s (status=\(writer.status.rawValue)).")
        complete(.failure(ClipWriterError.appendFailed("fechamento do arquivo (tempo esgotado)")))
    }

    private func fail(_ error: Error) {
        guard !finished else { return }
        finished = true
        writer.cancelWriting()
        complete(.failure(error))
    }
}
