import Foundation

/// Escolha do quadro da miniatura (v0.6.17). O quadro do momento do comando pode sair escuro (cena escura, exposição ainda se
/// ajustando); quando sair, tenta outros instantes do clipe e fica com o primeiro que não seja escuro (ou o mais claro).
public enum ThumbnailRules {
    /// Brilho médio (0 a 1) abaixo do qual a imagem é considerada escura demais para miniatura.
    public static let darkThreshold = 0.08

    public static func isTooDark(_ meanLuma: Double) -> Bool { meanLuma < darkThreshold }

    /// Instantes (s) a tentar, em ordem de preferência: o momento do comando e alguns pontos depois, depois o meio e
    /// três quartos do clipe. Sempre dentro do clipe e sem repetir.
    public static func candidateTimes(preSec: Double, duration: Double) -> [Double] {
        guard duration > 0.2 else { return [0] }
        let last = duration - 0.1
        let raw = [preSec + 0.3, preSec + 1.5, preSec + 3, duration / 2, duration * 0.75, 0.5]
        var out: [Double] = []
        for t in raw {
            let clamped = min(max(0, t), last)
            if !out.contains(where: { abs($0 - clamped) < 0.25 }) { out.append(clamped) }
        }
        return out
    }

    /// Índice da imagem a usar: a primeira que não é escura; se todas forem, a mais clara.
    public static func pick(lumas: [Double]) -> Int? {
        guard !lumas.isEmpty else { return nil }
        if let first = lumas.firstIndex(where: { !isTooDark($0) }) { return first }
        return lumas.indices.max { lumas[$0] < lumas[$1] }
    }
}
