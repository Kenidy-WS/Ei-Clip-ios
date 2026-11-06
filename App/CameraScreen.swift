import SwiftUI

/// Tela da Câmera (v0.3.4), igual à do web app: prévia em tela cheia, barra do topo (voltar, pílula do buffer, voz e ajustes)
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
            ZStack {
                qualityStrip
                HStack {
                    Spacer()
                    GlassIconButton(systemName: "moon", label: Textos.escurecerATela) { engine.setScreenDimmed(true) }
                        .disabled(engine.testRunning)
                }
            }
            .padding(.horizontal, 14)
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

    /// Faixa do topo (v0.7.0): qualidade e fluidez escolhidas, como "1080 60", discretas como na câmera do iPhone. Só leitura:
    /// vem de `chosen` e da câmera em uso (já publicados); nada novo é publicado durante a reconfiguração da câmera.
    private var qualityStrip: some View {
        let text = engine.chosen.stripText(position: engine.cameraPosition)
        return Text(text)
            .font(.system(size: 13, weight: .semibold).monospacedDigit())
            .foregroundColor(.white.opacity(0.85))
            .shadow(color: .black.opacity(0.55), radius: 2)
            .allowsHitTesting(false)
            .accessibilityLabel(Textos.qualidadeDaGravacao(text))
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
                    Text("● \(formatDuration(engine.recordSec))")
                        .font(.system(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundColor(recRed.opacity(0.6))
                        .padding(.top, 64)
                } else {
                    // v0.6.15: a pré-gravação aparece também na tela escura, como a gravação (apagada, para não iluminar).
                    let window = max(1, engine.effectiveWindowSec)
                    VStack(spacing: 6) {
                        Text("\(Int(engine.bufferSec.rounded()))/\(window) s")
                            .font(.system(size: 15, weight: .semibold).monospacedDigit())
                            .foregroundColor(Color.white.opacity(0.45))
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12)).frame(width: 90, height: 2)
                            Capsule().fill(Color.white.opacity(0.4))
                                .frame(width: 90 * min(1, engine.bufferSec / Double(window)), height: 2)
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

    private var topBar: some View {
        ZStack {
            HStack(spacing: 8) {
                GlassIconButton(systemName: "chevron.left", label: Textos.voltar, action: onBack)
                Spacer()
                GlassIconButton(
                    systemName: engine.voiceMode == .off ? "mic.slash" : "mic",
                    color: engine.voiceMode == .off ? muted : okGreen,
                    highlighted: engine.voiceHeard,
                    label: Textos.comandoDeVoz
                ) {
                    engine.voiceEnabled.toggle()
                }
                .disabled(engine.testRunning)
                GlassIconButton(systemName: "gearshape", label: Textos.ajustes, action: onSettings)
            }
            bufferPill
        }
        .padding(.horizontal, 14)
        .padding(.top, 22)
        .padding(.bottom, 8)
    }

    /// Pílula do buffer: "5/15 s" com uma linha fina de progresso; ao gravar fica vermelha com "● 0:07".
    private var bufferPill: some View {
        let recording = engine.isRecording
        let text = recording
            ? "● \(formatDuration(engine.recordSec))"
            : "\(Int(engine.bufferSec.rounded()))/\(engine.effectiveWindowSec) s"
        let fill = min(1, engine.bufferSec / Double(max(1, engine.effectiveWindowSec)))
        return Text(text)
            .font(.system(size: 14, weight: .semibold).monospacedDigit())
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .frame(minWidth: 84, minHeight: 34)
            .background {
                if recording {
                    Capsule().fill(recRed)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                        .overlay(Capsule().fill(Color(red: 0.23, green: 0.23, blue: 0.24).opacity(0.5)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.5))
                }
            }
            .overlay(alignment: .bottomLeading) {
                if !recording {
                    GeometryReader { g in
                        Rectangle().fill(Color.white.opacity(0.75)).frame(width: g.size.width * fill, height: 2)
                            .animation(.linear(duration: 0.25), value: fill)
                    }
                    .frame(height: 2)
                }
            }
            .clipShape(Capsule())
    }

    // MARK: - Base

    private var bottomBar: some View {
        HStack {
            thumbButton
            Spacer()
            shutter
            Spacer()
            flipButton
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
