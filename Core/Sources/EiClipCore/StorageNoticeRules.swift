import Foundation

// v0.9.30: o aviso de espaço da câmera mostra minutos que dependem da qualidade escolhida. Ao abrir a câmera (inclusive ao trocar
// a qualidade nos Ajustes) o aviso que ficou na tela precisa acompanhar a qualidade nova.

/// O que fazer com um aviso de espaço que já está na tela quando a câmera abre.
public enum StorageNoticeOnOpen: Equatable {
    /// Há espaço de sobra: o aviso antigo já não vale e sai da tela.
    case clearOld
    /// Continua pouco espaço: o aviso novo (com os minutos novos) entra no lugar do antigo, mesmo que o antigo fosse mais pesado.
    case replaceOld
}

public enum StorageNoticeRules {
    public static func onOpen(level: StorageLevel) -> StorageNoticeOnOpen {
        level == .ok ? .clearOld : .replaceOld
    }
}

/// v0.9.30: a Apple avisa a loja atual assim que o app começa a escutar `Storefront.updates`. Só vale reler se a loja (ou a moeda)
/// for diferente da última lida; sem leitura anterior, a primeira leitura de produtos já pega a loja atual.
public enum StorefrontRules {
    public static func shouldReload(last: String?, current: String) -> Bool {
        guard let last else { return false }
        return last != current
    }
}
