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
