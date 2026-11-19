import SwiftUI

/// Tela de Início, igual à do web app: marca, texto, "Abrir câmera", Recentes (v0.3.1) e a versão.
/// A engrenagem abre os Ajustes (v0.3.6). "Ver todos" abre a Galeria (v0.4.0).
struct HomeView: View {
    let opening: Bool
    let message: String
    let onOpen: () -> Void
    let onSettings: () -> Void
    /// v0.4.0: "Ver todos" abre a Galeria do app (antes abria o app Fotos).
    let onSeeAll: () -> Void

    @StateObject private var recents = RecentClips()
    @Environment(\.scenePhase) private var scenePhase
    @State private var playing: RecentClips.Item?
    /// v0.9.16: aviso fixo de espaço (nulo = espaço de sobra, nada na tela). Não bloqueia a câmera.
    @State private var storageBanner: StorageBanner?
    private let storageTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onSettings) {
                    // v0.7.7: o mesmo ícone de ajustes da câmera (antes o Início ainda tinha a engrenagem da versão antiga).
                    SlidersIcon()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                        .frame(width: 24, height: 24)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Textos.ajustes)
            }

            if let banner = storageBanner {
                storageBannerView(banner)
            }

            Spacer()

            // Espaços iguais aos do web app: marca e logo a 10; depois 8 entre os blocos; o texto tem 20 a mais embaixo.
            VStack(spacing: 8) {
                VStack(spacing: 10) {
                    BrandMark(size: 96)
                    Image("BrandLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150)
                        .accessibilityLabel(Textos.nomeDoApp)
                }
                Text(Textos.slogan)
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
                // Botão igual ao do web app: branco, 52 pt de altura, até 320 pt de largura, cantos de 14 pt, texto 17 semibold.
                Button(action: onOpen) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera")
                        Text(opening ? Textos.abrindo : Textos.abrirCamera)
                            .transaction { $0.animation = nil }  // v0.7.15: troca seca, sem sombra do texto anterior
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: 320)
                    .frame(height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PrimaryPressStyle())
                .disabled(opening)
                if !message.isEmpty && !(storageBanner != nil && Textos.ehAvisoDeEspaco(message)) {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            recentSection

            Text(Textos.versaoDoApp(Diagnostics.appVersion))
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.4))
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
        .onAppear {
            recents.reload()
            refreshStorage()
        }
        .onReceive(storageTimer) { _ in refreshStorage() }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                recents.reload()
                refreshStorage()
            }  // v0.7.6: voltando dos Ajustes, a lista e o aviso se atualizam
        }
        .fullScreenCover(item: $playing) { item in
            ClipPlayerView(asset: item.asset) { playing = nil }
        }
    }

    /// v0.9.16: lê o espaço livre e a qualidade escolhida (a taxa decide quantos minutos cabem). Só mexe no estado se mudou.
    private func refreshStorage() {
        var next: StorageBanner?
        if let free = StorageInfo.freeBytes() {
            let config = Preferences(store: UserDefaults.standard).captureChoice.validated()
            next = StorageRules.banner(freeBytes: free, videoBitrate: config.bitrate)
        }
        if next != storageBanner { storageBanner = next }
    }

    /// Faixa fixa: amarela (pouco espaço) ou vermelha (quase esgotado). Só texto; o caminho para apagar clipes é o "Ver todos".
    private func storageBannerView(_ banner: StorageBanner) -> some View {
        let critical = banner.level == .critical
        let tint = critical ? Color(red: 1.0, green: 0.42, blue: 0.39) : Color(red: 1.0, green: 0.84, blue: 0.04)
        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(critical ? Textos.avisoEspacoCriticoTitulo : Textos.avisoPoucoEspacoTitulo)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(tint)
                Text(critical ? Textos.avisoEspacoCritico(banner.minutes) : Textos.avisoPoucoEspaco(banner.minutes))
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(tint.opacity(critical ? 0.18 : 0.14), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 4)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    /// "Recentes": os 4 clipes mais novos do álbum "Ei Clip". Tocar reproduz; "Ver todos" abre a Galeria.
    private var recentSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(Textos.recentes)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))  // #8e8e93
                Spacer()
                if !recents.items.isEmpty {
                    Button(Textos.verTodos, action: onSeeAll)
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.7))
                }
            }
            if recents.items.isEmpty {
                EmptyClipsView(accessProblem: recents.accessProblem)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: RecentClips.count), spacing: 8) {
                    ForEach(recents.items) { item in
                        Button { playing = item } label: { ClipTile(asset: item.asset) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

/// Ao tocar, o botão fica a 85% (como `:active` do web app).
struct PrimaryPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}
