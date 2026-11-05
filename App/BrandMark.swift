import SwiftUI

/// Marca do Ei Clip (anel amarelo, triângulo e ponto vermelho) com a animação de entrada do web app:
/// o anel é "desenhado" em 1 s, o triângulo aparece aos 0,6 s e o ponto salta aos 0,95 s.
struct BrandMark: View {
    var size: CGFloat = 96
    @State private var trail: CGFloat = 0
    @State private var triangleOn = false
    @State private var dotOn = false

    var body: some View {
        let k = size / 200  // as imagens vêm de um desenho de 200 x 200
        ZStack {
            Image("MarkRing")
                .resizable()
                .frame(width: size, height: size)
                .mask(
                    Circle()
                        .trim(from: 0, to: trail)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 60 * k))
                        .frame(width: 120 * k, height: 120 * k)
                        .rotationEffect(.degrees(35))
                        .frame(width: size, height: size)
                )
            Image("MarkTriangle")
                .resizable()
                .frame(width: size, height: size)
                .scaleEffect(triangleOn ? 1 : 0.5, anchor: UnitPoint(x: 0.52, y: 0.5))
                .opacity(triangleOn ? 1 : 0)
            Image("MarkDot")
                .resizable()
                .frame(width: size, height: size)
                .scaleEffect(dotOn ? 1 : 0.001, anchor: UnitPoint(x: 149.1 / 200, y: 65.6 / 200))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) { trail = 1 }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) { triangleOn = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.95)) { dotOn = true }
        }
    }
}
