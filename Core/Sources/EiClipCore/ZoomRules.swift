import Foundation

/// Fase do gesto de pinça (v0.9.0), já traduzida do UIKit para a lógica pura.
public enum PinchPhase: Equatable {
    case began
    case changed
    case ended
}

/// Zoom contínuo por pinça (v0.9.0). Dois "fatores" andam juntos:
/// - o **fator do aparelho** (`videoZoomFactor`): na câmera combinada, 1,0 é a ultra-angular e `main` (em geral 2,0) é a principal;
/// - o **fator da tela** (o que a pessoa vê: 0,5×, 1×, 2×…): na combinada é o do aparelho dividido por `main`.
/// Sem câmera combinada (`main` nulo) os dois são iguais, e a ultra-angular (outro aparelho) fica só nos botões.
public enum ZoomRules {
    /// Teto do zoom na tela, pedido pelo Kenidy (como o app Câmera do iPhone).
    public static let maxScreenZoom = 6.0
    /// Folga para considerar que o zoom está "em cima" do ponto de uma lente. É a mesma do arredondamento do texto
    /// (`label` mostra "1×" de 0,95 a 1,05), para o botão destacado nunca contradizer o número.
    public static let pointTolerance = 0.05
    /// Mudança mínima (no fator da tela) para valer mandar ao aparelho.
    public static let minStep = 0.005

    /// Fator da tela a partir do fator do aparelho.
    public static func screenFactor(device: Double, main: Double?) -> Double {
        guard let main = main, main > 0 else { return device }
        return device / main
    }

    /// Fator do aparelho a partir do fator da tela.
    public static func deviceFactor(screen: Double, main: Double?) -> Double {
        guard let main = main, main > 0 else { return screen }
        return screen * main
    }

    /// Faixa que a pinça alcança, em fator da tela. Com a combinada começa na ultra-angular (1 ÷ `main`, ex.: 0,5×); sem ela
    /// começa em 1×. Termina em 6× ou no zoom máximo que o formato aceita (o que for menor), nunca abaixo do começo.
    public static func range(main: Double?, deviceMax: Double) -> ClosedRange<Double> {
        let lower = (main.map { $0 > 0 ? 1.0 / $0 : 1.0 }) ?? 1.0
        let upper = max(lower, min(maxScreenZoom, screenFactor(device: deviceMax, main: main)))
        return lower...upper
    }

    public static func clamp(_ value: Double, in range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }

    /// Zoom da tela durante a pinça: o de partida vezes a escala do gesto, dentro da faixa.
    public static func pinchTarget(start: Double, scale: Double, range: ClosedRange<Double>) -> Double {
        guard start > 0, scale.isFinite, scale > 0 else { return clamp(start, in: range) }
        return clamp(start * scale, in: range)
    }

    /// Ponto de cada lente, em fator da tela (com a combinada: 0,5, 1 e 2).
    public static func screenPoint(of lens: Lens, main: Double?) -> Double {
        screenFactor(device: LensZoom.factor(for: lens, mainFactor: main), main: main)
    }

    /// Lente em uso para um zoom da tela: a de maior ponto que o zoom já alcançou (com folga); abaixo da primeira, a primeira.
    /// Sem a combinada a ultra-angular nunca entra (é outro aparelho; só os botões chegam a ela).
    public static func lens(forScreen zoom: Double, available: [Lens], main: Double?) -> Lens {
        let usable = available
            .filter { main != nil || $0 != .ultraWide }
            .sorted { screenPoint(of: $0, main: main) < screenPoint(of: $1, main: main) }
        guard var chosen = usable.first else { return .wide }
        for item in usable where screenPoint(of: item, main: main) <= zoom + pointTolerance { chosen = item }
        return chosen
    }

    /// O zoom está em cima do ponto da lente?
    public static func isAtPoint(_ zoom: Double, lens: Lens, main: Double?) -> Bool {
        abs(zoom - screenPoint(of: lens, main: main)) < pointTolerance
    }

    /// Vale mandar o valor novo ao aparelho?
    public static func shouldSend(current: Double, new: Double) -> Bool {
        abs(new - current) >= minStep
    }

    /// Texto do zoom na tela: "1×", "1,4×", "0,5×".
    public static func label(_ zoom: Double) -> String {
        let rounded = (zoom * 10).rounded() / 10
        if rounded == rounded.rounded() { return "\(Int(rounded))×" }
        return String(format: "%.1f", rounded).replacingOccurrences(of: ".", with: ",") + "×"
    }

    /// Por que a pinça não vale agora (texto do Diagnóstico); nulo = vale. Desde a v0.9.1 vale também gravando.
    public static func blockedReason(
        cameraOpen: Bool, dimmed: Bool, testRunning: Bool, reconfiguring: Bool, ultraWideAlone: Bool
    ) -> String? {
        if !cameraOpen { return "câmera fechada" }
        if dimmed { return "tela escura" }
        if testRunning { return "teste em andamento" }
        if reconfiguring { return "câmera sendo reconfigurada" }
        if ultraWideAlone { return "ultra-angular sem câmera combinada (só o botão chega a ela)" }
        return nil
    }
}
