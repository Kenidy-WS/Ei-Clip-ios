import UIKit

/// Há algo por cima da raiz do app (player, Ajustes ou aviso)? Usado pelo atalho "abrir câmera" (v0.9.2) e pelos botões de
/// volume (v0.9.5), que não devem agir por baixo de outra tela.
enum ScreenOverlay {
    static func isPresented() -> Bool {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .contains { $0.isKeyWindow && $0.rootViewController?.presentedViewController != nil }
    }
}
