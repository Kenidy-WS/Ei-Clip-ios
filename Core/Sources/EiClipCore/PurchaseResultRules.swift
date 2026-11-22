import Foundation

// v0.9.34: o que a folha de resultado mostra depois de uma compra aprovada (lógica pura, sem StoreKit e sem textos).
// Parte do produto comprado e da situação de "Meu plano" JÁ recalculada depois da compra.
// Simples de propósito: ou a compra valeu (e a tela diz o quê), ou a Apple só devolveu uma assinatura que já existia.

public enum PurchaseResultContent: Equatable {
    /// Assinatura nova. `renewsOn` = próxima renovação, se a Apple informou.
    case subscription(planID: String, renewsOn: Date?)
    /// A Apple devolveu uma assinatura que já existia (outro plano, troca agendada ou cancelada com período em curso).
    /// Não houve compra nova; a tela só orienta a usar "Gerenciar assinatura".
    case alreadySubscribed
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
        if let requested, requested != productID { return .alreadySubscribed }
        switch planKind {
        case .renewing(_, let date): return .subscription(planID: productID, renewsOn: date)
        case .planChange, .canceled: return .alreadySubscribed
        default: return .subscription(planID: productID, renewsOn: nil)
        }
    }
}
