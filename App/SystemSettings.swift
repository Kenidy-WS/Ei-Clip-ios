import UIKit

/// v0.7.5: abre a página do Ei Clip nos Ajustes do iPhone (botão "Abrir Ajustes" dos avisos de permissão).
enum SystemSettings {
    static func open() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
