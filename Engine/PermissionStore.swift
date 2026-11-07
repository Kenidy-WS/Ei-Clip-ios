import AVFoundation
import Foundation

extension Notification.Name {
    /// v0.7.7: o motor avisa a tela que, nesta abertura, uma permissão foi negada ou ficou sem resposta (userInfo["issues"]).
    static let eiClipPermissionNotice = Notification.Name("eiClipPermissionNotice")
}

/// v0.7.6: o que o app já pediu ao sistema (guardado no aparelho) e a situação atual das quatro permissões.
enum PermissionStore {
    static let ledger = PermissionLedger(store: UserDefaults.standard)

    /// A situação das permissões que o app usa agora (a voz só conta se o comando de voz está ligado).
    static func statuses(voiceEnabled: Bool) -> [PermissionStatus] {
        var list = [
            PermissionStatus(
                kind: .camera, state: DiagSystemInfo.state(AVCaptureDevice.authorizationStatus(for: .video)),
                askedBefore: ledger.wasAsked(.camera)),
            PermissionStatus(
                kind: .microphone, state: DiagSystemInfo.state(AVCaptureDevice.authorizationStatus(for: .audio)),
                askedBefore: ledger.wasAsked(.microphone)),
        ]
        if voiceEnabled {
            list.append(PermissionStatus(kind: .speech, state: DiagSystemInfo.speechState(), askedBefore: ledger.wasAsked(.speech)))
        }
        list.append(PermissionStatus(kind: .photos, state: DiagSystemInfo.photosState(), askedBefore: ledger.wasAsked(.photos)))
        return list
    }

    /// Texto para o Diagnóstico: quais permissões o app já pediu.
    static func askedText() -> String {
        let names: [(PermissionKind, String)] = [(.camera, "câmera"), (.microphone, "microfone"), (.speech, "voz"), (.photos, "Fotos")]
        return names.map { "\($0.1) \(ledger.wasAsked($0.0) ? "sim" : "não")" }.joined(separator: " · ")
    }
}
