import Foundation

/// v0.7.6: as quatro permissões do iOS que o app usa.
public enum PermissionKind: String, CaseIterable, Equatable {
    case camera, microphone, speech, photos
}

/// Estado de uma permissão do iOS, sem depender de AVFoundation, Speech nem Photos (o motor converte).
public enum PermissionState: Equatable {
    case notAsked, granted, limited, denied, restricted
}

/// O que fazer com as Fotos quando o usuário toca em gravar.
public enum PhotosAction: Equatable {
    /// Permitido (total ou limitado): nada a fazer.
    case none
    /// Ainda não pedida: pedir de novo. O iOS só mostra o aviso dele enquanto o estado é "ainda não pedida".
    case askAgain
    /// Negada ou restrita: o iOS não mostra o aviso de novo. Só os Ajustes resolvem (o aviso do app leva até lá).
    case explainDenied
}

/// Situação de uma permissão: o estado no iOS e se o app já chegou a pedi-la alguma vez (guardado no aparelho).
public struct PermissionStatus: Equatable {
    public let kind: PermissionKind
    public let state: PermissionState
    public let askedBefore: Bool

    public init(kind: PermissionKind, state: PermissionState, askedBefore: Bool) {
        self.kind = kind
        self.state = state
        self.askedBefore = askedBefore
    }
}

public enum PermissionProblem: Equatable {
    /// Negada ou restrita: o iOS não pergunta de novo, só os Ajustes resolvem.
    case denied
    /// O app já pediu, mas o iOS continua com "ainda não pedida": o aviso do sistema não apareceu (ou não foi respondido).
    case unanswered
    /// Só as Fotos: acesso limitado (o usuário escolheu "Selecionar Fotos"). O álbum "Ei Clip" precisa de acesso completo.
    case limited
}

public struct PermissionIssue: Equatable {
    public let kind: PermissionKind
    public let problem: PermissionProblem

    public init(kind: PermissionKind, problem: PermissionProblem) {
        self.kind = kind
        self.problem = problem
    }
}

public enum PermissionRules {
    public static func photosAction(_ state: PermissionState) -> PhotosAction {
        switch state {
        case .granted, .limited: return .none
        case .notAsked: return .askAgain
        case .denied, .restricted: return .explainDenied
        }
    }

    /// Se dá para salvar clipes no álbum (o acesso limitado também serve).
    public static func canSaveToPhotos(_ state: PermissionState) -> Bool {
        state == .granted || state == .limited
    }

    /// O problema de uma permissão, ou nil se está tudo certo. "Ainda não pedida" só é problema se o app já pediu antes: na
    /// primeira vez o aviso do iOS aparece sozinho e o app não deve se meter.
    public static func problem(state: PermissionState, askedBefore: Bool) -> PermissionProblem? {
        switch state {
        case .granted: return nil
        case .limited: return .limited
        case .denied, .restricted: return .denied
        case .notAsked: return askedBefore ? .unanswered : nil
        }
    }

    /// Só as permissões com problema, na ordem recebida (a ordem do aviso).
    public static func issues(in statuses: [PermissionStatus]) -> [PermissionIssue] {
        statuses.compactMap { status in
            problem(state: status.state, askedBefore: status.askedBefore).map {
                PermissionIssue(kind: status.kind, problem: $0)
            }
        }
    }

    /// Sem a câmera negada o app abre; com ela, não.
    public static func blocksCamera(_ issues: [PermissionIssue]) -> Bool {
        issues.contains { $0.kind == .camera && $0.problem == .denied }
    }

    /// Evita pedidos repetidos no mesmo instante (toques seguidos em gravar). Não é um prazo de espera: o app nunca desiste
    /// de um pedido; só não manda outro dentro de `minGap` segundos.
    public static func shouldAskNow(lastAskUptime: Double?, now: Double, minGap: Double = 2) -> Bool {
        guard let last = lastAskUptime else { return true }
        return now - last >= minGap
    }
}

/// v0.7.6: guarda no aparelho quais permissões o app já pediu ao sistema. Com isso o app percebe o caso "pediu e o iPhone não
/// mostrou o aviso" (estado continua "ainda não pedida") na vez seguinte, sem cronômetro.
public struct PermissionLedger {
    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    private func key(_ kind: PermissionKind) -> String { "permAsked.\(kind.rawValue)" }

    public func mark(_ kind: PermissionKind) {
        store.set(true, forKey: key(kind))
    }

    public func wasAsked(_ kind: PermissionKind) -> Bool {
        (store.object(forKey: key(kind)) as? Bool) ?? false
    }
}
