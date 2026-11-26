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
    /// Ambiente em que o registro foi gravado (v0.9.48; nil nos registros antigos).
    public var environment: RecordEnvironment?

    /// Repetidos e excesso (mais de 10) são descartados ao montar, mantendo a ordem de chegada.
    public init(clipIDs: [UUID] = [], environment: RecordEnvironment? = nil) {
        self.environment = environment
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

/// O que veio do registro guardado (Keychain), já interpretado.
public enum LedgerLoad: Equatable {
    /// Nada guardado (instalação nova ou registro apagado): começa em zero.
    case fresh
    case loaded(FreeClipLedger)
    /// Havia dados, mas não dá para ler: a Engine recomeça em zero e registra no Diagnóstico.
    case corrupt
}

extension FreeClipLedger {
    /// Interpreta os bytes guardados. Repetidos e excesso são descartados (o registro nunca passa de 10).
    public static func load(from data: Data?) -> LedgerLoad {
        guard let data = data else { return .fresh }
        guard let decoded = try? JSONDecoder().decode(FreeClipLedger.self, from: data) else { return .corrupt }
        return .loaded(FreeClipLedger(clipIDs: decoded.clipIDs, environment: decoded.environment))
    }

    /// Bytes para guardar (JSON).
    public func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }
}

/// Quando um clipe vale como clipe gratuito usado.
public enum FreeClipRules {
    /// O arquivo está pronto e é válido (tamanho e duração mínimos, os mesmos da recuperação de gravações)?
    public static func isCountable(bytes: Int, durationSec: Double) -> Bool {
        bytes >= RecordingFiles.minRecoverableBytes
            && durationSec.isFinite
            && durationSec >= RecordingFiles.minRecoverableSeconds
    }
}
