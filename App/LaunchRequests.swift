import Foundation

/// Pedido "abrir câmera" vindo de fora do app (v0.9.2): a ação do Atalhos/Botão de Ação só deixa o recado aqui; quem decide e
/// abre a câmera é a `RootView`, pelos mesmos caminhos de sempre (regra pura em `LaunchRules`, no Core).
/// Fica fora do motor e não é `@Published`: nada novo é publicado para a tela.
enum LaunchRequests {
    static let didPost = Notification.Name("eiClipLaunchRequest")

    private static let lock = NSLock()
    private static var postedAt: Date?

    /// Chamado pela ação (pode vir de qualquer linha de execução).
    static func post() {
        lock.lock()
        postedAt = Date()
        lock.unlock()
        NotificationCenter.default.post(name: didPost, object: nil)
    }

    /// v0.9.3: há pedido esperando? (só para o Diagnóstico; não consome)
    static var hasPending: Bool {
        lock.lock()
        defer { lock.unlock() }
        return postedAt != nil
    }

    /// Pega o pedido uma única vez. Devolve há quantos segundos ele foi feito, ou `nil` se não há pedido.
    static func consume() -> TimeInterval? {
        lock.lock()
        defer { lock.unlock() }
        guard let at = postedAt else { return nil }
        postedAt = nil
        return Date().timeIntervalSince(at)
    }
}
