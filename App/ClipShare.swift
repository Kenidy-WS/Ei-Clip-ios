import Photos
import SwiftUI
import UIKit

/// Compartilhar clipes (v0.4.10): copia o arquivo do clipe para uma pasta temporária e abre a folha de compartilhar do iOS
/// (WhatsApp, Instagram, TikTok, AirDrop, Arquivos...). No web app o botão "Salvar" baixava o arquivo; no iPhone o clipe
/// já está no Rolo, então o que faz sentido é enviar para outro app.
enum ClipShare {
    private static var folder: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("compartilhar", isDirectory: true)
    }

    /// Copia o vídeo do clipe para um arquivo temporário. nil se não foi possível (por exemplo, sem rede e o clipe está no iCloud).
    static func fileURL(for asset: PHAsset) async -> URL? {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .video }) ?? resources.first(where: { $0.type == .fullSizeVideo })
        else { return nil }
        let dir = folder.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            return nil
        }
        let url = dir.appendingPathComponent(resource.originalFilename)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { continuation in
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: options) { error in
                continuation.resume(returning: error == nil ? url : nil)
            }
        }
    }

    /// Apaga as cópias temporárias (ao fechar a folha de compartilhar).
    static func cleanUp() {
        try? FileManager.default.removeItem(at: folder)
    }

    /// Abre a folha de compartilhar do iOS por cima da tela atual (inclusive por cima do player em tela cheia).
    static func present(_ urls: [URL], onDone: @escaping () -> Void) {
        guard let top = topController() else {
            onDone()
            return
        }
        let controller = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in onDone() }
        controller.popoverPresentationController?.sourceView = top.view
        top.present(controller, animated: true)
    }

    private static func topController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        var top = scenes.flatMap { $0.windows }.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
