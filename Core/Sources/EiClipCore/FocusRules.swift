import Foundation

/// Foco por toque (v0.6.7). Regras puras: o motor converte o toque em ponto da câmera e chama o aparelho; aqui ficam o
/// recorte do ponto e o tempo em que o anel de foco fica na tela.
public enum FocusRules {
    /// Quanto tempo o anel de foco fica visível depois do toque.
    public static let indicatorSeconds = 1.2

    /// Ponto de interesse da câmera: 0...1 nos dois eixos (fora disso o aparelho recusa).
    public static func clamp(x: Double, y: Double) -> (x: Double, y: Double) {
        (min(1, max(0, x)), min(1, max(0, y)))
    }

    /// O ponto padrão (centro), usado quando a cena muda e o foco volta ao automático.
    public static let center: (x: Double, y: Double) = (0.5, 0.5)

    /// Vale tocar para focar? Só com a câmera aberta, sem tela escura e fora do teste de aberturas.
    public static func canFocus(cameraOpen: Bool, dimmed: Bool, testRunning: Bool, reconfiguring: Bool) -> Bool {
        cameraOpen && !dimmed && !testRunning && !reconfiguring
    }
}

/// O anel de foco na tela: onde (em pontos da tela) e quando apareceu.
public struct FocusMark: Equatable {
    public let id: Int
    public let x: Double
    public let y: Double
    public let at: TimeInterval

    public init(id: Int, x: Double, y: Double, at: TimeInterval) {
        self.id = id
        self.x = x
        self.y = y
        self.at = at
    }

    public func isVisible(now: TimeInterval) -> Bool {
        now - at < FocusRules.indicatorSeconds
    }
}
