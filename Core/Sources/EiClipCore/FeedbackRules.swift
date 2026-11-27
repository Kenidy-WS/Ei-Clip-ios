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

    // MARK: - Rodada anterior no arquivo do feedback (v0.9.49)

    /// Tamanho máximo (em bytes) do trecho da rodada anterior que vai no e-mail.
    public static let previousMaxBytes = 300_000

    /// Seção "Rodada anterior" para o fim do arquivo do feedback. Se o app travou ou foi fechado, o que importa fica na rodada
    /// anterior. Passando do teto, mantém o FINAL do registro (onde o problema aparece), sempre em linhas inteiras,
    /// e diz quantas linhas antigas foram cortadas.
    public static func previousSection(_ previous: String, maxBytes: Int = previousMaxBytes) -> String {
        let title = "\n\n== Rodada anterior ==\n"
        let clean = previous.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return title + "(não há rodada anterior com conteúdo)\n" }
        let lines = clean.split(separator: "\n", omittingEmptySubsequences: false)
        var kept: [Substring] = []
        var bytes = 0
        for line in lines.reversed() {
            let size = line.utf8.count + 1
            if bytes + size > maxBytes { break }
            bytes += size
            kept.append(line)
        }
        kept.reverse()
        let cut = lines.count - kept.count
        let note = cut == 0
            ? "(completa: \(lines.count) linhas)\n"
            : "(últimas \(kept.count) de \(lines.count) linhas; \(cut) mais antigas cortadas)\n"
        return title + note + kept.joined(separator: "\n") + "\n"
    }
}
