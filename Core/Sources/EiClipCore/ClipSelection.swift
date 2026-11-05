import Foundation

/// Seleção de clipes na Galeria (v0.4.12). Guarda os identificadores escolhidos; a ordem da Galeria vem de fora.
public struct ClipSelection: Equatable {
    public private(set) var ids: Set<String> = []

    public init() {}

    public var count: Int { ids.count }
    public var isEmpty: Bool { ids.isEmpty }

    public func contains(_ id: String) -> Bool { ids.contains(id) }

    /// Toca num clipe: seleciona se não estava, tira se estava.
    public mutating func toggle(_ id: String) {
        if ids.contains(id) { ids.remove(id) } else { ids.insert(id) }
    }

    public mutating func selectAll(_ all: [String]) { ids = Set(all) }

    public mutating func clear() { ids = [] }

    public mutating func replace(with newIds: Set<String>) { ids = newIds }

    /// Só os escolhidos que ainda existem na lista (clipe apagado por fora sai da seleção), na ordem da lista.
    public func ordered(in all: [String]) -> [String] { all.filter { ids.contains($0) } }

    /// "Todos" vira "Nenhum" quando tudo já está escolhido.
    public func allSelected(in all: [String]) -> Bool { !all.isEmpty && all.allSatisfy { ids.contains($0) } }
}

/// Seleção arrastando o dedo (v0.4.13): do clipe onde o dedo começou (`anchor`) até o clipe onde ele está (`current`), em
/// índices da lista, nos dois sentidos. O que já estava escolhido antes do arrasto (`base`) continua; voltar o dedo desmarca
/// só o que o arrasto tinha marcado.
public func dragSelection(base: Set<String>, ids: [String], anchor: Int, current: Int) -> Set<String> {
    guard !ids.isEmpty else { return base }
    let low = max(0, min(anchor, current))
    let high = min(ids.count - 1, max(anchor, current))
    guard low <= high else { return base }
    return base.union(ids[low...high])
}
