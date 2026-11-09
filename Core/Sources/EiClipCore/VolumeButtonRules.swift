import Foundation

/// O que um aperto nos botões de volume faz na tela da câmera (v0.9.5): liga ou para a gravação, como o botão da tela e o
/// comando de voz.
public enum VolumeAction: Equatable {
    case start
    case stop
    /// Não vale agora; o texto vai para o Diagnóstico.
    case ignored(String)
}

public enum VolumeButtonRules {
    /// Dois apertos mais próximos que isto (segundos) contam como um só (mão molhada, aperto duplo sem querer).
    public static let minGap: TimeInterval = 0.8

    /// Versão mínima do iOS para os botões de volume como obturador (`AVCaptureEventInteraction`): 17.2.
    public static func isSupported(major: Int, minor: Int) -> Bool {
        major > 17 || (major == 17 && minor >= 2)
    }

    /// Decide o que fazer com um aperto (já liberado: o app trata a fase "soltou").
    public static func action(
        enabled: Bool, cameraOpen: Bool, testRunning: Bool, reconfiguring: Bool, overlayPresented: Bool,
        recording: Bool, stopping: Bool, startPending: Bool, sinceLast: TimeInterval
    ) -> VolumeAction {
        if !enabled { return .ignored("chave desligada em Ajustes") }
        if !cameraOpen { return .ignored("câmera fechada") }
        if testRunning { return .ignored("teste de aberturas em andamento") }
        if overlayPresented { return .ignored("há uma tela por cima (Ajustes, player ou aviso)") }
        if reconfiguring { return .ignored("a câmera está sendo reconfigurada") }
        if sinceLast < minGap { return .ignored("aperto repetido (menos de 0,8 s do anterior)") }
        if recording { return stopping ? .ignored("a gravação já está sendo encerrada") : .stop }
        if startPending { return .ignored("o início da gravação já está em andamento") }
        return .start
    }
}
