import Foundation

// C2, etapa 3: os produtos de compra e a tradução do que o StoreKit contou para os tipos do AccessGate.
// Lógica pura (sem StoreKit): a Engine lê o StoreKit 2 e entrega valores simples para cá.

/// Os três produtos criados no App Store Connect (IDs fixos, nunca mudam).
public enum StoreProductID {
    public static let monthly = "app.eiclip.mensal"
    public static let yearly = "app.eiclip.anual"
    public static let permanent = "app.eiclip.permanente"
    /// Grupo de assinaturas "Ei Clip Acesso" (Anual e Mensal).
    public static let subscriptionGroupID = "22598306"
    /// Ordem de exibição na tela.
    public static let all = [monthly, yearly, permanent]
    public static let subscriptions = [monthly, yearly]

    public static func isSubscription(_ id: String) -> Bool { subscriptions.contains(id) }
}

/// Estado bruto de uma assinatura como o StoreKit 2 informa.
public enum RawSubscriptionState: Equatable {
    case subscribed
    case inGracePeriod
    case inBillingRetry
    case expired
    case revoked
}

public enum StoreMapping {
    /// Prazo mínimo de carência de cobrança da Apple (6 dias), usado só se o iOS não informar a data da carência.
    public static let fallbackGraceDays = 6

    /// Traduz o estado bruto para `SubscriptionStatus`.
    /// - `periodEnd`: fim do período pago (vem da transação verificada).
    /// - `graceUntil`: fim da carência de cobrança, se o iOS informar.
    public static func status(
        raw: RawSubscriptionState, periodEnd: Date, graceUntil: Date?
    ) -> SubscriptionStatus {
        switch raw {
        case .subscribed: return .active(periodEnd: periodEnd)
        case .inGracePeriod:
            let fallback = periodEnd.addingTimeInterval(Double(fallbackGraceDays) * 86_400)
            return .inGracePeriod(until: graceUntil ?? fallback)
        case .inBillingRetry: return .billingRetry
        case .expired: return .expired
        case .revoked: return .revoked
        }
    }
}

public enum StoreAnswerBuilder {
    /// Junta o que o StoreKit contou numa resposta única (resposta válida da Apple).
    /// `subscriptions`: uma entrada por assinatura encontrada. Escolhe a melhor situação:
    /// ativa (a de fim mais distante) > carência de cobrança > nova tentativa de cobrança > terminada > revogada.
    public static func build(
        permanentOwned: Bool, subscriptions: [SubscriptionStatus], pending: Bool
    ) -> StoreAnswer {
        .answered(permanent: permanentOwned, subscription: best(subscriptions), purchasePending: pending)
    }

    static func best(_ list: [SubscriptionStatus]) -> SubscriptionStatus? {
        list.max { rank($0) < rank($1) }
    }

    /// Maior = melhor. Dentro da mesma categoria, a data mais distante ganha.
    private static func rank(_ s: SubscriptionStatus) -> Double {
        switch s {
        case .active(let end): return 5_000_000_000_000 + end.timeIntervalSince1970
        case .inGracePeriod(let until): return 4_000_000_000_000 + until.timeIntervalSince1970
        case .billingRetry: return 3_000_000_000_000
        case .expired: return 2_000_000_000_000
        case .revoked: return 1_000_000_000_000
        }
    }
}

extension StoreAnswer {
    /// Texto curto para o Diagnóstico (sem dados pessoais).
    public var logText: String {
        switch self {
        case .unavailable: return "Apple sem resposta (estado desconhecido)"
        case let .answered(permanent, subscription, pending):
            var parts: [String] = []
            parts.append(permanent ? "permanente: sim" : "permanente: não")
            switch subscription {
            case .none: parts.append("assinatura: nenhuma")
            case .active?: parts.append("assinatura: ativa")
            case .inGracePeriod?: parts.append("assinatura: carência de cobrança")
            case .billingRetry?: parts.append("assinatura: problema de pagamento")
            case .expired?: parts.append("assinatura: terminou")
            case .revoked?: parts.append("assinatura: revogada")
            }
            if pending { parts.append("compra pendente") }
            return parts.joined(separator: " · ")
        }
    }
}
