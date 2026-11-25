import Foundation

// v0.9.46: lista de produtos VAZIA, sem erro, quando o iPhone está sem rede.
// Visto em 24 e 25/11: offline o StoreKit pode devolver 0 produtos sem avisar de erro. O app entendia "carregou, a loja
// não tem as opções" e a tela dizia "As opções de acesso ainda não estão disponíveis", o que parece defeito da loja.
// Com o iOS dizendo que não há rede, 0 produtos é falha de rede: a tela mostra "verifique a conexão" e "Tentar novamente".
// Com rede (ou sem sinal ainda), vale o comportamento anterior (produtos que a Apple ainda não publicou).

public enum ProductsLoadRules {
    /// - `count`: quantos produtos o StoreKit devolveu.
    /// - `definitelyOffline`: o iOS informou, de fato, que não há rede (estado desconhecido NÃO conta).
    public static func emptyMeansNetworkFailure(count: Int, definitelyOffline: Bool) -> Bool {
        count == 0 && definitelyOffline
    }
}
