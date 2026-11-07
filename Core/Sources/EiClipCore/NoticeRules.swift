import Foundation

/// Peso de um aviso na tela da câmera (v0.7.18): decide a cor, o tamanho do texto e quanto tempo o aviso fica.
public enum NoticeLevel: Int, Equatable, Comparable {
    /// Informação (ex.: "Clipe salvo."): discreto e curto.
    case info = 0
    /// Atenção (ex.: bateria baixa, qualidade reduzida por calor): em âmbar, fica mais tempo.
    case attention = 1
    /// Crítico (ex.: muito quente, bateria muito baixa, sem espaço, clipe não salvo): em vermelho, fica mais tempo ainda.
    case critical = 2

    public static func < (a: NoticeLevel, b: NoticeLevel) -> Bool { a.rawValue < b.rawValue }

    /// Tempo MÍNIMO do aviso na tela (o tempo real cresce com o tamanho do texto: ver `NoticeRules.duration`).
    public var seconds: Double {
        switch self {
        case .info: return 3
        case .attention: return 6
        case .critical: return 10
        }
    }
}

/// Regras dos avisos da câmera, puras e testáveis.
public enum NoticeRules {
    /// Tempo de leitura: 1,5 s para perceber o aviso mais 0,35 s por palavra (uns 170 palavras por minuto), no máximo 12 s.
    public static let baseSeconds = 1.5
    public static let secondsPerWord = 0.35
    public static let maxSeconds = 12.0

    /// Quanto tempo o aviso fica na tela: o maior entre o mínimo do peso e o tempo de leitura do texto (v0.7.19).
    public static func duration(level: NoticeLevel, text: String) -> Double {
        let words = text.split(whereSeparator: { $0.isWhitespace }).count
        let reading = min(maxSeconds, baseSeconds + secondsPerWord * Double(words))
        return max(level.seconds, reading)
    }

    /// Arrastar o aviso para cima (como os avisos do iOS) o fecha: vale a partir de 20 pontos para cima.
    public static func isDismissSwipe(translationY: Double) -> Bool {
        translationY <= -20
    }

    /// Um aviso novo entra no lugar do que está na tela? Só se o atual não pesar mais: um aviso crítico não é apagado por
    /// uma informação que chega logo depois (ex.: "Clipe salvo." não cobre "O iPhone está muito quente").
    public static func accepts(new: NoticeLevel, over current: NoticeLevel?) -> Bool {
        guard let current else { return true }
        return new >= current
    }
}
