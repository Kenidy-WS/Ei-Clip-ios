import Foundation
import Security

/// C2, etapa 6: último acesso CONFIRMADO pela Apple, guardado no Keychain (sobrevive ao fechar o app e, em geral, à reinstalação).
///
/// Serve à tolerância offline: sem resposta da Apple, o gate usa este registro. As regras são puras (`ConfirmedAccessRules`).
/// Falha técnica de leitura ou gravação NUNCA prejudica o usuário (segue com o que há na memória) e vai para o Diagnóstico.
final class ConfirmedAccessStore {
    static let shared = ConfirmedAccessStore()

    private let service = "app.eiclip.access"
    private let account = "confirmed"
    private let lock = NSLock()
    private var record = LastConfirmed.none
    private var loaded = false

    private func log(_ text: String) { Diagnostics.shared.log("acesso confirmado", text) }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
    }

    private func loadLocked() {
        if loaded { return }
        loaded = true
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            switch ConfirmedAccessRules.load(from: item as? Data) {
            case .loaded(let r):
                record = r
                log("registro lido do Keychain: \(describe(r))")
            case .corrupt:
                record = .none
                log("registro do Keychain ilegível; recomeçando sem acesso confirmado")
            case .fresh:
                record = .none
            }
        case errSecItemNotFound:
            record = .none
            log("nenhum registro no Keychain (instalação nova ou ainda sem confirmação da Apple)")
        default:
            record = .none
            log("ERRO ao ler o Keychain (código \(status)); segue só com a resposta da Apple")
        }
    }

    private func saveLocked() {
        guard let data = ConfirmedAccessRules.encoded(record) else {
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
            log("ERRO ao gravar no Keychain (código \(status)); o registro vale só até fechar o app")
        }
    }

    private func describe(_ r: LastConfirmed) -> String {
        let end = r.subscriptionPeriodEnd.map { Self.formatter.string(from: $0) } ?? "sem período"
        let seen = r.latestSeen.map { Self.formatter.string(from: $0) } ?? "nunca"
        return "permanente=\(r.permanent ? "sim" : "não"), fim do período pago=\(end), maior data vista=\(seen)"
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "dd/MM/yyyy HH:mm"
        return f
    }()

    /// O registro atual (lido do Keychain na primeira vez).
    var current: LastConfirmed {
        lock.lock()
        defer { lock.unlock() }
        loadLocked()
        return record
    }

    /// Chamado ao abrir o app: lê e registra no Diagnóstico.
    func logAtLaunch() { _ = current }

    /// A data a usar nas contas de acesso: nunca menor que a maior já vista. Também avança a maior data vista.
    func effectiveNow(_ now: Date = Date()) -> Date {
        lock.lock()
        defer { lock.unlock() }
        loadLocked()
        let effective = ConfirmedAccessRules.effectiveNow(now: now, last: record)
        let advanced = ConfirmedAccessRules.advance(record, now: now)
        record = advanced.record
        if advanced.shouldPersist { saveLocked() }
        if effective > now.addingTimeInterval(60) {
            log("relógio do aparelho está atrás da maior data já vista; usando a maior data (\(Self.formatter.string(from: effective)))")
        }
        return effective
    }

    /// Aplica uma resposta VÁLIDA (ou a falta dela) da Apple e grava. Devolve o registro novo.
    @discardableResult
    func apply(answer: StoreAnswer, now: Date = Date()) -> LastConfirmed {
        lock.lock()
        defer { lock.unlock() }
        loadLocked()
        let before = record
        record = ConfirmedAccessRules.updated(record, with: answer, now: now)
        let changed = before.permanent != record.permanent
            || before.subscriptionPeriodEnd != record.subscriptionPeriodEnd
            || before.everPermanent != record.everPermanent
            || before.everSubscribed != record.everSubscribed
        if case .answered = answer {
            saveLocked()
            if changed { log("registro atualizado pela Apple: \(describe(record))") }
        } else {
            saveLocked()
        }
        return record
    }
}
