import Foundation

/// Porta de `src/core/wake-word.ts` do web app (fonte de verdade do produto; lá é somente leitura).
/// Reconhece a palavra de ativação ("Ei Clip", "Câmera, ação" ou "Ei Câmera") a partir do texto do reconhecedor de voz.
/// Lógica pura: o motor de voz só entrega o texto e age conforme a resposta.
public enum WakeWords {
    // MARK: - Texto

    /// Palavras do texto sem acentos, pontuação e caixa alta: "Ei, Clipe!" -> ["ei", "clipe"].
    public static func words(_ text: String) -> [String] {
        let folded = text.lowercased().folding(options: .diacriticInsensitive, locale: nil)
        var cleaned = ""
        for s in folded.unicodeScalars {
            let v = s.value
            if (v >= 97 && v <= 122) || (v >= 48 && v <= 57) {
                cleaned.unicodeScalars.append(s)
            } else {
                cleaned.append(" ")
            }
        }
        return cleaned.split(separator: " ").map(String.init)
    }

    /// Tira acentos, pontuação e caixa alta: "Ei, Clipe!" -> "ei clipe".
    public static func normalize(_ text: String) -> String {
        words(text).joined(separator: " ")
    }

    // MARK: - "Ei Clip"

    // Variações que o iPhone devolve na prática para "Ei" e "Clip" (no iOS 27 o texto vem como "clipe").
    private static let greetings: Set<String> = [
        "ei", "hei", "hey", "ey", "ay", "ai", "oi", "ec", "eh", "eii", "eei", "e", "a", "ae", "eu",
    ]
    private static let joinedGreetingPrefixes = ["ei", "hei", "hey", "ey", "oi", "ai", "ec", "e", "a"]
    private static let joinedClipEndings: Set<String> = ["clip", "clipe", "clipes", "clips"]
    private static let clipWords: Set<String> = ["clip", "clipe", "clips", "clipes", "click", "clic", "clique"]

    /// Saudação e "clip" escritos juntos ("eiclip", "eclipse").
    private static func isJoinedClip(_ w: String) -> Bool {
        if w == "eclipse" { return true }
        for p in joinedGreetingPrefixes where w.hasPrefix(p) {
            if joinedClipEndings.contains(String(w.dropFirst(p.count))) { return true }
        }
        return false
    }

    /// Verdadeiro se o texto contém uma saudação seguida de "clip" (ex.: "ei clipe", "hey clip").
    public static func isWakePhrase(_ text: String) -> Bool {
        let ws = words(text)
        if ws.contains(where: isJoinedClip) { return true }
        var i = 1
        while i < ws.count {
            if clipWords.contains(ws[i]) && greetings.contains(ws[i - 1]) { return true }
            i += 1
        }
        return false
    }

    /// Só "clip"/"clipe" solto (o reconhecedor às vezes engole o "Ei"). Serve apenas para COMEÇAR a gravar:
    /// um começo falso é barato (o clipe tem pré-gravação e dá para parar); parar sem querer, não.
    public static func isLooseWakeStart(_ text: String) -> Bool {
        words(text).contains { $0 == "clip" || $0 == "clipe" }
    }

    /// Início da frase ainda sendo reconhecida: texto parcial terminando em saudação + "cli" ("ei cli").
    /// Chega ~0,3 s antes de "ei clipe". Só serve para COMEÇAR a gravar.
    public static func isEarlyWakePhrase(_ text: String) -> Bool {
        let ws = words(text)
        let n = ws.count
        return n >= 2 && ws[n - 1] == "cli" && greetings.contains(ws[n - 2])
    }

    // MARK: - Outras palavras de ativação
    // Com vários celulares perto, cada pessoa usa uma palavra diferente. "câmera" é uma palavra comum, então estas duas são
    // mais estritas: só valem a frase completa (sem "clip" solto nem começo parcial) e a saudação de "Ei Câmera" não aceita
    // as variações curtas ("a", "e", "eu", "ai"), que fariam "a câmera está ligada" disparar a gravação.

    private static let cameraWords: Set<String> = ["camera", "camara"]
    private static let acaoWords: Set<String> = ["acao", "acoes", "action"]
    /// Ligações que o reconhecedor pode inserir: "câmera e ação", "câmera, a ação".
    private static let linkWords: Set<String> = ["a", "e", "de"]
    private static let strictGreetings: Set<String> = ["ei", "hei", "hey", "ey", "eii", "eei", "oi"]
    private static let strictGreetingPrefixes = ["ei", "hei", "hey", "ey", "oi"]

    /// "cameraacao", "cameraeacao"...
    private static func isJoinedCameraAcao(_ w: String) -> Bool {
        for p in ["camera", "camara"] where w.hasPrefix(p) {
            let rest = String(w.dropFirst(p.count))
            if acaoWords.contains(rest) { return true }
            if let f = rest.first, f == "e" || f == "a", acaoWords.contains(String(rest.dropFirst())) { return true }
        }
        return false
    }

    /// "eicamera", "oicamara"...
    private static func isJoinedEiCamera(_ w: String) -> Bool {
        for p in strictGreetingPrefixes where w.hasPrefix(p) {
            if cameraWords.contains(String(w.dropFirst(p.count))) { return true }
        }
        return false
    }

    /// "Câmera, ação" (também "luz, câmera, ação" e "câmera e ação").
    public static func isCameraAcaoPhrase(_ text: String) -> Bool {
        let ws = words(text)
        if ws.contains(where: isJoinedCameraAcao) { return true }
        var i = 0
        while i < ws.count - 1 {
            if cameraWords.contains(ws[i]) {
                let next = linkWords.contains(ws[i + 1]) ? i + 2 : i + 1
                if next < ws.count && acaoWords.contains(ws[next]) { return true }
            }
            i += 1
        }
        return false
    }

    /// "Ei câmera" (também "oi câmera", "hey camera"). "A câmera" ou "câmera" soltas não valem.
    public static func isEiCameraPhrase(_ text: String) -> Bool {
        let ws = words(text)
        if ws.contains(where: isJoinedEiCamera) { return true }
        var i = 1
        while i < ws.count {
            if cameraWords.contains(ws[i]) && strictGreetings.contains(ws[i - 1]) { return true }
            i += 1
        }
        return false
    }
}

/// Qual palavra de ativação está valendo.
public enum WakeWord: String, CaseIterable {
    case clip = "clip"
    case cameraAcao = "camera-acao"
    case eiCamera = "ei-camera"

    public static let defaultWord: WakeWord = .clip

    /// Valida um valor guardado (`nil` ou texto desconhecido não é palavra válida).
    public static func parse(_ value: String?) -> WakeWord? {
        guard let value else { return nil }
        return WakeWord(rawValue: value)
    }

    /// Como aparece para a pessoa.
    public var label: String {
        switch self {
        case .clip: return "Ei Clip"
        case .cameraAcao: return "Câmera, ação"
        case .eiCamera: return "Ei Câmera"
        }
    }

    public var matcher: WakeMatcher {
        switch self {
        case .clip:
            return WakeMatcher(
                full: WakeWords.isWakePhrase, loose: WakeWords.isLooseWakeStart, early: WakeWords.isEarlyWakePhrase)
        case .cameraAcao:
            return WakeMatcher(full: WakeWords.isCameraAcaoPhrase, loose: { _ in false }, early: { _ in false })
        case .eiCamera:
            return WakeMatcher(full: WakeWords.isEiCameraPhrase, loose: { _ in false }, early: { _ in false })
        }
    }
}

/// Como reconhecer cada palavra de ativação: frase completa e, só para "Ei Clip", os atalhos que apenas COMEÇAM a gravar.
public struct WakeMatcher {
    public let full: (String) -> Bool
    /// "clip" solto (o reconhecedor engole o "Ei").
    public let loose: (String) -> Bool
    /// Começo parcial da frase ("ei cli").
    public let early: (String) -> Bool
}

/// Trava contra disparo duplo. O reconhecedor entrega a mesma fala várias vezes (parcial e depois final),
/// então um comando só vale se for de outra fala (`key` diferente) e passou o intervalo mínimo desde o último.
public struct WakeGate {
    private let minGapMs: Double
    private var lastKey = ""
    private var lastAtMs = -Double.infinity

    public init(minGapMs: Double) {
        self.minGapMs = minGapMs
    }

    public mutating func accept(_ key: String, nowMs: Double) -> Bool {
        if key == lastKey || nowMs - lastAtMs < minGapMs { return false }
        lastKey = key
        lastAtMs = nowMs
        return true
    }

    public mutating func reset() {
        lastKey = ""
        lastAtMs = -Double.infinity
    }
}
