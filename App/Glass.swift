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

/// Botão redondo de vidro com um ícone (voltar, ajustes, voz).
struct GlassIconButton: View {
    let systemName: String
    var color: Color = .white
    var size: CGFloat = 44
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                GlassCircle(size: size)
                Image(systemName: systemName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
