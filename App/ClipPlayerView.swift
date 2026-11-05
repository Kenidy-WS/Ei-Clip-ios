import AVFoundation
import Photos
import SwiftUI
import UIKit

/// Vídeo do player: uma camada `AVPlayerLayer` (sem os controles do sistema, que são pequenos e difíceis de tocar).
struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {}
}

final class PlayerUIView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

/// Player de clipe (v0.4.3), igual ao do web app: vídeo em tela cheia, barras de vidro por cima e controles próprios.
/// Topo: voltar e a pílula com o dia e a hora ("Hoje", "Ontem", dia da semana, data). Embaixo: reproduzir/pausar, tempo,
/// barra de posição, velocidade (1× → 1,5× → 2× → 0,5×) e som. Tocar no vídeo esconde ou mostra as barras.
/// O botão de voltar e o gesto de borda fecham. (Detalhes, arrastar, compartilhar e excluir entram nas próximas versões.)
struct ClipPlayerView: View {
    let asset: PHAsset
    let onClose: () -> Void

    @StateObject private var model = PlayerModel()
    @State private var chromeHidden = false
    @State private var seeking = false
    @State private var seekValue: Double = 0

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PlayerLayerView(player: model.player)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { chromeHidden.toggle() }
            if model.failed {
                Text(Textos.naoFoiPossivelReproduzir)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassBackground(RoundedRectangle(cornerRadius: 14))
            } else if !model.isReady {
                ProgressView().tint(.white)
            }
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .animation(.easeOut(duration: 0.2), value: chromeHidden)
        }
        .edgeBack(onClose)
        .onAppear {
            Diagnostics.shared.log("player", "abriu clipe de \(dayLabel(asset.creationDate ?? Date())), \(formatDuration(asset.duration))")
            model.load(asset)
        }
        .onDisappear {
            model.pause()
            Diagnostics.shared.log("player", "fechou")
        }
    }

    // MARK: - Topo

    private var topBar: some View {
        let created = asset.creationDate ?? Date()
        return HStack {
            GlassIconButton(systemName: "chevron.left", label: Textos.voltar, action: onClose)
            Spacer()
            VStack(spacing: 1) {
                Text(dayLabel(created))
                    .font(.system(size: 14, weight: .semibold))
                Text(Self.timeFormatter.string(from: created))
                    .font(.system(size: 11).monospacedDigit())
                    .opacity(0.75)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .glassBackground(Capsule())
            Spacer()
            Color.clear.frame(width: 44, height: 44)  // o botão de detalhes entra na v0.4.4
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // MARK: - Controles

    private var bottomBar: some View {
        HStack(spacing: 8) {
            controlButton(
                systemName: model.isPlaying ? "pause.fill" : "play.fill",
                label: model.isPlaying ? Textos.pausar : Textos.reproduzir
            ) { model.togglePlay() }

            Text(formatDuration(seeking ? seekValue * model.duration : model.currentTime))
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundColor(.white)
                .frame(minWidth: 34)

            Slider(
                value: Binding(
                    get: { seeking ? seekValue : model.fraction },
                    set: { value in
                        seekValue = value
                        model.seek(toFraction: value)
                    }),
                in: 0...1,
                onEditingChanged: { editing in
                    if editing { seekValue = model.fraction }
                    seeking = editing
                }
            )
            .tint(.white)
            .accessibilityLabel(Textos.posicaoDoVideo)

            Button { model.setRate(PlaybackRate.next(after: model.rate)) } label: {
                Text(PlaybackRate.label(model.rate))
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(Textos.velocidade)

            controlButton(
                systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: model.isMuted ? Textos.ligarOSom : Textos.desligarOSom
            ) { model.isMuted.toggle() }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 52)
        .glassBackground(RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, 14)
        .padding(.bottom, 24)
    }

    private func controlButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
    }
}
