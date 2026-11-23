import Foundation

// C2, etapa 6: regras puras do "último acesso confirmado" (guardado no Keychain pela Engine) e proteção do relógio.
// A tolerância de 7 dias só vale quando a Apple NÃO pôde ser consultada. Qualquer resposta válida da Apple
// (inclusive "terminou" ou "revogada") apaga o período confirmado e, com ele, a tolerância.

public enum ConfirmedAccessRules {
    /// A data a usar nas contas: nunca menor que a maior já vista (relógio atrasado não devolve acesso).
    public static func effectiveNow(now: Date, last: LastConfirmed) -> Date {
        guard let seen = last.latestSeen else { return now }
        return max(now, seen)
    }

    /// Registra a maior data vista. Devolve o registro novo e se a mudança é grande o bastante para valer um novo
    /// registro no Keychain (a cada 1 hora, para não gravar o tempo todo).
    public static func advance(_ last: LastConfirmed, now: Date, persistEvery: TimeInterval = 3600) -> (record: LastConfirmed, shouldPersist: Bool) {
        let seen = last.latestSeen
        guard seen == nil || now > seen! else { return (last, false) }
        var out = last
        out.latestSeen = now
        let should = seen == nil || now.timeIntervalSince(seen!) >= persistEvery
        return (out, should)
    }

    /// Atualiza o registro com a resposta da Apple. `.unavailable` não muda nada além da maior data vista.
    public static func updated(_ last: LastConfirmed, with answer: StoreAnswer, now: Date) -> LastConfirmed {
        var out = advance(last, now: now).record
        guard case let .answered(permanent, subscription, _) = answer else { return out }
        // Resposta válida da Apple: a data do aparelho passa a ser a referência de novo (corrige um relógio que ficou à frente).
        // v0.9.39: exceto quando a resposta é "ativa" com fim ANTES da maior data já vista: isso é o registro do aparelho
        // com o relógio atrasado, e voltar a data devolveria acesso. A maior data vista fica onde estava.
        var resetClock = true
        if case .active(let end)? = subscription, let seen = last.latestSeen, end < seen { resetClock = false }
        if resetClock { out.latestSeen = now }
        out.permanent = permanent
        if permanent { out.everPermanent = true }
        switch subscription {
        case .active(let end)?:
            out.subscriptionPeriodEnd = end
            out.everSubscribed = true
        case .inGracePeriod(let until)?:
            // Segue valendo o fim do período pago anterior; sem ele, usa o fim da carência.
            out.subscriptionPeriodEnd = out.subscriptionPeriodEnd ?? until
            out.everSubscribed = true
        case .billingRetry?, .expired?, .revoked?:
            out.subscriptionPeriodEnd = nil
            out.everSubscribed = true
        case nil:
            // A Apple respondeu e não há assinatura: nada de tolerância.
            out.subscriptionPeriodEnd = nil
        }
        return out
    }

    // MARK: - Registro no Keychain

    public enum Loaded: Equatable {
        case loaded(LastConfirmed)
        case corrupt
        case fresh
    }

    public static func load(from data: Data?) -> Loaded {
        guard let data else { return .fresh }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let decoded = try? decoder.decode(LastConfirmed.self, from: data) else { return .corrupt }
        return .loaded(decoded)
    }

    public static func encoded(_ last: LastConfirmed) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return try? encoder.encode(last)
    }
}
