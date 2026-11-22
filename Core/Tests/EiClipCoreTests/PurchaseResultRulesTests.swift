import XCTest
@testable import EiClipCore

final class PurchaseResultRulesTests: XCTestCase {
    private let d = Date(timeIntervalSince1970: 1_800_000_000)

    func testAssinaturaComRenovacao() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.yearly, requested: StoreProductID.yearly,
            planKind: .renewing(planID: StoreProductID.yearly, renewsOn: d))
        XCTAssertEqual(r, .subscription(planID: StoreProductID.yearly, renewsOn: d))
    }

    func testAssinaturaSemDataDaApple() {
        let r = PurchaseResultRules.content(purchased: StoreProductID.monthly, planKind: .renewalUnknown(until: d))
        XCTAssertEqual(r, .subscription(planID: StoreProductID.monthly, renewsOn: nil))
    }

    func testPlanoDiferenteDoPedidoNaoViraCompraNova() {
        let r = PurchaseResultRules.content(
            purchased: StoreProductID.yearly, requested: StoreProductID.monthly,
            planKind: .renewing(planID: StoreProductID.yearly, renewsOn: d))
        XCTAssertEqual(r, .alreadySubscribed)
    }

    func testTrocaAgendadaOuCanceladaSoOrienta() {
        XCTAssertEqual(
            PurchaseResultRules.content(
                purchased: StoreProductID.yearly, requested: StoreProductID.yearly,
                planKind: .planChange(fromID: StoreProductID.yearly, toID: StoreProductID.monthly, changesOn: d)),
            .alreadySubscribed)
        XCTAssertEqual(
            PurchaseResultRules.content(
                purchased: StoreProductID.yearly, requested: StoreProductID.monthly, planKind: .canceled(until: d)),
            .alreadySubscribed)
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
}
