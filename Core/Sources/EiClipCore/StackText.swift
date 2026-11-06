import Foundation

/// v0.6.22: texto das "fotografias" das linhas de execução (pilhas) que o vigia registra quando a tela trava.
public enum StackText {
    /// Linhas de execução paradas esperando trabalho: não interessam e são omitidas (só contadas).
    public static let idleTopSymbols: Set<String> = ["__workq_kernreturn"]

    public static func isIdle(topSymbol: String) -> Bool {
        idleTopSymbols.contains(topSymbol)
    }

    /// Uma linha: "rótulo: topo < ... < base". Corta cada nome em `maxSymbolLength` e a pilha em `maxFrames`.
    public static func line(label: String, symbols: [String], maxFrames: Int = 12, maxSymbolLength: Int = 70) -> String {
        guard !symbols.isEmpty else { return "\(label): (sem pilha)" }
        let cut = symbols.prefix(maxFrames).map { name -> String in
            name.count > maxSymbolLength ? String(name.prefix(maxSymbolLength - 1)) + "…" : name
        }
        return "\(label): " + cut.joined(separator: " < ")
    }
}
