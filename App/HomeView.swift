import SwiftUI

/// Tela de Início, igual à do web app: marca, texto, "Abrir câmera", Recentes (v0.3.1) e a versão.
/// Os Ajustes finais entram na v0.3.3 (por ora a engrenagem abre o Diagnóstico).
struct HomeView: View {
    let opening: Bool
    let message: String
    let onOpen: () -> Void
    let onSettings: () -> Void

    @StateObject private var recents = RecentClips()
    @State private var playing: RecentClips.Item?

    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)  // #ffd60a, o amarelo do web app

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Ajustes")
            }

            Spacer()

            VStack(spacing: 10) {
                BrandMark(size: 96)
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .accessibilityLabel("Ei Clip")
                Text("Câmera de ação com comando de voz.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                Button(action: onOpen) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text(opening ? "Abrindo…" : "Abrir câmera")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(yellow, in: Capsule())
                }
                .disabled(opening)
                if !message.isEmpty {
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

            Text("Ei Clip \(Diagnostics.appVersion)")
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.4))
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
        .onAppear { recents.reload() }
        .fullScreenCover(item: $playing) { item in
            ClipPlayerView(asset: item.asset) { playing = nil }
        }
    }

    /// "Recentes": os 4 clipes mais novos do álbum "Ei Clip". Tocar reproduz; "Ver todos" abre o app Fotos.
    private var recentSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(Textos.recentes)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))  // #8e8e93
                Spacer()
                if !recents.items.isEmpty {
                    Button(Textos.verTodos) {
                        if let url = URL(string: "photos-redirect://") { UIApplication.shared.open(url) }
                    }
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.7))
                }
            }
            if recents.items.isEmpty {
                Text(Textos.semClipes)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))
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
