import Photos

/// Apaga clipes do Rolo (v0.4.11). O iOS mostra a PRÓPRIA confirmação ("Apagar N vídeos?"); não dá para trocá-la nem
/// dispensá-la. Os clipes vão para "Apagados recentemente" das Fotos (ficam lá por 30 dias, dá para recuperar).
enum PhotoDeleter {
    /// true se foram apagados; false se o usuário cancelou na confirmação do iOS ou se houve erro.
    static func delete(_ assets: [PHAsset]) async -> Bool {
        guard !assets.isEmpty else { return false }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            } completionHandler: { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
