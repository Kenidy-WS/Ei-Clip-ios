import Foundation

/// Compensação de exposição, o "EV" (v0.7.16). Regras puras: o motor pergunta o intervalo ao aparelho e aplica o valor;
/// aqui ficam o recorte, o passo, a conversão do arraste em valor e o texto. Nada aqui conhece câmera nem tela.
public enum ExposureRules {
    /// Limite pedido pelo Kenidy: de −2 a +2, mesmo que o aparelho aceite mais.
    public static let limit = 2.0
    /// Passo do valor (uma casa decimal).
    public static let step = 0.1
    /// Quantos pontos de tela valem 1 EV no arraste. O sol anda junto com o dedo (1 EV = 30 pontos; ±2 = ±60 pontos).
    public static let pointsPerEV = 30.0
    /// Quanto tempo o quadrado de foco (com o sol) fica na tela depois do último toque ou arraste.
    public static let idleSeconds = FocusRules.indicatorSeconds

    /// Intervalo realmente usado: o do aparelho, limitado a ±2. `nil` se o aparelho não oferece ajuste de brilho
    /// (intervalo vazio ou sem espaço para os dois lados do zero). O motor então esconde o sol e registra o motivo.
    public static func range(deviceMin: Double, deviceMax: Double) -> ClosedRange<Double>? {
        guard deviceMin.isFinite, deviceMax.isFinite, deviceMin < 0, deviceMax > 0 else { return nil }
        let low = max(deviceMin, -limit)
        let high = min(deviceMax, limit)
        guard low < high else { return nil }
        return low...high
    }

    /// Arredonda ao passo e recorta ao intervalo.
    public static func clamp(_ value: Double, in range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return 0 }
        let stepped = (value / step).rounded() * step
        let bounded = min(max(stepped, range.lowerBound), range.upperBound)
        // Evita "−0,0" e restos de ponto flutuante (0,30000000000000004).
        let clean = (bounded * 10).rounded() / 10
        return clean == 0 ? 0 : clean
    }

    /// Valor depois de arrastar `translation` pontos na vertical (negativo = para cima = mais brilho), a partir de `start`.
    public static func value(start: Double, translation: Double, in range: ClosedRange<Double>) -> Double {
        clamp(start - translation / pointsPerEV, in: range)
    }

    /// Deslocamento do sol em pontos para um valor (para cima é negativo; 0 fica na altura do centro do quadrado).
    public static func sunOffset(for value: Double) -> Double {
        -value * pointsPerEV
    }

    /// Texto do valor: "0,0", "+0,7", "-1,2" (vírgula, como no pt-BR).
    public static func label(_ value: Double) -> String {
        let v = (value * 10).rounded() / 10
        if v == 0 { return "0,0" }
        let body = String(format: "%.1f", abs(v)).replacingOccurrences(of: ".", with: ",")
        return (v > 0 ? "+" : "-") + body
    }

    public static func isNeutral(_ value: Double) -> Bool {
        abs(value) < step / 2
    }

    /// O quadrado de foco já deve sumir? Conta a partir do toque que o criou ou do último arraste do sol, o que for mais novo.
    public static func isExpired(markAt: TimeInterval, lastTouchAt: TimeInterval, now: TimeInterval) -> Bool {
        now - max(markAt, lastTouchAt) >= idleSeconds
    }

    /// Vale mexer no brilho agora? Só com a câmera aberta, sem tela escura, sem teste e sem reconfigurar a câmera.
    public static func canAdjust(supported: Bool, cameraOpen: Bool, dimmed: Bool, testRunning: Bool, reconfiguring: Bool) -> Bool {
        supported && FocusRules.canFocus(cameraOpen: cameraOpen, dimmed: dimmed, testRunning: testRunning, reconfiguring: reconfiguring)
    }

    /// O sol vai à esquerda do quadrado quando faltaria espaço à direita (toque perto da borda).
    public static func sunOnRight(markX: Double, screenWidth: Double, squareSize: Double = 76, sunColumn: Double = 56) -> Bool {
        markX + squareSize / 2 + sunColumn + 8 <= screenWidth
    }
}
