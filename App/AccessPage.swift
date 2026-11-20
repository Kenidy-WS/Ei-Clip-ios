import SwiftUI
import StoreKit

/// C2, etapa 3: página "Acesso" dos Ajustes (PROVISÓRIA, para testar as compras). A tela final "Escolha seu acesso" vem na etapa 4.
/// Modo sombra: nada é bloqueado. Só esta página observa o StoreManager.
struct AccessPage: View {
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if let m = store.message {
                // v0.9.24: o aviso (compra concluída, restaurada, etc.) fica no topo, em destaque, onde se vê sem rolar.
                SheetGroup {
                    SheetRow {
                        Text(m)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(SheetStyle.yellow)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
            SheetGroup {
                SheetRow {
                    Text(Textos.acessoSituacao)
                    Spacer(minLength: 12)
                    Text(situationText)
                        .font(.system(size: 14))
                        .foregroundColor(SheetStyle.muted)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            productsGroup
            SheetGroup {
                actionRow(Textos.restaurarCompras) { Task { await store.restore() } }
                SheetDivider()
                actionRow(Textos.resgatarCodigo) { Task { await store.redeemCode() } }
            }
            Text(Textos.acessoProvisoria)
                .font(.system(size: 12))
                .foregroundColor(SheetStyle.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)
        }
    }

    // MARK: - Produtos

    @ViewBuilder private var productsGroup: some View {
        switch store.loadState {
        case .idle, .loading:
            SheetGroup { SheetRow { Text(Textos.carregandoProdutos).foregroundColor(SheetStyle.muted); Spacer() } }
        case .failed:
            SheetGroup {
                SheetRow { Text(Textos.produtosFalhou).font(.system(size: 14)).foregroundColor(SheetStyle.muted); Spacer() }
                SheetDivider()
                actionRow(Textos.tentarNovamente) { Task { await store.loadProducts() } }
            }
        case .loaded:
            if store.products.isEmpty {
                SheetGroup { SheetRow { Text(Textos.produtosNenhum).font(.system(size: 14)).foregroundColor(SheetStyle.muted); Spacer() } }
            } else {
                SheetGroup {
                    ForEach(Array(store.products.enumerated()), id: \.element.id) { index, product in
                        if index > 0 { SheetDivider() }
                        productRow(product)
                    }
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        SheetRow {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.displayName)
                Text(kindText(product.id)).font(.system(size: 12)).foregroundColor(SheetStyle.muted)
                if !store.showsPrice(of: product) {
                    Text(Textos.precoNaFolhaDaApple).font(.system(size: 12)).foregroundColor(SheetStyle.muted)
                }
            }
            Spacer(minLength: 12)
            Button {
                Task { await store.buy(product) }
            } label: {
                Text(store.showsPrice(of: product) ? product.displayPrice : Textos.verPreco)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(SheetStyle.yellow, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(store.busy)
            .opacity(store.busy ? 0.5 : 1)
        }
    }

    private func actionRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SheetRow { Text(title); Spacer() }.contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(store.busy)
        .opacity(store.busy ? 0.5 : 1)
    }

    private func kindText(_ id: String) -> String {
        switch id {
        case StoreProductID.monthly: return Textos.assinaturaMensal
        case StoreProductID.yearly: return Textos.assinaturaAnual
        default: return Textos.pagamentoUnico
        }
    }

    // MARK: - Situação

    private var planName: String? {
        switch store.activePlanID {
        case StoreProductID.monthly: return Textos.planoMensal
        case StoreProductID.yearly: return Textos.planoAnual
        default: return nil
        }
    }

    private var situationText: String {
        guard let state = store.access?.state else { return Textos.situacaoLendo }
        func day(_ d: Date) -> String { d.formatted(date: .numeric, time: .omitted) }
        switch state {
        case .freeClips(let remaining): return Textos.situacaoTeste(remaining)
        case .permanent: return Textos.situacaoPermanente
        case .subscribed(let end): return Textos.situacaoAssinaturaAtiva(day(end), plano: planName)
        case .subscribedUnconfirmed(let end, _): return Textos.situacaoNaoConfirmada(day(end))
        case .billingProblem: return Textos.situacaoProblemaPagamento
        case .subscriptionEnded: return Textos.situacaoTerminou
        case .subscriptionNotConfirmed: return Textos.situacaoNaoConfirmadaFim
        case .accessRevoked: return Textos.situacaoRevogado
        case .purchasePending: return Textos.situacaoEmAnalise
        }
    }
}
