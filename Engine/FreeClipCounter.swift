import Foundation
import Security

/// Registro dos clipes gratuitos no Keychain (C2, etapa 2; desde a v0.9.27 o gate da gravação usa esta contagem).
///
/// Um único registro (JSON) com os UUIDs dos clipes já contados. O Keychain costuma sobreviver à exclusão e à reinstalação
/// do app, mas isso não é garantia da Apple: o Diagnóstico mostra o que foi lido a cada abertura.
/// Falha técnica de leitura NUNCA prejudica o usuário (não bloqueia, não apaga o registro) e vai para o Diagnóstico.
final class FreeClipCounter {
    static let shared = FreeClipCounter()

    private let service = "app.eiclip.freeclips"
    private let account = "ledger"
    private let lock = NSLock()
    private var ledger = FreeClipLedger()
    private var loaded = false
    private var readFailed = false

    private func log(_ text: String) { Diagnostics.shared.log("contador", text) }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    /// Lê o registro (se ainda não leu, ou se a leitura anterior falhou). Chamar com o cadeado já fechado.
    private func loadLocked() {
        if loaded && !readFailed { return }
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            switch FreeClipLedger.load(from: item as? Data) {
            case .loaded(let l):
                ledger = l
                log("registro lido do Keychain: \(l.used) de \(FreeClipLedger.limit) clipes gratuitos usados")
            case .corrupt:
                ledger = FreeClipLedger()
                log("registro do Keychain ilegível; recomeçando do zero (não bloqueia o usuário)")
            case .fresh:
                ledger = FreeClipLedger()
            }
            loaded = true
            readFailed = false
        case errSecItemNotFound:
            ledger = FreeClipLedger()
            loaded = true
            readFailed = false
            log("nenhum registro no Keychain (instalação nova ou registro apagado): 0 de \(FreeClipLedger.limit) usados")
        default:
            loaded = true
            readFailed = true
            log("ERRO ao ler o Keychain (código \(status)); não bloqueia o usuário e o registro existente não é alterado")
        }
    }

    /// Grava o registro inteiro. Chamar com o cadeado já fechado.
    private func saveLocked() {
        guard let data = ledger.encoded() else {
            log("ERRO: não foi possível codificar o registro")
            return
        }
        var status = SecItemUpdate(baseQuery as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var add = baseQuery
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            status = SecItemAdd(add as CFDictionary, nil)
        }
        if status != errSecSuccess {
            log("ERRO ao gravar no Keychain (código \(status)); a contagem vale só até fechar o app")
        }
    }

    /// Quantos clipes gratuitos já foram contados (0 se a leitura do Keychain falhou: erro nunca prejudica o usuário).
    var used: Int {
        if let simulated = AccessSimulation.shared.usedOverride { return simulated }
        lock.lock()
        defer { lock.unlock() }
        loadLocked()
        return readFailed ? 0 : ledger.used
    }

    /// Chamado ao abrir o app: só lê e registra no Diagnóstico (serve para o teste de reinstalação).
    func logAtLaunch() {
        lock.lock()
        defer { lock.unlock() }
        loadLocked()
    }

    /// Conta o clipe `id`, uma única vez. `source` diz de onde veio (gravação, recuperação).
    /// Devolve o total de usados se contou agora; nil se não contou (já contado, passou de 10 ou erro de leitura).
    @discardableResult
    func count(clipID id: UUID, source: String) -> Int? {
        if AccessSimulation.shared.isOn {
            let n = AccessSimulation.shared.increment()
            log("SIMULAÇÃO: clipe contado só na simulação (\(source)): \(n.map(String.init) ?? "já em 10"); o registro real não muda")
            if n != nil { NotificationCenter.default.post(name: .eiClipFreeCountChanged, object: nil) }
            return n
        }
        lock.lock()
        loadLocked()
        if readFailed {
            lock.unlock()
            log("clipe NÃO contado (\(source)): erro de leitura do Keychain")
            return nil
        }
        var counted: Int?
        switch ledger.record(id) {
        case .counted:
            saveLocked()
            counted = ledger.used
            log("clipe contado (\(source)): \(ledger.used) de \(FreeClipLedger.limit) usados, restam \(ledger.remaining)")
        case .alreadyCounted:
            log("clipe já estava contado (\(source)); nada muda: \(ledger.used) de \(FreeClipLedger.limit) usados")
        case .limitReached:
            log("clipe além dos \(FreeClipLedger.limit) (\(source)); contador segue em \(ledger.used)")
        }
        lock.unlock()
        if counted != nil { NotificationCenter.default.post(name: .eiClipFreeCountChanged, object: nil) }
        return counted
    }
}
