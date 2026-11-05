import Photos
import SwiftUI

/// Galeria do app (v0.4.0), igual à do web app: só os clipes do álbum "Ei Clip", do mais novo para o mais antigo, em grade
/// (colunas de no mínimo 110 pt, espaço de 4 pt, miniaturas 3:4 com cantos de 6 pt). Tocar num clipe o reproduz.
/// Título "N clipes"; sem clipes, "Nenhum clipe ainda.". A lista se atualiza sozinha quando um clipe é salvo ou excluído.
struct GalleryView: View {
    let onBack: () -> Void

    @StateObject private var library = RecentClips(limit: nil)
    @State private var playing: RecentClips.Item?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 4)]

    var body: some View {
        VStack(spacing: 0) {
            header
            if library.items.isEmpty {
                Spacer()
                Text(Textos.semClipes)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.56, green: 0.56, blue: 0.58))  // #8e8e93
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(library.items) { item in
                            Button { playing = item } label: { ClipTile(asset: item.asset, cornerRadius: 6) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .edgeBack(onBack)
        .onAppear(perform: load)
        .onChange(of: library.items.count) { count in
            Diagnostics.shared.log("galeria", "lista mudou: \(count) clipes")
        }
        .fullScreenCover(item: $playing) { item in
            ClipPlayerView(asset: item.asset) { playing = nil }
        }
    }

    private var header: some View {
        ZStack {
            Text(library.items.isEmpty ? Textos.clipes : Textos.quantidadeDeClipes(library.items.count))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Textos.voltar)
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private func load() {
        let started = Date()
        library.reload()
        let ms = Int(Date().timeIntervalSince(started) * 1000)
        Diagnostics.shared.log("galeria", "aberta: \(library.items.count) clipes (lista em \(ms) ms)")
    }
}
