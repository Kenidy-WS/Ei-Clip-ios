import Foundation

/// Qual câmera usar (v0.5.7; a troca de lente e a câmera frontal chegam na etapa 6).
public enum CameraPosition: String, Equatable {
    case back
    case front
}

/// Ajustes de captura num valor só (v0.5.7): qualidade, quadros por segundo, qualidade de imagem e câmera. O padrão é o
/// mesmo de antes (1080p, 30 fps, imagem padrão, câmera traseira). `validated` impede combinações que o aparelho não faz.
public struct CaptureConfig: Equatable {
    public var quality: VideoQuality
    public var fps: Int
    public var imageLevel: ImageQuality
    public var position: CameraPosition
    /// v0.6.6: estabilização de imagem (desligada por padrão: pode cortar um pouco das bordas).
    public var stabilize: Bool
    /// v0.6.10: lente da câmera traseira (a frontal só tem a principal).
    public var lens: Lens

    public static let supportedFps = [30, 60]
    public static let standard = CaptureConfig(quality: .p1080, fps: 30, imageLevel: .standard, position: .back, stabilize: false)

    public init(
        quality: VideoQuality, fps: Int, imageLevel: ImageQuality, position: CameraPosition, stabilize: Bool = false,
        lens: Lens = .wide
    ) {
        self.lens = lens
        self.stabilize = stabilize
        self.quality = quality
        self.fps = fps
        self.imageLevel = imageLevel
        self.position = position
    }

    /// A outra câmera (v0.6.9).
    public var flipped: CameraPosition { position == .back ? .front : .back }

    /// Versão corrigida: fps desconhecido vira 30; 4K fica em 30 fps; câmera frontal fica em no máximo 1080p.
    public func validated() -> CaptureConfig {
        var config = self
        if !Self.supportedFps.contains(config.fps) { config.fps = 30 }
        if config.quality == .p2160 { config.fps = 30 }
        if config.position == .front && config.quality == .p2160 { config.quality = .p1080 }
        if config.position == .front { config.lens = .wide }
        return config
    }

    /// Taxa de vídeo em bits/s para esta configuração.
    public var bitrate: Int { videoBitrate(quality, fps: fps, level: imageLevel) }

    /// v0.7.0: texto da faixa do topo da câmera, como no app Câmera do iPhone: "4K 30", "1080 60", "720 30". Mostra o que está
    /// ESCOLHIDO para a câmera em uso (a frontal fica em no máximo 1080p; 4K fica em 30 fps), não o que o aparelho entregou
    /// (isso está no Diagnóstico). Só texto: não publica nada novo na tela.
    public func stripText(position: CameraPosition) -> String {
        var config = self
        config.position = position
        config = config.validated()
        let resolution = config.quality == .p2160 ? "4K" : "\(config.quality.rawValue)"
        return "\(resolution) \(config.fps)"
    }

    /// v0.7.14: texto da faixa com o valor REAL. Com a câmera aberta mostra a configuração efetiva (já com a redução por calor
    /// e com o fps que o formato aceitou); com a câmera fechada ou reabrindo, mostra a escolhida. Só texto, não publica nada.
    public static func liveStripText(chosen: CaptureConfig, effective: CaptureConfig, opened: Bool, position: CameraPosition) -> String {
        (opened ? effective : chosen).stripText(position: position)
    }

    /// Texto curto para o Diagnóstico, por exemplo "1080p · 30 fps · padrão".
    public var summary: String {
        let level: String
        switch imageLevel {
        case .standard: level = "padrão"
        case .high: level = "alta"
        case .maximum: level = "máxima"
        }
        return "\(quality.rawValue)p · \(fps) fps · \(level)" + (stabilize ? " · estabilizada" : "")
            + (position == .front ? " · câmera frontal" : "")
            + (lens == .wide ? "" : " · lente \(lens.label)")
    }
}
