import Photos
import UIKit

/// Miniaturas dos clipes (v0.5.4): um gerenciador único, cache em memória e pedido cancelável.
/// Antes cada miniatura pedia a imagem ao desenhar e nunca cancelava; rolando a Galeria, os pedidos acumulavam.
enum Thumbnails {
    static let size = CGSize(width: 300, height: 400)

    private static let manager = PHCachingImageManager()
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 300
        return cache
    }()

    private static func key(_ asset: PHAsset) -> NSString { asset.localIdentifier as NSString }

    /// Miniatura já pronta (sem pedir nada ao sistema), se houver.
    static func cached(for asset: PHAsset) -> UIImage? {
        cache.object(forKey: key(asset))
    }

    /// Pede a miniatura. `onImage` roda na fila principal (pode vir duas vezes: uma rápida e a final). Só a versão FINAL
    /// entra no cache. Devolve o número do pedido, para `cancel`.
    @discardableResult
    static func request(for asset: PHAsset, onImage: @escaping (UIImage) -> Void) -> PHImageRequestID {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        let cacheKey = key(asset)
        return manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) {
            image, info in
            guard let image else { return }
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            if !degraded { cache.setObject(image, forKey: cacheKey) }
            onImage(image)
        }
    }

    static func cancel(_ id: PHImageRequestID?) {
        guard let id, id != PHInvalidImageRequestID else { return }
        manager.cancelImageRequest(id)
    }
}
