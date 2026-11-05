import Foundation
import UIKit

/// Registro de eventos do aparelho. Sem Xcode, este texto (botão "Copiar") é o nosso único log.
final class Diagnostics: ObservableObject {
    static let shared = Diagnostics()

    @Published private(set) var lines: [String] = []
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    /// Pode ser chamado de qualquer fila.
    func log(_ tag: String, _ message: String) {
        let now = Date()
        DispatchQueue.main.async {
            let line = "[\(self.formatter.string(from: now))] \(tag): \(message)"
            self.lines.append(line)
            if self.lines.count > 800 { self.lines.removeFirst(self.lines.count - 800) }
        }
    }

    func clear() {
        DispatchQueue.main.async { self.lines.removeAll() }
    }

    static var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }

    private var header: String {
        var sys = utsname()
        uname(&sys)
        let machine = withUnsafePointer(to: &sys.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) { String(cString: $0) }
        }
        let bundleId = Bundle.main.bundleIdentifier ?? "?"
        return "Ei Clip \(Diagnostics.appVersion) · \(machine) · iOS \(UIDevice.current.systemVersion) · \(bundleId)\n"
    }

    /// Texto completo para copiar.
    var text: String {
        header + lines.joined(separator: "\n")
    }
}
