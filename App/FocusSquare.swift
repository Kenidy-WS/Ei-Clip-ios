import SwiftUI

/// Quadrado de foco (v0.7.16), como o da câmera nativa: quadrado de verdade, linha fina e um tracinho para dentro no meio
/// de cada lado (a "mira").
struct FocusSquare: View {
    static let size: CGFloat = 76
    private let tick: CGFloat = 6

    var body: some View {
        let s = Self.size
        let h = s / 2
        ZStack {
            Rectangle()
                .stroke(Color.yellow, lineWidth: 1)
            Path { p in
                p.move(to: CGPoint(x: h, y: 0))
                p.addLine(to: CGPoint(x: h, y: tick))
                p.move(to: CGPoint(x: h, y: s))
                p.addLine(to: CGPoint(x: h, y: s - tick))
                p.move(to: CGPoint(x: 0, y: h))
                p.addLine(to: CGPoint(x: tick, y: h))
                p.move(to: CGPoint(x: s, y: h))
                p.addLine(to: CGPoint(x: s - tick, y: h))
            }
            .stroke(Color.yellow, lineWidth: 1)
        }
        .frame(width: s, height: s)
        .shadow(color: .black.opacity(0.35), radius: 1)
        .accessibilityHidden(true)
    }
}

/// Sol do EV (v0.7.16): fica colado no quadrado de foco, na altura do centro. Arrastar para cima clareia, para baixo escurece
/// (de −2 a +2, limitado pelo aparelho). O valor vem de `engine.evValue` lido a cada 0,05 s (`LiveTick`): nada é publicado
/// pelo motor, para não repetir o travamento do iOS 27. Durante o arraste a tela usa o valor local, para o sol acompanhar o dedo.
struct ExposureSun: View {
    @EnvironmentObject var engine: CaptureEngine
    let mark: FocusMark
    let screenWidth: CGFloat

    @State private var dragStart: Double?
    @State private var dragEV: Double?

    private let column: CGFloat = 56
    private let columnHeight: CGFloat = 190  // v0.7.19: barra curta (±60 pontos do sol) e espaço para o valor embaixo

    var body: some View {
        let onRight = ExposureRules.sunOnRight(markX: mark.x, screenWidth: Double(screenWidth))
        let centerX = CGFloat(mark.x) + (onRight ? 1 : -1) * (FocusSquare.size / 2 + 8 + column / 2)
        LiveTick(interval: 0.05) {
            let ev = dragEV ?? engine.evValue
            ZStack {
                Capsule()
                    .fill(Color.yellow.opacity(0.55))
                    .frame(width: 1, height: CGFloat(ExposureRules.limit * 2 * ExposureRules.sunPointsPerEV))
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(.yellow)
                    .shadow(color: .black.opacity(0.45), radius: 1.5)
                    .offset(y: CGFloat(ExposureRules.sunOffset(for: ev)))
                if !ExposureRules.isNeutral(ev) {
                    Text(ExposureRules.label(ev))
                        .font(.system(size: 12, weight: .medium).monospacedDigit())
                        .foregroundColor(.yellow)
                        .shadow(color: .black.opacity(0.6), radius: 1.5)
                        .offset(y: CGFloat(ExposureRules.sunOffset(for: ev)) + 22)
                }
            }
            .frame(width: column, height: columnHeight)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { g in
                    let start = dragStart ?? engine.evValue
                    if dragStart == nil { dragStart = start }
                    let range = engine.evRange ?? (-ExposureRules.limit...ExposureRules.limit)
                    let v = ExposureRules.value(start: start, translation: Double(g.translation.height), in: range)
                    dragEV = v
                    engine.adjustEV(to: v)
                }
                .onEnded { _ in
                    engine.finishEVAdjust(from: dragStart)
                    dragStart = nil
                    dragEV = nil
                }
        )
        .offset(x: centerX - column / 2, y: CGFloat(mark.y) - columnHeight / 2)
        .accessibilityLabel(Textos.ajustarBrilho)
    }
}
