import Foundation

/// Janela do buffer retroativo ("Pré-gravação"): 15, 30 ou 60 s (o 60 s é só do app nativo). Valor guardado inválido (ou ausente) vira 15 s.
public enum BufferWindow {
    public static let options = [15, 30, 60]
    public static let defaultSeconds = 15

    public static func sanitized(_ stored: Int?) -> Int {
        guard let stored, options.contains(stored) else { return defaultSeconds }
        return stored
    }
}
