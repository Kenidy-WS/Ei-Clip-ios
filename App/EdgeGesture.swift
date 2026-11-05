import SwiftUI

/// Gesto de voltar pela borda (igual ao `gestures.ts` do web app): arrastar da borda esquerda para a direita volta um passo.
/// Só vale se o dedo começa a até 28 pt da borda, anda 70 pt ou mais, em até 0,7 s e mais para o lado do que para baixo ou cima.
/// Assim não atrapalha a rolagem nem a barra de posição do vídeo.
struct EdgeBackGesture: ViewModifier {
    let onBack: () -> Void
    @State private var startedAt: Date?

    private let edge: CGFloat = 28
    private let minDX: CGFloat = 70
    private let maxSeconds: TimeInterval = 0.7

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                .onChanged { _ in
                    if startedAt == nil { startedAt = Date() }
                }
                .onEnded { value in
                    let began = startedAt ?? Date()
                    startedAt = nil
                    let dx = value.translation.width
                    let dy = value.translation.height
                    guard value.startLocation.x <= edge, dx >= minDX,
                        Date().timeIntervalSince(began) <= maxSeconds,
                        abs(dy) <= abs(dx) * 0.6
                    else { return }
                    onBack()
                })
    }
}

extension View {
    /// Voltar arrastando da borda esquerda (v0.3.5).
    func edgeBack(_ action: @escaping () -> Void) -> some View {
        modifier(EdgeBackGesture(onBack: action))
    }
}
