import AVFoundation
import UIKit

/// Miniatura própria do clipe (v0.6.15). A miniatura que as Fotos geram é o PRIMEIRO quadro do vídeo; com a pré-gravação longa o
/// clipe começa logo depois de a câmera abrir, quando a exposição ainda se ajusta (quadro escuro). Aqui a imagem é tirada do
/// momento do comando, ainda do arquivo local, antes de ele ir para as Fotos, e guardada em disco ligada ao identificador do
/// vídeo. Clipes antigos (sem miniatura própria) seguem usando a das Fotos.
enum ThumbnailStore {
    private static var folder: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let url = base.appendingPathComponent("Miniaturas", isDirectory: true)
        if !fm.fileExists(atPath: url.path) { try? fm.createDirectory(at: url, withIntermediateDirectories: true) }
        return url
    }

    private static func file(for id: String) -> URL {
        let safe = id.map { $0.isLetter || $0.isNumber || $0 == "-" ? String($0) : "_" }.joined()
        return folder.appendingPathComponent(safe + ".jpg")
    }

    /// Tira um quadro do arquivo no instante pedido (em segundos).
    static func makeImage(from url: URL, at seconds: Double) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = Thumbnails.size
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
        let t = duration > 0.2 ? min(max(0, seconds), duration - 0.1) : 0
        let time = CMTime(seconds: t, preferredTimescale: 600)
        return await withCheckedContinuation { cont in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                cont.resume(returning: image.map { UIImage(cgImage: $0) })
            }
        }
    }

    static func save(_ image: UIImage, id: String) {
        guard !id.isEmpty, let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: file(for: id), options: .atomic)
        Thumbnails.remember(image, id: id)
    }

    static func load(id: String) -> UIImage? {
        guard let data = try? Data(contentsOf: file(for: id)) else { return nil }
        return UIImage(data: data)
    }
}
