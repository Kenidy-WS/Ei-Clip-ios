import Foundation

/// Tipo de acerto da palavra de ativação.
public enum WakeKind: String, Equatable {
    /// Frase completa ("ei clipe"): liga ou para a gravação.
    case full
    /// Começo parcial ("ei cli"): só liga (chega ~0,3 s antes da frase completa).
    case early
    /// "clip"/"clipe" solto: liga; com gravação em andamento há mais de 3,5 s, também para (como no web app).
    case loose

    /// Como aparece no Diagnóstico.
    public var label: String {
        switch self {
        case .full: return "frase completa"
        case .early: return "começo parcial"
        case .loose: return "clip solto"
        }
    }
}

/// O que o detector precisa saber da gravação para decidir o que cada texto significa (como `S.rec` e `S.finalizing` no web app).
public struct WakeState: Equatable {
    /// Há gravação em andamento.
    public var recording: Bool
    /// Há quanto tempo a gravação começou (ms); 0 se não grava.
    public var recordingMs: Double
    /// A gravação está sendo encerrada (bipe de fim, fechamento do arquivo): comandos não valem.
    public var finalizing: Bool

    public init(recording: Bool, recordingMs: Double, finalizing: Bool) {
        self.recording = recording
        self.recordingMs = recordingMs
        self.finalizing = finalizing
    }

    public static let idle = WakeState(recording: false, recordingMs: 0, finalizing: false)

    /// "clip" solto só PARA a gravação depois disto (o "clip" do próprio "Ei clip" que começou chega repetido e não pode parar logo).
    public static let looseStopAfterMs = 3500.0
}

/// Transforma o fluxo de textos do reconhecedor do iOS em acertos únicos da palavra de ativação.
///
/// Diferença para o web app: lá cada fala vem com um índice; no iOS o texto é um só, que cresce ("Ei" → "Ei cli" → "Ei clipe"),
/// às vezes ACUMULA ("Ei clipe ei clipe") e às vezes ZERA depois de uma pausa (volta a "Ei"). Por isso o rastreador lembra
/// quantas palavras do texto já foram "gastas" por um acerto e só olha o que vem depois.
/// Assim "Ei" → "Ei cli" → "Ei clipe" dá UM acerto (o parcial), e não três.
///
/// Fala nova ou revisão? (v0.2.3) O iOS também REVISA o texto já dito ("Chuca ei Chuca ei cli" → "Chuca ei clipe", 5 → 3 palavras)
/// e, quando não troca só o final, o texto deixa de ser continuação do anterior. A regra:
/// - o texto continua o anterior (começa igual): segue de onde parou;
/// - mudou, e passou 1 s ou mais desde o texto anterior: é uma fala nova (o iOS zerou depois de uma pausa), recomeça do zero;
/// - mudou rápido (menos de 1 s): é revisão; o que já foi gasto continua gasto (no máximo encolhe junto com o texto);
/// - revisão que chega tarde (1 a 3 s) e parece fala nova: a trava de intervalo (3 s, como no web app) barra o acerto repetido.
///
/// O que vale em cada situação (igual ao `voice.ts` do web app):
/// - sem gravar: frase completa, começo parcial ou "clip" solto ligam;
/// - gravando: só a frase completa para (o "ei cli" parcial NÃO é gasto, para o "ei clipe" completo chegar depois);
///   "clip" solto também para, mas só depois de 3,5 s de gravação;
/// - encerrando a gravação: nada vale, e o que for dito é descartado (não pode ligar de novo logo depois).
public struct WakeTracker {
    public let word: WakeWord
    private let matcher: WakeMatcher
    private var gate: WakeGate
    private var consumed = 0
    private var utterance = 0
    private var lastWords: [String] = []
    private var lastFeedMs: Double = 0

    /// Pausa a partir da qual um texto que não continua o anterior conta como fala nova (e não como revisão).
    public static let newUtteranceGapMs = 1000.0

    public init(word: WakeWord, minGapMs: Double = 3000) {
        self.word = word
        self.matcher = word.matcher
        self.gate = WakeGate(minGapMs: minGapMs)
    }

    /// Entrega o texto mais recente (parcial ou final). Devolve o tipo de acerto, ou `nil` se não houve acerto novo.
    public mutating func feed(_ text: String, nowMs: Double, state: WakeState = .idle) -> WakeKind? {
        let words = WakeWords.words(text)
        let continues = words.count >= lastWords.count && Array(words.prefix(lastWords.count)) == lastWords
        if !lastWords.isEmpty && !continues {
            if nowMs - lastFeedMs >= WakeTracker.newUtteranceGapMs {
                consumed = 0  // fala nova: o iOS zerou o texto depois de uma pausa
            } else if words.count < consumed {
                consumed = words.count  // revisão: encolheu, mas nada do que sobrou é novo
            }
        }
        lastWords = words
        lastFeedMs = nowMs
        guard consumed < words.count else { return nil }
        if state.finalizing {
            consumed = words.count  // descarta o que foi dito durante o encerramento
            return nil
        }
        let tail = words[consumed...].joined(separator: " ")

        let kind: WakeKind
        if matcher.full(tail) {
            kind = .full
        } else if state.recording {
            guard matcher.loose(tail), state.recordingMs > WakeState.looseStopAfterMs else { return nil }
            kind = .loose
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
        lastWords = []
    }
}
