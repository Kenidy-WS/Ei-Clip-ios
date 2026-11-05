import AVFoundation

/// Bipe de início/fim da gravação (amostras geradas em `Core/BeepWave.swift`).
final class BeepPlayer {
    private var players: [BeepKind: AVAudioPlayer] = [:]

    /// Cria os players. Chamar com a sessão de áudio já ativa.
    func prepare() {
        for kind in [BeepKind.start, BeepKind.stop] where players[kind] == nil {
            let samples = renderBeep(kind, sampleRate: 48_000)
            let data = wavData(samples: samples, sampleRate: 48_000)
            if let player = try? AVAudioPlayer(data: data) {
                player.volume = 1
                player.prepareToPlay()
                players[kind] = player
            }
        }
    }

    func play(_ kind: BeepKind) {
        guard let player = players[kind] else { return }
        player.currentTime = 0
        player.play()
    }
}
