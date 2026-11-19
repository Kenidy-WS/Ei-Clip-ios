import Foundation

/// Estado térmico do aparelho (mesmos níveis do iOS: normal, morno, quente, crítico).
public enum ThermalLevel: Int, Equatable, Comparable {
    case nominal = 0
    case fair = 1
    case serious = 2
    case critical = 3

    public static func < (a: ThermalLevel, b: ThermalLevel) -> Bool { a.rawValue < b.rawValue }
}

extension CaptureConfig {
    /// Configuração pesada: 4K, 60 fps ou qualidade máxima (esquenta mais; vale avisar antes de o aparelho ficar quente).
    public var isHeavy: Bool {
        quality == .p2160 || fps > 30 || imageLevel == .maximum
    }

    /// Um passo para baixo, começando pelo que mais pesa: 4K → 1080p, 60 → 30 fps, qualidade máxima → alta → padrão e,
    /// por último, 1080p → 720p (só se `allow720`). Nulo quando já está no piso.
    func loweredOneStep(allow720: Bool) -> CaptureConfig? {
        var next = self
        if next.quality == .p2160 {
            next.quality = .p1080
            return next.validated()
        }
        if next.fps > 30 {
            next.fps = 30
            return next.validated()
        }
        if next.imageLevel == .maximum {
            next.imageLevel = .high
            return next
        }
        if next.imageLevel == .high {
            next.imageLevel = .standard
            return next
        }
        if allow720 && next.quality == .p1080 {
            next.quality = .p720
            return next
        }
        return nil
    }

    /// Quantos passos para baixo ainda existem (sem o 720p, a menos que `allow720`).
    public func availableLowerSteps(allow720: Bool) -> Int {
        var count = 0
        var current = self
        while let next = current.loweredOneStep(allow720: allow720) {
            count += 1
            current = next
        }
        return count
    }

    /// A configuração depois de `steps` passos para baixo (para quando não há mais passos).
    public func lowered(by steps: Int) -> CaptureConfig {
        var current = self
        var left = steps
        while left > 0, let next = current.loweredOneStep(allow720: true) {
            current = next
            left -= 1
        }
        return current
    }
}

/// O que mudou entre duas configurações, em poucas palavras, para o aviso de calor (v0.8.5): "60 → 30 fps", "4K → 1080p",
/// "qualidade Máxima → Alta". Vários itens vêm separados por vírgula. Nulo se nada mudou.
public func reductionDescription(from: CaptureConfig, to: CaptureConfig) -> String? {
    func res(_ q: VideoQuality) -> String { q == .p2160 ? "4K" : "\(q.rawValue)p" }
    func level(_ l: ImageQuality) -> String {
        switch l {
        case .standard: return "Padrão"
        case .high: return "Alta"
        case .maximum: return "Máxima"
        }
    }
    var parts: [String] = []
    if from.quality != to.quality { parts.append("\(res(from.quality)) → \(res(to.quality))") }
    if from.fps != to.fps { parts.append("\(from.fps) → \(to.fps) fps") }
    if from.imageLevel != to.imageLevel { parts.append("qualidade \(level(from.imageLevel)) → \(level(to.imageLevel))") }
    return parts.isEmpty ? nil : parts.joined(separator: ", ")
}

/// O que dizer ao usuário sobre a temperatura.
public enum ThermalNotice: Equatable {
    /// Quente: a qualidade acabou de ser reduzida.
    case reduced
    /// Quente, mas gravando: a redução fica para depois da gravação (trocar a qualidade no meio cortaria o clipe).
    case reducePending
    /// Quente e já na qualidade mais baixa permitida: só o cuidado.
    case hotAtFloor
    /// Crítico: o iOS pode desligar a câmera a qualquer momento. Desde a v0.9.11 só avisa (a qualidade escolhida continua),
    /// a menos que venha junto de uma redução (redução automática ligada, ou reserva depois de uma falha da câmera).
    case critical
    /// Quente com a redução automática desligada (v0.7.28): só avisa; reduzir fica por conta do usuário.
    case hotAdvice
}

public struct ThermalAction: Equatable {
    /// Aviso a mostrar agora (nulo = nada novo).
    public var notice: ThermalNotice?
    /// Novo total de passos de redução a aplicar já (nulo = não mexe na câmera).
    public var lowerTo: Int?

    public init(notice: ThermalNotice? = nil, lowerTo: Int? = nil) {
        self.notice = notice
        self.lowerTo = lowerTo
    }
}

/// Reação ao calor (v0.6.2): decide quando avisar e quantos passos reduzir. A redução NUNCA sobe sozinha quando o aparelho
/// esfria (subir e descer a qualidade a cada oscilação reabriria a câmera à toa): quem escolhe voltar é o usuário.
public struct ThermalGovernor {
    /// Passos de redução já aplicados.
    public private(set) var appliedSteps = 0
    /// v0.9.11: a câmera falhou com o aparelho quente (interrompida pelo iOS ou perdendo quadros em sequência). É a reserva:
    /// a partir daí a redução vale mesmo com a redução automática desligada, até o usuário escolher a qualidade de novo.
    public private(set) var cameraFailed = false
    private var lastLevel: ThermalLevel = .nominal
    /// v0.9.15: até quando o aviso de "quente" fica em silêncio (aberto já quente).
    private var quietUntil: Date?

    public init() {}

    /// Quantos passos de redução cada nível pede: quente 1, crítico 2.
    static func stepsWanted(_ level: ThermalLevel) -> Int {
        switch level {
        case .nominal, .fair: return 0
        case .serious: return 1
        case .critical: return 2
        }
    }

    /// Reage a um estado térmico. `chosen` é a configuração escolhida pelo usuário (não a já reduzida).
    ///
    /// `autoReduce` (v0.7.28, padrão desligado no app): desligado, o calor só avisa e nada é reduzido sozinho, nem no
    /// "crítico" (v0.9.11: a escolha do usuário vale). A reserva é a falha da câmera (`noteCameraFailure`): depois dela, com
    /// o aparelho quente ou crítico, valem 2 passos de redução.
    public mutating func react(
        level: ThermalLevel, chosen: CaptureConfig, recording: Bool, autoReduce: Bool = true, now: Date = Date()
    ) -> ThermalAction {
        // O 720p só entra no passo crítico; quente (não crítico) para no 1080p.
        let possible = chosen.availableLowerSteps(allow720: level == .critical)
        let failedHot = cameraFailed && level >= .serious
        let reduces = autoReduce || failedHot
        let wanted = failedHot ? min(2, possible) : (autoReduce ? min(Self.stepsWanted(level), possible) : 0)
        let suppressed = level == .serious && (quietUntil.map { now < $0 } ?? false)
        let worsened = level > lastLevel
        if !suppressed {
            lastLevel = level  // em silêncio, o nível não é guardado: o aviso vem quando o prazo acabar
            quietUntil = nil
        }

        var action = ThermalAction()
        if wanted > appliedSteps {
            if recording {
                if worsened { action.notice = .reducePending }
            } else {
                appliedSteps = wanted
                lastLevel = level  // a redução já avisou: não repete o aviso de quente depois do prazo
                quietUntil = nil
                action.lowerTo = wanted
                action.notice = level == .critical ? .critical : .reduced
            }
            return action
        }
        guard worsened, !suppressed else { return action }
        switch level {
        case .nominal: break
        case .fair: break  // v0.6.15: "morno" é normal em clima quente; só avisa a partir de "quente"
        case .serious: action.notice = reduces ? .hotAtFloor : (chosen.availableLowerSteps(allow720: false) > 0 ? .hotAdvice : .hotAtFloor)
        case .critical: action.notice = .critical
        }
        return action
    }

    /// v0.9.11: a câmera falhou com o aparelho quente. Quem chama confere antes que o nível é quente ou crítico e, depois,
    /// chama `react` (a redução de reserva sai dali; gravando, fica para o fim da gravação).
    public mutating func noteCameraFailure() {
        cameraFailed = true
    }

    /// v0.9.15: segundos depois da abertura em que o aviso de "quente" fica em silêncio.
    public static let openingQuietSec: TimeInterval = 60

    /// v0.9.15: ao abrir a câmera com o aparelho já "quente" (não crítico), o aviso de quente espera `openingQuietSec`
    /// segundos, para não aparecer junto com a abertura. Passado o prazo, se o aparelho ainda estiver quente, o aviso vem
    /// (a antecedência antes do crítico continua). O crítico avisa na hora, a redução automática (se ligada) não é afetada,
    /// e esfriar dentro do prazo cancela o aviso. Quem chama deve reavaliar após o prazo. Devolve verdadeiro se adiou.
    @discardableResult
    public mutating func quietOpening(level: ThermalLevel, now: Date = Date()) -> Bool {
        guard level == .serious, lastLevel < .serious else { return false }
        quietUntil = now.addingTimeInterval(Self.openingQuietSec)
        return true
    }

    /// Zera a redução (o usuário escolheu a qualidade de novo) e esquece o último nível e a falha da câmera.
    public mutating func reset() {
        appliedSteps = 0
        cameraFailed = false
        lastLevel = .nominal
        quietUntil = nil
    }
}
