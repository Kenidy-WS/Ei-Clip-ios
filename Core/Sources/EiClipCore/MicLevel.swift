import Foundation

/// Abaixo (ou igual) a isto, 3 s depois de abrir a câmera, o microfone é considerado MUDO.
public let micSilentPeakThreshold: Float = 0.0008

public func isMicSilent(peak: Float) -> Bool {
    peak <= micSilentPeakThreshold
}

/// Pico (0...1) de amostras Float32 (-1...1).
public func peakLevel(float samples: UnsafeBufferPointer<Float>) -> Float {
    var peak: Float = 0
    for s in samples {
        let a = abs(s)
        if a > peak { peak = a }
    }
    return min(1, peak)
}

/// Pico (0...1) de amostras Int16.
public func peakLevel(int16 samples: UnsafeBufferPointer<Int16>) -> Float {
    var peak: Int32 = 0
    for s in samples {
        let a = abs(Int32(s))
        if a > peak { peak = a }
    }
    return min(1, Float(peak) / 32768)
}

/// Guarda o maior pico visto desde o início da captura.
public struct PeakTracker {
    public private(set) var peak: Float = 0

    public init() {}

    public mutating func feed(_ level: Float) {
        if level > peak { peak = level }
    }

    public mutating func reset() {
        peak = 0
    }
}
