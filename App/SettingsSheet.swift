import SwiftUI

/// Folha de Ajustes (v0.3.6), igual à do web app: primeira página com o essencial e os tópicos; cada tópico abre uma página
/// (a folha "empurra" a página, com botão voltar e título). Arrastar para baixo fecha (gesto da própria folha do iOS);
/// o gesto de voltar pela borda volta uma página antes de fechar.
/// Só aparece o que o motor já faz. Resolução, fluidez, qualidade, nível, espelhar e armazenamento entram na etapa 5,
/// cada um junto com o seu controle no motor.
struct SettingsSheet: View {
    @EnvironmentObject var engine: CaptureEngine
    @Environment(\.dismiss) private var dismiss
    @State private var page: Page = .main
    @State private var showDiagnostics = false

    enum Page {
        case main, voice, sound

        var title: String {
            switch self {
            case .main: return Textos.ajustes
            case .voice: return Textos.comandoDeVoz
            case .sound: return Textos.sons
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                ZStack {
                    switch page {
                    case .main: mainPage.transition(.move(edge: .leading).combined(with: .opacity))
                    case .voice: voicePage.transition(.move(edge: .trailing).combined(with: .opacity))
                    case .sound: soundPage.transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .foregroundColor(.white)
        .presentationDetents([.height(560)])
        .presentationDragIndicator(.hidden)
        .sheetGlass()
        .fullScreenCover(isPresented: $showDiagnostics) {
            DiagnosticsView().environmentObject(engine)
        }
        .edgeGestures(back: {
            if page != .main { go(.main) } else { dismiss() }
        })
    }

    private func go(_ next: Page) {
        withAnimation(.easeOut(duration: 0.25)) { page = next }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        HStack(spacing: 4) {
            if page != .main {
                SheetIconButton(systemName: "chevron.left", label: Textos.voltar) { go(.main) }
            }
            Text(page.title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, page == .main ? 8 : 0)
            SheetIconButton(systemName: "xmark", label: Textos.fechar) { dismiss() }
        }
        .frame(height: 48)
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    // MARK: - Páginas

    private var mainPage: some View {
        VStack(spacing: 0) {
            SheetGroup {
                SheetRow {
                    Text(Textos.preGravacao)
                    Spacer()
                    WebSegment(
                        options: BufferWindow.options.map { ("\($0) s", $0) }, selection: $engine.windowSec
                    )
                    .opacity(engine.isRecording ? 0.4 : 1)
                    .disabled(engine.isRecording)
                }
            }
            SheetGroup {
                SheetSwitchRow(title: Textos.estabilizacao, subtitle: Textos.estabilizacaoAjuda, isOn: $engine.stabilization)
                    .opacity(engine.isRecording ? 0.4 : 1)
                    .disabled(engine.isRecording)
            }
            SheetGroup {
                SheetNavRow(title: Textos.comandoDeVoz, value: voiceSummary) { go(.voice) }
                SheetDivider()
                SheetNavRow(title: Textos.sons, value: engine.beepEnabled ? Textos.ligados : Textos.desligados) {
                    go(.sound)
                }
            }
            SheetGroup {
                SheetNavRow(title: Textos.diagnostico, value: nil) { showDiagnostics = true }
            }
        }
    }

    private var voiceSummary: String {
        engine.voiceEnabled ? engine.voiceWord.label : Textos.desligado
    }

    private var voicePage: some View {
        VStack(spacing: 0) {
            SheetGroup(compact: true) {
                SheetSwitchRow(title: Textos.comandoDeVoz, subtitle: nil, isOn: $engine.voiceEnabled)
            }
            SheetGroup(compact: true) {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Textos.palavraDeAtivacao)
                        Text(Textos.escolhaOGatilho).font(.system(size: 12)).foregroundColor(SheetStyle.muted)
                    }
                    WebSegment(
                        options: WakeWord.allCases.map { ($0.label, $0) }, selection: $engine.voiceWord, wide: true)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .opacity(engine.voiceEnabled ? 1 : 0.4)
            .disabled(!engine.voiceEnabled)
        }
    }

    private var soundPage: some View {
        SheetGroup(compact: true) {
            SheetSwitchRow(title: Textos.sonsDeGravacao, subtitle: nil, isOn: $engine.beepEnabled)
            SheetDivider()
            SheetSwitchRow(title: Textos.sonsNoVideo, subtitle: Textos.sonsNoVideoAjuda, isOn: $engine.beepInClip)
                .opacity(engine.beepEnabled ? 1 : 0.4)
                .disabled(!engine.beepEnabled)
        }
    }
}

// MARK: - Estilo (tokens do web app)

enum SheetStyle {
    static let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)  // #ffd60a
    static let muted = Color(red: 0.56, green: 0.56, blue: 0.58)  // #8e8e93
    static let surface2 = Color(red: 0.17, green: 0.17, blue: 0.18)  // #2c2c2e
    static let segOn = Color(red: 0.28, green: 0.28, blue: 0.29)  // #48484a
    static let line = Color.white.opacity(0.12)
}

extension View {
    /// Fundo de vidro da folha (iOS 16.4 em diante; antes, cinza escuro liso).
    @ViewBuilder func sheetGlass() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    Color(red: 0.11, green: 0.11, blue: 0.12).opacity(0.9)
                }
            }
        } else {
            self.background(Color(red: 0.11, green: 0.11, blue: 0.12))
        }
    }
}

/// Cartão arredondado com linhas, como nos Ajustes do iPhone.
struct SheetGroup<Content: View>: View {
    var compact = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .padding(.horizontal, 20)
            .padding(.vertical, compact ? 8 : 0)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 16)
    }
}

struct SheetDivider: View {
    var body: some View { Rectangle().fill(SheetStyle.line).frame(height: 1) }
}

struct SheetRow<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        HStack(spacing: 12, content: content)
            .font(.system(size: 17))
            .frame(minHeight: 52)
    }
}

struct SheetNavRow: View {
    let title: String
    let value: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SheetRow {
                Text(title)
                Spacer()
                if let value { Text(value).font(.system(size: 14)).foregroundColor(SheetStyle.muted) }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(SheetStyle.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SheetSwitchRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        SheetRow {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(SheetStyle.muted)
                        .frame(maxWidth: 230, alignment: .leading)
                }
            }
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(SheetStyle.yellow)
        }
    }
}

struct SheetIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .regular))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Seletor de opções do web app (`.seg`): trilho cinza, opção marcada em cinza claro com texto amarelo.
struct WebSegment<V: Hashable>: View {
    let options: [(String, V)]
    @Binding var selection: V
    var wide = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let on = options[i].1 == selection
                Button {
                    selection = options[i].1
                } label: {
                    Text(options[i].0)
                        .font(.system(size: wide ? 13 : 14, weight: on ? .semibold : .regular))
                        .foregroundColor(on ? SheetStyle.yellow : SheetStyle.muted)
                        .lineLimit(1)
                        .padding(.horizontal, wide ? 2 : 14)
                        .padding(.vertical, wide ? 8 : 6)
                        .frame(maxWidth: wide ? .infinity : nil)
                        .background(on ? SheetStyle.segOn : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(SheetStyle.surface2, in: RoundedRectangle(cornerRadius: 10))
    }
}
