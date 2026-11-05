import AVFoundation
import Photos
import UIKit

/// v0.3.10: leituras do sistema para o painel do Diagnóstico. Só leitura: nada aqui pede permissão ao usuário.
enum DiagSystemInfo {
    static func permission(_ status: AVAuthorizationStatus) -> (text: String, blocked: Bool) {
        switch status {
        case .authorized: return ("permitida", false)
        case .denied: return ("NEGADA", true)
        case .restricted: return ("RESTRITA", true)
        case .notDetermined: return ("ainda não pedida", false)
        @unknown default: return ("?", false)
        }
    }

    /// Fotos: o álbum "Ei Clip" exige acesso completo; "limitada" também conta como problema.
    static func photos() -> (text: String, notFull: Bool) {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: return ("completa", false)
        case .limited: return ("LIMITADA", true)
        case .denied: return ("NEGADA", true)
        case .restricted: return ("RESTRITA", true)
        case .notDetermined: return ("ainda não pedida", false)
        @unknown default: return ("?", false)
        }
    }

    static func thermal() -> (text: String, severe: Bool) {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return ("normal", false)
        case .fair: return ("morno", false)
        case .serious: return ("quente", true)
        case .critical: return ("crítico", true)
        @unknown default: return ("?", false)
        }
    }

    static func appStateName(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "ativo"
        case .inactive: return "inativo"
        case .background: return "segundo plano"
        @unknown default: return "?"
        }
    }
}

/// v0.3.10: os últimos inícios do app (para ver se o iOS encerrou o app e ele recomeçou). Guardado no aparelho.
enum LaunchLog {
    private static let key = "launchTimes"
    private static let keep = 6
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM HH:mm:ss"
        return f
    }()

    /// Anota este início do app (guarda os 6 últimos).
    static func record() {
        var times = UserDefaults.standard.array(forKey: key) as? [Double] ?? []
        times.append(Date().timeIntervalSince1970)
        UserDefaults.standard.set(Array(times.suffix(keep)), forKey: key)
    }

    static func text() -> String {
        let times = UserDefaults.standard.array(forKey: key) as? [Double] ?? []
        if times.isEmpty { return "-" }
        return times.map { formatter.string(from: Date(timeIntervalSince1970: $0)) }.joined(separator: " · ")
    }
}
