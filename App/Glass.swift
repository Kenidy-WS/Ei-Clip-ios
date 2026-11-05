import SwiftUI

/// "Vidro" do web app (`.btn-glass`): translúcido e claro, com desfoque, borda e brilho bem finos.
/// Só para elementos que flutuam sobre a imagem da câmera.
struct GlassCircle: View {
    var size: CGFloat = 44

    var body: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay(
                Circle().fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.16), Color.white.opacity(0.07)],
                        startPoint: .top, endPoint: .bottom))
            )
            .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 0.5))
            .frame(width: size, height: size)
    }
}

extension View {
    /// Fundo de vidro em qualquer forma (cápsula, retângulo arredondado): as barras do player (v0.4.3).
    func glassBackground<S: Shape>(_ shape: S) -> some View {
        background {
            shape.fill(.ultraThinMaterial)
                .overlay(
                    shape.fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.16), Color.white.opacity(0.07)],
                            startPoint: .top, endPoint: .bottom))
                )
                .overlay(shape.stroke(Color.white.opacity(0.24), lineWidth: 0.5))
        }
    }
}

/// Botão redondo de vidro com um ícone (voltar, ajustes, voz).
struct GlassIconButton: View {
    let systemName: String
    var color: Color = .white
    var size: CGFloat = 44
    /// v0.3.11: acende o fundo em verde (aviso de "ouvi").
    var highlighted: Bool = false
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                GlassCircle(size: size)
                if highlighted {
                    Circle().fill(Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255).opacity(0.5))
                        .frame(width: size, height: size)
                }
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(highlighted ? .white : color)
            }
            .animation(.easeOut(duration: 0.2), value: highlighted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
