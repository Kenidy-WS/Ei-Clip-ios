import SwiftUI
import UIKit

/// Rolagem automática da Galeria ao selecionar arrastando (v0.8.8): com o dedo perto da borda de cima ou de baixo da lista, ela
/// rola sozinha (quanto mais perto da borda, mais rápido) e os clipes que passam sob o dedo continuam sendo marcados.
///
/// Como: acha o `UIScrollView` por baixo da `ScrollView` do SwiftUI e muda o `contentOffset` a cada quadro (60 vezes por
/// segundo). O dedo parado não gera eventos, então a posição dele na lista é recalculada aqui: posição do último toque mais o
/// quanto a lista andou desde então. Reserva: se o `UIScrollView` não for achado, não rola (o resto da seleção segue igual) e o
/// Diagnóstico registra o motivo.
final class GalleryAutoScroller {
    weak var scrollView: UIScrollView?
    /// Recebe a posição do dedo no espaço da lista ("grid") depois de cada passo de rolagem.
    var onMove: ((CGPoint) -> Void)?
    /// Altura que a barra de seleção cobre embaixo (o dedo sobre ela conta como borda de baixo).
    var bottomBarHeight: CGFloat = 96

    private var timer: Timer?
    private var gridLocation = CGPoint.zero
    private var offsetAtTouch: CGFloat = 0
    private var fingerViewportY: CGFloat = 0
    private var travelled: CGFloat = 0
    private var warnedMissing = false

    private let edgeZone: CGFloat = 70
    private let maxStep: CGFloat = 16  // pontos por quadro (~960 pt/s no máximo)
    /// Espaço entre o início da pilha ("grid") e o início do conteúdo da rolagem (o `.padding(.top, 4)` da lista).
    private let contentTopPadding: CGFloat = 4

    /// Chamado a cada evento do dedo (toque novo ou movimento).
    func touch(_ location: CGPoint) {
        guard let sv = scrollView else {
            if !warnedMissing {
                warnedMissing = true
                Diagnostics.shared.log("galeria", "rolagem automática indisponível: a lista (UIScrollView) não foi encontrada")
            }
            return
        }
        gridLocation = location
        offsetAtTouch = sv.contentOffset.y
        fingerViewportY = location.y + contentTopPadding - sv.contentOffset.y
        if timer == nil {
            let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if travelled > 0 {
            Diagnostics.shared.log("galeria", "seleção: rolagem automática andou \(Int(travelled)) pt")
        }
        travelled = 0
    }

    private func tick() {
        guard let sv = scrollView else { return }
        let height = sv.bounds.height
        let y = fingerViewportY
        let bottomStart = height - bottomBarHeight - edgeZone
        var step: CGFloat = 0
        if y < edgeZone {
            step = -min(1, (edgeZone - y) / edgeZone) * maxStep
        } else if y > bottomStart {
            step = min(1, (y - bottomStart) / edgeZone) * maxStep
        }
        guard step != 0 else { return }
        let minOffset = -sv.adjustedContentInset.top
        let maxOffset = max(minOffset, sv.contentSize.height - height + sv.adjustedContentInset.bottom)
        let current = sv.contentOffset.y
        let next = min(max(current + step, minOffset), maxOffset)
        guard abs(next - current) > 0.1 else { return }
        sv.contentOffset = CGPoint(x: sv.contentOffset.x, y: next)
        travelled += abs(next - current)
        onMove?(CGPoint(x: gridLocation.x, y: gridLocation.y + (next - offsetAtTouch)))
    }
}

/// Fica "por baixo" da lista só para achar o `UIScrollView` que a contém.
struct ScrollViewFinder: UIViewRepresentable {
    let onFound: (UIScrollView) -> Void

    func makeUIView(context: Context) -> FinderView {
        let view = FinderView()
        view.isUserInteractionEnabled = false
        view.onFound = onFound
        return view
    }

    func updateUIView(_ uiView: FinderView, context: Context) {}

    final class FinderView: UIView {
        var onFound: ((UIScrollView) -> Void)?
        override func didMoveToWindow() {
            super.didMoveToWindow()
            var view: UIView? = superview
            while let current = view {
                if let scroll = current as? UIScrollView {
                    onFound?(scroll)
                    return
                }
                view = current.superview
            }
        }
    }
}
