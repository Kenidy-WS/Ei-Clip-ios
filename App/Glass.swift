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


/// Botão só com o ícone, sem círculo (v0.7.1): área de toque de 44 pt e sombra leve para ler sobre qualquer cena.
/// `highlighted` acende um halo verde atrás (aviso de "ouvi" da voz).
struct BareIconButton: View {
    let systemName: String
    var color: Color = .white
    var highlighted: Bool = false
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(red: 48 / 255, green: 209 / 255, blue: 88 / 255).opacity(highlighted ? 0.5 : 0))
                    .frame(width: 36, height: 36)
                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(highlighted ? .white : color)
                    .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.2), value: highlighted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Ícone de ajustes do web app (v0.7.1): duas barras com um ponto em cada, desenhado numa grade de 24 × 24.
struct SlidersIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let k = min(rect.width, rect.height) / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * k, y: rect.minY + y * k) }
        var path = Path()
        for (x1, x2, y) in [(4, 13, 7), (17, 20, 7), (4, 7, 17), (11, 20, 17)] as [(CGFloat, CGFloat, CGFloat)] {
            path.move(to: pt(x1, y))
            path.addLine(to: pt(x2, y))
        }
        for (cx, cy) in [(15, 7), (9, 17)] as [(CGFloat, CGFloat)] {
            path.addEllipse(in: CGRect(x: rect.minX + (cx - 2) * k, y: rect.minY + (cy - 2) * k, width: 4 * k, height: 4 * k))
        }
        return path
    }
}
