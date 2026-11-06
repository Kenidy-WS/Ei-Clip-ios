import Foundation

/// O que o vigia percebeu.
public enum StallEvent: Equatable {
    /// Ficou parado por `seconds` (avisa ao passar do limite e de novo a cada `repeatEvery`).
    case stalled(seconds: Double)
    /// Voltou a responder depois de `seconds`.
    case recovered(seconds: Double)
}

/// v0.6.21: detector de "parou de dar sinal" (tela principal do app, quadros da câmera). Quem observa chama `beat` a cada
/// sinal de vida e `check` de tempos em tempos, de outra fila. Tempos em segundos (relógio contínuo).
public struct StallDetector {
    public let threshold: Double
    public let repeatEvery: Double
    private var lastBeat: Double?
    private var lastReport: Double?

    public init(threshold: Double, repeatEvery: Double = 5) {
        self.threshold = threshold
        self.repeatEvery = repeatEvery
    }

    /// Sinal de vida. Devolve `.recovered` se o travamento já tinha sido avisado.
    public mutating func beat(at now: Double) -> StallEvent? {
        let gap = lastBeat.map { now - $0 } ?? 0
        let wasReported = lastReport != nil
        lastBeat = now
        lastReport = nil
        return wasReported ? .recovered(seconds: gap) : nil
    }

    /// Confere se o último sinal ficou velho demais. Devolve `.stalled` ao passar do limite e a cada `repeatEvery` depois.
    public mutating func check(at now: Double) -> StallEvent? {
        guard let last = lastBeat else {
            lastBeat = now
            return nil
        }
        let gap = now - last
        guard gap >= threshold else { return nil }
        if let reported = lastReport, now - reported < repeatEvery { return nil }
        lastReport = now
        return .stalled(seconds: gap)
    }
}
