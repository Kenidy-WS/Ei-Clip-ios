import Foundation

/// Resultado de tentar contar um clipe gratuito.
public enum LedgerRecordResult: Equatable {
    /// Contou agora.
    case counted
    /// Esse mesmo clipe (mesmo UUID) já estava contado: nada muda.
    case alreadyCounted
    /// Os 10 já foram usados: não passa de 10.
    case limitReached
}

/// Contador dos 10 clipes gratuitos (C2, etapa 1; lógica pura, sem Keychain).
///
/// Guarda a lista dos UUIDs dos clipes já contados, na ordem. O número de clipes usados é sempre o tamanho da lista
/// (nunca um número solto que alguém soma), então contar duas vezes o mesmo clipe não muda nada.
/// A gravação do registro no Keychain e o ponto único de contagem ficam para a etapa 2.
public struct FreeClipLedger: Equatable, Codable {
    /// Quantidade de clipes gratuitos.
    public static let limit = 10

    public private(set) var clipIDs: [UUID]

    /// Repetidos e excesso (mais de 10) são descartados ao montar, mantendo a ordem de chegada.
    public init(clipIDs: [UUID] = []) {
        var seen = Set<UUID>()
        var clean: [UUID] = []
        for id in clipIDs where !seen.contains(id) {
            if clean.count >= FreeClipLedger.limit { break }
            seen.insert(id)
            clean.append(id)
        }
        self.clipIDs = clean
    }

    /// Clipes já contados.
    public var used: Int { clipIDs.count }

    /// Clipes gratuitos que ainda restam (0 a 10).
    public var remaining: Int { max(0, FreeClipLedger.limit - clipIDs.count) }

    public func contains(_ id: UUID) -> Bool { clipIDs.contains(id) }

    /// Conta o clipe `id`, uma única vez.
    @discardableResult
    public mutating func record(_ id: UUID) -> LedgerRecordResult {
        if clipIDs.contains(id) { return .alreadyCounted }
        if clipIDs.count >= FreeClipLedger.limit { return .limitReached }
        clipIDs.append(id)
        return .counted
    }
}
