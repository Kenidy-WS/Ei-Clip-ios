import Foundation

/// Nível (v0.6.8): uma linha na prévia que mostra se o horizonte está reto. Regras puras sobre a gravidade lida pelo
/// acelerômetro (x, y, z em g, no sistema do aparelho: em pé, y ≈ -1).
public enum LevelRules {
    /// Até quantos graus de inclinação a linha fica verde ("reto").
    public static let levelToleranceDegrees = 1.0
    /// Com o aparelho deitado de barriga para cima ou para baixo (|z| acima disto) não há horizonte para medir.
    public static let flatThreshold = 0.85
    /// Peso da leitura nova no suavizado (0...1): menor = linha mais calma. v0.6.18: 0,25 → 0,5 (linha mais ágil).
    public static let smoothing = 0.5
    /// Zona morta da publicação (graus): a tela só redesenha se a linha mexeu pelo menos isto. v0.6.18: 0,5° → 0,2°.
    public static let publishDeadband = 0.2

    /// Inclinação em graus, de -45 a 45, em relação à posição mais próxima (em pé ou deitado de lado). Positivo = aparelho
    /// girado no sentido horário. Nulo quando o aparelho está deitado na mesa.
    public static func tilt(x: Double, y: Double, z: Double) -> Double? {
        guard abs(z) < flatThreshold else { return nil }
        guard hypot(x, y) > 0.001 else { return nil }
        let angle = atan2(x, -y) * 180 / .pi  // 0 = em pé; ±90 = deitado
        let nearest = (angle / 90).rounded() * 90
        return angle - nearest
    }

    public static func isLevel(_ tilt: Double) -> Bool {
        abs(tilt) <= levelToleranceDegrees
    }

    /// Suaviza a leitura (média móvel exponencial). Sem valor anterior, usa o novo.
    public static func smoothed(previous: Double?, new: Double) -> Double {
        guard let previous else { return new }
        return previous + (new - previous) * smoothing
    }

    /// Se vale redesenhar a linha: sem valor mostrado ainda, ou mudança de pelo menos a zona morta.
    public static func shouldPublish(shown: Double?, new: Double) -> Bool {
        guard let shown else { return true }
        return abs(shown - new) >= publishDeadband
    }

    /// Texto curto para a tela e o Diagnóstico, por exemplo "2,3°" ou "reto".
    public static func describe(_ tilt: Double?) -> String {
        guard let tilt else { return "sem horizonte (aparelho deitado)" }
        if isLevel(tilt) { return "reto" }
        return String(format: "%.1f°", abs(tilt)).replacingOccurrences(of: ".", with: ",")
            + (tilt > 0 ? " no sentido horário" : " no sentido anti-horário")
    }
}
