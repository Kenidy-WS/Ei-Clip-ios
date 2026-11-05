import AVFoundation
import CoreMedia

private func nonNegative(_ t: CMTime) -> CMTime {
    CMTimeCompare(t, .zero) < 0 ? .zero : t
}

/// Cópia do sample buffer com os tempos deslocados por `offset` (o clipe começa em 0).
func retimed(_ sb: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer? {
    var count: CMItemCount = 0
    CMSampleBufferGetSampleTimingInfoArray(sb, entryCount: 0, arrayToFill: nil, entriesNeededOut: &count)
    var infos: [CMSampleTimingInfo]
    if count > 0 {
        infos = [CMSampleTimingInfo](
            repeating: CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .invalid, decodeTimeStamp: .invalid),
            count: count)
        CMSampleBufferGetSampleTimingInfoArray(sb, entryCount: count, arrayToFill: &infos, entriesNeededOut: &count)
    } else {
        infos = [
            CMSampleTimingInfo(
                duration: CMSampleBufferGetDuration(sb),
                presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sb),
                decodeTimeStamp: .invalid)
        ]
        count = 1
    }
    for i in 0..<count {
        infos[i].presentationTimeStamp = nonNegative(CMTimeSubtract(infos[i].presentationTimeStamp, offset))
        if infos[i].decodeTimeStamp.isValid {
            infos[i].decodeTimeStamp = nonNegative(CMTimeSubtract(infos[i].decodeTimeStamp, offset))
        }
    }
    var out: CMSampleBuffer?
    let status = CMSampleBufferCreateCopyWithNewTiming(
        allocator: kCFAllocatorDefault, sampleBuffer: sb, sampleTimingEntryCount: count,
        sampleTimingArray: infos, sampleBufferOut: &out)
    return status == noErr ? out : nil
}

/// Verdadeiro se o quadro H.264 codificado é um keyframe (não tem a marca "NotSync").
func isKeyFrame(_ sb: CMSampleBuffer) -> Bool {
    guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sb, createIfNecessary: false) as? [[CFString: Any]],
        let first = attachments.first
    else { return true }
    let notSync = (first[kCMSampleAttachmentKey_NotSync] as? Bool) ?? false
    return !notSync
}

/// Cópia profunda de um bloco de áudio PCM da captura.
/// Guardar os buffers originais da captura por 30 s esgotaria o pool de memória dela (e pode mutar o microfone).
func deepCopyAudio(_ sb: CMSampleBuffer) -> CMSampleBuffer? {
    guard let fd = CMSampleBufferGetFormatDescription(sb), let src = CMSampleBufferGetDataBuffer(sb) else { return nil }
    let length = CMBlockBufferGetDataLength(src)
    guard length > 0 else { return nil }
    var dst: CMBlockBuffer?
    guard
        CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault, memoryBlock: nil, blockLength: length,
            blockAllocator: kCFAllocatorDefault, customBlockSource: nil, offsetToData: 0,
            dataLength: length, flags: kCMBlockBufferAssureMemoryNowFlag, blockBufferOut: &dst) == noErr,
        let dst
    else { return nil }
    var srcPtr: UnsafeMutablePointer<Int8>?
    var total = 0
    guard
        CMBlockBufferGetDataPointer(src, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &total, dataPointerOut: &srcPtr)
            == kCMBlockBufferNoErr, let srcPtr
    else { return nil }
    guard
        CMBlockBufferReplaceDataBytes(with: srcPtr, blockBuffer: dst, offsetIntoDestination: 0, dataLength: min(length, total))
            == kCMBlockBufferNoErr
    else { return nil }
    var out: CMSampleBuffer?
    let status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(
        allocator: kCFAllocatorDefault, dataBuffer: dst, formatDescription: fd,
        sampleCount: CMItemCount(CMSampleBufferGetNumSamples(sb)),
        presentationTimeStamp: CMSampleBufferGetPresentationTimeStamp(sb),
        packetDescriptions: nil, sampleBufferOut: &out)
    return status == noErr ? out : nil
}

/// Troca o som do bloco por silêncio (usado enquanto o bipe toca, para o microfone não captá-lo).
func silenceAudio(_ sb: CMSampleBuffer) {
    guard let bb = CMSampleBufferGetDataBuffer(sb) else { return }
    var length = 0
    var ptr: UnsafeMutablePointer<Int8>?
    guard
        CMBlockBufferGetDataPointer(bb, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &ptr)
            == kCMBlockBufferNoErr, let ptr
    else { return }
    memset(ptr, 0, length)
}

/// Pico (0...1) de um bloco de áudio PCM (Float32 ou Int16). Nil se o formato não for reconhecido.
func audioPeak(_ sb: CMSampleBuffer) -> Float? {
    guard
        let fd = CMSampleBufferGetFormatDescription(sb),
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fd)?.pointee,
        let bb = CMSampleBufferGetDataBuffer(sb)
    else { return nil }
    var length = 0
    var ptr: UnsafeMutablePointer<Int8>?
    guard
        CMBlockBufferGetDataPointer(bb, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &ptr)
            == kCMBlockBufferNoErr, let ptr
    else { return nil }
    let isFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0
    if isFloat && asbd.mBitsPerChannel == 32 {
        let count = length / MemoryLayout<Float>.size
        return ptr.withMemoryRebound(to: Float.self, capacity: count) {
            peakLevel(float: UnsafeBufferPointer(start: $0, count: count))
        }
    }
    if !isFloat && asbd.mBitsPerChannel == 16 {
        let count = length / MemoryLayout<Int16>.size
        return ptr.withMemoryRebound(to: Int16.self, capacity: count) {
            peakLevel(int16: UnsafeBufferPointer(start: $0, count: count))
        }
    }
    return nil
}

/// Descrição curta do formato de áudio, para o Diagnóstico.
func describeAudioFormat(_ fd: CMFormatDescription) -> String {
    guard let a = CMAudioFormatDescriptionGetStreamBasicDescription(fd)?.pointee else { return "?" }
    let kind = (a.mFormatFlags & kAudioFormatFlagIsFloat) != 0 ? "float" : "int"
    return "\(Int(a.mSampleRate))Hz \(a.mChannelsPerFrame)ch \(a.mBitsPerChannel)bit \(kind)"
}

/// Hora atual no relógio do aparelho (o mesmo dos tempos das amostras da câmera e do microfone), em segundos.
func hostNowSeconds() -> Double {
    CMTimeGetSeconds(CMClockGetTime(CMClockGetHostTimeClock()))
}

/// Soma `samples` (bipe, mono) ao bloco de áudio PCM. `blockStart`/`beepStart` na mesma hora (segundos).
func mixBeep(_ sb: CMSampleBuffer, blockStart: Double, beepStart: Double, samples: [Float], beepRate: Double) {
    guard
        let fd = CMSampleBufferGetFormatDescription(sb),
        let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fd)?.pointee,
        let bb = CMSampleBufferGetDataBuffer(sb)
    else { return }
    let channels = max(1, Int(asbd.mChannelsPerFrame))
    if channels > 1 && (asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0 { return }
    var length = 0
    var ptr: UnsafeMutablePointer<Int8>?
    guard
        CMBlockBufferGetDataPointer(bb, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &ptr)
            == kCMBlockBufferNoErr, let ptr
    else { return }
    let rate = asbd.mSampleRate
    let isFloat = (asbd.mFormatFlags & kAudioFormatFlagIsFloat) != 0

    if isFloat && asbd.mBitsPerChannel == 32 {
        let count = length / MemoryLayout<Float>.size
        ptr.withMemoryRebound(to: Float.self, capacity: count) { p in
            for i in 0..<(count / channels) {
                let t = blockStart + Double(i) / rate - beepStart
                if t < 0 { continue }
                let k = Int(t * beepRate)
                if k >= samples.count { break }
                for c in 0..<channels {
                    let idx = i * channels + c
                    p[idx] = max(-1, min(1, p[idx] + samples[k]))
                }
            }
        }
    } else if !isFloat && asbd.mBitsPerChannel == 16 {
        let count = length / MemoryLayout<Int16>.size
        ptr.withMemoryRebound(to: Int16.self, capacity: count) { p in
            for i in 0..<(count / channels) {
                let t = blockStart + Double(i) / rate - beepStart
                if t < 0 { continue }
                let k = Int(t * beepRate)
                if k >= samples.count { break }
                let add = Int32((samples[k] * 32767).rounded())
                for c in 0..<channels {
                    let idx = i * channels + c
                    p[idx] = Int16(max(-32768, min(32767, Int32(p[idx]) + add)))
                }
            }
        }
    }
}
