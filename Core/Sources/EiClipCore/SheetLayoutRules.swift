import Foundation

// v0.9.32: medidas da folha de Ajustes (lógica pura). A folha tem altura fixa (sem tela cheia, para o fundo não piscar);
// páginas altas rolam dentro dela, e o app avisa quando ainda há conteúdo abaixo.

public enum SheetLayoutRules {
    /// Altura preferida da folha e margem mínima que sobra no topo (a câmera continua visível).
    public static let preferredHeight: Double = 640
    public static let minTopMargin: Double = 110
    public static let minimumHeight: Double = 520
    /// Diferença mínima para dizer que ainda há conteúdo escondido (evita aviso por arredondamento).
    public static let hiddenThreshold: Double = 12

    /// Altura da folha para a tela do aparelho: a preferida, sempre deixando margem no topo.
    public static func sheetHeight(screenHeight: Double) -> Double {
        min(preferredHeight, max(minimumHeight, screenHeight - minTopMargin))
    }

    /// `contentBottom`: base do conteúdo, medida a partir do topo da área visível; `viewport`: altura da área visível.
    public static func hasMoreBelow(contentBottom: Double, viewport: Double) -> Bool {
        contentBottom - viewport > hiddenThreshold
    }
}
