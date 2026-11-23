import Foundation

// v0.9.40: regras da tela "Enviar feedback" (Ajustes). Lógica pura, sem textos e sem tela.

public enum FeedbackRules {
    /// Menor relato aceito (depois de tirar espaços e quebras de linha das pontas).
    public static let minimumLength = 3
    /// Maior relato aceito (o campo corta o excesso; um e-mail com isso já é bem longo).
    public static let maximumLength = 4000

    /// O relato sem espaços e quebras de linha nas pontas.
    public static func clean(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// O botão "Enviar feedback" só acende com um relato de verdade (não só espaços).
    public static func canSend(_ text: String) -> Bool {
        clean(text).count >= minimumLength
    }

    /// Corta o texto digitado ou colado no limite.
    public static func limited(_ text: String) -> String {
        text.count > maximumLength ? String(text.prefix(maximumLength)) : text
    }
}
