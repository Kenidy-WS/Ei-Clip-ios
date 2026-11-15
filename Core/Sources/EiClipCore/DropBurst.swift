import Foundation

/// v0.9.11: "a câmera está perdendo quadros em sequência". Conta os quadros descartados numa janela de tempo e avisa UMA vez
/// quando passam do limite (rearmar com `reset`, a cada abertura da câmera). É um dos sinais de falha da câmera para a
/// reserva do calor (`ThermalGovernor.noteCameraFailure`). Perdas soltas (uma ao abrir, outra ao trocar de lente) não contam.
public struct DropBurst {
    public let threshold: Int
    public let window: Double
    private var times: [Double] = []
    private var fired = false

    public init(threshold: Int = 30, window: Double = 5) {
        self.threshold = threshold
        self.window = window
    }

    /// Um quadro descartado no instante `now` (segundos, relógio contínuo). Verdadeiro só na vez em que o limite é atingido.
    public mutating func drop(at now: Double) -> Bool {
        times.append(now)
        times.removeAll { now - $0 > window }
        guard !fired, times.count >= threshold else { return false }
        fired = true
        return true
    }

    public mutating func reset() {
        times.removeAll()
        fired = false
    }
}
