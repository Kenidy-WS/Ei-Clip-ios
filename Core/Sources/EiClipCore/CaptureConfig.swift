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

    public static let supportedFps = [30, 60]
    public static let standard = CaptureConfig(quality: .p1080, fps: 30, imageLevel: .standard, position: .back)

    public init(quality: VideoQuality, fps: Int, imageLevel: ImageQuality, position: CameraPosition) {
        self.quality = quality
        self.fps = fps
        self.imageLevel = imageLevel
        self.position = position
    }

    /// Versão corrigida: fps desconhecido vira 30; 4K fica em 30 fps; câmera frontal fica em no máximo 1080p.
    public func validated() -> CaptureConfig {
        var config = self
        if !Self.supportedFps.contains(config.fps) { config.fps = 30 }
        if config.quality == .p2160 { config.fps = 30 }
        if config.position == .front && config.quality == .p2160 { config.quality = .p1080 }
        return config
    }

    /// Taxa de vídeo em bits/s para esta configuração.
    public var bitrate: Int { videoBitrate(quality, fps: fps, level: imageLevel) }

    /// Texto curto para o Diagnóstico, por exemplo "1080p · 30 fps · padrão".
    public var summary: String {
        let level: String
        switch imageLevel {
        case .standard: level = "padrão"
        case .high: level = "alta"
        case .maximum: level = "máxima"
        }
        return "\(quality.rawValue)p · \(fps) fps · \(level)"
    }
}
