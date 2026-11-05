import Foundation

public enum BeepKind {
    case start
    case stop
}

/// (frequência Hz, início s, duração s). Duas notas, como no web app (`core/beep-wave.ts`):
/// o início sobe (C5 → E5) e o fim desce (E5 → C5).
private func tones(_ kind: BeepKind) -> [(freq: Double, offset: Double, duration: Double)] {
    switch kind {
    case .start: return [(523, 0, 0.06), (659, 0.06, 0.06)]
    case .stop: return [(659, 0, 0.09), (523, 0.16, 0.09)]
    }
}

/// Volume do bipe ("Alto" do web app: pico 0,7).
public let defaultBeepGain: Float = 0.7

public func beepDuration(_ kind: BeepKind) -> Double {
    guard let last = tones(kind).last else { return 0 }
    return last.offset + last.duration
}

/// Gera as amostras (mono) do bipe: seno puro com entrada e saída suaves.
public func renderBeep(_ kind: BeepKind, sampleRate: Double, gain: Float = defaultBeepGain) -> [Float] {
    var out = [Float](repeating: 0, count: Int((beepDuration(kind) * sampleRate).rounded(.up)) + 1)
    for tone in tones(kind) {
        let i0 = Int((tone.offset * sampleRate).rounded(.down))
        let len = Int((tone.duration * sampleRate).rounded(.down))
        let attack = max(1, Int((min(0.02, tone.duration / 4) * sampleRate).rounded(.down)))
        let release = max(1, Int((min(0.07, tone.duration / 3) * sampleRate).rounded(.down)))
        for i in 0..<len {
            let phase = 2 * Double.pi * tone.freq * Double(i) / sampleRate
            let envelope = min(1, Double(i) / Double(attack), Double(len - i) / Double(release))
            if i0 + i < out.count {
                out[i0 + i] = Float(sin(phase) * envelope) * gain
            }
        }
    }
    return out
}

/// Arquivo WAV (mono, 16 bits) com as amostras, para tocar com AVAudioPlayer.
public func wavData(samples: [Float], sampleRate: Int) -> Data {
    var data = Data()
    func u32(_ v: UInt32) { var x = v.littleEndian; data.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; data.append(Data(bytes: &x, count: 2)) }
    let byteCount = UInt32(samples.count * 2)
    data.append(contentsOf: Array("RIFF".utf8))
    u32(36 + byteCount)
    data.append(contentsOf: Array("WAVE".utf8))
    data.append(contentsOf: Array("fmt ".utf8))
    u32(16)
    u16(1)  // PCM
    u16(1)  // mono
    u32(UInt32(sampleRate))
    u32(UInt32(sampleRate * 2))
    u16(2)
    u16(16)
    data.append(contentsOf: Array("data".utf8))
    u32(byteCount)
    for s in samples {
        let clamped = max(-1, min(1, s))
        u16(UInt16(bitPattern: Int16((clamped * 32767).rounded())))
    }
    return data
}
