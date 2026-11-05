import Foundation

/// Regras dos gestos de arrastar do player. Porta de `bindPlayerSwipeDown` em `ui/clips-view.ts` do web app
/// (medidas em pontos; velocidades em pontos por milissegundo).
public enum SwipeRules {
    // MARK: - Arrastar para baixo fecha (v0.4.5)

    /// O arrasto só conta como "para baixo" depois de 12 pt e se for mais vertical do que horizontal (1,2 vez).
    public static func isDownDrag(dx: Double, dy: Double) -> Bool {
        dy >= 12 && abs(dy) >= abs(dx) * 1.2
    }

    /// Quanto do arrasto já foi feito, de 0 a 1 (chega a 1 com 500 pt).
    public static func dismissProgress(dy: Double) -> Double {
        min(1, max(0, dy) / 500)
    }

    /// A tela encolhe até 88% e esmaece até 30% enquanto é arrastada.
    public static func dismissScale(progress: Double) -> Double { 1 - progress * 0.12 }
    public static func dismissOpacity(progress: Double) -> Double { 1 - progress * 0.7 }

    /// Soltando depois de 130 pt fecha; num arremesso rápido (mais de 0,6 pt/ms) fecha com mais de 50 pt.
    public static func shouldClose(dy: Double, elapsedMs: Double) -> Bool {
        let fast = dy / max(1, elapsedMs) > 0.6
        return dy > 130 || (fast && dy > 50)
    }
}
