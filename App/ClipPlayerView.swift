import AVKit
import Photos
import SwiftUI

/// Reproduz um clipe do Rolo dentro do app (v0.3.1). Compartilhar e excluir ficam no app Fotos.
struct ClipPlayerView: View {
    let asset: PHAsset
    let onClose: () -> Void
    @State private var player: AVPlayer?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player).ignoresSafeArea()
            } else {
                ProgressView().tint(.white).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel(Textos.voltar)
            .padding(12)
        }
        .edgeBack(onClose)
        .onAppear(perform: load)
        .onDisappear { player?.pause() }
    }

    private func load() {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
            DispatchQueue.main.async {
                guard let item else { return }
                let newPlayer = AVPlayer(playerItem: item)
                player = newPlayer
                newPlayer.play()
            }
        }
    }
}
