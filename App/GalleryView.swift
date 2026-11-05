import Photos
import UIKit
import SwiftUI

/// Galeria do app (v0.4.0), igual à do web app: só os clipes do álbum "Ei Clip", do mais novo para o mais antigo, em grade
/// (colunas de no mínimo 110 pt, espaço de 4 pt, miniaturas 3:4 com cantos de 6 pt). Tocar num clipe o reproduz.
/// Título "N clipes"; sem clipes, "Nenhum clipe ainda.". A lista se atualiza sozinha quando um clipe é salvo ou excluído.
///
/// Segurar e arrastar (v0.4.13): segurar um clipe liga a seleção e o marca; sem soltar, arrastar o dedo marca todos entre o
/// primeiro e o clipe sob o dedo (voltar o dedo desmarca; a rolagem fica parada durante o arrasto). A regra vem do Core
/// (`dragSelection`); aqui só se descobre qual clipe está sob o dedo.
///
/// Seleção em lote (v0.4.12): "Selecionar" liga o modo; tocar nos clipes marca ou desmarca; embaixo, compartilhar e apagar os
/// escolhidos. A lógica da seleção fica no Core (`ClipSelection`). O estado `selecting` vem da raiz, para o gesto de voltar
/// primeiro sair da seleção (v0.4.14).
/// Posição de cada miniatura na grade (espaço "grid"), para descobrir qual está sob o dedo.
private struct TileFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// Guarda as posições sem redesenhar a tela a cada quadro da rolagem.
private final class TileFrameStore {
    var frames: [String: CGRect] = [:]
}

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
    // Segurar e arrastar (v0.4.13)
    @State private var dragAnchor: Int?
    /// Vale só enquanto o dedo está no gesto de segurar e arrastar; zera sozinho ao soltar ou cancelar.
    @GestureState private var pressActive = false
    @State private var dragBase: Set<String> = []
    @State private var frames = TileFrameStore()

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
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: TileFramesKey.self, value: [item.id: proxy.frame(in: .named("grid"))])
                                    }
                                )
                                .simultaneousGesture(pressAndDrag(item))
                                .accessibilityAddTraits(.isButton)
                            }
                        }
                        .coordinateSpace(name: "grid")
                        .onPreferenceChange(TileFramesKey.self) { frames.frames = $0 }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .padding(.bottom, selecting ? 96 : 12)
                    }
                    .scrollDisabled(dragAnchor != nil)
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
        // v0.4.15: soltou (ou o iOS cancelou o toque): encerra o arrasto. Antes só o fim do gesto encerrava e, se ele não
        // chegasse, o clipe antigo continuava como ponto de partida e a seleção "andava sozinha".
        .onChange(of: pressActive) { active in
            if !active { dragAnchor = nil }
        }
        .fullScreenCover(item: $playing) { item in
            ClipPlayerView(asset: item.asset) { playing = nil }
        }
    }

    /// Segurar (0,35 s) liga a seleção e marca o clipe; continuando o toque, arrastar marca o intervalo.
    private func pressAndDrag(_ item: RecentClips.Item) -> some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("grid")))
            .updating($pressActive) { value, state, _ in
                if case .second(true, _) = value { state = true }
            }
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                if dragAnchor == nil { beginDragSelect(item) }
                guard let anchor = dragAnchor, let drag, let current = index(at: drag.location) else { return }
                let chosen = dragSelection(base: dragBase, ids: ids, anchor: anchor, current: current)
                if chosen != selection.ids {
                    selection.replace(with: chosen)
                    UISelectionFeedbackGenerator().selectionChanged()
                }
            }
            .onEnded { _ in dragAnchor = nil }
    }

    private func beginDragSelect(_ item: RecentClips.Item) {
        guard let position = ids.firstIndex(of: item.id) else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        selecting = true
        dragBase = selection.ids.union([item.id])
        selection.replace(with: dragBase)
        dragAnchor = position
        Diagnostics.shared.log("galeria", "seleção: segurou o clipe \(position + 1)")
    }

    /// Índice (na lista) do clipe que está sob o ponto; nil nos espaços entre as miniaturas.
    private func index(at point: CGPoint) -> Int? {
        guard let hit = frames.frames.first(where: { $0.value.contains(point) })?.key else { return nil }
        return ids.firstIndex(of: hit)
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
        Group {
            if selecting { selectingHeader } else { normalHeader }
        }
        .padding(.horizontal, 28)  // fora das faixas de borda (28 pt), para os botões nunca ficarem por baixo delas
        .padding(.top, 4)
    }

    /// v0.4.15: o título fica ao lado da seta (à esquerda) e os botões à direita, com espaço entre eles; antes o título
    /// ficava centralizado e encostava em "Selecionar".
    private var normalHeader: some View {
        HStack(spacing: 0) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Textos.voltar)
            Text(titleText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer(minLength: 16)
            if !library.items.isEmpty {
                Button(Textos.selecionar) { selecting = true }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
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

    private var selectingHeader: some View {
        ZStack {
            Text(titleText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
            HStack {
                Button(Textos.cancelar) { selecting = false }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                Spacer()
                Button(selection.allSelected(in: ids) ? Textos.nenhum : Textos.todos) {
                    if selection.allSelected(in: ids) { selection.clear() } else { selection.selectAll(ids) }
                }
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(minHeight: 44)
            }
        }
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
        .padding(.horizontal, 28)
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
