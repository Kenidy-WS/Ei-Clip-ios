import SwiftUI
import UIKit

/// Gesto de borda NATIVO (v0.5.2): arrastar da borda esquerda volta; da direita avança. Usa o reconhecedor do próprio iOS
/// (`UIScreenEdgePanGestureRecognizer`), que só reage a quem COMEÇA na borda e não toma os toques de ninguém. Substitui as
/// faixas de 28 pt das v0.4.8–v0.4.14, que bloqueavam os toques da borda (por isso os botões tinham margem de 28 pt).
/// A regra de aceitação (70 pt, 0,7 s, inclinação) fica no Core (`EdgeSwipe`).
///
/// Há um reconhecedor de cada lado, na janela. Cada tela que quer o gesto se registra; só a ÚLTIMA registrada (a que está por
/// cima: a folha de Ajustes sobre a raiz, o player sobre a Galeria) recebe. Uma tela que registra sem ações bloqueia o gesto.
final class EdgeGestureHub: NSObject, UIGestureRecognizerDelegate {
    static let shared = EdgeGestureHub()

    private struct Entry {
        let id: UUID
        var onBack: (() -> Void)?
        var onForward: (() -> Void)?
    }

    private var stack: [Entry] = []
    private weak var window: UIWindow?
    private var beganAt: Date?
    private lazy var leftPan = makePan(.left)
    private lazy var rightPan = makePan(.right)

    private func makePan(_ edge: UIRectEdge) -> UIScreenEdgePanGestureRecognizer {
        let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(_:)))
        pan.edges = edge
        pan.delegate = self
        return pan
    }

    func register(id: UUID, window: UIWindow, onBack: (() -> Void)?, onForward: (() -> Void)?) {
        install(on: window)
        stack.removeAll { $0.id == id }
        stack.append(Entry(id: id, onBack: onBack, onForward: onForward))
    }

    func update(id: UUID, onBack: (() -> Void)?, onForward: (() -> Void)?) {
        guard let index = stack.firstIndex(where: { $0.id == id }) else { return }
        stack[index].onBack = onBack
        stack[index].onForward = onForward
    }

    func unregister(id: UUID) {
        stack.removeAll { $0.id == id }
    }

    private func install(on newWindow: UIWindow) {
        guard window !== newWindow else { return }
        if let old = window {
            old.removeGestureRecognizer(leftPan)
            old.removeGestureRecognizer(rightPan)
        }
        newWindow.addGestureRecognizer(leftPan)
        newWindow.addGestureRecognizer(rightPan)
        window = newWindow
    }

    @objc private func handle(_ pan: UIScreenEdgePanGestureRecognizer) {
        switch pan.state {
        case .began:
            beganAt = Date()
        case .ended:
            let t = pan.translation(in: pan.view)
            let isLeft = pan.edges == .left
            let dx = Double(isLeft ? t.x : -t.x)
            let seconds = Date().timeIntervalSince(beganAt ?? Date())
            beganAt = nil
            guard EdgeSwipe.accepts(dx: dx, dy: Double(t.y), seconds: seconds), let top = stack.last else { return }
            // Com a folha de compartilhar do iOS por cima, o gesto não é nosso.
            if topController(of: window) is UIActivityViewController { return }
            if isLeft { top.onBack?() } else { top.onForward?() }
        case .cancelled, .failed:
            beganAt = nil
        default:
            break
        }
    }

    private func topController(of window: UIWindow?) -> UIViewController? {
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    // Convive com a rolagem e com os outros gestos.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

/// Vista invisível que registra a tela no `EdgeGestureHub` enquanto ela está na janela.
private struct EdgeGestureInstaller: UIViewRepresentable {
    let onBack: (() -> Void)?
    let onForward: (() -> Void)?

    final class Coordinator {
        let id = UUID()
        var onBack: (() -> Void)?
        var onForward: (() -> Void)?
        var attached = false

        func attach(to window: UIWindow) {
            EdgeGestureHub.shared.register(id: id, window: window, onBack: onBack, onForward: onForward)
            attached = true
        }

        func detach() {
            EdgeGestureHub.shared.unregister(id: id)
            attached = false
        }

        func refresh() {
            if attached { EdgeGestureHub.shared.update(id: id, onBack: onBack, onForward: onForward) }
        }
    }

    final class HostView: UIView {
        var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if let window { coordinator?.attach(to: window) } else { coordinator?.detach() }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> HostView {
        let view = HostView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        context.coordinator.onBack = onBack
        context.coordinator.onForward = onForward
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: HostView, context: Context) {
        context.coordinator.onBack = onBack
        context.coordinator.onForward = onForward
        context.coordinator.refresh()
    }

    static func dismantleUIView(_ uiView: HostView, coordinator: Coordinator) {
        coordinator.detach()
    }
}

extension View {
    /// Gestos de borda desta tela (v0.5.2): `back` na borda esquerda, `forward` na direita. Passar nil (ou nada) numa borda
    /// ignora o gesto dela. Só a tela que está por cima recebe.
    func edgeGestures(back: (() -> Void)? = nil, forward: (() -> Void)? = nil) -> some View {
        background(EdgeGestureInstaller(onBack: back, onForward: forward).frame(width: 0, height: 0))
    }
}
