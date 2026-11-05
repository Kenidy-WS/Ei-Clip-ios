import Photos
import SwiftUI

/// Galeria do app (v0.4.0), igual à do web app: só os clipes do álbum "Ei Clip", do mais novo para o mais antigo, em grade
/// (colunas de no mínimo 110 pt, espaço de 4 pt, miniaturas 3:4 com cantos de 6 pt). Tocar num clipe o reproduz.
/// Título "N clipes"; sem clipes, "Nenhum clipe ainda.". A lista se atualiza sozinha quando um clipe é salvo ou excluído.
///
/// Seleção em lote (v0.4.12): "Selecionar" liga o modo; tocar nos clipes marca ou desmarca; embaixo, compartilhar e apagar os
/// escolhidos. A lógica da seleção fica no Core (`ClipSelection`). O estado `selecting` vem da raiz, para o gesto de voltar
/// primeiro sair da seleção (v0.4.14).
struct GalleryView: View {
    let onBack: () -> Void
    /// v0.4.1: botão de câmera no topo (abre a câmera, como no web app).
    let onCamera: () -> Void
    @Binding var selecting: Bool

    @StateObject private var library = RecentClips(limit: nil)
    @State private var playing: RecentClips.Item?
    @State private var selection = ClipSelection()
    @State private var sharing = false
    @State private var notice: String?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 4)]

    private var ids: [String] { library.items.map(\.id) }

    var body: some View {
        ZStack(alignment: .bottom) {
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
                                ClipTile(
                                    asset: item.asset, cornerRadius: 6,
                                    selected: selecting ? selection.contains(item.id) : nil
                                )
                                .onTapGesture { tap(item) }
                                .accessibilityAddTraits(.isButton)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .padding(.bottom, selecting ? 96 : 12)
                    }
                }
            }
            if selecting { selectionBar }
            if let notice {
                Text(notice)
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassBackground(RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 110)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: load)
        .onChange(of: library.items.count) { count in
            Diagnostics.shared.log("galeria", "lista mudou: \(count) clipes")
            // Clipe apagado (por aqui ou por fora) sai da seleção.
            selection.replace(with: Set(selection.ordered(in: ids)))
        }
        .onChange(of: selecting) { on in
            if !on { selection.clear() }
        }
        .fullScreenCover(item: $playing) { item in
            ClipPlayerView(asset: item.asset) { playing = nil }
        }
    }

    private func tap(_ item: RecentClips.Item) {
        if selecting {
            selection.toggle(item.id)
        } else {
            playing = item
        }
    }

    // MARK: - Topo

    private var header: some View {
        ZStack {
            Text(titleText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            HStack {
                if selecting {
                    Button(Textos.cancelar) { selecting = false }
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 8)
                    Spacer()
                    Button(selection.allSelected(in: ids) ? Textos.nenhum : Textos.todos) {
                        if selection.allSelected(in: ids) { selection.clear() } else { selection.selectAll(ids) }
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 8)
                } else {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Textos.voltar)
                    Spacer()
                    if !library.items.isEmpty {
                        Button(Textos.selecionar) { selecting = true }
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 8)
                    }
                    Button(action: onCamera) {
                        Image(systemName: "camera")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Textos.abrirCamera)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private var titleText: String {
        if selecting { return selection.isEmpty ? Textos.selecioneClipes : Textos.selecionados(selection.count) }
        return library.items.isEmpty ? Textos.clipes : Textos.quantidadeDeClipes(library.items.count)
    }

    // MARK: - Ações da seleção (v0.4.12)

    private var selectionBar: some View {
        HStack {
            ZStack {
                GlassIconButton(systemName: "square.and.arrow.up", label: Textos.compartilhar) { shareSelected() }
                    .opacity(sharing ? 0.35 : 1)
                if sharing { ProgressView().tint(.white) }
            }
            Spacer()
            GlassIconButton(systemName: "trash", label: Textos.apagar) { deleteSelected() }
        }
        .disabled(selection.isEmpty || sharing)
        .opacity(selection.isEmpty ? 0.4 : 1)
        .padding(.horizontal, 14)
        .padding(.bottom, 24)
    }

    private var selectedAssets: [PHAsset] {
        let chosen = Set(selection.ordered(in: ids))
        return library.items.filter { chosen.contains($0.id) }.map(\.asset)
    }

    private func shareSelected() {
        let assets = selectedAssets
        guard !assets.isEmpty, !sharing else { return }
        sharing = true
        Task { @MainActor in
            var urls: [URL] = []
            for asset in assets {
                if let url = await ClipShare.fileURL(for: asset) { urls.append(url) }
            }
            sharing = false
            guard !urls.isEmpty else {
                Diagnostics.shared.log("galeria", "compartilhar: falhou ao preparar os arquivos")
                showNotice(Textos.naoFoiPossivelCompartilhar)
                return
            }
            Diagnostics.shared.log("galeria", "compartilhar: \(urls.count) de \(assets.count) arquivos prontos")
            ClipShare.present(urls) { ClipShare.cleanUp() }
        }
    }

    private func deleteSelected() {
        let assets = selectedAssets
        guard !assets.isEmpty else { return }
        Task { @MainActor in
            let deleted = await PhotoDeleter.delete(assets)
            Diagnostics.shared.log("galeria", deleted ? "apagou \(assets.count) clipes" : "apagar: cancelado ou falhou")
            if deleted { selecting = false }
        }
    }

    private func showNotice(_ text: String) {
        notice = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if notice == text { notice = nil }
        }
    }

    private func load() {
        let started = Date()
        library.reload()
        let ms = Int(Date().timeIntervalSince(started) * 1000)
        Diagnostics.shared.log("galeria", "aberta: \(library.items.count) clipes (lista em \(ms) ms)")
    }
}
