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

/// Aviso de bateria uma vez por degrau (v0.7.20): 20%, 15%, 10% e 5%.
///
/// O iOS só informa a bateria de 5 em 5, então cada degrau é lido exatamente. Guarda só o MENOR degrau já avisado
/// (`lowestWarned`; 100 = nenhum). Avisa quando a leitura chega a um degrau mais baixo que esse. Abrir o app de novo com a
/// bateria no mesmo degrau não repete o aviso (o valor é guardado no aparelho). Carregar, ou a leitura passar de 25%,
/// zera: ao descer de novo, os degraus avisam outra vez. Se o app abre já em 10%, avisa só o 10% (não empilha 20 e 15).
public struct BatteryStepTracker {
    public static let steps = [20, 15, 10, 5]
    /// Degraus nesta faixa ou abaixo são "muito baixa" (aviso crítico).
    public static let criticalStep = 10
    /// Acima disto a bateria é considerada recuperada e os avisos voltam a valer.
    public static let rearmAbove = 25
    public static let none = 100

    public private(set) var lowestWarned: Int

    public init(lowestWarned: Int = BatteryStepTracker.none) { self.lowestWarned = lowestWarned }

    /// O degrau mais fundo já atingido pela leitura (por exemplo 15 → 15; 12 → 15; 10 → 10), ou nil se está acima de 20%.
    public static func step(for percent: Int) -> Int? {
        steps.filter { percent <= $0 }.min()
    }

    public static func level(forStep step: Int) -> BatteryLevel { step <= criticalStep ? .critical : .low }

    /// O degrau a avisar agora, ou nil se não há novidade.
    public mutating func update(percent: Int?, charging: Bool) -> Int? {
        guard let percent else { return nil }
        if charging {
            lowestWarned = Self.none
            return nil
        }
        guard let step = Self.step(for: percent) else {
            if percent > Self.rearmAbove { lowestWarned = Self.none }
            return nil
        }
        guard step < lowestWarned else { return nil }
        lowestWarned = step
        return step
    }
}
