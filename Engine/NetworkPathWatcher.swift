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
    private var onReturn: (@Sendable () -> Void)?
    private var lastReturnFired: Date?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let nowOnline = path.status == .satisfied
            self.lock.lock()
            let previousOnline = self.status.map { $0 == .satisfied }
            self.status = path.status
            var handler: (@Sendable () -> Void)?
            // v0.9.45: a internet voltou (estava sem rede e agora tem): avisa quem pediu, sem repetir em sequência.
            if NetworkReturnRules.shouldReread(previousOnline: previousOnline, nowOnline: nowOnline, lastReread: self.lastReturnFired, now: Date()) {
                self.lastReturnFired = Date()
                handler = self.onReturn
            }
            self.lock.unlock()
            handler?()
        }
        monitor.start(queue: queue)
    }

    /// v0.9.45: quem quer saber quando a internet volta (o `StoreManager` relê a assinatura).
    func setOnReturn(_ handler: @escaping @Sendable () -> Void) {
        lock.lock(); onReturn = handler; lock.unlock()
    }

    /// Chamar cedo (na abertura) para o iOS ter tempo de informar o estado.
    func start() { _ = status }

    /// true = o iOS diz que não há rede, ou ainda não informou.
    var looksOffline: Bool {
        lock.lock(); defer { lock.unlock() }
        guard let status else { return true }
        return status != .satisfied
    }

    /// v0.9.46: true só quando o iOS JÁ informou e disse que não há rede (diferente de `looksOffline`, que também vale antes da primeira informação).
    var definitelyOffline: Bool {
        lock.lock(); defer { lock.unlock() }
        guard let status else { return false }
        return status != .satisfied
    }

    /// v0.9.46: espera (até `maxSeconds`) o iOS informar o estado da rede; na abertura a informação chega em milissegundos.
    func waitUntilKnown(maxSeconds: Double) async {
        let deadline = Date().addingTimeInterval(maxSeconds)
        while Date() < deadline {
            if isKnown { return }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    private var isKnown: Bool {
        lock.lock(); defer { lock.unlock() }
        return status != nil
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
