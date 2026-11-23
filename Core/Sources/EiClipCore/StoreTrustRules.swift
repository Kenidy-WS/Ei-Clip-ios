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
}
