import Foundation

/// Janela do buffer retroativo ("Pré-gravação"): 15 ou 30 s, como no web app. Valor guardado inválido (ou ausente) vira 15 s.
public enum BufferWindow {
    public static let options = [15, 30]
    public static let defaultSeconds = 15

    public static func sanitized(_ stored: Int?) -> Int {
        guard let stored, options.contains(stored) else { return defaultSeconds }
        return stored
    }
}
