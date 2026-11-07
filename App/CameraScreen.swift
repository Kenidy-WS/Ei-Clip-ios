import SwiftUI

/// Tela da Câmera (v0.3.4), igual à do web app: prévia em tela cheia, barra do topo (voltar, voz, pílula, flash e ajustes; v0.7.1)
/// e, embaixo, a miniatura do último clipe, o botão de gravar e um espaço para o botão de trocar de câmera (etapa 5).
/// Ainda não tem: lentes, trocar de câmera e nível (etapa 5); o "ouvi" do botão de voz entra com a voz (v0.3.6).
struct CameraScreen: View {
    @EnvironmentObject var engine: CaptureEngine
    let onSettings: () -> Void
    /// v0.4.8: a miniatura do último clipe abre o player nesse clipe (a raiz fecha a câmera e a reabre ao sair do player).
    let onLastClip: (RecentClips.Item) -> Void
    /// v0.4.2: voltar ao Início passa pela raiz, que define a direção da transição de tela.
    let onBack: () -> Void
    @StateObject private var recents = RecentClips()

    private let recRed = Color(red: 1.0, green: 0.27, blue: 0.23)  // #ff453a
    private let okGreen = Color(red: 0.19, green: 0.82, blue: 0.35)  // #30d158
    private let muted = Color(red: 0.56, green: 0.56, blue: 0.58)  // #8e8e93

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if engine.screenDimmed {
                dimmedLayer
            } else {
                CameraPreview(session: engine.session) { devicePoint, screenPoint in
                    engine.focus(devicePoint: devicePoint, screenPoint: screenPoint)
                }
                .ignoresSafeArea()
                .overlay(focusRing.ignoresSafeArea())
                .overlay(levelLine)
                controls
            }
        }
        .onAppear { recents.reload() }
        .onChange(of: engine.savedCount) { _ in recents.reload() }  // v0.6.15: a miniatura nova aparece na hora
    }

    /// Anel de foco (v0.6.7): aparece onde você tocou e some sozinho.
    private var focusRing: some View {
        ZStack {
            if let mark = engine.focusMark {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.yellow, lineWidth: 1.5)
                    .frame(width: 74, height: 74)
                    .position(x: mark.x, y: mark.y)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .task(id: mark.id) {
                        try? await Task.sleep(nanoseconds: UInt64(FocusRules.indicatorSeconds * 1_000_000_000))
                        engine.clearFocusMark(mark.id)
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: engine.focusMark)
        .allowsHitTesting(false)
    }

    /// Nível (v0.6.8): linha curta no centro que gira contra a inclinação do aparelho; verde quando reta, amarela fora disso.
    @ViewBuilder
    private var levelLine: some View {
        if engine.levelEnabled, let tilt = engine.levelTilt {
            let level = LevelRules.isLevel(tilt)
            ZStack {
                Capsule()
                    .fill(level ? okGreen : Color.yellow)
                    .frame(width: 150, height: 2)
                    .rotationEffect(.degrees(-tilt))
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 34, height: 2)
            }
            .shadow(color: .black.opacity(0.4), radius: 1.5)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            if !engine.message.isEmpty {
                Text(engine.message)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
            }
            lensBar
            bottomBar
        }
    }

    /// Botões de lente (v0.6.10): 0,5× (se o aparelho tiver), 1× e 2×. A lente em uso fica amarela.
    private var lensBar: some View {
        HStack(spacing: 10) {
            ForEach(engine.availableLenses, id: \.self) { item in
                let selected = engine.lens == item
                Button {
                    Task { await engine.setLens(item) }
                } label: {
                    Text(selected ? item.label : item.shortLabel)
                        .font(.system(size: selected ? 16 : 15, weight: .semibold))
                        .foregroundColor(selected ? Color.yellow : .white)
                        .frame(width: 46, height: 46)
                        .background(Circle().fill(selected ? Color.black.opacity(0.5) : Color.clear))
                        .shadow(color: .black.opacity(selected ? 0 : 0.5), radius: 2)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(engine.testRunning)
                .accessibilityLabel("Lente \(item.label)")
            }
        }
        .padding(.bottom, 22)  // v0.6.15: afastado do botão de gravar, como no app Câmera
        .opacity(engine.availableLenses.count > 1 ? 1 : 0)
    }

    // MARK: - Tela escura (v0.6.3)

    /// Preto liso: a câmera, a gravação e a voz seguem funcionando por baixo. Mostra só o tempo de gravação (apagado) e os
    /// avisos; tocar em qualquer lugar acende a tela.
    private var dimmedLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                if engine.isRecording {
                    LiveTick {
                        // v0.7.15: a qualidade real também aparece gravando ("● 0:07 | 1080 60").
                        HStack(spacing: 10) {
                            Text("● \(formatDuration(engine.recordSec))")
                            Rectangle().fill(recRed.opacity(0.4)).frame(width: 1, height: 12)
                            Text(engine.liveStripText())
                        }
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundColor(recRed.opacity(0.6))
                    }
                    .padding(.top, 64)
                } else {
                    // v0.6.15: a pré-gravação aparece também na tela escura, como a gravação (apagada, para não iluminar).
                    let window = max(1, engine.effectiveWindowSec)
                    LiveTick {
                        VStack(spacing: 6) {
                            // v0.7.8: a qualidade vai junto da pré-gravação ("1080 60 | 12/30 s"), igual à pílula da câmera.
                            // Só leitura do que já existe (`chosen`, `cameraPosition`): nada novo é publicado.
                            HStack(spacing: 10) {
                                Text(engine.liveStripText())
                                Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 12)
                                Text("\(Int(engine.bufferSec.rounded()))/\(window) s")
                            }
                            .font(.system(size: 15, weight: .semibold).monospacedDigit())
                            .foregroundColor(Color.white.opacity(0.45))
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12)).frame(width: 90, height: 2)
                                Capsule().fill(Color.white.opacity(0.4))
                                    .frame(width: 90 * min(1, engine.bufferSec / Double(window)), height: 2)
                            }
                        }
                    }
                    .padding(.top, 64)
                }
                Spacer()
                if !engine.message.isEmpty {
                    Text(engine.message)
                        .font(.footnote)
                        .foregroundColor(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 14)
                }
                Text(Textos.toqueParaAcender)
                    .font(.footnote)
                    .foregroundColor(Color.white.opacity(0.22))
                    .padding(.bottom, 50)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { engine.setScreenDimmed(false) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Textos.toqueParaAcender)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Topo

    /// Topo (v0.7.1): voltar, microfone, pílula, flash e ajustes, todos sem círculo. A pílula tem largura fixa; o microfone fica
    /// no meio do espaço entre o voltar e a pílula, e o flash no meio do espaço entre a pílula e os ajustes.
    private var topBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                BareIconButton(systemName: "chevron.left", label: Textos.voltar, action: onBack)
                Spacer(minLength: 0)
                BareIconButton(
                    // v0.7.7: sem a permissão do microfone não chega som à voz: o ícone fica cortado e apagado.
                    systemName: (engine.voiceMode == .off || !engine.micAllowed) ? "mic.slash" : "mic",
                    color: (engine.voiceMode == .off || !engine.micAllowed) ? muted : okGreen,
                    highlighted: engine.voiceHeard,
                    label: Textos.comandoDeVoz
                ) {
                    engine.voiceEnabled.toggle()
                }
                .disabled(engine.testRunning)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            statusPill
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                flashButton
                Spacer(minLength: 0)
                Button(action: onSettings) {
                    SlidersIcon()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Textos.ajustes)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 10)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    /// Flash (v0.7.13): liga e apaga a lanterna da câmera traseira (vale também gravando); sempre abre apagado. O ícone lê o estado
    /// com `LiveTick` (nada novo é publicado durante a reconfiguração da câmera). Na frontal ou sem lanterna o ícone some, mas o
    /// espaço fica para os ajustes não mudarem de lugar.
    private var flashButton: some View {
        LiveTick(interval: 0.1) {
            let hidden = engine.cameraPosition == .front || !engine.torchSupported
            let on = engine.torchOn
            Button {
                engine.toggleTorch()
            } label: {
                Image(systemName: on ? "bolt.fill" : "bolt.slash.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(on ? Color.yellow : .white)
                    .shadow(color: .black.opacity(0.55), radius: 2, y: 1)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(hidden ? 0 : 1)
            .allowsHitTesting(!hidden)
            .accessibilityHidden(hidden)
            .accessibilityLabel(on ? Textos.apagarLanterna : Textos.ligarLanterna)
        }
    }

    /// Pílula do topo (v0.7.1): discreta e de largura fixa. Parado: "1080 60 | 12/30 s" (qualidade e pré-gravação).
    /// Gravando: vermelha, "● 0:07 | 1080 60".
    private var statusPill: some View {
        // v0.7.2: o conteúdo inteiro é relido 4 vezes por segundo pelo relógio da própria tela (`LiveTick`);
        // o motor não publica mais os tempos (ver `CaptureEngine.bufferSec`).
        LiveTick { statusPillContent }
    }

    private var statusPillContent: some View {
        let recording = engine.isRecording
        let quality = engine.liveStripText()
        let preroll = "\(Int(engine.bufferSec.rounded()))/\(engine.effectiveWindowSec) s"
        let textFont = Font.system(size: 13, weight: .medium).monospacedDigit()
        return HStack(spacing: 12) {
            if recording {
                HStack(spacing: 6) {
                    Circle().fill(Color.white).frame(width: 7, height: 7)
                    Text(formatDuration(engine.recordSec))
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                }
            } else {
                Text(quality).font(textFont)
            }
            Rectangle().fill(Color.white.opacity(recording ? 0.4 : 0.28)).frame(width: 1, height: 12)
            Text(recording ? quality : preroll).font(textFont)
        }
        .foregroundColor(.white.opacity(0.92))
        .frame(width: 168, height: 32)
        .background(Capsule().fill(recording ? recRed : Color.black.opacity(0.28)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(recording ? "\(Textos.gravando) \(formatDuration(engine.recordSec)), \(Textos.qualidadeDaGravacao(quality))" : "\(Textos.qualidadeDaGravacao(quality)), \(Textos.preGravacaoAcumulada(preroll))")
    }

    // MARK: - Base

    /// Base (v0.7.1): miniatura à esquerda, obturador no centro exato da tela e, à direita, a lua no meio do espaço entre o
    /// obturador e o botão de trocar de câmera. As duas metades têm a mesma largura, por isso o obturador fica centralizado.
    private var bottomBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                thumbButton
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            shutter
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                GlassIconButton(systemName: "moon", size: 38, label: Textos.escurecerATela) { engine.setScreenDimmed(true) }
                    .disabled(engine.testRunning)
                Spacer(minLength: 0)
                flipButton
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    /// Troca entre a câmera traseira e a frontal (v0.6.9). Apagado enquanto grava.
    private var flipButton: some View {
        Button {
            Task { await engine.switchCamera() }
        } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 52, height: 52)
                .background(.ultraThinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .opacity(engine.isRecording ? 0.35 : 1)
        .disabled(engine.isRecording || engine.testRunning)
        .accessibilityLabel(Textos.trocarCamera)
    }

    /// Miniatura do último clipe; tocar abre o player nesse clipe (a câmera fecha; ao fechar o player, reabre).
    private var thumbButton: some View {
        Button {
            if let first = recents.items.first { onLastClip(first) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                if let pending = engine.pendingThumbnail {
                    // v0.6.16: clipe recém-gravado, ainda sendo salvo nas Fotos: a miniatura aparece na hora.
                    Image(uiImage: pending).resizable().scaledToFill().frame(width: 52, height: 52).clipped()
                        .overlay(ProgressView().tint(.white).scaleEffect(0.8))
                } else if let first = recents.items.first {
                    ClipTile(asset: first.asset, aspect: 1, showsDuration: false)
                } else {
                    Image(systemName: "photo.on.rectangle").foregroundColor(.white)
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.5), lineWidth: 1.5))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Textos.clipes)
    }

    /// Botão de gravar: anel branco; o centro vermelho vira quadrado arredondado ao gravar.
    private var shutter: some View {
        let recording = engine.isRecording
        return Button {
            if recording {
                Task { await engine.stopRecording() }
            } else {
                engine.startRecording()
            }
        } label: {
            ZStack {
                Circle().stroke(Color.white, lineWidth: 4).frame(width: 78, height: 78)
                RoundedRectangle(cornerRadius: recording ? 8 : 30)
                    .fill(recRed)
                    .frame(width: recording ? 30 : 60, height: recording ? 30 : 60)
                    .animation(.easeOut(duration: 0.18), value: recording)
            }
            // v0.6.16: área de toque maior que o desenho (96 pt), para acertar o botão sem olhar.
            .frame(width: 96, height: 96)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recording ? Textos.pararESalvar : Textos.gravar)
    }
}

/// v0.7.2: relógio próprio da tela. Relê o conteúdo 4 vezes por segundo, sem o motor publicar nada (os tempos
/// `bufferSec` e `recordSec` deixaram de ser `@Published` por causa do impasse do SwiftUI no iOS 27.0.1).
struct LiveTick<Content: View>: View {
    private let content: () -> Content
    private let interval: TimeInterval

    init(interval: TimeInterval = 0.25, @ViewBuilder _ content: @escaping () -> Content) {
        self.interval = interval
        self.content = content
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { _ in
            content()
        }
    }
}
