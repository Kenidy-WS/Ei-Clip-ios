import Foundation

// C2, etapa 6 (correção da v0.9.39): quando a resposta do StoreKit é confiável sem internet.
// Sem rede, o StoreKit responde com o registro guardado no aparelho e compara com o relógio: passada a data de fim,
// diz "terminou" mesmo que a Apple já tenha renovado (o aparelho ainda não soube). Isso bloquearia quem paga.
// Regra: "terminou" só vale como resposta da Apple se o fim já era esperado (renovação automática desligada)
// ou se a Apple informou o motivo do término. Se a renovação estava ligada e não há motivo, é "não confirmado"
// e vale a tolerância (fim do último período confirmado + 7 dias, contada pela maior data já vista).
// Os dados de renovação usados aqui são assinados pela Apple (só entram se verificados), então não dá para forjar.

public enum StoreTrustRules {
    /// Uma assinatura vencida cuja renovação a Apple ainda esperava: o "terminou" pode ser só o registro do aparelho.
    /// - `willAutoRenew`: renovação automática ligada, segundo os dados de renovação verificados (nil = sem dados).
    /// - `hasExpirationReason`: a Apple informou o motivo do término (cancelamento, cobrança, preço, produto).
    /// Sem dados de renovação (nil), vale o comportamento anterior (o "terminou" é aceito), como reserva.
    public static func renewalExpected(raw: RawSubscriptionState, willAutoRenew: Bool?, hasExpirationReason: Bool) -> Bool {
        raw == .expired && willAutoRenew == true && !hasExpirationReason
    }

    /// Junta a leitura das assinaturas: se a melhor situação lida é "terminou" e alguma assinatura vencida ainda esperava
    /// renovação, a leitura vale como SEM CONFIRMAÇÃO (`.failed`). Com o permanente confirmado ele continua valendo
    /// (`StoreAnswerBuilder.build`); sem ele, o `AccessGate` usa o último período confirmado + 7 dias.
    public static func reconcile(_ list: [SubscriptionStatus], renewalExpected: [Bool]) -> SubscriptionsRead {
        guard let best = StoreAnswerBuilder.best(list), case .expired = best else { return .read(list) }
        for (i, status) in list.enumerated() where i < renewalExpected.count {
            if case .expired = status, renewalExpected[i] { return .failed }
        }
        return .read(list)
    }

    /// v0.9.42: lista de assinaturas VAZIA, sem erro. Sem internet o StoreKit pode devolver lista vazia mesmo com assinatura paga
    /// (teste de 24/11: 18 min antes do fim do período). Vazia só vale como "a Apple confirmou que não há assinatura" quando há
    /// rede ou quando o aparelho nunca teve período pago guardado. Com período pago guardado e sem rede (ou sem sinal de rede),
    /// a leitura é SEM CONFIRMAÇÃO: o registro não é apagado e vale a tolerância (fim do último período + 7 dias).
    /// - `hadPaidPeriod`: o último acesso confirmado (Keychain) tem um fim de período pago guardado.
    /// - `offlineSignal`: o iOS diz que não há rede, ainda não informou, ou o carregamento de produtos falhou por rede.
    public static func emptyListUntrusted(list: [SubscriptionStatus], hadPaidPeriod: Bool, offlineSignal: Bool) -> Bool {
        list.isEmpty && hadPaidPeriod && offlineSignal
    }

    /// v0.9.43: o PERMANENTE guardado (Keychain) não veio na leitura e não há sinal de rede. Sem rede o StoreKit pode não devolver
    /// o direito (mesma classe do erro da lista de assinaturas vazia, v0.9.42). Dizer "a Apple confirmou que você não tem o
    /// permanente" apagaria o registro e bloquearia quem pagou. Com Permanente guardado, sem rede, a leitura inteira vale como
    /// SEM CONFIRMAÇÃO (`.failed`): o Permanente segue liberado, sem prazo (ele não usa os 7 dias) e o registro não é apagado.
    /// Só uma resposta válida da Apple, com rede, tira o Permanente (reembolso, revogação).
    /// - `permanentOwned`: o StoreKit devolveu o Permanente agora.
    /// - `hadPermanent`: o último acesso confirmado (Keychain) diz que o Permanente estava valendo.
    /// - `offlineSignal`: o iOS diz que não há rede, ainda não informou, ou o carregamento de produtos falhou por rede.
    public static func permanentMissingUntrusted(permanentOwned: Bool, hadPermanent: Bool, offlineSignal: Bool) -> Bool {
        !permanentOwned && hadPermanent && offlineSignal
    }
}
