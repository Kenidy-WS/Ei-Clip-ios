import Foundation

/// v0.7.5: estado de uma permissão do iOS, sem depender de AVFoundation nem de Photos (o motor converte).
public enum PermissionState: Equatable {
    case notAsked, granted, limited, denied, restricted
}

/// O que fazer com as Fotos quando o usuário tenta gravar.
public enum PhotosAction: Equatable {
    /// Permitido (total ou limitado): nada a fazer.
    case none
    /// Ainda não pedida: pedir de novo. O iOS só mostra o aviso enquanto o estado é "ainda não pedida".
    case askAgain
    /// Negada ou restrita: o iOS não mostra o aviso de novo. Só os Ajustes resolvem; o app explica.
    case explainDenied
}

public enum PermissionRules {
    /// Quanto o app espera por uma resposta do iPhone a um pedido de permissão antes de seguir sem ela.
    public static let waitSeconds: Double = 10

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

    /// Evita empilhar pedidos: só pede de novo se o último foi há `waitSeconds` ou mais (ou se nunca pediu).
    public static func shouldAskNow(lastAskUptime: Double?, now: Double) -> Bool {
        guard let last = lastAskUptime else { return true }
        return now - last >= waitSeconds
    }
}

/// v0.7.5: espera uma operação por um tempo limitado. Se ela não terminar, devolve `nil` e segue; a operação continua
/// em segundo plano e o resultado dela é descartado. Usada nos pedidos de permissão, que dependem de um aviso do iOS
/// que pode não aparecer (visto num iPhone 16 com iOS 27.0.1).
public enum AsyncTimeout {
    public static func run<T: Sendable>(seconds: Double, _ operation: @escaping @Sendable () async -> T) async -> T? {
        await withCheckedContinuation { (continuation: CheckedContinuation<T?, Never>) in
            let once = Once<T>(continuation)
            Task { once.finish(await operation()) }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
                once.finish(nil)
            }
        }
    }

    /// Garante que a continuação seja retomada uma única vez (a primeira que chegar, resultado ou tempo esgotado).
    private final class Once<T>: @unchecked Sendable {
        private let lock = NSLock()
        private var continuation: CheckedContinuation<T?, Never>?

        init(_ continuation: CheckedContinuation<T?, Never>) {
            self.continuation = continuation
        }

        func finish(_ value: T?) {
            lock.lock()
            let pending = continuation
            continuation = nil
            lock.unlock()
            pending?.resume(returning: value)
        }
    }
}
