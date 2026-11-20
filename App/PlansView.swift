import StoreKit
import SwiftUI

/// C2, etapa 4: tela "Escolha seu acesso". Três cartões (nada vem escolhido), botão fixo embaixo, painéis de resultado.
/// Cores: amarelo = seleção; vermelho só em falha de compra; verde só no ícone do acesso confirmado.
struct PlansView: View {
    let request: PlansRequest
    let onClose: () -> Void

    @ObservedObject private var store = StoreManager.shared
    @State private var selected: String?

    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyURL = URL(string: "https://ei-clip.github.io/ei-clip-legal/privacidade/")!
    private let red = Color(red: 1.0, green: 0.42, blue: 0.39)  // #ff6b63
    private let green = Color(red: 0.19, green: 0.82, blue: 0.35)  // #30d158

    private var isPaid: Bool {
        if case .allowPaid? = store.access?.decision { return true }
        return false
    }

    private var isPending: Bool { store.access?.state == .purchasePending }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                if isPaid {
                    paidPanel
                } else if isPending {
                    pendingPanel
                } else {
                    plansContent
                }
            }
        }
        .preferredColorScheme(.dark)
        // Mesmos gestos do resto do app: borda esquerda volta; puxar para baixo fecha (folha). Nada fecha durante a compra.
        .edgeGestures(back: { if !store.busy { onClose() } })
        .interactiveDismissDisabled(store.busy)
        .onAppear { applyAutoSelection() }
        .onChange(of: store.products.count) { _ in applyAutoSelection() }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Textos.fechar)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Cartões

    private var subtitle: String {
        request.reason.map { Textos.planosSubtitulo($0) } ?? Textos.planosSubtituloVoluntario
    }

    private var complement: String {
        request.reason.map { Textos.planosComplemento($0) } ?? Textos.planosComplementoVoluntario
    }

    private var plansContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(Textos.escolhaTitulo)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(complement)
                        .font(.system(size: 14))
                        .foregroundColor(SheetStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    cards
                    if request.reason == .subscriptionNotConfirmed {
                        secondaryButton(Textos.tentarNovamente) {
                            Task {
                                await store.refresh(reason: "tentar novamente")
                                if store.loadState == .failed { await store.loadProducts() }
                            }
                        }
                    }
                    HStack(spacing: 10) {
                        secondaryButton(Textos.restaurarCompras) { Task { await store.restore() } }
                        secondaryButton(Textos.resgatarCodigo) { Task { await store.redeemCode() } }
                    }
                    if let m = store.message, !isSuccessMessage(m) {
                        Text(m)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isFailureMessage(m) ? red : SheetStyle.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(Textos.planosNotaLegal)
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                    HStack(spacing: 28) {
                        Link(Textos.termosDeUso, destination: Self.termsURL)
                        Link(Textos.politicaDePrivacidade, destination: Self.privacyURL)
                    }
                    .font(.system(size: 14))
                    .foregroundColor(Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
            .fitsWithoutBounce()
            bottomButton
        }
    }

    @ViewBuilder private var cards: some View {
        switch store.loadState {
        case .idle, .loading:
            Text(Textos.carregandoProdutos).font(.system(size: 14)).foregroundColor(SheetStyle.muted)
        case .failed:
            Text(Textos.produtosFalhou).font(.system(size: 14)).foregroundColor(SheetStyle.muted)
            secondaryButton(Textos.tentarNovamente) { Task { await store.loadProducts() } }
        case .loaded:
            if store.products.isEmpty {
                Text(Textos.produtosNenhum).font(.system(size: 14)).foregroundColor(SheetStyle.muted)
            } else {
                ForEach(store.products, id: \.id) { product in card(product) }
            }
        }
    }

    private func card(_ product: Product) -> some View {
        let isSelected = selected == product.id
        let single = store.products.count == 1
        let shows = store.showsPrice(of: product)
        return Button {
            selected = product.id
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if !single { radio(isSelected) }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(name(of: product.id)).font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
                    }
                    Text(priceLine(product, shows: shows))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    if product.id == StoreProductID.yearly, shows {
                        Text(Textos.equivaleAPorMes(PlansScreenRules.monthlyEquivalent(yearly: product.price).formatted(.currency(code: product.priceFormatStyle.currencyCode).locale(product.priceFormatStyle.locale))))
                            .font(.system(size: 13)).foregroundColor(SheetStyle.muted)
                    }
                    Text(detail(of: product.id))
                        .font(.system(size: 13)).foregroundColor(SheetStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? SheetStyle.yellow.opacity(0.08) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(SheetStyle.yellow, lineWidth: isSelected ? 1.5 : 0))
            // Etiqueta sobre a borda de cima do cartão, à direita (como na prancha). Fundo liso para cortar a linha.
            .overlay(alignment: .topTrailing) {
                if product.id == StoreProductID.yearly, let percent = savings {
                    Text(Textos.economiaDe(percent))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(SheetStyle.surface2, in: Capsule())
                        .overlay(Capsule().stroke(SheetStyle.yellow, lineWidth: isSelected ? 1 : 0))
                        .padding(.trailing, 14)
                        .offset(y: -12)
                }
            }
            .padding(.top, product.id == StoreProductID.yearly && savings != nil ? 6 : 0)
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(store.busy)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func radio(_ on: Bool) -> some View {
        ZStack {
            Circle().stroke(on ? SheetStyle.yellow : SheetStyle.muted, lineWidth: 1.5)
            if on {
                Circle().fill(SheetStyle.yellow)
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.black)
            }
        }
        .frame(width: 22, height: 22)
        .padding(.top, 1)
    }

    private func name(of id: String) -> String {
        switch id {
        case StoreProductID.monthly: return Textos.planoMensalNome
        case StoreProductID.yearly: return Textos.planoAnualNome
        default: return Textos.planoPermanenteNome
        }
    }

    private func detail(of id: String) -> String {
        switch id {
        case StoreProductID.monthly: return Textos.planoMensalDetalhe
        case StoreProductID.yearly: return Textos.planoAnualDetalhe
        default: return Textos.planoPermanenteDetalhe
        }
    }

    private func priceLine(_ product: Product, shows: Bool) -> String {
        guard shows else { return Textos.valorNaConfirmacao }
        switch product.id {
        case StoreProductID.monthly: return Textos.precoPorMes(product.displayPrice)
        case StoreProductID.yearly: return Textos.precoPorAno(product.displayPrice)
        default: return product.displayPrice
        }
    }

    /// Economia do anual: só com os dois preços visíveis (mesma moeda) e a partir de 15 %.
    private var savings: Int? {
        guard let m = store.products.first(where: { $0.id == StoreProductID.monthly }),
            let y = store.products.first(where: { $0.id == StoreProductID.yearly }),
            store.showsPrice(of: m), store.showsPrice(of: y)
        else { return nil }
        return PlansScreenRules.savingsPercent(monthly: m.price, yearly: y.price)
    }

    private func applyAutoSelection() {
        if selected == nil, let only = PlansScreenRules.autoSelection(productIDs: store.products.map { $0.id }) {
            selected = only
        }
    }

    // MARK: - Botão fixo

    private var selectedProduct: Product? { store.products.first { $0.id == selected } }

    private var bottomButton: some View {
        let action = PlansScreenRules.action(selected: selectedProduct?.id)
        let price = selectedProduct.flatMap { store.showsPrice(of: $0) ? $0.displayPrice : nil }
        let label: String
        switch action {
        case .choose: label = Textos.escolhaUmAcesso
        case .subscribeYearly: label = Textos.botaoAssinarAnual(price)
        case .subscribeMonthly: label = Textos.botaoAssinarMensal(price)
        case .buyPermanent: label = Textos.botaoComprarPermanente(price)
        }
        let enabled = action != .choose && !store.busy
        return Button {
            if let product = selectedProduct { Task { await store.buy(product) } }
        } label: {
            Text(store.busy ? Textos.processando : label)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(enabled || store.busy ? .black : SheetStyle.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(enabled || store.busy ? Color.white : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .opacity(store.busy ? 0.7 : 1)
        }
        .buttonStyle(PrimaryPressStyle())
        .disabled(!enabled)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(store.busy)
        .opacity(store.busy ? 0.5 : 1)
    }

    // MARK: - Painéis de resultado

    private var paidPanel: some View {
        resultPanel(
            icon: "checkmark.circle.fill", iconColor: green, title: Textos.acessoLiberado, text: Textos.acessoLiberadoTexto,
            button: Textos.fechar)
    }

    private var pendingPanel: some View {
        resultPanel(
            icon: "clock", iconColor: SheetStyle.muted, title: Textos.emAnaliseTitulo, text: Textos.emAnaliseTexto,
            button: Textos.entendi)
    }

    private func resultPanel(icon: String, iconColor: Color, title: String, text: String, button: String) -> some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 52)).foregroundColor(iconColor)
                Text(title).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text(text)
                    .font(.system(size: 16)).foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            Spacer()
            Button(action: onClose) {
                Text(button)
                    .font(.system(size: 17, weight: .semibold)).foregroundColor(.black)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PrimaryPressStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Mensagens da loja

    private func isSuccessMessage(_ m: String) -> Bool { m == Textos.compraConcluida || m == Textos.comprasRestauradas }

    private func isFailureMessage(_ m: String) -> Bool {
        [Textos.compraFalhou, Textos.compraNaoVerificada, Textos.restaurarFalhou, Textos.resgatarFalhou].contains(m)
    }
}

private extension View {
    /// Se o conteúdo cabe na tela, não rola nem "balança": assim puxar para baixo fecha a folha sem disputar com a rolagem.
    /// Se não cabe (letra grande, tela pequena), rola normalmente e a folha só fecha puxando com a lista no topo.
    @ViewBuilder func fitsWithoutBounce() -> some View {
        if #available(iOS 16.4, *) {
            self.scrollBounceBehavior(.basedOnSize)
        } else {
            self
        }
    }
}
