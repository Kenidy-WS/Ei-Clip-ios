import Foundation

/// Regra do gesto de borda (voltar pela esquerda, avançar pela direita), igual à de `gestures.ts` do web app: andar 70 pt ou
/// mais para dentro da tela, em até 0,7 s, e mais para o lado do que para cima ou para baixo (inclinação de até 0,6).
public enum EdgeSwipe {
    public static let minDistance = 70.0
    public static let maxSeconds = 0.7
    public static let maxSlope = 0.6

    /// `dx` é a distância para DENTRO da tela (positiva nas duas bordas); `dy`, a vertical.
    public static func accepts(dx: Double, dy: Double, seconds: Double) -> Bool {
        dx >= minDistance && seconds <= maxSeconds && abs(dy) <= dx * maxSlope
    }
}
