import Foundation

/// v0.9.13: o que o Diagnóstico mostra do texto que o reconhecedor de voz devolveu.
///
/// O iPhone transcreve TUDO o que o microfone ouve, inclusive a conversa de quem está por perto. O Diagnóstico vai para o
/// arquivo que o testador compartilha, então só ficam as palavras que lembram a palavra de ativação ("ei clipe", "eclipse",
/// "ei câmera", "câmera ação"). O resto vira "[…]"; sem nenhuma palavra assim, vira "[fala de fundo, N palavras]".
///
/// Lógica pura: não muda o que a voz detecta (o detector continua recebendo o texto inteiro, sem filtro).
public enum VoiceLogText {
    // Mesmas variações do `WakeWords` (que mantém os conjuntos privados; aqui só decidem o que aparece no registro).
    private static let greetings: Set<String> = [
        "ei", "hei", "hey", "ey", "ay", "ai", "oi", "ec", "eh", "eii", "eei", "e", "a", "ae", "eu",
    ]
    private static let strictGreetings: Set<String> = ["ei", "hei", "hey", "ey", "eii", "eei", "oi"]
    private static let clipWords: Set<String> = [
        "clip", "clipe", "clips", "clipes", "click", "clic", "clique", "cli", "eclipse",
    ]
    private static let joinedPrefixes = ["ei", "hei", "hey", "ey", "oi", "ai", "ec", "e", "a"]
    private static let joinedEndings: Set<String> = ["clip", "clipe", "clips", "clipes"]
    private static let cameraWords: Set<String> = ["camera", "camara"]
    private static let acaoWords: Set<String> = ["acao", "acoes", "action"]
    private static let linkWords: Set<String> = ["a", "e", "de"]

    /// "clip", "clipe", "cli" (começo parcial), "eclipse", "eiclip"...
    private static func isClipLike(_ w: String) -> Bool {
        if clipWords.contains(w) { return true }
        for p in joinedPrefixes where w.hasPrefix(p) {
            if joinedEndings.contains(String(w.dropFirst(p.count))) { return true }
        }
        return false
    }

    /// "cameraacao", "cameraeacao", "eicamera"...
    private static func isJoinedCamera(_ w: String) -> Bool {
        for p in ["camera", "camara"] where w.hasPrefix(p) {
            let rest = String(w.dropFirst(p.count))
            if acaoWords.contains(rest) { return true }
            if let f = rest.first, f == "e" || f == "a", acaoWords.contains(String(rest.dropFirst())) { return true }
        }
        for p in ["ei", "hei", "hey", "ey", "oi"] where w.hasPrefix(p) {
            if cameraWords.contains(String(w.dropFirst(p.count))) { return true }
        }
        return false
    }

    /// Quais palavras (já sem acento e em minúsculas) podem aparecer no registro.
    static func keepMask(_ ws: [String]) -> [Bool] {
        var keep = [Bool](repeating: false, count: ws.count)
        for i in ws.indices {
            let w = ws[i]
            if isClipLike(w) {
                keep[i] = true
                if i > 0 && greetings.contains(ws[i - 1]) { keep[i - 1] = true }
            } else if isJoinedCamera(w) {
                keep[i] = true
            } else if cameraWords.contains(w) {
                // "câmera" sozinha é palavra comum: só aparece depois de "ei", "oi"...
                if i > 0 && strictGreetings.contains(ws[i - 1]) {
                    keep[i] = true
                    keep[i - 1] = true
                }
            } else if acaoWords.contains(w) {
                // "câmera ação", "câmera e ação": só aparece se vier depois de "câmera".
                var j = i - 1
                if j >= 0 && linkWords.contains(ws[j]) { j -= 1 }
                if j >= 0 && cameraWords.contains(ws[j]) {
                    for k in j...i { keep[k] = true }
                }
            }
        }
        return keep
    }

    /// Texto para o Diagnóstico. Palavras sem acento e em minúsculas ("Ei, Clipe!" -> "ei clipe").
    public static func redacted(_ text: String) -> String {
        let ws = WakeWords.words(text)
        if ws.isEmpty { return "(vazio)" }
        let keep = keepMask(ws)
        if !keep.contains(true) {
            return "[fala de fundo, \(ws.count) \(ws.count == 1 ? "palavra" : "palavras")]"
        }
        var parts: [String] = []
        var hiding = false
        for i in ws.indices {
            if keep[i] {
                hiding = false
                parts.append(ws[i])
            } else if !hiding {
                hiding = true
                parts.append("[…]")
            }
        }
        return parts.joined(separator: " ")
    }
}
