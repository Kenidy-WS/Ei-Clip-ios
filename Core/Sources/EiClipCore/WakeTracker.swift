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
/// às vezes ACUMULA ("Ei clipe ei clipe"), às vezes ZERA depois de uma pausa (volta a "Ei"), às vezes é REVISADO
/// ("Chuca ei Chuca ei cli" → "Chuca ei clipe") e às vezes chega repetido, igual, só com a confiança nova.
///
/// Desde a v0.2.4 o rastreador conta OCORRÊNCIAS da frase no texto, em vez de contar palavras ou medir tempo:
/// - cada trecho do texto que forma a frase (frase completa, começo parcial ou "clip" solto) é uma ocorrência;
/// - `fired` é quantas ocorrências já viraram acerto; se o texto encolher ou zerar, `fired` encolhe junto;
/// - só uma ocorrência NOVA (índice >= `fired`) pode disparar. Texto repetido, revisão ("ei cli" → "ei clipe" continua sendo a
///   mesma ocorrência) e texto que zera não dependem de relógio nenhum.
///
/// O que vale em cada situação (igual ao `voice.ts` do web app):
/// - sem gravar: frase completa, começo parcial ou "clip" solto ligam;
/// - gravando: só a frase completa para (o "ei cli" parcial NÃO é gasto: depois vira "ei clipe", a mesma ocorrência, e aí vale);
///   "clip" solto também para, mas só depois de 3,5 s de gravação;
/// - encerrando a gravação: nada vale, e o que for dito é descartado (não pode ligar de novo logo depois);
/// - menos de 3 s desde o acerto anterior: a trava de intervalo barra o comando, e ele NÃO fica guardado para depois.
public struct WakeTracker {
    public let word: WakeWord
    private let matcher: WakeMatcher
    private var gate: WakeGate
    private var fired = 0
    private var utterance = 0

    public init(word: WakeWord, minGapMs: Double = 3000) {
        self.word = word
        self.matcher = word.matcher
        self.gate = WakeGate(minGapMs: minGapMs)
    }

    /// Ocorrências da frase no texto, em ordem. Cada uma termina na primeira palavra em que o trecho (desde o fim da anterior) já forma a frase.
    private func occurrences(_ words: [String]) -> [WakeKind] {
        var result: [WakeKind] = []
        var start = 0
        var end = 1
        while end <= words.count {
            let seg = words[start..<end].joined(separator: " ")
            if matcher.full(seg) {
                result.append(.full)
                start = end
            } else if matcher.early(seg) {
                result.append(.early)
                start = end
            } else if matcher.loose(seg) {
                result.append(.loose)
                start = end
            }
            end += 1
        }
        return result
    }

    /// Entrega o texto mais recente (parcial ou final). Devolve o tipo de acerto, ou `nil` se não houve acerto novo.
    public mutating func feed(_ text: String, nowMs: Double, state: WakeState = .idle) -> WakeKind? {
        let events = occurrences(WakeWords.words(text))
        if fired > events.count { fired = events.count }  // o texto encolheu ou zerou
        guard fired < events.count else { return nil }
        if state.finalizing {
            fired = events.count  // descarta o que foi dito durante o encerramento
            return nil
        }
        // Dentre as ocorrências novas, a última que vale nesta situação.
        var chosen: WakeKind?
        for kind in events[fired...] {
            if state.recording {
                if kind == .full || (kind == .loose && state.recordingMs > WakeState.looseStopAfterMs) { chosen = kind }
            } else {
                chosen = kind
            }
        }
        guard let kind = chosen else { return nil }  // não vale agora (ex.: "ei cli" gravando): fica para quando virar "ei clipe"
        // Gasta as ocorrências mesmo que a trava barre este acerto: senão ele dispararia mais tarde.
        fired = events.count
        utterance += 1
        return gate.accept("\(utterance)", nowMs: nowMs) ? kind : nil
    }

    /// Nova tarefa de reconhecimento: o texto recomeça do zero. A trava de intervalo continua valendo
    /// (religar o reconhecedor não pode permitir um disparo duplo logo em seguida).
    public mutating func reset() {
        fired = 0
    }
}
