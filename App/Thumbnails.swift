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

    /// Miniatura já pronta (sem pedir nada ao sistema), se houver: primeiro a memória; depois a miniatura própria do clipe
    /// (v0.6.15, guardada em disco), que vira memória.
    static func cached(for asset: PHAsset) -> UIImage? {
        if let image = cache.object(forKey: key(asset)) { return image }
        if let own = ThumbnailStore.load(id: asset.localIdentifier) {
            cache.setObject(own, forKey: key(asset))
            return own
        }
        return nil
    }

    /// Guarda uma miniatura própria na memória (o clipe acabou de ser salvo).
    static func remember(_ image: UIImage, id: String) {
        cache.setObject(image, forKey: id as NSString)
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
