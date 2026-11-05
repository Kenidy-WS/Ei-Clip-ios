import Foundation

/// Janela do buffer retroativo ("Pré-gravação"): 15, 30 ou 60 s (60 s desde a v0.6.5). Valor guardado inválido (ou ausente) vira 15 s.
public enum BufferWindow {
    public static let options = [15, 30, 60]
    public static let defaultSeconds = 15
    /// Memória que o anel pode ocupar (vídeo codificado + áudio PCM). O iPhone encerra o app que passa de ~1,5 GB; esta
    /// folga deixa a câmera, o codificador e a voz trabalharem.
    public static let memoryBudgetBytes: Int64 = 350_000_000
    /// Áudio PCM copiado para o anel, em bytes por segundo (estéreo 16 bits a 48 kHz, com folga).
    public static let pcmBytesPerSec = 192_000

    public static func sanitized(_ stored: Int?) -> Int {
        guard let stored, options.contains(stored) else { return defaultSeconds }
        return stored
    }

    /// Memória estimada do anel cheio: janela + folga de 3 s, vídeo (taxa em bits/s) + áudio.
    public static func ringBytes(windowSec: Int, videoBitrate: Int) -> Int64 {
        let perSecond = Int64(videoBitrate / 8 + pcmBytesPerSec)
        return Int64(Double(windowSec) + replayRingSlackSec) * perSecond
    }

    /// Maior janela permitida para a qualidade atual (nunca menos que a menor opção).
    public static func maxAllowed(videoBitrate: Int) -> Int {
        let ok = options.filter { ringBytes(windowSec: $0, videoBitrate: videoBitrate) <= memoryBudgetBytes }
        return ok.max() ?? options[0]
    }

    /// A janela efetiva: a pedida, limitada pelo que a memória aguenta.
    public static func effective(requested: Int, videoBitrate: Int) -> Int {
        min(sanitized(requested), maxAllowed(videoBitrate: videoBitrate))
    }
}
