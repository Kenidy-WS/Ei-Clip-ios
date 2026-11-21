import Foundation

// C2, etapa 5a: leitura da assinatura (lógica pura, sem StoreKit). Só informação: o `AccessGate` não usa nada daqui.
// A Engine lê o StoreKit 2 e entrega valores simples; a tela final (etapa 5b) vai usar `SubscriptionOutlook`.

/// Como a assinatura vai se comportar daqui para frente (a "perspectiva"), para o Diagnóstico e para a tela da 5b.
public enum SubscriptionOutlook: Equatable {
    /// Ativa e renovando no mesmo plano; próxima renovação em `periodEnd`.
    case renewing(productID: String, periodEnd: Date)
    /// Ativa e renovando, com TROCA AGENDADA de plano para a próxima renovação (ex.: Anual → Mensal).
    case renewingOtherPlan(from: String, to: String, periodEnd: Date)
    /// Ativa, mas a renovação foi desligada: o período pago vale até `until` e não haverá nova cobrança.
    case canceledStillPaid(until: Date)
    /// Cobrança falhou e a Apple ainda dá acesso até `until` (carência de cobrança).
    case billingGrace(until: Date)
    /// Cobrança falhou e a Apple segue tentando; SEM acesso.
    case billingRetry
    /// Terminou (não renovou).
    case ended
    /// Reembolsada ou revogada.
    case revoked
    /// Ativa, mas os dados de renovação não vieram (ausentes ou não verificados): não dá para dizer se renova.
    case renewalUnknown(periodEnd: Date)

    /// Esta perspectiva concede acesso? (Espelha o `AccessGate`; um teste confere que os dois concordam.)
    public var grantsAccess: Bool {
        switch self {
        case .renewing, .renewingOtherPlan, .canceledStillPaid, .billingGrace, .renewalUnknown: return true
        case .billingRetry, .ended, .revoked: return false
        }
    }

    /// Texto para o Diagnóstico. `date` formata as datas (a Engine passa o formatador do app).
    public func logText(date: (Date) -> String) -> String {
        switch self {
        case let .renewing(productID, end):
            return "renovação ligada (\(productID)): próxima renovação em \(date(end))"
        case let .renewingOtherPlan(from, to, end):
            return "renovação ligada, TROCA AGENDADA \(from) → \(to) em \(date(end))"
        case let .canceledStillPaid(until):
            return "renovação CANCELADA: acesso até \(date(until)), sem nova cobrança"
        case let .billingGrace(until):
            return "problema de cobrança, em carência: acesso até \(date(until))"
        case .billingRetry:
            return "problema de cobrança, nova tentativa da Apple: sem acesso"
        case .ended:
            return "assinatura terminou"
        case .revoked:
            return "assinatura reembolsada ou revogada"
        case let .renewalUnknown(end):
            return "renovação não lida (dados da Apple ausentes ou não verificados); período pago até \(date(end))"
        }
    }
}

public enum SubscriptionOutlookRules {
    /// Classifica uma assinatura.
    /// - `status`: já traduzido pelo `StoreMapping` (carência com a data do iOS ou o mínimo de 6 dias).
    /// - `productID`: plano da transação atual.
    /// - `willAutoRenew`: `nil` = dados de renovação ausentes ou não verificados.
    /// - `autoRenewPreference`: plano que renova na próxima vez (`nil` = o mesmo).
    /// - `now`: carência que já passou vira "nova tentativa" (igual ao `AccessGate`).
    public static func outlook(
        status: SubscriptionStatus, productID: String, willAutoRenew: Bool?,
        autoRenewPreference: String?, now: Date
    ) -> SubscriptionOutlook {
        switch status {
        case .active(let end):
            guard let renews = willAutoRenew else { return .renewalUnknown(periodEnd: end) }
            if !renews { return .canceledStillPaid(until: end) }
            if let next = autoRenewPreference, next != productID {
                return .renewingOtherPlan(from: productID, to: next, periodEnd: end)
            }
            return .renewing(productID: productID, periodEnd: end)
        case .inGracePeriod(let until):
            return until > now ? .billingGrace(until: until) : .billingRetry
        case .billingRetry: return .billingRetry
        case .expired: return .ended
        case .revoked: return .revoked
        }
    }
}

/// Resultado da leitura das assinaturas na Apple.
public enum SubscriptionsRead: Equatable {
    /// A Apple respondeu (a lista pode ser vazia).
    case read([SubscriptionStatus])
    /// Erro, sem rede ou sem resposta.
    case failed
}

extension StoreAnswerBuilder {
    /// Monta a resposta a partir das duas leituras da Apple (direitos e assinaturas).
    /// Falha na leitura da assinatura: com o permanente confirmado ele continua valendo (a resposta segue válida, sem assinatura);
    /// sem o permanente o estado é DESCONHECIDO (`.unavailable`), nunca "sem direito".
    public static func build(permanentOwned: Bool, read: SubscriptionsRead, pending: Bool) -> StoreAnswer {
        switch read {
        case .read(let list):
            return build(permanentOwned: permanentOwned, subscriptions: list, pending: pending)
        case .failed:
            if permanentOwned { return .answered(permanent: true, subscription: nil, purchasePending: pending) }
            return .unavailable
        }
    }

    /// Posição da melhor situação da lista (mesma regra de `best`); `nil` se vazia.
    public static func bestIndex(of list: [SubscriptionStatus]) -> Int? {
        guard let best = best(list) else { return nil }
        return list.firstIndex(of: best)
    }
}
