import Foundation

/// Foco por toque (v0.6.7). Regras puras: o motor converte o toque em ponto da câmera e chama o aparelho; aqui ficam o
/// recorte do ponto e o tempo em que o anel de foco fica na tela.
public enum FocusRules {
    /// Quanto tempo o quadrado de foco (e, desde a v0.7.16, o sol do EV) fica visível depois do toque.
    public static let indicatorSeconds = 3.0

    /// Ponto de interesse da câmera: 0...1 nos dois eixos (fora disso o aparelho recusa).
    public static func clamp(x: Double, y: Double) -> (x: Double, y: Double) {
        (min(1, max(0, x)), min(1, max(0, y)))
    }

    /// Faixas da tela onde tocar NÃO foca (v0.6.16): em cima ficam os botões do topo; embaixo, as lentes e o botão de gravar
    /// (tocar perto do botão de gravar disparava o foco e atrapalhava o toque).
    public static let topExcludedPoints = 130.0
    public static let bottomExcludedPoints = 250.0

    /// O toque (altura `y` numa tela de `height` pontos) vale como pedido de foco?
    public static func isFocusArea(y: Double, height: Double) -> Bool {
        y >= topExcludedPoints && y <= height - bottomExcludedPoints
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
