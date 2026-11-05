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
                CameraPreview(session: engine.session).ignoresSafeArea()
                controls
            }
        }
        .onAppear { recents.reload() }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            topBar
            HStack {
                Spacer()
                GlassIconButton(systemName: "moon", label: Textos.escurecerATela) { engine.setScreenDimmed(true) }
                    .disabled(engine.testRunning)
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
            bottomBar
        }
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
            : "\(Int(engine.bufferSec.rounded()))/\(engine.windowSec) s"
        let fill = min(1, engine.bufferSec / Double(max(1, engine.windowSec)))
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
            Color.clear.frame(width: 52, height: 52)  // lugar do botão de trocar de câmera (etapa 5)
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }

    /// Miniatura do último clipe; tocar abre o player nesse clipe (a câmera fecha; ao fechar o player, reabre).
    private var thumbButton: some View {
        Button {
            if let first = recents.items.first { onLastClip(first) }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1))
                if let first = recents.items.first {
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
        }
        .buttonStyle(.plain)
        .accessibilityLabel(recording ? Textos.pararESalvar : Textos.gravar)
    }
}
