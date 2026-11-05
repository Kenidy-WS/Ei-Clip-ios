import Foundation

/// Nível do espaço livre no aparelho (v0.6.0).
public enum StorageLevel: Int, Equatable, Comparable {
    case ok = 0
    case low = 1
    case critical = 2

    public static func < (a: StorageLevel, b: StorageLevel) -> Bool { a.rawValue < b.rawValue }
}

/// Regras de espaço livre (v0.6.0): quanto tempo de gravação ainda cabe, quando avisar e quando encerrar a gravação para o
/// clipe não se perder. Sem acesso ao disco: o motor lê o espaço livre e chama estas funções.
public enum StorageRules {
    /// Áudio AAC do arquivo, em bytes por segundo (≈ 128 a 192 kbps, com folga).
    public static let audioBytesPerSec = 24_000
    /// Abaixo disto (minutos de gravação que ainda cabem) o aviso é "pouco espaço".
    public static let lowMinutes = 15.0
    /// Abaixo disto o aviso é "espaço quase esgotado".
    public static let criticalMinutes = 3.0
    /// Reserva que nunca deve ser usada (o iOS precisa de espaço para trabalhar).
    public static let reserveBytes: Int64 = 150_000_000
    /// O clipe pronto é salvo nas Fotos por CÓPIA: durante o salvamento existem dois arquivos (o do clipe e o das Fotos).
    public static let copiesOnSave = 2

    /// Bytes gravados por segundo (vídeo + áudio) para uma taxa de vídeo em bits por segundo.
    public static func bytesPerSecond(videoBitrate: Int) -> Int {
        videoBitrate / 8 + audioBytesPerSec
    }

    /// Segundos de gravação que ainda cabem, já contando a reserva e o espaço da cópia nas Fotos.
    public static func remainingSeconds(freeBytes: Int64, videoBitrate: Int, copies: Int = copiesOnSave) -> Int {
        let usable = freeBytes - reserveBytes
        guard usable > 0 else { return 0 }
        let perSecond = Int64(bytesPerSecond(videoBitrate: videoBitrate)) * Int64(max(1, copies))
        return Int(usable / perSecond)
    }

    public static func level(freeBytes: Int64, videoBitrate: Int, copies: Int = copiesOnSave) -> StorageLevel {
        let minutes = Double(remainingSeconds(freeBytes: freeBytes, videoBitrate: videoBitrate, copies: copies)) / 60
        if minutes < criticalMinutes { return .critical }
        if minutes < lowMinutes { return .low }
        return .ok
    }

    /// Hora de encerrar a gravação (e salvar) antes que o espaço acabe: o que sobra precisa cobrir a cópia do arquivo gravado até
    /// agora, a reserva e uns 10 s de gravação (o intervalo entre duas conferências).
    public static func shouldStopRecording(
        freeBytes: Int64, recordedBytes: Int64, videoBitrate: Int, copies: Int = copiesOnSave
    ) -> Bool {
        let margin = Int64(bytesPerSecond(videoBitrate: videoBitrate)) * 10
        let needed = Int64(max(1, copies) - 1) * recordedBytes + reserveBytes + margin
        return freeBytes < needed
    }

    /// Texto curto para o Diagnóstico, por exemplo "12.3 GB livres · ≈ 48 min de gravação".
    public static func describe(freeBytes: Int64, videoBitrate: Int, copies: Int = copiesOnSave) -> String {
        let gb = Double(freeBytes) / 1_000_000_000
        let minutes = remainingSeconds(freeBytes: freeBytes, videoBitrate: videoBitrate, copies: copies) / 60
        return String(format: "%.1f GB livres · ≈ %d min de gravação", gb, minutes)
    }
}

/// Decide quando avisar: só quando o nível PIORA (de ok para pouco, de pouco para quase esgotado). Melhorar não avisa, e
/// depois de melhorar um novo agravamento avisa de novo.
public struct StorageAlertTracker {
    private var last: StorageLevel = .ok

    public init() {}

    /// O nível a avisar agora, ou nil se não há novidade.
    public mutating func update(_ level: StorageLevel) -> StorageLevel? {
        let previous = last
        last = level
        return level > previous ? level : nil
    }

    /// Esquece o que já foi avisado (por exemplo, ao abrir a câmera de novo).
    public mutating func reset() { last = .ok }
}
