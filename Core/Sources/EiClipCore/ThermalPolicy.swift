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
    /// Crítico: o iOS pode desligar a câmera a qualquer momento.
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
    private var lastLevel: ThermalLevel = .nominal

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
    /// `autoReduce` (v0.7.28, padrão desligado no app): desligado, o "quente" só avisa e nada é reduzido sozinho; no
    /// "crítico" a redução vale sempre, como proteção (o iOS pode desligar a câmera).
    public mutating func react(
        level: ThermalLevel, chosen: CaptureConfig, recording: Bool, autoReduce: Bool = true
    ) -> ThermalAction {
        // O 720p só entra no passo crítico; quente (não crítico) para no 1080p.
        let possible = chosen.availableLowerSteps(allow720: level == .critical)
        let reduces = autoReduce || level == .critical
        let wanted = reduces ? min(Self.stepsWanted(level), possible) : 0
        let worsened = level > lastLevel
        lastLevel = level

        var action = ThermalAction()
        if wanted > appliedSteps {
            if recording {
                if worsened { action.notice = .reducePending }
            } else {
                appliedSteps = wanted
                action.lowerTo = wanted
                action.notice = level == .critical ? .critical : .reduced
            }
            return action
        }
        guard worsened else { return action }
        switch level {
        case .nominal: break
        case .fair: break  // v0.6.15: "morno" é normal em clima quente; só avisa a partir de "quente"
        case .serious: action.notice = reduces ? .hotAtFloor : (chosen.availableLowerSteps(allow720: false) > 0 ? .hotAdvice : .hotAtFloor)
        case .critical: action.notice = .critical
        }
        return action
    }

    /// Zera a redução (o usuário escolheu outra configuração) e esquece o último nível.
    public mutating func reset() {
        appliedSteps = 0
        lastLevel = .nominal
    }
}
