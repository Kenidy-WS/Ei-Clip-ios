import Foundation

// v0.9.34: o que a folha de resultado mostra depois de uma compra aprovada (lógica pura, sem StoreKit e sem textos).
// Parte do produto comprado e da situação de "Meu plano" JÁ recalculada depois da compra.

public enum PurchaseResultContent: Equatable {
    /// Assinatura nova. `renewsOn` = próxima renovação, se a Apple informou.
    case subscription(planID: String, renewsOn: Date?)
    /// Assinatura comprada com outra já ativa: a Apple só agenda a troca para a próxima renovação.
    case planChangeScheduled(toID: String, changesOn: Date)
    /// O toque foi num plano, mas a Apple devolveu a assinatura que já estava ativa (não houve compra nova nem troca agendada).
    case alreadySubscribed(planID: String, renewsOn: Date?)
    /// Tocou no plano que já é o atual, mas há troca para outro plano agendada: a troca continua valendo.
    case keptWithScheduledChange(planID: String, toID: String, changesOn: Date)
    /// A assinatura já foi cancelada e vale até `until`; nenhuma compra nova foi feita.
    case alreadyCanceled(planID: String, until: Date)
    /// Permanente sem assinatura que possa cobrar.
    case permanentAlone
    /// Permanente comprado com assinatura que ainda pode cobrar: o aviso diz que ela NÃO foi cancelada.
    case permanentWithSubscription(PurchaseWarning)
}

public enum PurchaseResultRules {
    /// - `productID`: a transação devolvida pela Apple; `requested`: o plano em que a pessoa tocou.
    public static func content(purchased productID: String, requested: String? = nil, planKind: PlanScreenKind) -> PurchaseResultContent {
        if productID == StoreProductID.permanent {
            guard case .permanent(let extra) = planKind else { return .permanentAlone }
            switch extra {
            case .none: return .permanentAlone
            case .renewing(let date): return .permanentWithSubscription(.renewing(renewsOn: date))
            case .billingTrouble: return .permanentWithSubscription(.mayCharge)
            }
        }
        if case .canceled(let until) = planKind { return .alreadyCanceled(planID: productID, until: until) }
        if let requested, requested == productID, case .planChange(_, let toID, let date) = planKind {
            return .keptWithScheduledChange(planID: productID, toID: toID, changesOn: date)
        }
        if let requested, requested != productID {
            switch planKind {
            case .planChange(_, let toID, let date): return .planChangeScheduled(toID: toID, changesOn: date)
            case .renewing(_, let date): return .alreadySubscribed(planID: productID, renewsOn: date)
            default: return .alreadySubscribed(planID: productID, renewsOn: nil)
            }
        }
        switch planKind {
        case .renewing(_, let date): return .subscription(planID: productID, renewsOn: date)
        case .planChange(_, let toID, let date): return .planChangeScheduled(toID: toID, changesOn: date)
        default: return .subscription(planID: productID, renewsOn: nil)
        }
    }
}
