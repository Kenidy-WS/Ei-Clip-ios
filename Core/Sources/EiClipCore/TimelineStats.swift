import Foundation

/// Estatística dos tempos (em segundos) das amostras que entram no arquivo do clipe.
/// Serve para achar buracos, retrocessos e saltos de tempo (clipe "travado", áudio fora de sincronia).
/// Lógica pura (sem câmera), com testes em `TimelineStatsTests`.
public struct TimelineStats {
    /// Salto entre amostras seguidas acima disso conta como "buraco"
    /// (vídeo a 30 fps ≈ 0,033 s entre quadros; bloco de áudio ≈ 0,024 s).
    public let gapLimit: Double
    public private(set) var count = 0
    public private(set) var first: Double?
    public private(set) var last: Double?
    /// Maior salto entre duas amostras seguidas, e o tempo em que ele começou.
    public private(set) var maxGap = 0.0
    public private(set) var maxGapAt = 0.0
    /// Quantos saltos passaram de `gapLimit`.
    public private(set) var bigGaps = 0
    /// Quantas vezes o tempo voltou para trás.
    public private(set) var backwards = 0

    public init(gapLimit: Double = 0.25) {
        self.gapLimit = gapLimit
    }

    /// Do primeiro ao último tempo (0 se não houver amostras).
    public var span: Double {
        guard let f = first, let l = last else { return 0 }
        return l - f
    }

    public mutating func add(_ t: Double) {
        if let prev = last {
            let delta = t - prev
            if delta < 0 {
                backwards += 1
            } else {
                if delta > maxGap {
                    maxGap = delta
                    maxGapAt = prev
                }
                if delta > gapLimit { bigGaps += 1 }
            }
        } else {
            first = t
        }
        last = t
        count += 1
    }

    /// Texto curto para o Diagnóstico.
    public var summary: String {
        guard count > 0, let f = first, let l = last else { return "sem amostras" }
        return String(
            format: "%ld amostras, de %.2f a %.2f s, maior salto %.3f s (em %.2f s), saltos > %.2f s: %ld, retrocessos: %ld",
            count, f, l, maxGap, maxGapAt, gapLimit, bigGaps, backwards)
    }
}
