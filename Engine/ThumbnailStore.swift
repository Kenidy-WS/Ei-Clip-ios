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

    /// Tira a miniatura do arquivo: tenta o instante pedido e, se o quadro sair escuro, outros instantes do clipe (v0.6.17).
    static func makeImage(from url: URL, at seconds: Double) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let duration = (try? await asset.load(.duration)).map { CMTimeGetSeconds($0) } ?? 0
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = Thumbnails.size
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        var images: [UIImage] = []
        var lumas: [Double] = []
        // O primeiro instante é o pedido; os demais só entram se o anterior for escuro.
        let times = ThumbnailRules.candidateTimes(preSec: max(0, seconds - 0.3), duration: duration)
        for t in times {
            guard let image = await frame(generator, at: t) else { continue }
            let luma = meanLuma(image)
            images.append(image)
            lumas.append(luma)
            if !ThumbnailRules.isTooDark(luma) { break }
        }
        guard let index = ThumbnailRules.pick(lumas: lumas) else { return nil }
        return images[index]
    }

    private static func frame(_ generator: AVAssetImageGenerator, at seconds: Double) async -> UIImage? {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        return await withCheckedContinuation { cont in
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, _ in
                cont.resume(returning: image.map { UIImage(cgImage: $0) })
            }
        }
    }

    /// Brilho médio da imagem (0 a 1), numa reduçao de 16x16 em tons de cinza.
    private static func meanLuma(_ image: UIImage) -> Double {
        guard let cg = image.cgImage else { return 1 }
        let side = 16
        var pixels = [UInt8](repeating: 0, count: side * side)
        let ok = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard
                let context = CGContext(
                    data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side,
                    space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
            else { return false }
            context.interpolationQuality = .low
            context.draw(cg, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard ok else { return 1 }
        return Double(pixels.reduce(0) { $0 + Int($1) }) / Double(pixels.count * 255)
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
