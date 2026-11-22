import Foundation

/// Tutorial de primeiro acesso (v0.9.35): três telas, mostradas uma única vez, por cima do Início.
public enum OnboardingRules {
    /// Como funciona, o que o app vai pedir, calor e qualidade.
    public static let pageCount = 3

    /// Mostrar o tutorial ao abrir o app? Só se ainda não foi concluído e o app não foi aberto por um pedido "abrir câmera"
    /// (Botão de Ação, Atalhos ou Siri): nesse caso o tutorial espera a próxima abertura normal, para não atrapalhar o atalho.
    public static func shouldShowAtLaunch(seen: Bool, launchRequestPending: Bool) -> Bool {
        !seen && !launchRequestPending
    }

    /// A tela é a última (o botão passa a ser "Entendi")?
    public static func isLast(_ page: Int) -> Bool { page >= pageCount - 1 }

    /// A tela seguinte; na última, continua nela.
    public static func next(after page: Int) -> Int { min(max(page, 0) + 1, pageCount - 1) }
}
