import Foundation

/// Onde o usuário está, além do que o motor diz (v0.5.1). Antes eram três variáveis soltas na `RootView`; aqui a regra é pura
/// e tem teste. Câmera e Início dependem do motor (`cameraOpen`): a rota só guarda o que o motor não sabe.
public struct AppRoute: Equatable {
    /// A Galeria está na tela.
    public private(set) var inGallery = false
    /// A câmera está fechada de propósito (player aberto pela miniatura): uma tela preta ocupa o lugar dela, sem piscar o Início.
    public private(set) var parked = false
    /// A Galeria foi aberta pela câmera (voltar leva à câmera) e não pelo Início.
    public private(set) var galleryFromCamera = false

    public init() {}

    /// A tela que vale agora (usada para escolher a transição).
    public func screen(cameraOpen: Bool) -> AppScreen {
        if inGallery || parked { return .gallery }
        return cameraOpen ? .camera : .home
    }

    /// Registra de onde a Galeria vai abrir (antes da troca de tela).
    public mutating func markGalleryOrigin(fromCamera: Bool) { galleryFromCamera = fromCamera }
    public mutating func showGallery() { inGallery = true }
    public mutating func hideGallery() { inGallery = false }
    public mutating func park() { parked = true }
    public mutating func unpark() { parked = false }
}

/// O que o gesto de voltar (borda esquerda) faz.
public enum EdgeBackAction: Equatable {
    /// Na Galeria com seleção: sai da seleção primeiro (v0.4.14).
    case exitSelection
    /// Na Galeria: volta (à câmera ou ao Início, conforme a origem).
    case leaveGallery
    /// Na câmera: volta ao Início.
    case closeCamera
    /// Tela escura (v0.6.3): o gesto só acende a tela; não navega.
    case wakeScreen
    case none
}

/// Gravando, o gesto é ignorado: um arrasto sem querer com a mão molhada não pode encerrar o clipe (v0.3.5).
/// Com a tela escura (v0.6.3), qualquer gesto de voltar só acende a tela.
public func edgeBackAction(
    inGallery: Bool, selecting: Bool, cameraOpen: Bool, recording: Bool, dimmed: Bool = false
) -> EdgeBackAction {
    if dimmed { return .wakeScreen }
    if inGallery { return selecting ? .exitSelection : .leaveGallery }
    if cameraOpen && !recording { return .closeCamera }
    return .none
}

/// O que o gesto de avançar (borda direita) faz.
public enum EdgeForwardAction: Equatable {
    case galleryFromCamera
    case galleryFromHome
    case none
}

/// Abre a Galeria pelo Início ou pela câmera. Não vale na Galeria, com o player aberto, abrindo a câmera, no teste de
/// aberturas nem gravando.
public func edgeForwardAction(
    route: AppRoute, playerOpen: Bool, opening: Bool, testRunning: Bool, cameraOpen: Bool, recording: Bool,
    dimmed: Bool = false
) -> EdgeForwardAction {
    if dimmed { return .none }
    if route.inGallery || route.parked || playerOpen { return .none }
    if opening || testRunning { return .none }
    if cameraOpen { return recording ? .none : .galleryFromCamera }
    return .galleryFromHome
}

/// Tela escura (v0.6.3): só vale com a câmera aberta (a tela escura existe para a câmera seguir trabalhando) e fora do teste de
/// aberturas.
public func canDimScreen(cameraOpen: Bool, testRunning: Bool) -> Bool {
    cameraOpen && !testRunning
}
