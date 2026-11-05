import Foundation

/// Velocidades do botão do player (v0.4.3). Cada toque passa para a próxima: 1× → 1,5× → 2× → 0,5× → 1×.
/// Porta de `RATES` e `rateText` em `ui/clips-view.ts`.
public enum PlaybackRate {
    public static let steps: [Double] = [1, 1.5, 2, 0.5]

    /// A próxima velocidade. Um valor fora da lista volta para 1×.
    public static func next(after rate: Double) -> Double {
        guard let i = steps.firstIndex(of: rate) else { return steps[0] }
        return steps[(i + 1) % steps.count]
    }

    /// "1×", "1,5×", "2×", "0,5×".
    public static func label(_ rate: Double) -> String {
        let text = rate == rate.rounded() ? String(Int(rate)) : String(rate)
        return text.replacingOccurrences(of: ".", with: ",") + "×"
    }
}
