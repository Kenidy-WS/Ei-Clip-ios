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
/// Arrastar o vídeo para baixo fecha (v0.4.5); para os lados troca de clipe (v0.4.6). Compartilhar (v0.4.10) e excluir (v0.4.11) ficam na linha de ações de baixo.
struct ClipPlayerView: View {
    let asset: PHAsset
    let onClose: () -> Void

    @StateObject private var model = PlayerModel()
    @State private var chromeHidden = false
    @State private var seeking = false
    @State private var seekValue: Double = 0
    @State private var infoOpen = false
    @State private var info: ClipInfo?
    /// v0.4.10: preparando o arquivo para compartilhar / aviso curto de erro.
    @State private var sharing = false
    @State private var notice: String?
    // Arrastar (v0.4.5 para baixo; v0.4.6 para os lados)
    @State private var dragY: CGFloat = 0
    @State private var dragMode: DragMode = .idle
    @State private var dragStart: Date?
    @State private var closing = false
    @State private var slideX: CGFloat = 0
    /// Todos os clipes do álbum, na ordem da Galeria (do mais novo para o mais antigo), e o índice do que está na tela.
    @State private var clips: [PHAsset] = []
    @State private var index = 0

    private enum DragMode { case idle, down, side }

    /// O clipe que está na tela (o inicial, até a lista carregar).
    private var shown: PHAsset {
        clips.indices.contains(index) ? clips[index] : asset
    }

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
            // A lista inteira vem do álbum (mesmo quando o player abre pelos Recentes), para dar para trocar de clipe.
            var list = RecentClips.fetchAssets(limit: nil)
            if let found = list.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) {
                index = found
            } else {
                list = [asset]
                index = 0
            }
            clips = list
            Diagnostics.shared.log(
                "player",
                "abriu clipe \(index + 1) de \(list.count): \(dayLabel(shown.creationDate ?? Date())), \(formatDuration(shown.duration))")
            model.load(shown)
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
                .offset(x: slideX)
                .opacity(SwipeRules.slideOpacity(offset: Double(slideX)))
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .onTapGesture {
                    // Com os detalhes abertos, o toque só os fecha (como no web app).
                    if infoOpen { infoOpen = false } else { chromeHidden.toggle() }
                }
            if let notice {
                Text(notice)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassBackground(RoundedRectangle(cornerRadius: 14))
            } else if model.failed {
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
                actionsBar
            }
            .opacity(chromeHidden ? 0 : 1)
            .allowsHitTesting(!chromeHidden)
            .animation(.easeOut(duration: 0.2), value: chromeHidden)
        }
    }

    // MARK: - Arrastar: para baixo fecha (v0.4.5); para os lados troca de clipe (v0.4.6)

    private var dismissProgress: Double { SwipeRules.dismissProgress(dy: Double(dragY)) }

    /// O gesto vale só sobre o vídeo (as barras têm os seus botões e a barra de posição). O primeiro movimento decide o eixo
    /// e ele não muda até soltar. Para baixo: soltando depois de 130 pt (ou num arremesso rápido) fecha, senão volta ao lugar.
    /// Para os lados (fora das bordas, que são o gesto de voltar): troca de clipe na ordem da Galeria.
    private var dragGesture: some Gesture {
        // Espaço global: a tela se move durante o arrasto, e no espaço local a medida do dedo se distorceria.
        DragGesture(minimumDistance: 12, coordinateSpace: .global)
            .onChanged { value in
                if dragStart == nil { dragStart = Date() }
                let dx = Double(value.translation.width)
                let dy = Double(value.translation.height)
                if dragMode == .idle {
                    if SwipeRules.isDownDrag(dx: dx, dy: dy) {
                        dragMode = .down
                    } else if SwipeRules.isSideDrag(dx: dx, dy: dy),
                        !SwipeRules.startsOnEdge(x: Double(value.startLocation.x), width: Double(UIScreen.main.bounds.width))
                    {
                        dragMode = .side
                    } else {
                        return
                    }
                }
                switch dragMode {
                case .down:
                    dragY = CGFloat(max(0, dy))
                case .side:
                    let hasNeighbor = SwipeRules.neighborIndex(
                        current: index, direction: SwipeRules.neighborDirection(dx: dx), count: clips.count) != nil
                    slideX = CGFloat(SwipeRules.resistedOffset(dx: dx, hasNeighbor: hasNeighbor))
                case .idle:
                    break
                }
            }
            .onEnded { value in
                let started = dragStart ?? Date()
                dragStart = nil
                let mode = dragMode
                dragMode = .idle
                let ms = Date().timeIntervalSince(started) * 1000
                switch mode {
                case .down:
                    let dy = Double(max(0, value.translation.height))
                    if SwipeRules.shouldClose(dy: dy, elapsedMs: ms) {
                        Diagnostics.shared.log("player", "fechado arrastando para baixo (\(Int(dy)) pt, \(Int(ms)) ms)")
                        withAnimation(.easeOut(duration: 0.17)) { closing = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { onClose() }
                    } else {
                        withAnimation(.easeOut(duration: 0.22)) { dragY = 0 }
                    }
                case .side:
                    let dx = Double(value.translation.width)
                    let direction = SwipeRules.neighborDirection(dx: dx)
                    if SwipeRules.shouldChangeClip(dx: dx, elapsedMs: ms),
                        let next = SwipeRules.neighborIndex(current: index, direction: direction, count: clips.count)
                    {
                        changeClip(to: next, direction: direction)
                    } else {
                        withAnimation(.easeOut(duration: 0.18)) { slideX = 0 }  // nas pontas: só um tranco e volta
                    }
                case .idle:
                    break
                }
            }
    }

    /// O vídeo atual sai para o lado do dedo (220 ms), o novo espera o primeiro quadro ficar pronto (no máximo 0,6 s) e entra
    /// pelo lado oposto (320 ms, curva suave). Antes (v0.4.6) entrava logo, ainda vazio, e a troca parecia abrupta.
    private func changeClip(to next: Int, direction: Int) {
        let width = UIScreen.main.bounds.width
        withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.22)) { slideX = -CGFloat(direction) * width }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            index = next
            infoOpen = false
            info = nil
            model.load(shown)
            Diagnostics.shared.log(
                "player",
                "trocou para o clipe \(next + 1) de \(clips.count): \(dayLabel(shown.creationDate ?? Date())), \(formatDuration(shown.duration))")
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { slideX = CGFloat(direction) * width }
            Task { @MainActor in
                var waited = 0
                while !model.isReady && !model.failed && waited < 20 {
                    try? await Task.sleep(nanoseconds: 30_000_000)
                    waited += 1
                }
                withAnimation(.timingCurve(0.22, 0.8, 0.26, 1, duration: 0.32)) { slideX = 0 }
            }
        }
    }

    // MARK: - Topo

    private var topBar: some View {
        let created = shown.creationDate ?? Date()
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
            (Textos.infoData, formatDetailDate(shown.creationDate ?? Date())),
            (Textos.infoDuracao, formatDuration(shown.duration)),
            (Textos.infoTamanho, info?.sizeBytes.map(formatMegabytes) ?? "—"),
            (Textos.infoResolucao, formatDimensions(width: shown.pixelWidth, height: shown.pixelHeight)),
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
        let target = shown
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
        .padding(.bottom, 12)
    }

    /// Linha de ações embaixo (v0.4.10), como no app Fotos: compartilhar à esquerda e apagar à direita (v0.4.11).
    /// A barra de posição fica logo acima (v0.4.9: mais alta que antes).
    private var actionsBar: some View {
        HStack {
            ZStack {
                GlassIconButton(systemName: "square.and.arrow.up", label: Textos.compartilhar) { share() }
                    .opacity(sharing ? 0.35 : 1)
                    .disabled(sharing)
                if sharing { ProgressView().tint(.white) }
            }
            Spacer()
            GlassIconButton(systemName: "trash", label: Textos.apagar) { deleteShown() }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 24)
    }

    /// Copia o clipe para um arquivo temporário e abre a folha de compartilhar do iOS.
    private func share() {
        guard !sharing else { return }
        sharing = true
        let target = shown
        Task { @MainActor in
            let url = await ClipShare.fileURL(for: target)
            sharing = false
            guard let url else {
                Diagnostics.shared.log("player", "compartilhar: falhou ao preparar o arquivo")
                showNotice(Textos.naoFoiPossivelCompartilhar)
                return
            }
            Diagnostics.shared.log("player", "compartilhar: arquivo pronto, abrindo a folha do iOS")
            ClipShare.present([url]) { ClipShare.cleanUp() }
        }
    }

    /// Apaga o clipe da tela (o iOS pede a confirmação). Apagado, o player mostra o vizinho (o mais antigo; se não houver, o
    /// mais novo); sem mais clipes, fecha. Cancelando na confirmação, nada muda.
    private func deleteShown() {
        let target = shown
        model.pause()
        Task { @MainActor in
            let deleted = await PhotoDeleter.delete([target])
            guard deleted else {
                Diagnostics.shared.log("player", "apagar: cancelado ou falhou")
                model.play()
                return
            }
            guard clips.indices.contains(index) else {
                onClose()
                return
            }
            clips.remove(at: index)
            Diagnostics.shared.log("player", "apagou o clipe; restam \(clips.count)")
            if clips.isEmpty {
                onClose()
                return
            }
            index = min(index, clips.count - 1)
            infoOpen = false
            info = nil
            chromeHidden = false
            model.load(shown)
        }
    }

    private func showNotice(_ text: String) {
        notice = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if notice == text { notice = nil }
        }
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
