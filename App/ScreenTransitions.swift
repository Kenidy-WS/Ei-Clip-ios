import SwiftUI
import UIKit

/// Desliza e esmaece (a entrada e a saída da transição de tela). Medidas em `ScreenMotion` (Core).
private struct SlideFade: ViewModifier {
    let x: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content.offset(x: x).opacity(opacity)
    }
}

extension AnyTransition {
    /// Transição entre as telas (v0.4.2), igual à do web app: avançar desliza da direita (a anterior sai para a esquerda),
    /// voltar desliza da esquerda (a anterior sai para a direita), entre Câmera e Galeria só esmaece.
    static func screen(_ kind: ScreenTransitionKind) -> AnyTransition {
        let w = UIScreen.main.bounds.width
        let enter = w * ScreenMotion.enterOffsetFraction
        let exit = w * ScreenMotion.exitOffsetFraction
        switch kind {
        case .none: return .identity
        case .fade: return .opacity
        case .forward: return slide(from: enter, to: -exit)
        case .back: return slide(from: -enter, to: exit)
        }
    }

    private static func slide(from: CGFloat, to: CGFloat) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(active: SlideFade(x: from, opacity: 0), identity: SlideFade(x: 0, opacity: 1)),
            removal: .modifier(active: SlideFade(x: to, opacity: 0), identity: SlideFade(x: 0, opacity: 1)))
    }
}

extension Animation {
    /// Curva e duração das trocas de tela (`--t-screen` e `--ease-out` do web app).
    static var screenChange: Animation {
        .timingCurve(0.22, 0.8, 0.26, 1, duration: ScreenMotion.duration)
    }
}
