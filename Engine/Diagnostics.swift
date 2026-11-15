import Foundation

/// Registro de eventos do aparelho. Sem Xcode, este texto é o nosso único log.
/// Desde a v0.1.5 cada linha também é gravada num arquivo, para sobreviver ao fechamento do app:
/// ao abrir, a rodada que terminou vira "anterior".
/// v0.9.11: sai como arquivo .txt pela folha de compartilhar do iOS ("Compartilhar" e "Compartilhar rodada anterior");
/// o antigo "Copiar" travava o aparelho com registros grandes. O arquivo da rodada atual leva o registro completo
/// (a tela só guarda as últimas 800 linhas).
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
    /// v0.9.11: arquivo da rodada atual (para montar o .txt de compartilhar).
    private var currentURL: URL?
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
        currentURL = current
        write(Diagnostics.makeHeader())
    }

    /// Pode ser chamado de qualquer fila.
    func log(_ tag: String, _ message: String) {
        let line = "[\(formatter.string(from: Date()))] \(tag): \(message)"
        write(line + "\n")
        DispatchQueue.main.async {
            MainMark.run("registro") {
                self.lines.append(line)
                if self.lines.count > 800 { self.lines.removeFirst(self.lines.count - 800) }
            }
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

    /// v0.3.10: cabeçalho + painel (seções) + registro. v0.9.11: o registro vem do arquivo da rodada (completo); se o
    /// arquivo não puder ser lido, a reserva são as linhas da tela.
    func fullText(panel: String) -> String {
        let fromFile: String? = fileQueue.sync { () -> String? in
            guard let url = currentURL, let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty else { return nil }
            return text
        }
        let record = fromFile ?? (Diagnostics.makeHeader() + lines.joined(separator: "\n"))
        return Diagnostics.makeHeader() + panel + "\n\n== Registro ==\n" + record
    }

    // MARK: - Compartilhar (v0.9.11)

    private static var exportFolder: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("diagnostico", isDirectory: true)
    }

    /// Grava o texto num .txt temporário para a folha de compartilhar. Nulo se não foi possível gravar.
    static func exportFile(_ text: String, kind: String) -> URL? {
        let fm = FileManager.default
        try? fm.removeItem(at: exportFolder)
        do {
            try fm.createDirectory(at: exportFolder, withIntermediateDirectories: true)
            let stamp = DateFormatter()
            stamp.dateFormat = "yyyyMMdd-HHmm"
            let url = exportFolder.appendingPathComponent("EiClip-diagnostico-\(kind)-\(stamp.string(from: Date())).txt")
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    /// Apaga o .txt temporário (ao fechar a folha de compartilhar).
    static func cleanUpExport() {
        try? FileManager.default.removeItem(at: exportFolder)
    }
}
