import Foundation
import Network

/// v0.9.42: sinal de rede do iOS (sem pedir permissão). Só serve para decidir se uma lista de assinaturas vazia é confiável:
/// sem rede, ou antes de o iOS informar, tratamos como "sem sinal de rede" (o lado seguro para quem já pagou).
final class NetworkPathWatcher: @unchecked Sendable {
    static let shared = NetworkPathWatcher()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "app.eiclip.networkpath")
    private let lock = NSLock()
    private var status: NWPath.Status?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            self.lock.lock()
            self.status = path.status
            self.lock.unlock()
        }
        monitor.start(queue: queue)
    }

    /// Chamar cedo (na abertura) para o iOS ter tempo de informar o estado.
    func start() { _ = status }

    /// true = o iOS diz que não há rede, ou ainda não informou.
    var looksOffline: Bool {
        lock.lock(); defer { lock.unlock() }
        guard let status else { return true }
        return status != .satisfied
    }

    var logText: String {
        lock.lock(); defer { lock.unlock() }
        guard let status else { return "rede: o iOS ainda não informou" }
        switch status {
        case .satisfied: return "rede: disponível"
        case .unsatisfied: return "rede: indisponível"
        case .requiresConnection: return "rede: exige conexão"
        @unknown default: return "rede: estado desconhecido"
        }
    }
}
