import Photos

/// Salva o clipe no Rolo da Câmera, dentro do álbum "Ei Clip" (sem galeria própria).
enum PhotoSaver {
    static let albumTitle = "Ei Clip"

    static func requestAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    private static func existingAlbum() -> PHAssetCollection? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", albumTitle)
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options)
        return result.firstObject
    }

    /// Devolve uma descrição do resultado (para o Diagnóstico). Lança erro se não salvou.
    static func save(_ url: URL) async throws -> String {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw NSError(
                domain: "EiClip", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "sem permissão para as Fotos (status \(status.rawValue))"])
        }
        let album = existingAlbum()
        var placeholderId = ""
        try await PHPhotoLibrary.shared().performChanges {
            guard
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url),
                let placeholder = request.placeholderForCreatedAsset
            else { return }
            placeholderId = placeholder.localIdentifier
            if let album, let albumRequest = PHAssetCollectionChangeRequest(for: album) {
                albumRequest.addAssets([placeholder] as NSArray)
            } else {
                let create = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumTitle)
                create.addAssets([placeholder] as NSArray)
            }
        }
        let how = album == nil ? "álbum criado" : "álbum existente"
        return placeholderId.isEmpty ? "salvo (\(how)), sem id" : "salvo (\(how)) id=\(placeholderId)"
    }
}
