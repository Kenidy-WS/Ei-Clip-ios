import Foundation

/// Ambiente em que um registro do Keychain foi gravado (v0.9.48).
/// TestFlight usa o ambiente de teste da Apple (Sandbox); a App Store usa produção.
public enum RecordEnvironment: String, Codable, Equatable {
    case sandbox
    case production
}

/// O Keychain sobrevive à troca do TestFlight pela versão da loja. Estas regras impedem que o contador de clipes grátis
/// e o "permanente" de TESTE passem para o app oficial. Compra real não é afetada: o direito sempre é relido da Apple,
/// e o que a versão da loja grava sai marcado como produção e nunca é descartado.
public enum EnvironmentRules {
    public enum Decision: Equatable {
        case keep
        case discard
    }

    /// Descarta só quando o app aberto é o da loja e o registro NÃO foi gravado por uma versão da loja
    /// (marcado como Sandbox, ou sem marca, que é o caso de tudo o que o TestFlight gravou até a v0.9.47).
    /// Ambiente atual desconhecido: nunca descarta (reserva).
    public static func decide(recorded: RecordEnvironment?, current: RecordEnvironment?) -> Decision {
        guard current == .production else { return .keep }
        return recorded == .production ? .keep : .discard
    }

    /// Ambiente do app aberto, pelo nome do arquivo do recibo da Apple (TestFlight: "sandboxReceipt"; loja: "receipt").
    /// Qualquer outro caso (sem recibo, simulador, nome novo) é desconhecido.
    public static func detect(receiptFileName: String?) -> RecordEnvironment? {
        switch receiptFileName {
        case "sandboxReceipt": return .sandbox
        case "receipt": return .production
        default: return nil
        }
    }
}
