import Foundation
import StoreKit
import UIKit

/// C2, etapa 3: compras pelo StoreKit 2 (produtos, compra, restaurar, atualizações, resgatar código).
/// MODO SOMBRA: calcula o acesso com o `AccessGate` e registra no Diagnóstico, mas NÃO bloqueia nada (o gate ativo é a etapa 4).
/// Sem servidor e sem login: a Apple é a fonte da verdade e as transações são verificadas no aparelho.
/// Só a página "Acesso" dos Ajustes observa este objeto; a câmera e as demais telas não dependem dele.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum LoadState: Equatable { case idle, loading, loaded, failed }

    @Published private(set) var products: [Product] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var access: AccessResult?
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    @Published private(set) var purchasePending = false
    /// v0.9.24: ID da assinatura em vigor (para a página Acesso dizer qual plano está ativo); nil se permanente, sem assinatura ou sem resposta.
    @Published private(set) var activePlanID: String?
    private var lastActivePlanID: String?
    /// v0.9.26: produtos cujo preço não deve ser mostrado (moeda diferente da loja). Atribuído ANTES de `products` ser publicado, sem novo @Published.
    private var hiddenPriceIDs: Set<String> = []

    /// Vale para qualquer ambiente: só oculta se a moeda do produto for comprovadamente diferente da moeda da loja.
    func showsPrice(of product: Product) -> Bool { !hiddenPriceIDs.contains(product.id) }

    private var started = false
    private var updatesTask: Task<Void, Never>?
    private var confirmed = LastConfirmed.none
    private var refreshing = false
    private var refreshAgain = false
    private var lastRefresh: Date?

    private func log(_ text: String) { Diagnostics.shared.log("compras", text) }

    /// v0.9.25 (só diagnóstico): ambiente, moeda e valor que a Apple registrou na transação.
    private func txInfo(_ t: StoreKit.Transaction) -> String {
        let price = t.price.map { "\($0)" } ?? "-"
        return "ambiente \(t.environment.rawValue) · moeda da transação \(t.currency?.identifier ?? "-") · valor \(price)"
    }

    /// v0.9.23: fechar a folha da Apple (login ou resgate) sem concluir volta como "Request Canceled": é desistência, não falha.
    private func isCancellation(_ error: Error) -> Bool {
        if let e = error as? StoreKitError, case .userCancelled = e { return true }
        let text = error.localizedDescription.lowercased()
        return text.contains("canceled") || text.contains("cancelled")
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy HH:mm:ss"
        return f
    }()

    // MARK: - Início

    /// Chamado uma vez ao abrir o app: escuta as atualizações da Apple, carrega os produtos e lê os direitos.
    func start() async {
        guard !started else { return }
        started = true
        log("StoreKit 2 iniciado (modo sombra: nada é bloqueado)")
        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleUpdate(result)
            }
        }
        await loadProducts()
        await refresh(reason: "abertura")
    }

    /// Ao voltar para o app: relê os direitos se a última leitura tem mais de 60 s.
    func refreshIfStale() async {
        guard started else { return }
        if let last = lastRefresh, Date().timeIntervalSince(last) < 60 { return }
        await refresh(reason: "app ativo")
    }

    // MARK: - Produtos

    func loadProducts() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let list = try await Product.products(for: StoreProductID.all)
            let order = StoreProductID.all
            let store = await Storefront.current
            // v0.9.25 (diagnóstico) + v0.9.26 (proteção): moeda da loja ao lado da moeda de cada produto.
            var storeCurrency: String?
            if #available(iOS 17.0, *) {
                let cur = store?.currency
                storeCurrency = cur?.identifier
            }
            var hidden: Set<String> = []
            var priceLines: [String] = []
            for p in list {
                let productCurrency = p.priceFormatStyle.currencyCode
                if case .hide(let pc, let sc) = PriceCurrencyGuard.decide(storeCurrency: storeCurrency, productCurrency: productCurrency) {
                    hidden.insert(p.id)
                    priceLines.append("preços: \(p.id) · preço OCULTO na tela (moeda do produto \(pc) ≠ moeda da loja \(sc)); a folha da Apple mostra o valor")
                }
                log("preços: \(p.id) · exibido \(p.displayPrice) · valor \(p.price) · moeda do produto \(productCurrency) · formato \(p.priceFormatStyle.locale.identifier)")
            }
            hiddenPriceIDs = hidden
            products = list.sorted { (order.firstIndex(of: $0.id) ?? 99) < (order.firstIndex(of: $1.id) ?? 99) }
            loadState = .loaded
            let found = list.map { "\($0.id) \($0.displayPrice)" }.joined(separator: ", ")
            log("produtos: \(list.count) de \(order.count) carregados (\(found))")
            let detail = list.map { "\($0.id) valor=\($0.price)" }.joined(separator: ", ")
            log("loja da Apple: país \(store?.countryCode ?? "desconhecido"), id \(store?.id ?? "-") · \(detail)")
            log("preços: loja país \(store?.countryCode ?? "-") · moeda da loja \(storeCurrency ?? "indisponível")")
            priceLines.forEach { log($0) }
            let missing = order.filter { id in !list.contains { $0.id == id } }
            if !missing.isEmpty {
                log("produtos NÃO encontrados na Apple: \(missing.joined(separator: ", ")) (podem levar horas para aparecer depois de criados)")
            }
        } catch {
            loadState = .failed
            log("ERRO ao carregar os produtos: \(error.localizedDescription)")
        }
    }

    // MARK: - Direitos

    /// Lê os direitos na Apple, monta a resposta e calcula o acesso (modo sombra).
    func refresh(reason: String) async {
        if refreshing {
            refreshAgain = true
            return
        }
        refreshing = true
        repeat {
            refreshAgain = false
            await refreshOnce(reason: reason)
        } while refreshAgain
        refreshing = false
    }

    private func refreshOnce(reason: String) async {
        var permanentOwned = false
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let t):
                if t.revocationDate != nil { continue }
                if t.productID == StoreProductID.permanent { permanentOwned = true }
            case .unverified(let t, _):
                log("direito NÃO verificado, ignorado: \(t.productID)")
            }
        }

        var subs: [SubscriptionStatus] = []
        var failed = false
        lastActivePlanID = nil
        if !permanentOwned {
            do {
                subs = try await subscriptionStatuses()
            } catch {
                failed = true
                log("ERRO ao ler as assinaturas na Apple: \(error.localizedDescription)")
            }
        }

        let answer: StoreAnswer = failed
            ? .unavailable
            : StoreAnswerBuilder.build(permanentOwned: permanentOwned, subscriptions: subs, pending: purchasePending)
        if case let .answered(permanent, subscription, _) = answer {
            if permanent { confirmed.permanent = true }
            if case .active(let end)? = subscription {
                confirmed.subscriptionPeriodEnd = max(confirmed.subscriptionPeriodEnd ?? .distantPast, end)
            }
        }
        let result = AccessGate.evaluate(
            store: answer, last: confirmed, now: Date(), freeClipsUsed: FreeClipCounter.shared.used)
        lastRefresh = Date()
        log("direitos lidos (\(reason)): \(answer.logText)")
        log("\(result.logText) [modo sombra]")
        if access != result { access = result }
        let plan = (permanentOwned || failed) ? nil : lastActivePlanID
        if activePlanID != plan { activePlanID = plan }
    }

    private func subscriptionStatuses() async throws -> [SubscriptionStatus] {
        let list = try await Product.SubscriptionInfo.status(for: StoreProductID.subscriptionGroupID)
        var out: [SubscriptionStatus] = []
        var bestEnd = Date.distantPast
        for status in list {
            guard case .verified(let t) = status.transaction else {
                log("assinatura NÃO verificada, ignorada")
                continue
            }
            let raw: RawSubscriptionState
            if status.state == .subscribed {
                raw = .subscribed
            } else if status.state == .inGracePeriod {
                raw = .inGracePeriod
            } else if status.state == .inBillingRetryPeriod {
                raw = .inBillingRetry
            } else if status.state == .revoked {
                raw = .revoked
            } else {
                raw = .expired
            }
            var graceUntil: Date?
            if #available(iOS 16.4, *), case .verified(let info) = status.renewalInfo {
                graceUntil = info.gracePeriodExpirationDate
            }
            let end = t.expirationDate ?? .distantPast
            if (raw == .subscribed || raw == .inGracePeriod), end >= bestEnd {
                bestEnd = end
                lastActivePlanID = t.productID
            }
            log("assinatura \(t.productID): \(raw), período até \(StoreManager.dateFormatter.string(from: end))")
            log("preços: assinatura \(t.productID) · \(txInfo(t))")
            out.append(StoreMapping.status(raw: raw, periodEnd: end, graceUntil: graceUntil))
        }
        return out
    }

    // MARK: - Atualizações da Apple (compra fora do app, renovação, reembolso, código)

    private func handleUpdate(_ result: VerificationResult<StoreKit.Transaction>) async {
        switch result {
        case .verified(let t):
            log("atualização da Apple: \(t.productID)" + (t.revocationDate != nil ? " (revogada)" : ""))
            await t.finish()
            purchasePending = false
            await refresh(reason: "atualização")
        case .unverified(let t, _):
            log("atualização NÃO verificada, ignorada: \(t.productID)")
        }
    }

    // MARK: - Comprar

    func buy(_ product: Product) async {
        guard !busy else { return }
        busy = true
        message = nil
        defer { busy = false }
        log("compra iniciada: \(product.id)")
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let t):
                    await t.finish()
                    purchasePending = false
                    log("compra concluída e verificada: \(t.productID)")
                    log("preços: compra \(t.productID) · \(txInfo(t))")
                    message = Textos.compraConcluida
                    await refresh(reason: "compra")
                case .unverified(let t, _):
                    log("compra NÃO verificada, sem acesso: \(t.productID)")
                    message = Textos.compraNaoVerificada
                }
            case .pending:
                purchasePending = true
                log("compra pendente (aprovação ou autenticação adicional)")
                message = Textos.compraEmAnalise
                await refresh(reason: "compra pendente")
            case .userCancelled:
                log("compra cancelada pelo usuário")
            @unknown default:
                log("compra: resultado desconhecido")
            }
        } catch {
            log("ERRO na compra: \(error.localizedDescription)")
            message = Textos.compraFalhou
        }
    }

    // MARK: - Restaurar e resgatar código

    func restore() async {
        guard !busy else { return }
        busy = true
        message = nil
        defer { busy = false }
        log("restaurar compras: pedido")
        do {
            try await AppStore.sync()
            await refresh(reason: "restaurar")
            if case .allowPaid? = access?.decision {
                message = Textos.comprasRestauradas
            } else {
                message = Textos.nenhumaCompraEncontrada
            }
            log("restaurar compras: concluído")
        } catch {
            if isCancellation(error) {
                log("restaurar compras: cancelado pelo usuário (\(error.localizedDescription))")
            } else {
                log("ERRO ao restaurar as compras: \(error.localizedDescription)")
                message = Textos.restaurarFalhou
            }
        }
    }

    func redeemCode() async {
        guard !busy else { return }
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let scene else {
            log("resgatar código: nenhuma tela ativa para abrir a folha da Apple")
            message = Textos.resgatarFalhou
            return
        }
        busy = true
        message = nil
        defer { busy = false }
        log("resgatar código: abrindo a folha da Apple")
        do {
            try await AppStore.presentOfferCodeRedeemSheet(in: scene)
            log("resgatar código: folha fechada (o resultado chega como atualização da Apple)")
            await refresh(reason: "resgatar código")
        } catch {
            if isCancellation(error) {
                log("resgatar código: folha fechada sem resgatar (\(error.localizedDescription))")
            } else {
                log("ERRO ao resgatar o código: \(error.localizedDescription)")
                message = Textos.resgatarFalhou
            }
            await refresh(reason: "resgatar código")
        }
    }
}
