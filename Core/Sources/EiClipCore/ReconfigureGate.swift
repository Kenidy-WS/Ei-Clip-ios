import Foundation

/// v0.6.20: trava de "câmera sendo reconfigurada" (troca de câmera, lente, ajuste de captura, calor). Um só dono por vez:
/// quem consegue `tryBegin()` segura a trava até `end()`, inclusive nas voltas ("a frontal não abriu"). Toque que chega
/// durante a reconfiguração é recusado na hora (antes a trava era publicada por uma fila assíncrona e deixava passar).
public struct ReconfigureGate {
    public private(set) var busy = false

    public init() {}

    /// Pega a trava. Falso se já está ocupada.
    public mutating func tryBegin() -> Bool {
        if busy { return false }
        busy = true
        return true
    }

    public mutating func end() {
        busy = false
    }
}
