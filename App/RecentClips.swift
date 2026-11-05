import Photos
import SwiftUI

/// Os clipes mais recentes do álbum "Ei Clip" do Rolo (v0.3.1). Não pede permissão: só lê quando as Fotos já foram autorizadas
/// (o pedido acontece ao abrir a câmera pela primeira vez).
final class RecentClips: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    struct Item: Identifiable {
        let asset: PHAsset
        var id: String { asset.localIdentifier }
    }

    /// Quantos aparecem no Início (igual ao web app).
    static let count = 4

    @Published private(set) var items: [Item] = []
    private var observing = false

    deinit {
        if observing { PHPhotoLibrary.shared().unregisterChangeObserver(self) }
    }

    func reload() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard status == .authorized || status == .limited else {
            items = []
            return
        }
        if !observing {
            PHPhotoLibrary.shared().register(self)  // só depois de autorizado, para não provocar o pedido de permissão
            observing = true
        }
        let albumOptions = PHFetchOptions()
        albumOptions.predicate = NSPredicate(format: "title = %@", PhotoSaver.albumTitle)
        guard
            let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: albumOptions)
                .firstObject
        else {
            items = []
            return
        }
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.fetchLimit = Self.count
        var list: [Item] = []
        PHAsset.fetchAssets(in: album, options: options).enumerateObjects { asset, _, _ in
            list.append(Item(asset: asset))
        }
        items = list
    }

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in self?.reload() }
    }
}

/// Miniatura de um clipe (proporção 3:4, cantos arredondados, duração no canto), como no web app.
struct ClipTile: View {
    let asset: PHAsset
    var aspect: CGFloat = 3.0 / 4.0
    var showsDuration = true
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color(red: 0.11, green: 0.11, blue: 0.12)  // #1c1c1e
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "camera")
                    .foregroundColor(Color.white.opacity(0.3))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            if showsDuration {
                Text(formatDuration(asset.duration))
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                    .padding(.leading, 7)
                    .padding(.bottom, 5)
            }
        }
        .aspectRatio(aspect, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onAppear(perform: loadThumbnail)
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: asset, targetSize: CGSize(width: 300, height: 400), contentMode: .aspectFill, options: options
        ) { result, _ in
            if let result { image = result }
        }
    }
}
