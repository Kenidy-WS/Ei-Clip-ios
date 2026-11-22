import Foundation

/// C2, etapa 4: cópia protegida por cadeado da última resposta da Apple, lida pelo gate da gravação em qualquer fila.
/// Não é `@Published` (a câmera não pode depender de estado publicado). O `StoreManager` atualiza depois de cada leitura;
/// o cálculo é refeito a cada consulta, com a contagem atual dos clipes gratuitos e a hora de agora.
final class AccessSnapshot {
    static let shared = AccessSnapshot()

    private let lock = NSLock()
    private var answer: StoreAnswer?
    private var last = LastConfirmed.none

    func update(answer: StoreAnswer, last: LastConfirmed) {
        lock.lock()
        self.answer = answer
        self.last = last
        lock.unlock()
    }

    /// O acesso de agora. Nil = a Apple ainda não respondeu desde que o app abriu (a gravação segue, sem contar clipe gratuito).
    func evaluate(now: Date = Date()) -> AccessResult? {
        lock.lock()
        let answer = self.answer
        let last = self.last
        lock.unlock()
        guard let answer else { return nil }
        return AccessGate.evaluate(store: answer, last: last, now: ConfirmedAccessStore.shared.effectiveNow(now), freeClipsUsed: FreeClipCounter.shared.used)
    }
}

extension Notification.Name {
    /// Um clipe gratuito foi contado: o chip e as telas de acesso se atualizam.
    static let eiClipFreeCountChanged = Notification.Name("eiClipFreeCountChanged")
}
