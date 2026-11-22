import Foundation

// v0.9.36: resumo curto do plano, mostrado à direita da linha "Meu plano" nos Ajustes (lógica pura, sem textos).
// Parte da situação que a tela "Meu plano" já usa (`PlanScreenKind`); nada aqui muda o acesso.

/// O que a linha "Meu plano" mostra à direita. Os textos ficam em `Engine/Textos.swift`.
public enum PlanSummary: Equatable {
    /// Ainda carregando (ou plano desconhecido): a linha fica sem resumo.
    case none
    case freeClips(remaining: Int)
    case noFreeClips
    case monthly
    case yearly
    /// Período pago que vale até esta data (assinatura cancelada, ou ativa sem informação de renovação).
    case endsOn(Date)
    case permanent
    case checkPayment
    case notConfirmed
    case ended
    case pending
    case revoked
}

public enum PlanSummaryRules {
    public static func summary(_ kind: PlanScreenKind) -> PlanSummary {
        switch kind {
        case .loading:
            return .none
        case .trial(let remaining):
            return remaining > 0 ? .freeClips(remaining: remaining) : .noFreeClips
        case .renewing(let planID, _):
            return plan(planID)
        case .planChange(let fromID, _, _):
            return plan(fromID)  // com troca agendada, vale o plano de hoje
        case .renewalUnknown(let until), .canceled(let until):
            return .endsOn(until)
        case .billingGrace, .paused:
            return .checkPayment
        case .permanent:
            return .permanent
        case .unconfirmed, .notConfirmed:
            return .notConfirmed
        case .ended:
            return .ended
        case .revoked:
            return .revoked
        case .pending:
            return .pending
        }
    }

    private static func plan(_ productID: String) -> PlanSummary {
        switch productID {
        case StoreProductID.monthly: return .monthly
        case StoreProductID.yearly: return .yearly
        default: return .none
        }
    }
}
