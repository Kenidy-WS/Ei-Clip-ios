import Foundation

/// v0.6.23: o `@Published` avisa a tela TODA vez que recebe um valor, mesmo igual. O relógio do motor (4 vezes por
/// segundo) republicava os tempos do buffer e da gravação sem parar, redesenhando a tela da câmera 8 vezes por segundo
/// (e na v0.6.22 a tela travou num impasse entre essa publicação e o cálculo de layout do SwiftUI). Agora o tempo só
/// é publicado quando o valor mostrado muda de verdade.
public enum PublishRules {
    /// Passo dos tempos publicados (a tela mostra segundos inteiros e uma barra de 90 pt).
    public static let timeStep = 0.5

    public static func quantized(_ seconds: Double) -> Double {
        (seconds / timeStep).rounded(.down) * timeStep
    }

    /// Valor a publicar, ou nil se o que a tela já mostra continua valendo.
    public static func timeToPublish(shown: Double, new: Double) -> Double? {
        let q = quantized(new)
        return q == shown ? nil : q
    }
}
