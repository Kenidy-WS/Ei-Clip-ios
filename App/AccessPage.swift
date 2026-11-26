import SwiftUI
import StoreKit

/// Página "Meu plano" dos Ajustes. v0.9.31 (C2, etapa 5b): versão final. A situação vem de `PlanScreenRules` (Core, com testes);
/// aqui só se desenha. Avisos antes de comprar o permanente existem só onde há assinatura que pode cobrar de novo.
struct AccessPage: View {
    @ObservedObject private var store = StoreManager.shared
    @State private var pendingProduct: Product?
    @State private var showBuyWarning = false

    private struct Line {
        let label: String
        let value: String
        var color: Color = .white
    }

    private struct Content {
        let tone: PlanTone
        let title: String
        let subtitle: String
        var lines: [Line] = []
        var note: String?
        var noteColor: Color = SheetStyle.muted
    }

    var body: some View {
        let kind = store.planKind
        let content = content(for: kind)
        let manage = PlanScreenRules.manageAction(kind)
        let section = PlanScreenRules.purchaseSection(kind)
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
            sectionTitle(Textos.secaoSituacao)
            SheetGroup { situationCard(content, recheck: PlanScreenRules.showsRecheck(kind)) }
            if let note = content.note {
                Text(note)
                    .font(.system(size: 14))
                    .foregroundColor(content.noteColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 10)
            }
            sectionTitle(Textos.secaoGerenciamento)
            SheetGroup {
                switch manage {
                case .manage:
                    actionRow(Textos.gerenciarAssinatura, chevron: true) { Task { await store.manageSubscription() } }
                    SheetDivider()
                case .fixPayment:
                    fixPaymentRow
                    SheetDivider()
                case .none:
                    EmptyView()
                }
                actionRow(Textos.restaurarCompras, chevron: true) { Task { await store.restore() } }
                SheetDivider()
                actionRow(Textos.resgatarCodigo, chevron: true) { Task { await store.redeemCode() } }
            }
            purchaseBlock(section: section, kind: kind)
            if case .permanent = kind {
                SheetGroup {
                    SheetRow {
                        Image(systemName: "checkmark").foregroundColor(PlanTone.green.color)
                        Text(Textos.acessoPermanenteAtivo)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .confirmationDialog(Textos.alertaAntesDeContinuar, isPresented: $showBuyWarning, titleVisibility: .visible) {
            Button(Textos.alertaContinuarCompra) {
                if let product = pendingProduct { Task { await store.buy(product) } }
            }
            Button(Textos.gerenciarAssinatura) { Task { await store.manageSubscription() } }
            Button(Textos.alertaVoltar, role: .cancel) {}
        } message: {
            Text(buyAlertText)
        }
    }

    // MARK: - Situação

    private func sectionTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 13))
            .foregroundColor(SheetStyle.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
    }

    private func situationCard(_ c: Content, recheck: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Circle().fill(c.tone.color).frame(width: 12, height: 12).padding(.top, 6).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.title).font(.system(size: 17, weight: .semibold))
                    Text(c.subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.68, green: 0.68, blue: 0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            ForEach(Array(c.lines.enumerated()), id: \.offset) { _, line in
                SheetDivider()
                SheetRow {
                    Text(line.label)
                    Spacer(minLength: 12)
                    Text(line.value).foregroundColor(line.color).multilineTextAlignment(.trailing)
                }
            }
            if recheck {
                SheetDivider()
                Button {
                    Task { await store.refresh(reason: "verificar de novo") }
                } label: {
                    SheetRow {
                        Text(Textos.verificarDeNovo).foregroundColor(SheetStyle.yellow)
                        Spacer()
                        chevronImage
                    }.contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(store.busy)
                .opacity(store.busy ? 0.5 : 1)
            }
        }
    }

    private func day(_ d: Date) -> String { d.formatted(date: .numeric, time: .omitted) }
    /// v0.9.44: data e hora do fim do prazo de 7 dias ("01/12/2026, às 10:31").
    private func dayAndTime(_ d: Date) -> String {
        "\(d.formatted(date: .numeric, time: .omitted)), às \(d.formatted(date: .omitted, time: .shortened))"
    }

    private func planWord(_ id: String) -> String? {
        switch id {
        case StoreProductID.monthly: return Textos.nomeMensalMinusculo
        case StoreProductID.yearly: return Textos.nomeAnualMinusculo
        default: return nil
        }
    }

    private func planName(_ id: String) -> String {
        id == StoreProductID.yearly ? Textos.planoAnualNome : Textos.planoMensalNome
    }

    /// Valor do plano na loja. Só aparece se o preço é confiável (mesma moeda da loja); senão a linha some, nunca chuta.
    private func valueLine(planID: String) -> Line? {
        guard let product = store.products.first(where: { $0.id == planID }), store.showsPrice(of: product) else { return nil }
        let price = planID == StoreProductID.yearly ? Textos.precoPorAnoCurto(product.displayPrice) : Textos.precoPorMesCurto(product.displayPrice)
        return Line(label: Textos.rotuloValor, value: price)
    }

    private func content(for kind: PlanScreenKind) -> Content {
        let tone = PlanScreenRules.tone(kind)
        let muted = SheetStyle.muted
        let amber = PlanTone.amber.color
        switch kind {
        case .loading:
            return Content(tone: tone, title: Textos.tituloVerificando, subtitle: Textos.subtituloVerificando)
        case .trial(let remaining):
            return Content(tone: tone, title: Textos.tituloTeste, subtitle: Textos.subtituloTeste(remaining))
        case let .renewing(planID, date):
            var lines = [Line(label: Textos.rotuloRenovaEm, value: day(date))]
            if let v = valueLine(planID: planID) { lines.append(v) }
            return Content(tone: tone, title: Textos.tituloAssinaturaAtiva(planWord(planID)), subtitle: Textos.subtituloRenova, lines: lines)
        case let .planChange(from, to, date):
            var lines = [
                Line(label: Textos.rotuloPlanoAtual, value: planName(from)),
                Line(label: Textos.rotuloProximoPlano, value: planName(to)),
                Line(label: Textos.rotuloMudancaEm, value: day(date)),
            ]
            if let v = valueLine(planID: to) { lines.append(v) }
            return Content(
                tone: tone, title: Textos.tituloAssinaturaAtiva(planWord(from)),
                subtitle: Textos.subtituloTroca(de: planName(from), para: planName(to), data: day(date)), lines: lines)
        case .renewalUnknown(let until):
            return Content(
                tone: tone, title: Textos.tituloAssinaturaAtiva(nil), subtitle: Textos.subtituloRenovacaoDesconhecida,
                lines: [Line(label: Textos.rotuloValidaAte, value: day(until))])
        case .canceled(let until):
            return Content(
                tone: tone, title: Textos.tituloCancelada, subtitle: Textos.subtituloCancelada,
                lines: [Line(label: Textos.rotuloAcessoAte, value: day(until)), Line(label: Textos.rotuloRenovacao, value: Textos.valorNaoRenova, color: muted)])
        case .billingGrace(let until):
            return Content(
                tone: tone, title: Textos.tituloProblemaPagamento, subtitle: Textos.subtituloCarencia(day(until)),
                lines: [Line(label: Textos.rotuloAcessoAte, value: day(until), color: amber), Line(label: Textos.rotuloNovaTentativa, value: Textos.valorPelaApple, color: muted)])
        case .paused:
            return Content(
                tone: tone, title: Textos.tituloPausado, subtitle: Textos.subtituloPausado,
                lines: [Line(label: Textos.rotuloAcesso, value: Textos.valorPausado, color: PlanTone.red.color)])
        case .permanent(let extra):
            var c = Content(tone: tone, title: Textos.tituloPermanente, subtitle: Textos.subtituloPermanente)
            switch extra {
            case .none: break
            case .renewing(let date):
                c.lines = [Line(label: Textos.rotuloAssinatura, value: Textos.valorRenovacaoAtiva, color: amber), Line(label: Textos.rotuloProximaRenovacao, value: day(date))]
                c.note = Textos.avisoPermanenteRenovando
                c.noteColor = amber
            case .billingTrouble:
                c.lines = [Line(label: Textos.rotuloAssinatura, value: Textos.valorComProblema, color: amber)]
                c.note = Textos.avisoPermanenteProblema
                c.noteColor = amber
            }
            return c
        case .unconfirmed(let until):
            return Content(tone: tone, title: Textos.tituloNaoConfirmada, subtitle: Textos.subtituloNaoConfirmada(dayAndTime(until)))
        case .notConfirmed:
            return Content(tone: tone, title: Textos.tituloNaoConfirmadaFim, subtitle: Textos.subtituloNaoConfirmadaFim)
        case .ended:
            return Content(tone: tone, title: Textos.tituloEncerrada, subtitle: Textos.subtituloEncerrada)
        case .revoked:
            return Content(tone: tone, title: Textos.tituloRevogada, subtitle: Textos.subtituloRevogada)
        case .pending:
            return Content(tone: tone, title: Textos.tituloEmAnalise, subtitle: Textos.subtituloEmAnalise)
        }
    }

    // MARK: - Gerenciar e comprar

    private var fixPaymentRow: some View {
        Button {
            Task { await store.manageSubscription() }
        } label: {
            SheetRow {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Textos.resolverPagamento).font(.system(size: 17, weight: .semibold)).foregroundColor(SheetStyle.yellow)
                    Text(Textos.resolverPagamentoLegenda).font(.system(size: 13)).foregroundColor(SheetStyle.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 8)
                Spacer(minLength: 8)
                chevronImage
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(store.busy)
        .opacity(store.busy ? 0.5 : 1)
    }

    private var chevronImage: some View {
        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(SheetStyle.muted)
    }

    @ViewBuilder private func purchaseBlock(section: PurchaseSection, kind: PlanScreenKind) -> some View {
        switch section {
        case .none:
            EmptyView()
        case .allPlans:
            sectionTitle(Textos.secaoEscolhaPlano)
            productsGroup
        case .permanentOnly, .permanentDisabled:
            sectionTitle(Textos.secaoAcessoPermanente)
            if let product = store.products.first(where: { $0.id == StoreProductID.permanent }) {
                permanentBlock(product, kind: kind, disabled: section == .permanentDisabled)
            } else {
                productsGroup
            }
        }
    }

    private func permanentBlock(_ product: Product, kind: PlanScreenKind, disabled: Bool) -> some View {
        let shows = store.showsPrice(of: product)
        let warning: String? = {
            switch PlanScreenRules.purchaseWarning(kind) {
            case .renewing: return Textos.avisoCompraRenovando
            case .mayCharge: return Textos.avisoCompraPodeCobrar
            case .none: return nil
            }
        }()
        return VStack(spacing: 0) {
            SheetGroup {
                SheetRow {
                    Text(Textos.rotuloPagamentoUnico)
                    Spacer(minLength: 12)
                    Text(shows ? product.displayPrice : Textos.verPreco).foregroundColor(shows ? .white : SheetStyle.muted)
                }
            }
            if !shows {
                noteText(Textos.precoNaFolhaDaApple)
            }
            if let warning { noteText(warning) }
            Button {
                requestBuy(product)
            } label: {
                Text(Textos.comprarPermanente)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(SheetStyle.yellow, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .disabled(store.busy || disabled)
            .opacity(store.busy || disabled ? 0.5 : 1)
            .padding(.bottom, 14)
        }
    }

    private func noteText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(SheetStyle.muted)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 6)
            .padding(.bottom, 10)
    }

    /// Toque em comprar: com assinatura que pode cobrar de novo, o permanente passa antes pelo alerta "Antes de continuar".
    private func requestBuy(_ product: Product) {
        guard !store.busy else { return }
        if product.id == StoreProductID.permanent, PlanScreenRules.purchaseWarning(store.planKind) != .none {
            pendingProduct = product
            showBuyWarning = true
        } else {
            Task { await store.buy(product) }
        }
    }

    private var buyAlertText: String {
        switch PlanScreenRules.purchaseWarning(store.planKind) {
        case .renewing(let date): return Textos.alertaRenovando(day(date))
        case .mayCharge: return Textos.alertaPodeCobrar
        case .none: return ""
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
            VStack(alignment: .leading, spacing: 6) {
                Text(product.displayName)
                Text(kindText(product.id)).font(.system(size: 12)).foregroundColor(SheetStyle.muted)
                if !store.showsPrice(of: product) {
                    Text(Textos.precoNaFolhaDaApple).font(.system(size: 12)).foregroundColor(SheetStyle.muted)
                }
            }
            Spacer(minLength: 12)
            Button {
                requestBuy(product)
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
        .padding(.vertical, 14)
    }

    private func actionRow(_ title: String, chevron: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            SheetRow {
                Text(title)
                Spacer()
                if chevron { chevronImage }
            }.contentShape(Rectangle())
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
}

private extension PlanTone {
    var color: Color {
        switch self {
        case .green: return Color(red: 0.19, green: 0.82, blue: 0.35)  // #30d158
        case .amber: return Color(red: 1.0, green: 0.62, blue: 0.04)  // #ff9f0a
        case .red: return Color(red: 1.0, green: 0.41, blue: 0.38)  // #ff6961
        case .neutral: return Color(red: 0.68, green: 0.68, blue: 0.70)  // #aeaeb2
        }
    }
}
