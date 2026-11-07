import Foundation

/// Nível da bateria para os avisos (v0.6.1).
public enum BatteryLevel: Int, Equatable, Comparable {
    case ok = 0
    case low = 1
    case critical = 2

    public static func < (a: BatteryLevel, b: BatteryLevel) -> Bool { a.rawValue < b.rawValue }
}

/// Regras da bateria (v0.6.1): quando é "baixa" e quando é "muito baixa". Carregando, nunca avisa.
public enum BatteryRules {
    /// Em 20% ou menos: bateria baixa (o iOS também avisa nesse ponto, mas sem saber que há uma gravação em andamento).
    public static let lowPercent = 20
    /// Em 10% ou menos: bateria muito baixa.
    public static let criticalPercent = 10
    /// Depois de avisar, o nível só "melhora" quando a carga passa da faixa mais esta margem (evita repetir o aviso quando
    /// a carga fica oscilando em torno do limite).
    public static let hysteresisPercent = 3

    public static func level(percent: Int, charging: Bool) -> BatteryLevel {
        if charging { return .ok }
        if percent <= criticalPercent { return .critical }
        if percent <= lowPercent { return .low }
        return .ok
    }

    /// Texto curto para o Diagnóstico, por exemplo "≈60% · na bateria". Sem leitura (percentual nulo): "desconhecida".
    /// v0.7.19: o "≈" porque o iOS só informa a bateria de 5 em 5 (o valor real pode ser até 2 pontos diferente).
    public static func describe(percent: Int?, charging: Bool) -> String {
        guard let percent else { return "desconhecida" }
        return "≈\(percent)% · \(charging ? "carregando" : "na bateria")"
    }
}

/// Decide quando avisar: só quando o nível PIORA. Carregar ou subir bem acima do limite zera o que já foi avisado.
public struct BatteryAlertTracker {
    private var last: BatteryLevel = .ok

    public init() {}

    /// O nível a avisar agora, ou nil se não há novidade (ou se não há leitura da bateria).
    public mutating func update(percent: Int?, charging: Bool) -> BatteryLevel? {
        guard let percent else { return nil }
        var level = BatteryRules.level(percent: percent, charging: charging)
        if !charging {
            // Histerese: logo acima do limite, continua valendo o nível anterior (sem avisar de novo).
            if last == .critical, level < .critical, percent < BatteryRules.criticalPercent + BatteryRules.hysteresisPercent {
                level = .critical
            }
            if last >= .low, level == .ok, percent < BatteryRules.lowPercent + BatteryRules.hysteresisPercent {
                level = .low
            }
        }
        let previous = last
        last = level
        return level > previous ? level : nil
    }

    /// Esquece o que já foi avisado (ao abrir a câmera de novo).
    public mutating func reset() { last = .ok }
}
