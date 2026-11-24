import XCTest
@testable import EiClipCore

final class StoreProductsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    func testIdsFixos() {
        XCTAssertEqual(StoreProductID.all, ["app.eiclip.mensal", "app.eiclip.anual", "app.eiclip.permanente"])
        XCTAssertTrue(StoreProductID.isSubscription("app.eiclip.anual"))
        XCTAssertTrue(StoreProductID.isSubscription("app.eiclip.mensal"))
        XCTAssertFalse(StoreProductID.isSubscription("app.eiclip.permanente"))
        XCTAssertFalse(StoreProductID.isSubscription("outro"))
    }

    func testMapeamentoDosEstados() {
        let end = now.addingTimeInterval(10 * day)
        XCTAssertEqual(StoreMapping.status(raw: .subscribed, periodEnd: end, graceUntil: nil), .active(periodEnd: end))
        XCTAssertEqual(StoreMapping.status(raw: .inBillingRetry, periodEnd: end, graceUntil: nil), .billingRetry)
        XCTAssertEqual(StoreMapping.status(raw: .expired, periodEnd: end, graceUntil: nil), .expired)
        XCTAssertEqual(StoreMapping.status(raw: .revoked, periodEnd: end, graceUntil: nil), .revoked)
    }

    func testCarenciaUsaADataDoIOSOuOMinimoDe6Dias() {
        let end = now
        let grace = now.addingTimeInterval(3 * day)
        XCTAssertEqual(StoreMapping.status(raw: .inGracePeriod, periodEnd: end, graceUntil: grace), .inGracePeriod(until: grace))
        XCTAssertEqual(
            StoreMapping.status(raw: .inGracePeriod, periodEnd: end, graceUntil: nil),
            .inGracePeriod(until: end.addingTimeInterval(6 * day)))
    }

    func testPermanenteVenceTudo() {
        let a = StoreAnswerBuilder.build(permanentOwned: true, subscriptions: [.expired, .revoked], pending: false)
        XCTAssertEqual(a, .answered(permanent: true, subscription: .expired, purchasePending: false))
    }

    func testSemNadaDevolveRespostaValidaVazia() {
        let a = StoreAnswerBuilder.build(permanentOwned: false, subscriptions: [], pending: false)
        XCTAssertEqual(a, .answered(permanent: false, subscription: nil, purchasePending: false))
    }

    func testAtivaGanhaDeTerminadaERevogada() {
        let end = now.addingTimeInterval(5 * day)
        let a = StoreAnswerBuilder.build(permanentOwned: false, subscriptions: [.expired, .active(periodEnd: end), .revoked], pending: false)
        XCTAssertEqual(a, .answered(permanent: false, subscription: .active(periodEnd: end), purchasePending: false))
    }

    func testEntreDuasAtivasVenceAMaisLonga() {
        let curta = SubscriptionStatus.active(periodEnd: now.addingTimeInterval(3 * day))
        let longa = SubscriptionStatus.active(periodEnd: now.addingTimeInterval(300 * day))
        XCTAssertEqual(StoreAnswerBuilder.best([curta, longa]), longa)
        XCTAssertEqual(StoreAnswerBuilder.best([longa, curta]), longa)
    }

    func testOrdemDeMelhorSituacao() {
        let grace = SubscriptionStatus.inGracePeriod(until: now.addingTimeInterval(2 * day))
        XCTAssertEqual(StoreAnswerBuilder.best([.billingRetry, grace, .expired]), grace)
        XCTAssertEqual(StoreAnswerBuilder.best([.expired, .billingRetry, .revoked]), .billingRetry)
        XCTAssertEqual(StoreAnswerBuilder.best([.revoked, .expired]), .expired)
        XCTAssertNil(StoreAnswerBuilder.best([]))
    }

    func testCompraPendenteFicaNaResposta() {
        let a = StoreAnswerBuilder.build(permanentOwned: false, subscriptions: [], pending: true)
        XCTAssertEqual(a, .answered(permanent: false, subscription: nil, purchasePending: true))
        // Pendente nunca concede acesso (AccessGate): sem permanente, sem assinatura, sem direito.
        let r = AccessGate.evaluate(store: a, last: .none, now: now, freeClipsUsed: 10)
        XCTAssertEqual(r.state, .purchasePending)
        XCTAssertFalse(r.decision.allowsRecording)
    }

    func testTextoDoDiagnostico() {
        XCTAssertEqual(StoreAnswer.unavailable.logText, "Apple sem resposta (estado desconhecido)")
        let a = StoreAnswer.answered(permanent: false, subscription: .billingRetry, purchasePending: true)
        XCTAssertEqual(a.logText, "permanente: não · assinatura: problema de pagamento · compra pendente")
        let b = StoreAnswer.answered(permanent: true, subscription: nil, purchasePending: false)
        XCTAssertEqual(b.logText, "permanente: sim · assinatura: nenhuma")
    }
}

// v0.9.39: "terminou" sem internet com a renovação ligada não é resposta da Apple.
final class StoreTrustRulesTests: XCTestCase {
    private let end = Date(timeIntervalSince1970: 1_800_000_000)

    func testRenovacaoLigadaSemMotivoEsperaRenovacao() {
        XCTAssertTrue(StoreTrustRules.renewalExpected(raw: .expired, willAutoRenew: true, hasExpirationReason: false))
    }

    func testCanceladaOuComMotivoTerminouDeVerdade() {
        // O caso do teste de 23/11: Anual cancelado (willAutoRenew=false, motivo 1 = cancelado pelo cliente).
        XCTAssertFalse(StoreTrustRules.renewalExpected(raw: .expired, willAutoRenew: false, hasExpirationReason: true))
        XCTAssertFalse(StoreTrustRules.renewalExpected(raw: .expired, willAutoRenew: false, hasExpirationReason: false))
        XCTAssertFalse(StoreTrustRules.renewalExpected(raw: .expired, willAutoRenew: true, hasExpirationReason: true))
    }

    func testSemDadosDeRenovacaoValeOComportamentoAnterior() {
        XCTAssertFalse(StoreTrustRules.renewalExpected(raw: .expired, willAutoRenew: nil, hasExpirationReason: false))
    }

    func testOutrosEstadosNuncaEsperamRenovacao() {
        for raw in [RawSubscriptionState.subscribed, .inGracePeriod, .inBillingRetry, .revoked] {
            XCTAssertFalse(StoreTrustRules.renewalExpected(raw: raw, willAutoRenew: true, hasExpirationReason: false))
        }
    }

    func testVencidaEsperandoRenovacaoViraSemConfirmacao() {
        XCTAssertEqual(StoreTrustRules.reconcile([.expired], renewalExpected: [true]), .failed)
        XCTAssertEqual(StoreTrustRules.reconcile([.expired, .expired], renewalExpected: [false, true]), .failed)
    }

    func testVencidaDeVerdadeContinuaTerminou() {
        XCTAssertEqual(StoreTrustRules.reconcile([.expired], renewalExpected: [false]), .read([.expired]))
    }

    func testAtivaOuRevogadaNaoMudam() {
        XCTAssertEqual(StoreTrustRules.reconcile([.active(periodEnd: end), .expired], renewalExpected: [false, true]),
                       .read([.active(periodEnd: end), .expired]))
        XCTAssertEqual(StoreTrustRules.reconcile([.revoked], renewalExpected: [false]), .read([.revoked]))
        XCTAssertEqual(StoreTrustRules.reconcile([], renewalExpected: []), .read([]))
    }

    func testComPermanenteContinuaLiberadoSemAssinaturaConfirmada() {
        let read = StoreTrustRules.reconcile([.expired], renewalExpected: [true])
        XCTAssertEqual(StoreAnswerBuilder.build(permanentOwned: true, read: read, pending: false),
                       .answered(permanent: true, subscription: nil, purchasePending: false))
        XCTAssertEqual(StoreAnswerBuilder.build(permanentOwned: false, read: read, pending: false), .unavailable)
    }

    // MARK: - v0.9.42: lista vazia sem internet

    func testListaVaziaSemRedeComPeriodoGuardadoNaoEConfirmada() {
        XCTAssertTrue(StoreTrustRules.emptyListUntrusted(list: [], hadPaidPeriod: true, offlineSignal: true))
    }

    func testListaVaziaComRedeContinuaSendoSemAssinatura() {
        XCTAssertFalse(StoreTrustRules.emptyListUntrusted(list: [], hadPaidPeriod: true, offlineSignal: false))
    }

    func testListaVaziaSemPeriodoGuardadoNaoMudaNada() {
        XCTAssertFalse(StoreTrustRules.emptyListUntrusted(list: [], hadPaidPeriod: false, offlineSignal: true))
    }

    func testListaComAssinaturaNaoEAfetada() {
        let end = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertFalse(StoreTrustRules.emptyListUntrusted(list: [.active(periodEnd: end)], hadPaidPeriod: true, offlineSignal: true))
        XCTAssertFalse(StoreTrustRules.emptyListUntrusted(list: [.revoked], hadPaidPeriod: true, offlineSignal: true))
    }

    func testListaVaziaNaoConfirmadaMantemOPeriodoELiberaPorTolerancia() {
        // Fluxo completo: o resultado `.failed` não apaga o registro e o gate libera dentro dos 7 dias.
        let t0 = Date(timeIntervalSince1970: 1_800_000_000)
        let end = t0.addingTimeInterval(18 * 60)
        let last = LastConfirmed(permanent: false, subscriptionPeriodEnd: end, everSubscribed: true, latestSeen: t0)
        let answer = StoreAnswerBuilder.build(permanentOwned: false, read: .failed, pending: false)
        XCTAssertEqual(answer, .unavailable)
        let kept = ConfirmedAccessRules.updated(last, with: answer, now: t0)
        XCTAssertEqual(kept.subscriptionPeriodEnd, end)
        let decision = AccessGate.evaluate(store: answer, last: kept, now: t0, freeClipsUsed: 10).decision
        if case .allowPaid = decision {} else { XCTFail("deveria liberar por tolerância, veio \(decision)") }
    }
}
