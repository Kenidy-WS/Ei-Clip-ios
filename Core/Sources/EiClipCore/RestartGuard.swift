import Foundation

/// Decide se o reconhecedor de voz deve ser religado depois que uma tarefa terminou.
///
/// O reconhecedor do iOS encerra a tarefa de tempos em tempos (limite de duração, "nenhuma fala detectada", erro).
/// Religar é o normal; mas se as tarefas morrem quase na hora, várias vezes seguidas, algo está errado
/// (permissão, modelo ausente, microfone mudo) e religar sem parar só gastaria bateria e encheria o Diagnóstico.
public struct RestartGuard {
    /// Uma tarefa que viveu menos que isto (em segundos) conta como "morte rápida".
    public let minLifeSec: Double
    /// Quantas mortes rápidas seguidas fazem desistir de religar.
    public let maxQuickFailures: Int
    public private(set) var quickFailures = 0

    public init(minLifeSec: Double = 1.0, maxQuickFailures: Int = 5) {
        self.minLifeSec = minLifeSec
        self.maxQuickFailures = maxQuickFailures
    }

    /// Registra o fim de uma tarefa que viveu `lifeSec` segundos. Devolve verdadeiro se deve religar.
    public mutating func taskEnded(lifeSec: Double) -> Bool {
        if lifeSec < minLifeSec {
            quickFailures += 1
        } else {
            quickFailures = 0
        }
        return quickFailures < maxQuickFailures
    }

    public mutating func reset() {
        quickFailures = 0
    }
}
