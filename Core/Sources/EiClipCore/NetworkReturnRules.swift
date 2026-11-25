import Foundation

// v0.9.45: quando reler a assinatura porque a internet voltou. Lógica pura (o `NetworkPathWatcher` só avisa a mudança).
// Só vale a passagem de "sem rede" (estado conhecido) para "com rede". A primeira informação do iOS na abertura
// (ainda sem estado anterior) não conta: na abertura o app já relê tudo. Um intervalo mínimo evita releituras em
// sequência quando o sinal oscila (Wi-Fi caindo e voltando).

public enum NetworkReturnRules {
    /// Menor intervalo entre duas releituras por "internet voltou".
    public static let minGapSeconds: TimeInterval = 10

    /// - `previousOnline`: último estado conhecido (nil = o iOS ainda não tinha informado nada).
    /// - `nowOnline`: o iOS diz que há rede agora.
    /// - `lastReread`: quando foi a última releitura por este motivo.
    public static func shouldReread(previousOnline: Bool?, nowOnline: Bool, lastReread: Date?, now: Date) -> Bool {
        guard nowOnline, previousOnline == false else { return false }
        if let last = lastReread, now.timeIntervalSince(last) < minGapSeconds { return false }
        return true
    }
}
