import XCTest
@testable import EiClipCore

final class PurchaseResultRulesTests: XCTestCase {
    private let d = Date(timeIntervalSince1970: 1_800_000_000)

    func testAssinaturaComRenovacao() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.yearly, planKind: .renewing(planID: StoreProductID.yearly, renewsOn: d))
        XCTAssertEqual(r, .subscription(planID: StoreProductID.yearly, renewsOn: d))
    }

    func testAssinaturaSemDataDaApple() {
        let r = PurchaseResultRules.content(purchased: StoreProductID.monthly, planKind: .renewalUnknown(until: d))
        XCTAssertEqual(r, .subscription(planID: StoreProductID.monthly, renewsOn: nil))
    }

    func testPermanenteSozinho() {
        XCTAssertEqual(
            PurchaseResultRules.content(purchased: StoreProductID.permanent, planKind: .permanent(extra: .none)), .permanentAlone)
    }

    func testPermanenteComAssinaturaRenovando() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.permanent, planKind: .permanent(extra: .renewing(renewsOn: d)))
        XCTAssertEqual(r, .permanentWithSubscription(.renewing(renewsOn: d)))
    }

    func testPermanenteComProblemaDePagamento() {
        let r = PurchaseResultRules.content(purchased: StoreProductID.permanent, planKind: .permanent(extra: .billingTrouble))
        XCTAssertEqual(r, .permanentWithSubscription(.mayCharge))
    }

    func testPermanenteAindaNaoRecalculadoNaoQuebra() {
        XCTAssertEqual(PurchaseResultRules.content(purchased: StoreProductID.permanent, planKind: .loading), .permanentAlone)
    }

    func testTrocaAgendadaNaoViraCompraNova() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.monthly,
            planKind: .planChange(fromID: StoreProductID.yearly, toID: StoreProductID.monthly, changesOn: d))
        XCTAssertEqual(r, .planChangeScheduled(toID: StoreProductID.monthly, changesOn: d))
    }

    func testToqueNoMensalComAnualAtivoNaoDizAssinaturaNova() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.yearly, requested: StoreProductID.monthly,
            planKind: .renewing(planID: StoreProductID.yearly, renewsOn: d))
        XCTAssertEqual(r, .alreadySubscribed(planID: StoreProductID.yearly, renewsOn: d))
    }

    func testToqueEmOutroPlanoComTrocaAgendadaMostraATroca() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.yearly, requested: StoreProductID.monthly,
            planKind: .planChange(fromID: StoreProductID.yearly, toID: StoreProductID.monthly, changesOn: d))
        XCTAssertEqual(r, .planChangeScheduled(toID: StoreProductID.monthly, changesOn: d))
    }

    func testMesmoPlanoPedidoEDevolvidoEAssinaturaNova() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.monthly, requested: StoreProductID.monthly,
            planKind: .renewing(planID: StoreProductID.monthly, renewsOn: d))
        XCTAssertEqual(r, .subscription(planID: StoreProductID.monthly, renewsOn: d))
    }
}
