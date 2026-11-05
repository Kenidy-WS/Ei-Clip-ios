import SwiftUI

/// Gesto de voltar pela borda (igual ao `gestures.ts` do web app): arrastar da borda esquerda para a direita volta um passo.
/// Só vale se o dedo começa a até 28 pt da borda, anda 70 pt ou mais, em até 0,7 s e mais para o lado do que para baixo ou cima.
///
/// v0.4.8: o gesto é de uma FAIXA de 28 pt na borda (e não da tela inteira, em paralelo com os toques). Assim, um arrasto que
/// começa na borda nunca chega às miniaturas nem aos botões: antes, o fim do arrasto às vezes contava como toque e abria um vídeo.
struct EdgeBackGesture: ViewModifier {
    let onBack: () -> Void
    @State private var startedAt: Date?

    private let edge: CGFloat = 28
    private let minDX: CGFloat = 70
    private let maxSeconds: TimeInterval = 0.7

    func body(content: Content) -> some View {
        content.overlay(
            Color.clear
                .frame(width: edge)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .global)
                        .onChanged { _ in
                            if startedAt == nil { startedAt = Date() }
                        }
                        .onEnded { value in
                            let began = startedAt ?? Date()
                            startedAt = nil
                            let dx = value.translation.width
                            let dy = value.translation.height
                            guard dx >= minDX,
                                Date().timeIntervalSince(began) <= maxSeconds,
                                abs(dy) <= abs(dx) * 0.6
                            else { return }
                            onBack()
                        }),
            alignment: .leading)
    }
}

extension View {
    /// Voltar arrastando da borda esquerda (v0.3.5; faixa própria desde a v0.4.8).
    func edgeBack(_ action: @escaping () -> Void) -> some View {
        modifier(EdgeBackGesture(onBack: action))
    }
}
