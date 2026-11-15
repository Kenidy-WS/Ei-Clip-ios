import AVFoundation
import Photos

/// Detalhes técnicos de um clipe do Rolo (v0.4.4), lidos do próprio arquivo quando o usuário abre o cartão de detalhes.
/// O Fotos não guarda a "pré-gravação" do clipe, então essa linha do web app não existe aqui.
struct ClipInfo {
    var sizeBytes: Int64?
    var fps: Double?
    var bitsPerSecond: Double?
    var hasAudio: Bool?
    /// v0.9.11: lente do começo da gravação, lida da etiqueta nos metadados do arquivo (nulo em clipes sem etiqueta).
    var lens: String?

    static func load(for asset: PHAsset) async -> ClipInfo {
        let avAsset: AVAsset? = await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                continuation.resume(returning: avAsset)
            }
        }
        var info = ClipInfo()
        guard let avAsset else { return info }
        if let url = (avAsset as? AVURLAsset)?.url,
            let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize
        {
            info.sizeBytes = Int64(size)
        }
        if let video = try? await avAsset.loadTracks(withMediaType: .video).first {
            if let fps = try? await video.load(.nominalFrameRate), fps > 0 { info.fps = Double(fps) }
            if let rate = try? await video.load(.estimatedDataRate), rate > 0 { info.bitsPerSecond = Double(rate) }
        }
        if let audio = try? await avAsset.loadTracks(withMediaType: .audio) {
            info.hasAudio = !audio.isEmpty
        }
        info.lens = await lens(of: avAsset)
        return info
    }

    /// Procura a etiqueta do Ei Clip em todos os metadados do arquivo (o iOS pode guardá-la em mais de um formato).
    private static func lens(of avAsset: AVAsset) async -> String? {
        var items = (try? await avAsset.load(.metadata)) ?? []
        if let formats = try? await avAsset.load(.availableMetadataFormats) {
            for format in formats {
                if let more = try? await avAsset.loadMetadata(for: format) { items.append(contentsOf: more) }
            }
        }
        for item in items {
            if let text = try? await item.load(.stringValue), let lens = ClipTag.lens(from: text) {
                Diagnostics.shared.log("detalhes", "lente lida do arquivo: \(lens)")
                return lens
            }
        }
        Diagnostics.shared.log("detalhes", "arquivo sem etiqueta de lente (\(items.count) item(ns) de metadados)")
        return nil
    }
}
