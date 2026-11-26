import Foundation
import StoreKit
import UIKit

/// C2, etapa 3: compras pelo StoreKit 2 (produtos, compra, restaurar, atualizações, resgatar código).
/// Calcula o acesso com o `AccessGate` e entrega a resposta ao `AccessSnapshot`, que o gate da gravação consulta (etapa 4, v0.9.27).
/// Sem servidor e sem login: a Apple é a fonte da verdade e as transações são verificadas no aparelho.
/// A câmera NÃO observa este objeto: o gate lê o `AccessSnapshot` (sem @Published). Observam: chip do Início, escolha de acesso e Meu plano.
@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    enum LoadState: Equatable { case idle, loading, loaded, failed }

    @Published private(set) var products: [Product] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var access: AccessResult?
    /// v0.9.31 (5b): o que a tela "Meu plano" mostra. Só muda quando o resultado muda (comparado antes de atribuir).
    @Published private(set) var planKind: PlanScreenKind = .loading
    @Published private(set) var busy = false
    @Published private(set) var message: String?
    @Published private(set) var purchasePending = false
    /// v0.9.34: resultado da última compra feita nesta folha (aprovada ou não concluída); nil = nenhum. Limpo ao fechar a folha.
    enum PurchaseOutcome: Equatable {
        case approved(productID: String, requested: String)
        case failed
    }
    @Published private(set) var outcome: PurchaseOutcome?
    /// Situação de "Meu plano" com o acesso REAL ; só para o texto do resultado da compra. Não publicado.
    private(set) var resultPlanKind: PlanScreenKind = .loading
    func clearOutcome() {
        if outcome != nil { outcome = nil; message = nil }
    }
    /// v0.9.24: ID da assinatura em vigor (para a página Acesso dizer qual plano está ativo); nil se permanente, sem assinatura ou sem resposta.
    @Published private(set) var activePlanID: String?
    private var lastActivePlanID: String?
    /// v0.9.26: produtos cujo preço não deve ser mostrado (moeda diferente da loja). Atribuído ANTES de `products` ser publicado, sem novo @Published.
    private var hiddenPriceIDs: Set<String> = []

    /// Vale para qualquer ambiente: só oculta se a moeda do produto for comprovadamente diferente da moeda da loja.
    func showsPrice(of product: Product) -> Bool { !hiddenPriceIDs.contains(product.id) }

    private var started = false
    private var updatesTask: Task<Void, Never>?
    private var storefrontTask: Task<Void, Never>?
    private var confirmed = ConfirmedAccessStore.shared.current
    private var refreshing = false
    private var refreshAgain = false
    private var lastRefresh: Date?

    /// v0.9.29 (5a): perspectiva da assinatura (renovando, cancelada, carência...). Só informação; NÃO é `@Published` de propósito
    /// (a tela final da 5b decide como publicar). nil = sem assinatura lida (ou sem permissão da Apple agora).
    private(set) var latestOutlook: SubscriptionOutlook?

    /// v0.9.29 (5a): releitura de produtos sem piscar a tela (loja ou conta mudou).
    private var loadingProducts = false
    private var productsReloadPending = false
    /// v0.9.42: o último carregamento de produtos falhou por falta de rede (sinal extra de "sem internet").
    private var productsLoadFailedByNetwork = false
    /// Loja e moeda da última leitura de produtos ("id|moeda"), para perceber troca de loja ao voltar ao app.
    private var lastStorefrontKey: String?

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
        log("StoreKit 2 iniciado (gate de acesso ativo)")
        NetworkPathWatcher.shared.start()
        // v0.9.45: internet voltou com o app aberto: relê a assinatura (e os produtos, se falharam) sem esperar o toque.
        NetworkPathWatcher.shared.setOnReturn { [weak self] in
            Task { @MainActor in await self?.handleNetworkReturned() }
        }
        NotificationCenter.default.addObserver(forName: .eiClipFreeCountChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.recomputeAccess() }
        }
        updatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handleUpdate(result)
            }
        }
        // v0.9.29 (5a): a loja (país/moeda) mudou com o app aberto: relê produtos, preços e direitos.
        storefrontTask = Task { [weak self] in
            for await storefront in Storefront.updates {
                await self?.handleStorefrontChange(storefront)
            }
        }
        await loadProducts()
        await refresh(reason: "abertura")
    }

    /// Ao voltar para o app: confere se a loja mudou (relê tudo se mudou) e relê os direitos se a última leitura tem mais de 60 s.
    func refreshIfStale() async {
        guard started else { return }
        if await storefrontChangedSinceLastLoad() {
            log("loja diferente da última leitura de produtos (ao voltar ao app): relendo produtos e direitos")
            await loadProducts(silent: true)
            await refresh(reason: "loja mudou")
            return
        }
        if let last = lastRefresh, Date().timeIntervalSince(last) < 60 { return }
        await refresh(reason: "app ativo")
    }

    /// v0.9.45: o iOS avisou que a internet voltou. Espera 2 s (a conexão se firmar) e só relê com o app na tela;
    /// fora da tela a releitura fica para a volta ao app (`refreshIfStale`). Não muda a regra de acesso: só dá a resposta da Apple mais cedo.
    private func handleNetworkReturned() async {
        guard started else { return }
        log("rede: voltou (\(NetworkPathWatcher.shared.logText)); releitura em 2 s")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        guard UIApplication.shared.applicationState == .active else {
            log("rede: voltou com o app fora da tela; a releitura fica para a volta ao app")
            return
        }
        if loadState == .failed || products.isEmpty { await loadProducts(silent: true) }
        await refresh(reason: "internet voltou")
    }

    private func storefrontKey(_ store: Storefront?, currency: String?) -> String {
        "\(store?.id ?? "-")|\(currency ?? "-")"
    }

    private func currentStorefrontKey() async -> String {
        let store = await Storefront.current
        var currency: String?
        if #available(iOS 17.0, *) { currency = store?.currency?.identifier }
        return storefrontKey(store, currency: currency)
    }

    private func storefrontChangedSinceLastLoad() async -> Bool {
        let current = await currentStorefrontKey()
        return StorefrontRules.shouldReload(last: lastStorefrontKey, current: current)
    }

    private func handleStorefrontChange(_ storefront: Storefront) async {
        // v0.9.30: o iOS avisa a loja atual assim que o app começa a escutar; só vale reler se a loja ou a moeda mudou de verdade.
        var currency: String?
        if #available(iOS 17.0, *) { currency = storefront.currency?.identifier }
        let key = storefrontKey(storefront, currency: currency)
        guard StorefrontRules.shouldReload(last: lastStorefrontKey, current: key) else {
            log("loja: aviso do iOS sem mudança (país \(storefront.countryCode), id \(storefront.id)); nada a reler")
            return
        }
        log("loja mudou: país \(storefront.countryCode), id \(storefront.id) (relendo produtos e direitos)")
        await loadProducts(silent: true)
        await refresh(reason: "loja mudou")
    }

    // MARK: - Produtos

    /// `silent`: releitura em segundo plano (loja ou conta mudou): não mostra "carregando", não publica nada se nada mudou
    /// e, se falhar, mantém os produtos que já estavam na tela.
    func loadProducts(silent: Bool = false) async {
        if loadingProducts {
            if silent { productsReloadPending = true }
            return
        }
        loadingProducts = true
        repeat {
            productsReloadPending = false
            await loadProductsOnce(silent: silent)
        } while productsReloadPending
        loadingProducts = false
    }

    private func loadProductsOnce(silent: Bool) async {
        let showLoading = !(silent && loadState == .loaded)
        if showLoading { loadState = .loading }
        do {
            let list = try await Product.products(for: StoreProductID.all)
            // v0.9.46: 0 produtos sem erro, com o iOS dizendo que não há rede = falha de rede (não "a loja não tem as opções").
            if list.isEmpty {
                await NetworkPathWatcher.shared.waitUntilKnown(maxSeconds: 1.0)
                if ProductsLoadRules.emptyMeansNetworkFailure(count: list.count, definitelyOffline: NetworkPathWatcher.shared.definitelyOffline) {
                    productsLoadFailedByNetwork = true
                    if showLoading { loadState = .failed }
                    log("produtos: 0 de \(StoreProductID.all.count) sem rede (\(NetworkPathWatcher.shared.logText)): tratado como FALHA DE REDE, não como produtos inexistentes" + (showLoading ? "" : " (releitura silenciosa: os produtos anteriores continuam na tela)"))
                    return
                }
            }
            productsLoadFailedByNetwork = false
            let order = StoreProductID.all
            let store = await Storefront.current
            // v0.9.25 (diagnóstico) + v0.9.26 (proteção): moeda da loja ao lado da moeda de cada produto.
            var storeCurrency: String?
            if #available(iOS 17.0, *) {
                let cur = store?.currency
                storeCurrency = cur?.identifier
            }
            lastStorefrontKey = storefrontKey(store, currency: storeCurrency)
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
            let hiddenChanged = hidden != hiddenPriceIDs
            hiddenPriceIDs = hidden
            let sorted = list.sorted { (order.firstIndex(of: $0.id) ?? 99) < (order.firstIndex(of: $1.id) ?? 99) }
            if products != sorted {
                products = sorted
            } else if hiddenChanged {
                objectWillChange.send()
            }
            if loadState != .loaded { loadState = .loaded }
            if silent { log("produtos relidos (releitura silenciosa)") }
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
            if showLoading { loadState = .failed }
            productsLoadFailedByNetwork = StoreManager.isNetworkError(error)
            log("ERRO ao carregar os produtos: \(error.localizedDescription)" + (showLoading ? "" : " (releitura silenciosa: os produtos anteriores continuam na tela)"))
        }
    }

    /// v0.9.42: erro de falta de rede (URLError ou erro de rede do StoreKit).
    private static func isNetworkError(_ error: Error) -> Bool {
        if let storeError = error as? StoreKitError, case .networkError = storeError { return true }
        let ns = error as NSError
        guard ns.domain == NSURLErrorDomain else { return false }
        let codes = [NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut,
                     NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost, NSURLErrorDataNotAllowed,
                     NSURLErrorInternationalRoamingOff]
        return codes.contains(ns.code)
    }

    // MARK: - Direitos

    /// Lê os direitos na Apple, monta a resposta e calcula o acesso.
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

        // v0.9.29 (5a): a assinatura é lida SEMPRE, também com o permanente ativo. Falha nessa leitura não tira o permanente.
        var reads: [SubscriptionRead] = []
        var failed = false
        lastActivePlanID = nil
        do {
            reads = try await subscriptionReads()
        } catch {
            failed = true
            log("ERRO ao ler as assinaturas na Apple: \(error.localizedDescription)")
            if permanentOwned { log("leitura da assinatura falhou, mas o permanente já confirmado segue valendo") }
        }
        let statuses = reads.map { $0.status }
        // v0.9.39: "terminou" com a renovação ligada e sem motivo da Apple pode ser só o registro do aparelho sem internet.
        var emptyUntrusted = false
        var read: SubscriptionsRead = failed
            ? .failed : StoreTrustRules.reconcile(statuses, renewalExpected: reads.map { $0.renewalExpected })
        // v0.9.42/v0.9.43: sem sinal de rede, "nada" não é resposta confiável quando há acesso pago guardado.
        if !failed, case .read = read {
            let watcher = NetworkPathWatcher.shared
            let offline = watcher.looksOffline || productsLoadFailedByNetwork
            let netText = watcher.logText + (productsLoadFailedByNetwork ? " · produtos falharam por rede" : "")
            if StoreTrustRules.permanentMissingUntrusted(
                permanentOwned: permanentOwned, hadPermanent: confirmed.permanent, offlineSignal: offline) {
                log("permanente: há Permanente guardado, mas a Apple não o devolveu e " + netText
                    + ": tratada como NÃO CONFIRMADA (o Permanente segue liberado, sem prazo; registro mantido)")
                read = .failed
                emptyUntrusted = true
            } else if !permanentOwned, StoreTrustRules.emptyListUntrusted(
                list: statuses, hadPaidPeriod: confirmed.subscriptionPeriodEnd != nil, offlineSignal: offline) {
                log("assinaturas: a Apple devolveu lista VAZIA, mas há período pago guardado e " + netText
                    + ": tratada como NÃO CONFIRMADA (registro mantido; vale o último período confirmado + 7 dias)")
                read = .failed
                emptyUntrusted = true
            } else if statuses.isEmpty && !permanentOwned && (confirmed.subscriptionPeriodEnd != nil || confirmed.permanent) {
                log("direitos: lista vazia com rede (" + watcher.logText + "): a Apple confirmou que não há acesso pago")
            }
        }
        if !failed, !emptyUntrusted, read == .failed {
            log("assinatura vencida, mas a Apple ainda esperava a renovação (renovação automática ligada, sem motivo de término): "
                + "pode ser só o registro do aparelho sem internet; tratada como NÃO CONFIRMADA (vale o último período confirmado + 7 dias)")
        }
        if let best = StoreAnswerBuilder.bestIndex(of: statuses) {
            latestOutlook = reads[best].outlook
            if permanentOwned { log("permanente ativo; assinatura também lida: \(reads[best].outlook.logText(date: StoreManager.formatDate))") }
        } else {
            latestOutlook = nil
        }

        let real: StoreAnswer = StoreAnswerBuilder.build(
            permanentOwned: permanentOwned, read: read, pending: purchasePending)
        // Etapa 6: o registro do último acesso confirmado (Keychain) é atualizado a cada resposta; sem resposta, só avança a data vista.
        let realNow = Date()
        confirmed = ConfirmedAccessStore.shared.apply(answer: real, now: realNow)
        let result = AccessGate.evaluate(
            store: real, last: confirmed, now: ConfirmedAccessRules.effectiveNow(now: realNow, last: confirmed),
            freeClipsUsed: FreeClipCounter.shared.used)
        resultPlanKind = PlanScreenRules.kind(state: result.state, outlook: latestOutlook)
        lastRefresh = Date()
        log("direitos lidos (\(reason)): \(real.logText)")
        log(result.logText)
        AccessSnapshot.shared.update(answer: real, last: confirmed)
        if access != result { access = result }
        updatePlanKind()
        let plan = (permanentOwned || failed) ? nil : lastActivePlanID
        if activePlanID != plan { activePlanID = plan }
    }

    private static func formatDate(_ date: Date) -> String { dateFormatter.string(from: date) }

    /// Recalcula a situação da tela "Meu plano".
    private func updatePlanKind() {
        let kind = PlanScreenRules.kind(state: access?.state, outlook: latestOutlook)
        if planKind != kind {
            log("meu plano: \(kind)")
            planKind = kind
        }
    }

    /// Depois de contar um clipe gratuito: refaz o cálculo com a resposta já guardada (chip e telas mostram o número novo).
    private func recomputeAccess() {
        if let result = AccessSnapshot.shared.evaluate(), access != result {
            access = result
            updatePlanKind()
        }
    }

    /// Uma assinatura lida na Apple: situação (para o `AccessGate`) e perspectiva (só informação).
    private struct SubscriptionRead {
        let status: SubscriptionStatus
        let outlook: SubscriptionOutlook
        /// v0.9.39: vencida, mas a Apple ainda esperava a renovação (dados de renovação verificados).
        let renewalExpected: Bool
    }

    private func subscriptionReads() async throws -> [SubscriptionRead] {
        let list = try await Product.SubscriptionInfo.status(for: StoreProductID.subscriptionGroupID)
        var out: [SubscriptionRead] = []
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
            // v0.9.29 (5a): dados de renovação (só se verificados).
            var renewal: Product.SubscriptionInfo.RenewalInfo?
            if case .verified(let info) = status.renewalInfo { renewal = info }
            var graceUntil: Date?
            if #available(iOS 16.4, *) { graceUntil = renewal?.gracePeriodExpirationDate }
            let end = t.expirationDate ?? .distantPast
            if (raw == .subscribed || raw == .inGracePeriod), end >= bestEnd {
                bestEnd = end
                lastActivePlanID = t.productID
            }
            let mapped = StoreMapping.status(raw: raw, periodEnd: end, graceUntil: graceUntil)
            let outlook = SubscriptionOutlookRules.outlook(
                status: mapped, productID: t.productID, willAutoRenew: renewal?.willAutoRenew,
                autoRenewPreference: renewal?.autoRenewPreference, now: Date())
            log("assinatura \(t.productID): \(raw), período até \(StoreManager.formatDate(end))")
            log("assinatura \(t.productID): \(outlook.logText(date: StoreManager.formatDate))")
            if let renewal = renewal {
                let reason = renewal.expirationReason.map { "\($0)" } ?? "-"
                log("assinatura \(t.productID): dados da Apple · willAutoRenew=\(renewal.willAutoRenew) · preferência=\(renewal.autoRenewPreference ?? "-") · motivo de término=\(reason) · em nova tentativa=\(renewal.isInBillingRetry)")
            } else {
                log("assinatura \(t.productID): dados de renovação ausentes ou não verificados")
            }
            if raw == .inGracePeriod {
                let fallbackEnd = end.addingTimeInterval(Double(StoreMapping.fallbackGraceDays) * 86_400)
                let graceEnd = graceUntil ?? fallbackEnd
                let source = graceUntil == nil
                    ? "data estimada: o iOS não informou, usado o mínimo de \(StoreMapping.fallbackGraceDays) dias"
                    : "data informada pelo iOS"
                log("assinatura \(t.productID): carência de cobrança até \(StoreManager.formatDate(graceEnd)) (\(source))")
            }
            log("preços: assinatura \(t.productID) · \(txInfo(t))")
            let expected = StoreTrustRules.renewalExpected(
                raw: raw, willAutoRenew: renewal?.willAutoRenew, hasExpirationReason: renewal?.expirationReason != nil)
            if raw == .expired {
                log("assinatura \(t.productID): término " + (expected
                    ? "SEM confirmação (renovação ligada, sem motivo da Apple)"
                    : (renewal == nil ? "aceito (sem dados de renovação: comportamento anterior, como reserva)" : "confirmado (renovação desligada ou motivo informado pela Apple)")))
            }
            out.append(SubscriptionRead(status: mapped, outlook: outlook, renewalExpected: expected))
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
        clearOutcome()
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
                    outcome = .approved(productID: t.productID, requested: product.id)
                    log("resultado da compra: aprovada (pedido \(product.id), devolvido pela Apple \(t.productID))")
                case .unverified(let t, _):
                    log("compra NÃO verificada, sem acesso: \(t.productID)")
                    message = Textos.compraNaoVerificada
                    outcome = .failed
                    log("resultado da compra: não concluída (não verificada)")
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
            outcome = .failed
            log("resultado da compra: não concluída (erro)")
        }
    }

    // MARK: - Gerenciar assinatura (v0.9.31)

    /// Abre a tela de assinaturas da Apple (cancelar, trocar de plano, resolver problema de pagamento). O app não mexe no cartão.
    func manageSubscription() async {
        guard !busy else { return }
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let scene else {
            log("gerenciar assinatura: nenhuma tela ativa para abrir a tela da Apple")
            message = Textos.gerenciarFalhou
            return
        }
        busy = true
        message = nil
        defer { busy = false }
        log("gerenciar assinatura: abrindo a tela da Apple")
        do {
            try await AppStore.showManageSubscriptions(in: scene)
            log("gerenciar assinatura: tela fechada")
        } catch {
            if isCancellation(error) {
                log("gerenciar assinatura: tela fechada sem mudança (\(error.localizedDescription))")
            } else {
                log("ERRO ao abrir o gerenciamento da assinatura: \(error.localizedDescription)")
                message = Textos.gerenciarFalhou
            }
        }
        await refresh(reason: "gerenciar assinatura")
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
