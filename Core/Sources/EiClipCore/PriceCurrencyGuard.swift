import Foundation

// C2, etapa 3 (v0.9.26): proteção de consistência de moeda na exibição dos preços.
// Lógica pura (sem StoreKit): a Engine entrega a moeda da loja e a moeda do produto; aqui só se decide se o preço pode ser mostrado.
// Só trata da apresentação: a compra e a folha da Apple não dependem disto.

public enum PriceDisplay: Equatable {
    /// Mostrar o preço que a Apple entregou (`displayPrice`).
    case show
    /// Não mostrar: o produto veio em moeda diferente da loja do usuário.
    case hide(productCurrency: String, storeCurrency: String)
}

public enum PriceCurrencyGuard {
    /// Só oculta quando as DUAS moedas são conhecidas e diferentes. Sem informação de uma delas, mostra (sem prova de divergência, nada é escondido).
    public static func decide(storeCurrency: String?, productCurrency: String?) -> PriceDisplay {
        guard let store = normalized(storeCurrency), let product = normalized(productCurrency) else { return .show }
        return store == product ? .show : .hide(productCurrency: product, storeCurrency: store)
    }

    private static func normalized(_ code: String?) -> String? {
        guard let code else { return nil }
        let t = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return t.isEmpty ? nil : t
    }
}
