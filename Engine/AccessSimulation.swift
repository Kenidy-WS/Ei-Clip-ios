import Foundation

/// Simulação de TESTE (v0.9.27): finge "sem acesso pago" com N clipes gratuitos usados, para testar o gate e a tela
/// "Escolha seu acesso" mesmo com assinatura de teste ativa. Só em memória: some ao fechar o app. Não mexe no Keychain
/// nem na assinatura real. Sai antes da versão pública (Beta).
final class AccessSimulation {
    static let shared = AccessSimulation()

    private let lock = NSLock()
    private var used: Int?

    var isOn: Bool { usedOverride != nil }

    /// Teste de layout: mostra os preços mesmo quando a proteção de moeda os esconderia (catálogo de teste em dólar).
    /// O valor mostrado pode estar na moeda errada; vale só para ver o desenho final.
    private var forcePricesValue = false
    var forcePrices: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return forcePricesValue
        }
        set {
            lock.lock()
            forcePricesValue = newValue
            lock.unlock()
        }
    }

    var usedOverride: Int? {
        lock.lock()
        defer { lock.unlock() }
        return used
    }

    func start(used n: Int) {
        lock.lock()
        used = max(0, min(FreeClipLedger.limit, n))
        lock.unlock()
    }

    func stop() {
        lock.lock()
        used = nil
        lock.unlock()
    }

    /// Conta um clipe na simulação (no máximo 10). Nil se a simulação está desligada ou já chegou a 10.
    func increment() -> Int? {
        lock.lock()
        defer { lock.unlock() }
        guard let n = used, n < FreeClipLedger.limit else { return nil }
        used = n + 1
        return n + 1
    }
}
