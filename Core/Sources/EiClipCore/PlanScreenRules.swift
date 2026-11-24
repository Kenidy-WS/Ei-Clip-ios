import Foundation

// C2, etapa 5b: o que a tela "Meu plano" mostra em cada situação (lógica pura, sem StoreKit e sem textos).
// Parte do `AccessState` (o que o gate decidiu) e da `SubscriptionOutlook` (detalhes da assinatura, lidos na etapa 5a).
// Nada daqui muda o acesso: é só a apresentação.

/// Extra mostrado quando o acesso permanente convive com uma assinatura que ainda pode cobrar.
public enum PermanentExtra: Equatable {
    case none
    /// Assinatura ainda renovando (próxima renovação nesta data).
    case renewing(renewsOn: Date)
    /// Assinatura com problema de pagamento (a Apple ainda pode cobrar).
    case billingTrouble
}

/// A situação da tela "Meu plano".
public enum PlanScreenKind: Equatable {
    case loading
    case trial(remaining: Int)
    /// Assinatura ativa e renovando no mesmo plano.
    case renewing(planID: String, renewsOn: Date)
    /// Assinatura ativa, com troca de plano agendada para a próxima renovação.
    case planChange(fromID: String, toID: String, changesOn: Date)
    /// Assinatura ativa, mas a Apple não informou se renova.
    case renewalUnknown(until: Date)
    /// Cancelada: o período pago vale até `until`.
    case canceled(until: Date)
    /// Problema de cobrança, com acesso até `until`.
    case billingGrace(until: Date)
    /// Problema de cobrança, sem acesso (a Apple ainda tenta cobrar).
    case paused
    case permanent(extra: PermanentExtra)
    /// Não confirmada agora, ainda dentro da tolerância offline.
    /// `until`: fim da tolerância de 7 dias (a data até a qual ainda se pode gravar sem confirmar). v0.9.44.
    case unconfirmed(until: Date)
    case ended
    /// Não confirmada e a tolerância já passou.
    case notConfirmed
    case revoked
    case pending
}

/// Aviso a mostrar antes de comprar o acesso permanente.
public enum PurchaseWarning: Equatable {
    case none
    /// A assinatura segue renovando (próxima renovação nesta data) e a compra NÃO a cancela.
    case renewing(renewsOn: Date)
    /// A Apple ainda pode cobrar a assinatura (carência, nova tentativa ou renovação não confirmada).
    case mayCharge
}

/// Que bloco de compra a tela mostra.
public enum PurchaseSection: Equatable {
    case none
    /// Só o acesso permanente (quem já tem assinatura que renova, cancelada ou com problema de pagamento).
    case permanentOnly
    /// Compra em análise: o botão aparece desligado.
    case permanentDisabled
    /// Os três acessos (quem não tem acesso pago).
    case allPlans
}

/// Ação de gerenciamento da assinatura na Apple.
public enum ManageAction: Equatable {
    case none
    /// "Gerenciar assinatura".
    case manage
    /// Problema de pagamento: o destino é o mesmo, mas o rótulo diz o que resolver.
    case fixPayment
}

public enum PlanTone: Equatable {
    case green, amber, red, neutral
}

public enum PlanScreenRules {
    /// - `state`: `nil` enquanto o gate ainda não respondeu.
    /// - `outlook`: perspectiva da assinatura (pode ser `nil`).
    public static func kind(state: AccessState?, outlook: SubscriptionOutlook?) -> PlanScreenKind {
        guard let state else { return .loading }
        switch state {
        case .freeClips(let remaining):
            return .trial(remaining: remaining)
        case .permanent:
            return .permanent(extra: permanentExtra(outlook))
        case .subscribed(let end):
            switch outlook {
            case let .renewing(productID, periodEnd)?:
                return .renewing(planID: productID, renewsOn: periodEnd)
            case let .renewingOtherPlan(from, to, periodEnd)?:
                return .planChange(fromID: from, toID: to, changesOn: periodEnd)
            case let .canceledStillPaid(until)?:
                return .canceled(until: until)
            default:
                return .renewalUnknown(until: end)
            }
        case .subscribedUnconfirmed(_, let toleranceEnds):
            return .unconfirmed(until: toleranceEnds)
        case .billingProblem(let grace):
            if let grace { return .billingGrace(until: grace) }
            return .paused
        case .subscriptionEnded: return .ended
        case .subscriptionNotConfirmed: return .notConfirmed
        case .accessRevoked: return .revoked
        case .purchasePending: return .pending
        }
    }

    private static func permanentExtra(_ outlook: SubscriptionOutlook?) -> PermanentExtra {
        switch outlook {
        case let .renewing(_, end)?: return .renewing(renewsOn: end)
        case let .renewingOtherPlan(_, _, end)?: return .renewing(renewsOn: end)
        case .billingGrace?, .billingRetry?: return .billingTrouble
        default: return .none
        }
    }

    public static func tone(_ kind: PlanScreenKind) -> PlanTone {
        switch kind {
        case .loading, .trial: return .neutral
        case .renewing, .planChange, .renewalUnknown, .permanent: return .green
        case .canceled, .billingGrace, .unconfirmed, .notConfirmed, .pending: return .amber
        case .paused, .ended, .revoked: return .red
        }
    }

    /// Só onde existe uma assinatura que pode gerar nova cobrança.
    public static func purchaseWarning(_ kind: PlanScreenKind) -> PurchaseWarning {
        switch kind {
        case .renewing(_, let date): return .renewing(renewsOn: date)
        case .planChange(_, _, let date): return .renewing(renewsOn: date)
        case .renewalUnknown, .billingGrace, .paused: return .mayCharge
        default: return .none
        }
    }

    public static func purchaseSection(_ kind: PlanScreenKind) -> PurchaseSection {
        switch kind {
        case .trial, .ended, .notConfirmed, .revoked: return .allPlans
        case .renewing, .planChange, .renewalUnknown, .canceled, .billingGrace, .paused: return .permanentOnly
        case .pending: return .permanentDisabled
        case .loading, .unconfirmed, .permanent: return .none
        }
    }

    public static func manageAction(_ kind: PlanScreenKind) -> ManageAction {
        switch kind {
        case .renewing, .planChange, .renewalUnknown: return .manage
        case .billingGrace, .paused: return .fixPayment
        case .permanent(let extra): return extra == .none ? .none : .manage
        default: return .none
        }
    }

    /// "Verificar de novo": quando a Apple não pôde confirmar a assinatura.
    public static func showsRecheck(_ kind: PlanScreenKind) -> Bool {
        switch kind {
        case .unconfirmed, .notConfirmed: return true
        default: return false
        }
    }
}
