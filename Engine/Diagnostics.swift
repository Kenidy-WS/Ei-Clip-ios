import Foundation

/// Registro de eventos do aparelho. Sem Xcode, este texto (botão "Copiar") é o nosso único log.
/// Desde a v0.1.5 cada linha também é gravada num arquivo, para sobreviver ao fechamento do app:
/// ao abrir, a rodada que terminou vira "anterior" (botão "Copiar rodada anterior").
final class Diagnostics: ObservableObject {
    static let shared = Diagnostics()

    @Published private(set) var lines: [String] = []
    /// Texto completo da rodada anterior do app (vazio se não houve uma com conteúdo).
    let previousText: String

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private let fileQueue = DispatchQueue(label: "ei.diagnostics.file")
    private var handle: FileHandle?
    private var bytesWritten = 0
    /// Teto do arquivo de uma rodada (passou disso, só a tela continua registrando).
    private static let maxFileBytes = 3_000_000

    private init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("Diagnostico", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let current = dir.appendingPathComponent("atual.txt")
        let previous = dir.appendingPathComponent("anterior.txt")

        // Gira os arquivos: a rodada que acabou vira "anterior" (só se teve conteúdo de verdade,
        // para abrir o app duas vezes seguidas não apagar o registro que importa).
        let size = (try? fm.attributesOfItem(atPath: current.path)[.size] as? Int) ?? 0
        if size > 500 {
            try? fm.removeItem(at: previous)
            try? fm.moveItem(at: current, to: previous)
        }
        previousText = (try? String(contentsOf: previous, encoding: .utf8)) ?? ""

        fm.createFile(atPath: current.path, contents: nil)
        handle = try? FileHandle(forWritingTo: current)
        write(Diagnostics.makeHeader())
    }

    /// Pode ser chamado de qualquer fila.
    func log(_ tag: String, _ message: String) {
        let line = "[\(formatter.string(from: Date()))] \(tag): \(message)"
        write(line + "\n")
        DispatchQueue.main.async {
            self.lines.append(line)
            if self.lines.count > 800 { self.lines.removeFirst(self.lines.count - 800) }
        }
    }

    /// Limpa a tela e o arquivo da rodada atual (a rodada anterior fica como está).
    func clear() {
        DispatchQueue.main.async { self.lines.removeAll() }
        fileQueue.async {
            try? self.handle?.truncate(atOffset: 0)
            try? self.handle?.seek(toOffset: 0)
            self.bytesWritten = 0
        }
        write(Diagnostics.makeHeader())
    }

    /// Grava no arquivo da rodada atual, na ordem em que foi pedido.
    private func write(_ text: String) {
        fileQueue.async {
            guard let handle = self.handle, self.bytesWritten < Diagnostics.maxFileBytes,
                let data = text.data(using: .utf8)
            else { return }
            do {
                try handle.write(contentsOf: data)
                self.bytesWritten += data.count
            } catch {
                self.handle = nil
            }
        }
    }

    static var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }

    /// Modelo do aparelho (ex.: iPhone15,4).
    static var machineName: String {
        var sys = utsname()
        uname(&sys)
        return withUnsafePointer(to: &sys.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
    }

    private static func makeHeader() -> String {
        let machine = Diagnostics.machineName
        let bundleId = Bundle.main.bundleIdentifier ?? "?"
        // ProcessInfo (e não UIDevice) porque o cabeçalho também é montado fora da fila principal.
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let os = "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        return "Ei Clip \(Diagnostics.appVersion) · \(machine) · iOS \(os) · \(bundleId)\n"
    }

    /// Texto completo para copiar.
    var text: String {
        Diagnostics.makeHeader() + lines.joined(separator: "\n")
    }

    /// v0.3.10: cabeçalho + painel (seções) + registro, para o botão "Copiar".
    func fullText(panel: String) -> String {
        Diagnostics.makeHeader() + panel + "\n\n== Registro ==\n" + lines.joined(separator: "\n")
    }
}
