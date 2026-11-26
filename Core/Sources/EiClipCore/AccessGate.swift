import Foundation

// C2, etapa 1: regra de acesso (lógica pura, sem tela, sem StoreKit, sem Keychain).
// Decide se uma nova gravação pode começar. A Engine (etapas 2 e 3) traduz o StoreKit 2 para estes tipos.
// Princípio: "a Apple não respondeu" NUNCA é a mesma coisa que "sem direito".

/// Situação da assinatura segundo a Apple, já traduzida do StoreKit 2.
public enum SubscriptionStatus: Equatable {
    /// Período pago e confirmado, até `periodEnd`.
    case active(periodEnd: Date)
    /// A cobrança falhou, mas a Apple ainda dá acesso até `until` (período de tolerância de cobrança).
    case inGracePeriod(until: Date)
    /// A cobrança falhou e a Apple segue tentando; sem acesso.
    case billingRetry
    /// Terminou (não renovou).
    case expired
    /// Reembolsada ou revogada pela Apple.
    case revoked
}

/// O que o StoreKit disse agora.
public enum StoreAnswer: Equatable {
    /// Erro, sem rede ou sem resposta: o estado é DESCONHECIDO (não significa "sem direito").
    case unavailable
    /// Resposta válida. `permanent` = compra do Acesso permanente verificada;
    /// `subscription` = situação da assinatura, se houver; `purchasePending` = compra aguardando aprovação.
    case answered(permanent: Bool, subscription: SubscriptionStatus?, purchasePending: Bool)
}

/// Última coisa CONFIRMADA pela Apple (guardada no Keychain pela Engine, a partir da última resposta válida; etapa 6).
public struct LastConfirmed: Equatable, Codable {
    /// Acesso permanente confirmado e ainda valendo na última resposta válida.
    public var permanent: Bool
    /// Fim do último período de assinatura pago e confirmado (nil = sem período confirmado valendo).
    /// Só é preenchido por uma resposta válida "ativa"; qualquer outra resposta da Apple o apaga (sem tolerância).
    public var subscriptionPeriodEnd: Date?
    /// Já houve permanente confirmado alguma vez (serve para dizer "revogado" quando a Apple deixa de confirmar).
    public var everPermanent: Bool
    /// Já houve assinatura confirmada alguma vez (serve para dizer "terminou").
    public var everSubscribed: Bool
    /// Maior data já vista pelo app (proteção contra relógio atrasado).
    public var latestSeen: Date?
    /// Ambiente em que o registro foi gravado (v0.9.48; nil nos registros antigos).
    public var environment: RecordEnvironment?

    public init(
        permanent: Bool = false, subscriptionPeriodEnd: Date? = nil,
        everPermanent: Bool = false, everSubscribed: Bool = false, latestSeen: Date? = nil,
        environment: RecordEnvironment? = nil
    ) {
        self.environment = environment
        self.permanent = permanent
        self.subscriptionPeriodEnd = subscriptionPeriodEnd
        self.everPermanent = everPermanent || permanent
        self.everSubscribed = everSubscribed || subscriptionPeriodEnd != nil
        self.latestSeen = latestSeen
    }

    /// Nunca houve acesso confirmado.
    public static let none = LastConfirmed()
}

/// Situação de acesso, para a tela (chip, Ajustes) e para o Diagnóstico.
public enum AccessState: Equatable {
    /// Teste: restam `remaining` clipes (0 = esgotados).
    case freeClips(remaining: Int)
    case permanent
    case subscribed(periodEnd: Date)
    /// Assinatura que não pôde ser confirmada, ainda dentro da tolerância offline (fim do período + 7 dias).
    case subscribedUnconfirmed(periodEnd: Date, toleranceEnds: Date)
    /// Problema de pagamento; `graceUntil` != nil = a Apple ainda libera o acesso até essa data.
    case billingProblem(graceUntil: Date?)
    case subscriptionEnded
    /// Não confirmada e a tolerância de 7 dias já passou.
    case subscriptionNotConfirmed
    /// Reembolsada ou revogada.
    case accessRevoked
    case purchasePending
}

/// Por que a escolha de acesso foi aberta.
public enum PlansReason: Equatable {
    case freeClipsUsed
    case subscriptionEnded
    case subscriptionNotConfirmed
    case billingProblem
    case accessRevoked
}

/// Em que se baseia um acesso pago.
public enum AccessBasis: Equatable {
    case permanent
    case subscription
    case gracePeriod
    /// Permanente já confirmado, StoreKit sem resposta: continua liberado (sem tolerância de 7 dias).
    case offlinePermanent
    /// Assinatura sem confirmação, mas ainda dentro do período pago e confirmado.
    case offlinePaidPeriod
    /// Assinatura sem confirmação, no fim do período + 7 dias.
    case offlineTolerance
}

/// A decisão para uma nova gravação.
public enum AccessDecision: Equatable {
    /// Pode gravar; não consome clipe gratuito.
    case allowPaid(AccessBasis)
    /// Pode gravar como clipe gratuito; `remaining` = quantos restam ANTES deste (1 a 10).
    case allowFree(remaining: Int)
    /// Não grava; abre a escolha de acesso.
    case showPlans(PlansReason)

    public var allowsRecording: Bool {
        if case .showPlans = self { return false }
        return true
    }

    /// Só o clipe gratuito entra na contagem dos 10.
    public var consumesFreeClip: Bool {
        if case .allowFree = self { return true }
        return false
    }
}

public struct AccessResult: Equatable {
    public let state: AccessState
    public let decision: AccessDecision

    public init(state: AccessState, decision: AccessDecision) {
        self.state = state
        self.decision = decision
    }

    /// Texto curto para o Diagnóstico (sem dados pessoais).
    public var logText: String {
        switch decision {
        case .allowPaid(let basis): return "acesso: liberado (\(AccessResult.basisText(basis)))"
        case .allowFree(let remaining): return "acesso: clipe gratuito (restam \(remaining) antes deste)"
        case .showPlans(let reason): return "acesso: escolha de acesso (\(AccessResult.reasonText(reason)))"
        }
    }

    private static func basisText(_ basis: AccessBasis) -> String {
        switch basis {
        case .permanent: return "permanente"
        case .subscription: return "assinatura"
        case .gracePeriod: return "carência de cobrança"
        case .offlinePermanent: return "permanente, sem confirmação agora"
        case .offlinePaidPeriod: return "assinatura, sem confirmação agora, dentro do período pago"
        case .offlineTolerance: return "assinatura, sem confirmação, tolerância de 7 dias"
        }
    }

    private static func reasonText(_ reason: PlansReason) -> String {
        switch reason {
        case .freeClipsUsed: return "10 clipes gratuitos usados"
        case .subscriptionEnded: return "assinatura terminou"
        case .subscriptionNotConfirmed: return "assinatura não confirmada, tolerância acabou"
        case .billingProblem: return "problema de pagamento"
        case .accessRevoked: return "acesso reembolsado ou revogado"
        }
    }
}

public enum AccessGate {
    /// Tolerância offline da assinatura (opção B, 19/11): fim do período pago e confirmado + 7 dias.
    public static let offlineToleranceDays = 7
    static let offlineTolerance: TimeInterval = Double(offlineToleranceDays) * 86_400

    /// Decide se uma nova gravação pode começar.
    /// - `store`: a resposta atual do StoreKit (ou `.unavailable`).
    /// - `last`: a última coisa confirmada pela Apple.
    /// - `now`: a data a usar (a Engine passa `ConfirmedAccessRules.effectiveNow`, que não deixa o relógio voltar).
    /// - `freeClipsUsed`: clipes gratuitos já contados (`FreeClipLedger.used`).
    public static func evaluate(
        store: StoreAnswer, last: LastConfirmed, now: Date, freeClipsUsed: Int
    ) -> AccessResult {
        let remaining = max(0, FreeClipLedger.limit - max(0, freeClipsUsed))
        switch store {
        case let .answered(permanent, subscription, purchasePending):
            return fromAnswer(
                permanent: permanent, subscription: subscription, pending: purchasePending,
                last: last, now: now, remaining: remaining)
        case .unavailable:
            return fromUnknown(last: last, now: now, remaining: remaining)
        }
    }

    // MARK: - Resposta válida da Apple

    private static func fromAnswer(
        permanent: Bool, subscription: SubscriptionStatus?, pending: Bool,
        last: LastConfirmed, now: Date, remaining: Int
    ) -> AccessResult {
        if permanent { return paid(.permanent, .permanent) }
        if let subscription = subscription {
            switch subscription {
            case .active(let end):
                if now <= end { return paid(.subscribed(periodEnd: end), .subscription) }
                // v0.9.39: "ativa", mas pela maior data já vista o período acabou. Só acontece com o registro guardado no
                // aparelho e o relógio atrasado (a Apple, com internet, já teria renovado ou dito que terminou):
                // vale como "não confirmada", com a mesma tolerância de 7 dias, e não para sempre.
                let toleranceEnds = end.addingTimeInterval(offlineTolerance)
                if now <= toleranceEnds {
                    return paid(.subscribedUnconfirmed(periodEnd: end, toleranceEnds: toleranceEnds), .offlineTolerance)
                }
                return free(.subscriptionNotConfirmed, .subscriptionNotConfirmed, remaining)
            case .inGracePeriod(let until):
                if until > now { return paid(.billingProblem(graceUntil: until), .gracePeriod) }
                return free(.billingProblem(graceUntil: nil), .billingProblem, remaining)
            case .billingRetry:
                return free(.billingProblem(graceUntil: nil), .billingProblem, remaining)
            case .expired:
                // A Apple respondeu que terminou: sem tolerância de 7 dias.
                return free(.subscriptionEnded, .subscriptionEnded, remaining)
            case .revoked:
                return free(.accessRevoked, .accessRevoked, remaining)
            }
        }
        if pending { return free(.purchasePending, .freeClipsUsed, remaining) }
        // A Apple respondeu e não há nada ativo. Se já houve acesso confirmado, ele acabou.
        if last.permanent || last.everPermanent { return free(.accessRevoked, .accessRevoked, remaining) }
        if last.subscriptionPeriodEnd != nil || last.everSubscribed { return free(.subscriptionEnded, .subscriptionEnded, remaining) }
        return free(.freeClips(remaining: remaining), .freeClipsUsed, remaining)
    }

    // MARK: - StoreKit sem resposta (estado desconhecido)

    private static func fromUnknown(last: LastConfirmed, now: Date, remaining: Int) -> AccessResult {
        // Permanente já confirmado: continua liberado, mesmo sem internet. Não usa os 7 dias.
        if last.permanent { return paid(.permanent, .offlinePermanent) }
        if let end = last.subscriptionPeriodEnd {
            if now <= end { return paid(.subscribed(periodEnd: end), .offlinePaidPeriod) }
            let toleranceEnds = end.addingTimeInterval(offlineTolerance)
            if now <= toleranceEnds {
                return paid(.subscribedUnconfirmed(periodEnd: end, toleranceEnds: toleranceEnds), .offlineTolerance)
            }
            return free(.subscriptionNotConfirmed, .subscriptionNotConfirmed, remaining)
        }
        // Nunca houve acesso confirmado: a falha do StoreKit não concede nada.
        return free(.freeClips(remaining: remaining), .freeClipsUsed, remaining)
    }

    // MARK: - Montagem

    private static func paid(_ state: AccessState, _ basis: AccessBasis) -> AccessResult {
        AccessResult(state: state, decision: .allowPaid(basis))
    }

    /// Sem acesso pago: vale a regra dos clipes gratuitos.
    private static func free(_ state: AccessState, _ reason: PlansReason, _ remaining: Int) -> AccessResult {
        if remaining > 0 { return AccessResult(state: state, decision: .allowFree(remaining: remaining)) }
        return AccessResult(state: state, decision: .showPlans(reason))
    }
}
