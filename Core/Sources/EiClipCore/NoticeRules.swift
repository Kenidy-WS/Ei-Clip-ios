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

    /// Quanto tempo o aviso fica na tela (o toque nele também o fecha).
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
    /// Um aviso novo entra no lugar do que está na tela? Só se o atual não pesar mais: um aviso crítico não é apagado por
    /// uma informação que chega logo depois (ex.: "Clipe salvo." não cobre "O iPhone está muito quente").
    public static func accepts(new: NoticeLevel, over current: NoticeLevel?) -> Bool {
        guard let current else { return true }
        return new >= current
    }
}
