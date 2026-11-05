import AVFoundation
import Photos
import SwiftUI

/// Estado do player (v0.4.3): um único `AVPlayer`, a posição, a velocidade e o som. Os controles são da interface
/// (`ClipPlayerView`), não os do sistema. Sobre o som: o player abre COM som, como na v0.3.1; a sessão de áudio não é
/// tocada aqui (ela é área protegida e só muda na v0.4.12).
final class PlayerModel: ObservableObject {
    let player = AVPlayer()

    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var rate: Double = 1
    @Published private(set) var isReady = false
    @Published private(set) var failed = false
    @Published var isMuted = false {
        didSet { player.isMuted = isMuted }
    }

    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var loadToken = 0

    init() {
        player.actionAtItemEnd = .pause
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            let seconds = time.seconds
            if seconds.isFinite { self?.currentTime = seconds }
        }
        statusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            let playing = player.timeControlStatus != .paused
            DispatchQueue.main.async { self?.isPlaying = playing }
        }
    }

    deinit {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        player.pause()
    }

    /// Carrega o clipe do Rolo e começa a tocar. A velocidade volta a 1× (como no web app); o som continua como estava.
    func load(_ asset: PHAsset) {
        loadToken += 1
        let token = loadToken
        failed = false
        isReady = false
        duration = asset.duration
        currentTime = 0
        rate = 1
        player.defaultRate = 1
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .automatic
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, token == self.loadToken else { return }
                guard let item else {
                    self.failed = true
                    Diagnostics.shared.log("player", "não foi possível carregar o clipe")
                    return
                }
                self.player.replaceCurrentItem(with: item)
                self.player.isMuted = self.isMuted
                self.isReady = true
                self.play()
            }
        }
    }

    func play() {
        if duration > 0, currentTime >= duration - 0.05 { seek(toFraction: 0) }  // no fim, tocar recomeça
        player.play()
    }

    func pause() {
        player.pause()
    }

    func togglePlay() {
        if isPlaying { pause() } else { play() }
    }

    func setRate(_ value: Double) {
        rate = value
        player.defaultRate = Float(value)
        if isPlaying { player.rate = Float(value) }
    }

    /// Vai para a posição (0 a 1 da duração).
    func seek(toFraction fraction: Double) {
        guard duration > 0 else { return }
        let target = min(1, max(0, fraction)) * duration
        currentTime = target
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /// Posição como fração da duração (0 a 1).
    var fraction: Double {
        duration > 0 ? min(1, max(0, currentTime / duration)) : 0
    }
}
