import Foundation

/// As três telas do app (v0.4.2).
public enum AppScreen: Equatable {
    case home, camera, gallery
}

/// Como uma tela troca pela outra. Porta de `showView` em `src/ui/transitions.ts`.
public enum ScreenTransitionKind: Equatable {
    /// Sem troca (já estava na tela).
    case none
    /// Início → Câmera ou Galeria: a nova entra deslizando da direita e a anterior sai para a esquerda.
    case forward
    /// De volta ao Início: a nova entra deslizando da esquerda e a anterior sai para a direita.
    case back
    /// Entre Câmera e Galeria: só esmaece.
    case fade
}

/// Regra do web app: voltar ao Início recua; sair do Início avança; entre Câmera e Galeria só há fade.
public func screenTransition(from: AppScreen, to: AppScreen) -> ScreenTransitionKind {
    if from == to { return .none }
    if to == .home { return .back }
    if from == .home { return .forward }
    return .fade
}

/// Medidas das transições (iguais às de `styles.css` do web app).
public enum ScreenMotion {
    /// 300 ms (`--t-screen`).
    public static let duration: Double = 0.3
    /// A tela que entra parte de 26% da largura (`in-from-right` / `in-from-left`).
    public static let enterOffsetFraction: Double = 0.26
    /// A tela que sai vai até 14% da largura (`out-to-left` / `out-to-right`).
    public static let exitOffsetFraction: Double = 0.14
}
