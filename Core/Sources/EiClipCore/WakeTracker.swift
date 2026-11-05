import Foundation

/// Tipo de acerto da palavra de ativação.
public enum WakeKind: String, Equatable {
    /// Frase completa ("ei clipe"). Pode começar OU parar a gravação (quem decide é o motor).
    case full
    /// Começo parcial ("ei cli"). Só serve para COMEÇAR.
    case early
    /// "clip"/"clipe" solto. Só serve para COMEÇAR.
    case loose
}

/// Transforma o fluxo de textos do reconhecedor do iOS em acertos únicos da palavra de ativação.
///
/// Diferença para o web app: lá cada fala vem com um índice; no iOS o texto é um só, que cresce ("Ei" → "Ei cli" → "Ei clipe"),
/// às vezes ACUMULA ("Ei clipe ei clipe") e às vezes ZERA depois de uma pausa (volta a "Ei"). Por isso o rastreador lembra
/// quantas palavras do texto já foram "gastas" por um acerto e só olha o que vem depois. Se o texto encolher, é uma fala nova.
/// Assim "Ei" → "Ei cli" → "Ei clipe" dá UM acerto (o parcial), e não três.
public struct WakeTracker {
    public let word: WakeWord
    private let matcher: WakeMatcher
    private var gate: WakeGate
    private var consumed = 0
    private var utterance = 0

    public init(word: WakeWord, minGapMs: Double = 1500) {
        self.word = word
        self.matcher = word.matcher
        self.gate = WakeGate(minGapMs: minGapMs)
    }

    /// Entrega o texto mais recente (parcial ou final). Devolve o tipo de acerto, ou `nil` se não houve acerto novo.
    public mutating func feed(_ text: String, nowMs: Double) -> WakeKind? {
        let words = WakeWords.words(text)
        if words.count < consumed { consumed = 0 }  // o texto zerou: fala nova
        guard consumed < words.count else { return nil }
        let tail = words[consumed...].joined(separator: " ")

        let kind: WakeKind
        if matcher.full(tail) {
            kind = .full
        } else if matcher.early(tail) {
            kind = .early
        } else if matcher.loose(tail) {
            kind = .loose
        } else {
            return nil
        }
        // Gasta as palavras mesmo que a trava barre este acerto: senão ele dispararia mais tarde.
        consumed = words.count
        utterance += 1
        return gate.accept("\(utterance)", nowMs: nowMs) ? kind : nil
    }

    /// Nova tarefa de reconhecimento: o texto recomeça do zero. A trava de intervalo continua valendo
    /// (religar o reconhecedor não pode permitir um disparo duplo logo em seguida).
    public mutating func reset() {
        consumed = 0
    }
}
