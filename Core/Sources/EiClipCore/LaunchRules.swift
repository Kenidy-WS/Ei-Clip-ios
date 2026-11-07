import Foundation

/// O que o app faz ao receber o pedido "abrir câmera" vindo de fora (v0.9.2): Botão de Ação, Atalhos ou Siri.
public enum LaunchAction: Equatable {
    /// Estava no Início: abre a câmera pelo mesmo caminho do botão "Abrir câmera" (com o aviso de permissões, se houver).
    case openFromHome
    /// Estava na Galeria (a câmera fechada): volta à câmera pelo caminho de sempre.
    case openFromGallery
    /// A câmera já está na tela: nada a fazer.
    case alreadyOpen
    /// Não é seguro abrir agora; o texto vai para o Diagnóstico.
    case ignored(String)

    /// Texto curto para o Diagnóstico.
    public var text: String {
        switch self {
        case .openFromHome: return "abrir a câmera (estava no Início)"
        case .openFromGallery: return "abrir a câmera (estava na Galeria)"
        case .alreadyOpen: return "a câmera já está aberta"
        case .ignored(let why): return "ignorado: \(why)"
        }
    }
}

public enum LaunchRules {
    /// Um pedido que ninguém atendeu em 15 s é descartado (evita abrir a câmera por um pedido velho).
    public static let maxAge: TimeInterval = 15

    public static func isFresh(age: TimeInterval) -> Bool { age >= 0 && age <= maxAge }

    /// Decide o que fazer. `overlayPresented`: há algo por cima da raiz (player, Ajustes ou aviso); abrir a câmera por baixo
    /// de um player mexeria na sessão de áudio de reprodução, por isso nunca se abre nesse caso.
    public static func action(
        route: AppRoute, cameraOpen: Bool, overlayPresented: Bool, opening: Bool, testRunning: Bool
    ) -> LaunchAction {
        if testRunning { return .ignored("teste de aberturas em andamento") }
        if opening { return .ignored("a câmera já está abrindo") }
        if overlayPresented { return .ignored("há uma tela por cima (player, Ajustes ou aviso)") }
        if route.parked { return .ignored("player aberto pela câmera") }
        if route.inGallery { return .openFromGallery }
        if cameraOpen { return .alreadyOpen }
        return .openFromHome
    }
}
