import AVFoundation

/// ÁREA PROTEGIDA (sessão de áudio): mudanças aqui vão sozinhas numa versão.
///
/// A sessão de áudio do app é configurada à mão (a captura NÃO a configura sozinha), para sabermos
/// exatamente em que estado o microfone abriu. O estado é registrado no Diagnóstico.
enum AudioSessionConfig {
    static func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker])
        try session.setActive(true)
    }

    /// v0.4.17: sessão do PLAYER. Categoria de reprodução (volume normal e som mesmo com o botão de silencioso ligado); o
    /// microfone não é usado. Só vale com a câmera FECHADA (a raiz espera o fechamento antes de abrir o player). Ao abrir a câmera
    /// de novo, `activate()` volta para `playAndRecord`: a câmera já refaz a categoria a cada abertura.
    static func activatePlayback() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .moviePlayback, options: [])
        try session.setActive(true)
    }

    static func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    static func describe() -> String {
        let s = AVAudioSession.sharedInstance()
        let ins = s.currentRoute.inputs.map { "\($0.portName)(\($0.portType.rawValue))" }.joined(separator: ",")
        let outs = s.currentRoute.outputs.map { "\($0.portName)(\($0.portType.rawValue))" }.joined(separator: ",")
        return "cat=\(s.category.rawValue) modo=\(s.mode.rawValue) \(Int(s.sampleRate))Hz "
            + "entrada=[\(ins)] saída=[\(outs)] entradaDisponível=\(s.isInputAvailable) "
            + "outroÁudioTocando=\(s.isOtherAudioPlaying)"
    }
}
