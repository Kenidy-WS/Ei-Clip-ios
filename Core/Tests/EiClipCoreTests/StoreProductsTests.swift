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
