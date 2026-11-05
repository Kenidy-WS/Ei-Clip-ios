import Foundation

/// Resolução pedida à câmera (altura em pixels).
public enum VideoQuality: Int {
    case p720 = 720
    case p1080 = 1080
    case p2160 = 2160

    public var size: (width: Int, height: Int) {
        switch self {
        case .p720: return (1280, 720)
        case .p1080: return (1920, 1080)
        case .p2160: return (3840, 2160)
        }
    }
}

/// Qualidade de imagem: Padrão / Alta / Máxima.
public enum ImageQuality: Int {
    case standard = 0
    case high = 1
    case maximum = 2
}

/// Teto de taxa de vídeo.
public let maxVideoBitrate = 50_000_000

/// Mbps a 30 fps para Padrão / Alta / Máxima (mesma tabela do web app, `core/video-profile.ts`).
private func baseMbps(_ q: VideoQuality) -> [Double] {
    switch q {
    case .p720: return [8, 12, 16]
    case .p1080: return [16, 22, 28]
    case .p2160: return [30, 38, 45]
    }
}

/// Taxa de vídeo em bits/s. 60 fps precisa de mais taxa, mas não o dobro (fator 1,25).
public func videoBitrate(_ q: VideoQuality, fps: Int, level: ImageQuality) -> Int {
    let k: Double = fps > 30 ? 1.25 : 1
    let value = (baseMbps(q)[level.rawValue] * 1e6 * k).rounded()
    return min(maxVideoBitrate, Int(value))
}
