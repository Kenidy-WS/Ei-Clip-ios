import Foundation

// C2, etapa 4: regras puras da tela "Escolha seu acesso", do chip do Início e dos avisos da câmera (sem SwiftUI, sem StoreKit).

/// O que o início de uma gravação deve fazer, a partir do último cálculo de acesso.
public enum StartGate: Equatable {
    /// Pode gravar. `consumesFree` = este clipe entra na contagem dos 10 gratuitos.
    case proceed(consumesFree: Bool)
    /// Não grava; abre a escolha de acesso, com o motivo.
    case openPlans(PlansReason)
    /// Não grava; abre o painel "Compra em análise" (compra pendente e nenhum clipe gratuito restante).
    case openPending
}

public enum StartGateRules {
    /// `result` = acesso calculado AGORA com a resposta da Apple já recebida, ou nil se a Apple ainda não respondeu
    /// (o app acabou de abrir): nesse caso grava, sem contar clipe gratuito ("sem resposta" nunca é "sem direito").
    public static func decide(_ result: AccessResult?) -> StartGate {
        guard let result else { return .proceed(consumesFree: false) }
        switch result.decision {
        case .allowPaid: return .proceed(consumesFree: false)
        case .allowFree: return .proceed(consumesFree: true)
        case .showPlans(let reason):
            if result.state == .purchasePending { return .openPending }
            return .openPlans(reason)
        }
    }

    /// Clipe recuperado depois de uma falha: só conta como gratuito se o acesso pago NÃO está confirmado agora.
    public static func countsRecoveredClip(_ result: AccessResult?) -> Bool {
        guard let result else { return true }
        if case .allowPaid = result.decision { return false }
        return true
    }
}

/// Aviso na câmera ao salvar um clipe gratuito (a partir do 7º).
public enum FreeClipNotice {
    /// Quantos restam depois deste clipe, se vale avisar (restam 0 a 3); nil nos demais casos.
    public static func remainingToAnnounce(usedAfter used: Int) -> Int? {
        let remaining = FreeClipLedger.limit - used
        return (0...3).contains(remaining) ? remaining : nil
    }
}

/// Chip da tela de Início.
public struct HomeChip: Equatable {
    public enum Kind: Equatable {
        case remaining(Int)
        case used
        case ended
        case billing
        case notConfirmed
        case revoked
        case pending
    }

    public let kind: Kind
    /// Amarelo = atenção; cinza = informação.
    public let isAttention: Bool
    /// Tocar abre a escolha de acesso (mostra o "›").
    public let opensPlans: Bool

    /// Motivo mostrado na escolha de acesso ao tocar no chip; nil = abertura por vontade própria (ainda há clipes gratuitos)
    /// ou painel "Compra em análise".
    public var plansReason: PlansReason? {
        switch kind {
        case .remaining, .pending: return nil
        case .used: return .freeClipsUsed
        case .ended: return .subscriptionEnded
        case .billing: return .billingProblem
        case .notConfirmed: return .subscriptionNotConfirmed
        case .revoked: return .accessRevoked
        }
    }
}

public enum HomeChipRules {
    /// Nil = não mostra chip (acesso pago em vigor, ou ainda sem leitura).
    public static func chip(for state: AccessState?) -> HomeChip? {
        guard let state else { return nil }
        switch state {
        case .freeClips(let remaining):
            if remaining <= 0 { return HomeChip(kind: .used, isAttention: true, opensPlans: true) }
            return HomeChip(kind: .remaining(remaining), isAttention: remaining <= 3, opensPlans: remaining <= 3)
        case .subscriptionEnded: return HomeChip(kind: .ended, isAttention: true, opensPlans: true)
        case .subscriptionNotConfirmed: return HomeChip(kind: .notConfirmed, isAttention: true, opensPlans: true)
        case .accessRevoked: return HomeChip(kind: .revoked, isAttention: true, opensPlans: true)
        case .purchasePending: return HomeChip(kind: .pending, isAttention: false, opensPlans: true)
        case .billingProblem(let graceUntil):
            // Com carência, o acesso segue liberado: o aviso fica nos Ajustes (etapa 5b). Sem carência, abre a escolha.
            return graceUntil == nil ? HomeChip(kind: .billing, isAttention: true, opensPlans: true) : nil
        case .permanent, .subscribed, .subscribedUnconfirmed: return nil
        }
    }
}

/// Cartões e botão da tela "Escolha seu acesso".
public enum PlansScreenRules {
    /// Economia do plano anual frente a 12 meses do mensal, arredondada de 5 em 5 %. Só aparece a partir de 15 %.
    public static func savingsPercent(monthly: Decimal, yearly: Decimal) -> Int? {
        guard monthly > 0, yearly > 0 else { return nil }
        let full = monthly * 12
        guard yearly < full else { return nil }
        let ratio = NSDecimalNumber(decimal: (full - yearly) / full * 100).doubleValue
        let rounded = Int((ratio / 5).rounded()) * 5
        return rounded >= 15 ? rounded : nil
    }

    /// Valor mensal equivalente do plano anual (duas casas).
    public static func monthlyEquivalent(yearly: Decimal) -> Decimal {
        var value = yearly / 12
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .plain)
        return rounded
    }

    /// Com um único produto carregado, ele já vem escolhido e o cartão não mostra o botão de seleção.
    public static func autoSelection(productIDs: [String]) -> String? {
        productIDs.count == 1 ? productIDs[0] : nil
    }

    /// Tipo do botão fixo de baixo.
    public enum Action: Equatable {
        /// Nada escolhido: botão cinza e desligado.
        case choose
        case subscribeYearly
        case subscribeMonthly
        case buyPermanent
    }

    public static func action(selected: String?) -> Action {
        switch selected {
        case StoreProductID.yearly: return .subscribeYearly
        case StoreProductID.monthly: return .subscribeMonthly
        case StoreProductID.permanent: return .buyPermanent
        default: return .choose
        }
    }
}
