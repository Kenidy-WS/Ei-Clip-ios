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
/// O botão de voltar e o gesto de borda fecham. O botão "i" (v0.4.4) abre o cartão de detalhes do clipe.
/// Arrastar o vídeo para baixo fecha (v0.4.5). (Trocar de clipe, compartilhar e excluir entram nas próximas versões.)
struct ClipPlayerView: View {
    let asset: PHAsset
    let onClose: () -> Void

    @StateObject private var model = PlayerModel()
    @State private var chromeHidden = false
    @State private var seeking = false
    @State private var seekValue: Double = 0
    @State private var infoOpen = false
    @State private var info: ClipInfo?
    // Arrastar para baixo (v0.4.5)
    @State private var dragY: CGFloat = 0
    @State private var dragActive = false
    @State private var dragStart: Date?
    @State private var closing = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.dateFormat = "HH:mm"
        return f
    }()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            // v0.4.5: arrastando para baixo, a tela acompanha o dedo, encolhe e esmaece (como no web app).
            playerContent
                .offset(y: closing ? UIScreen.main.bounds.height * 0.4 : dragY)
                .scaleEffect(closing ? 0.85 : SwipeRules.dismissScale(progress: dismissProgress))
                .opacity(closing ? 0 : SwipeRules.dismissOpacity(progress: dismissProgress))
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

    /// Tudo o que se move junto no arrasto para baixo (o fundo preto fica parado).
    private var playerContent: some View {
        ZStack {
            PlayerLayerView(player: model.player)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .onTapGesture {
                    // Com os detalhes abertos, o toque só os fecha (como no web app).
                    if infoOpen { infoOpen = false } else { chromeHidden.toggle() }
                }
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
                if infoOpen { infoCard }
                Spacer()
                bottomBar
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .animation(.easeOut(duration: 0.2), value: chromeHidden)
        }
    }

    // MARK: - Arrastar para baixo fecha (v0.4.5)

    private var dismissProgress: Double { SwipeRules.dismissProgress(dy: Double(dragY)) }

    /// O gesto vale só sobre o vídeo (as barras têm os seus botões e a barra de posição). Só conta se começar para baixo e
    /// mais vertical do que horizontal; soltando depois de 130 pt (ou num arremesso rápido) fecha, senão volta ao lugar.
    private var dragGesture: some Gesture {
        // Espaço global: a tela se move durante o arrasto, e no espaço local a medida do dedo se distorceria.
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                if dragStart == nil { dragStart = Date() }
                let dx = Double(value.translation.width)
                let dy = Double(value.translation.height)
                if !dragActive {
                    guard SwipeRules.isDownDrag(dx: dx, dy: dy) else { return }
                    dragActive = true
                }
                dragY = CGFloat(max(0, dy))
            }
            .onEnded { value in
                let started = dragStart ?? Date()
                dragStart = nil
                guard dragActive else { return }
                dragActive = false
                let dy = Double(max(0, value.translation.height))
                let ms = Date().timeIntervalSince(started) * 1000
                if SwipeRules.shouldClose(dy: dy, elapsedMs: ms) {
                    Diagnostics.shared.log("player", "fechado arrastando para baixo (\(Int(dy)) pt, \(Int(ms)) ms)")
                    withAnimation(.easeOut(duration: 0.17)) { closing = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { onClose() }
                } else {
                    withAnimation(.easeOut(duration: 0.22)) { dragY = 0 }
                }
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
            GlassIconButton(systemName: "info.circle", label: Textos.detalhesDoVideo) {
                infoOpen.toggle()
                if infoOpen && info == nil { loadInfo() }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
    }

    // MARK: - Detalhes

    /// Cartão de detalhes (v0.4.4): data, duração, tamanho, resolução, fluidez, taxa e áudio. O que o arquivo ainda não
    /// informou aparece como "—".
    private var infoCard: some View {
        let rows: [(String, String)] = [
            (Textos.infoData, formatDetailDate(asset.creationDate ?? Date())),
            (Textos.infoDuracao, formatDuration(asset.duration)),
            (Textos.infoTamanho, info?.sizeBytes.map(formatMegabytes) ?? "—"),
            (Textos.infoResolucao, formatDimensions(width: asset.pixelWidth, height: asset.pixelHeight)),
            (Textos.infoFluidez, info?.fps.map(formatFps) ?? "—"),
            (Textos.infoTaxa, info?.bitsPerSecond.map(formatMbps) ?? "—"),
            (Textos.infoAudio, info?.hasAudio.map { $0 ? Textos.infoAudioSim : Textos.infoAudioNao } ?? "—"),
        ]
        return VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { i in
                HStack {
                    Text(rows[i].0).foregroundColor(Color.white.opacity(0.7))
                    Spacer()
                    Text(rows[i].1).fontWeight(.semibold).foregroundColor(.white)
                }
                .font(.system(size: 14))
            }
        }
        .padding(16)
        .glassBackground(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }

    private func loadInfo() {
        let target = asset
        Task {
            let loaded = await ClipInfo.load(for: target)
            await MainActor.run { info = loaded }
            Diagnostics.shared.log(
                "player",
                "detalhes: tamanho=\(loaded.sizeBytes.map(formatMegabytes) ?? "?") fluidez=\(loaded.fps.map(formatFps) ?? "?") "
                    + "taxa=\(loaded.bitsPerSecond.map(formatMbps) ?? "?") áudio=\(loaded.hasAudio.map { $0 ? "sim" : "não" } ?? "?") "
                    + "resolução=\(formatDimensions(width: target.pixelWidth, height: target.pixelHeight))")
        }
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
