import Foundation

// v0.9.34: o que a folha de resultado mostra depois de uma compra aprovada (lógica pura, sem StoreKit e sem textos).
// Parte do produto comprado e da situação de "Meu plano" JÁ recalculada depois da compra.

public enum PurchaseResultContent: Equatable {
    /// Assinatura nova. `renewsOn` = próxima renovação, se a Apple informou.
    case subscription(planID: String, renewsOn: Date?)
    /// Assinatura comprada com outra já ativa: a Apple só agenda a troca para a próxima renovação.
    case planChangeScheduled(toID: String, changesOn: Date)
    /// Permanente sem assinatura que possa cobrar.
    case permanentAlone
    /// Permanente comprado com assinatura que ainda pode cobrar: o aviso diz que ela NÃO foi cancelada.
    case permanentWithSubscription(PurchaseWarning)
}

public enum PurchaseResultRules {
    public static func content(purchased productID: String, planKind: PlanScreenKind) -> PurchaseResultContent {
        if productID == StoreProductID.permanent {
            guard case .permanent(let extra) = planKind else { return .permanentAlone }
            switch extra {
            case .none: return .permanentAlone
            case .renewing(let date): return .permanentWithSubscription(.renewing(renewsOn: date))
            case .billingTrouble: return .permanentWithSubscription(.mayCharge)
            }
        }
        switch planKind {
        case .renewing(_, let date): return .subscription(planID: productID, renewsOn: date)
        case .planChange(_, let toID, let date): return .planChangeScheduled(toID: toID, changesOn: date)
        default: return .subscription(planID: productID, renewsOn: nil)
        }
    }
}
