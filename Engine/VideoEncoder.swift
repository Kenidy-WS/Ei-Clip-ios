import CoreMedia
import VideoToolbox

/// Codificador H.264 por hardware (VideoToolbox), com keyframe a cada ~1 s para o corte do clipe ser preciso.
/// Sem quadros B: o tempo de exibição é igual ao de decodificação e o anel/arquivo ficam simples.
final class VideoEncoder {
    private var session: VTCompressionSession?
    private let bitrate: Int
    private let fps: Int
    private let lock = NSLock()

    /// Cada quadro codificado (qualquer fila).
    var onChunk: ((CMSampleBuffer) -> Void)?
    /// Erros do codificador (qualquer fila).
    var onError: ((String) -> Void)?

    /// Instante do último quadro entregue ao codificador (v0.6.17): `complete()` espera só até aqui.
    private var lastSubmittedPts = CMTime.invalid

    /// v0.8.2 (só Diagnóstico): quantos quadros entraram e quantos já saíram do codificador, e o instante de cada um.
    private let statsLock = NSLock()
    private var submittedCount = 0
    private var deliveredCount = 0
    private var lastDeliveredPts = CMTime.invalid

    struct Stats {
        var submitted = 0
        var delivered = 0
        /// Instantes (segundos) do último quadro enviado e do último entregue; atraso = diferença.
        var lastSubmittedSec = 0.0
        var lastDeliveredSec = 0.0
    }

    func stats() -> Stats {
        lock.lock()
        let sub = lastSubmittedPts
        lock.unlock()
        statsLock.lock()
        defer { statsLock.unlock() }
        return Stats(
            submitted: submittedCount, delivered: deliveredCount,
            lastSubmittedSec: sub.isValid ? sub.seconds : 0, lastDeliveredSec: lastDeliveredPts.isValid ? lastDeliveredPts.seconds : 0)
    }

    private(set) var width = 0
    private(set) var height = 0

    init(bitrate: Int, fps: Int) {
        self.bitrate = bitrate
        self.fps = fps
    }

    func encode(_ pixelBuffer: CVPixelBuffer, pts: CMTime, duration: CMTime) {
        lock.lock()
        if session == nil { createSession(for: pixelBuffer) }
        let s = session
        lastSubmittedPts = pts
        lock.unlock()
        statsLock.lock()
        submittedCount += 1
        statsLock.unlock()
        guard let s else { return }
        let status = VTCompressionSessionEncodeFrame(
            s, imageBuffer: pixelBuffer, presentationTimeStamp: pts, duration: duration,
            frameProperties: nil, infoFlagsOut: nil
        ) { [weak self] status, _, sampleBuffer in
            guard let self else { return }
            if status != noErr {
                self.onError?("callback do codificador: \(status)")
                return
            }
            guard let sampleBuffer, CMSampleBufferDataIsReady(sampleBuffer) else { return }
            self.statsLock.lock()
            self.deliveredCount += 1
            self.lastDeliveredPts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            self.statsLock.unlock()
            self.onChunk?(sampleBuffer)
        }
        if status != noErr { onError?("EncodeFrame: \(status)") }
    }

    /// Entrega os quadros que ainda estão no codificador (sem quadros B, são poucos), até o último já enviado.
    /// v0.6.17: com `.invalid` o iOS espera o codificador ficar vazio, o que em 4K nunca acontece com a câmera ainda
    /// mandando quadros (o botão de parar ficava preso até a câmera fechar). Com o instante do último quadro, volta logo.
    func complete() {
        lock.lock()
        let s = session
        let until = lastSubmittedPts
        lock.unlock()
        if let s { VTCompressionSessionCompleteFrames(s, untilPresentationTimeStamp: until) }
    }

    func close() {
        lock.lock()
        let s = session
        session = nil
        lock.unlock()
        if let s {
            VTCompressionSessionCompleteFrames(s, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(s)
        }
    }

    private func createSession(for pixelBuffer: CVPixelBuffer) {
        width = CVPixelBufferGetWidth(pixelBuffer)
        height = CVPixelBufferGetHeight(pixelBuffer)
        var created: VTCompressionSession?
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault, width: Int32(width), height: Int32(height),
            codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil,
            compressedDataAllocator: nil, outputCallback: nil, refcon: nil, compressionSessionOut: &created)
        guard status == noErr, let created else {
            onError?("VTCompressionSessionCreate: \(status)")
            return
        }
        func set(_ key: CFString, _ value: CFTypeRef) {
            let r = VTSessionSetProperty(created, key: key, value: value)
            if r != noErr { onError?("propriedade \(key): \(r)") }
        }
        set(kVTCompressionPropertyKey_RealTime, NSNumber(value: true))
        set(kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_AutoLevel)
        set(kVTCompressionPropertyKey_AllowFrameReordering, NSNumber(value: false))
        set(kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: bitrate))
        set(kVTCompressionPropertyKey_ExpectedFrameRate, NSNumber(value: fps))
        set(kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: fps))
        set(kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, NSNumber(value: 1.0))
        VTCompressionSessionPrepareToEncodeFrames(created)
        session = created
    }
}
