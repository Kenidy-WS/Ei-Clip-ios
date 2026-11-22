import XCTest
@testable import EiClipCore

final class PlanSummaryRulesTests: XCTestCase {
    private let day = Date(timeIntervalSince1970: 1_800_000_000)

    func testCarregandoFicaSemResumo() {
        XCTAssertEqual(PlanSummaryRules.summary(.loading), .none)
    }

    func testClipesGratisEEsgotados() {
        XCTAssertEqual(PlanSummaryRules.summary(.trial(remaining: 7)), .freeClips(remaining: 7))
        XCTAssertEqual(PlanSummaryRules.summary(.trial(remaining: 1)), .freeClips(remaining: 1))
        XCTAssertEqual(PlanSummaryRules.summary(.trial(remaining: 0)), .noFreeClips)
    }

    func testAssinaturaMensalEAnual() {
        XCTAssertEqual(PlanSummaryRules.summary(.renewing(planID: StoreProductID.monthly, renewsOn: day)), .monthly)
        XCTAssertEqual(PlanSummaryRules.summary(.renewing(planID: StoreProductID.yearly, renewsOn: day)), .yearly)
    }

    func testProdutoDesconhecidoFicaSemResumo() {
        XCTAssertEqual(PlanSummaryRules.summary(.renewing(planID: "outro", renewsOn: day)), .none)
    }

    func testTrocaAgendadaMostraOPlanoDeHoje() {
        let kind = PlanScreenKind.planChange(fromID: StoreProductID.yearly, toID: StoreProductID.monthly, changesOn: day)
        XCTAssertEqual(PlanSummaryRules.summary(kind), .yearly)
    }

    func testCanceladaEAtivaSemRenovacaoMostramAData() {
        XCTAssertEqual(PlanSummaryRules.summary(.canceled(until: day)), .endsOn(day))
        XCTAssertEqual(PlanSummaryRules.summary(.renewalUnknown(until: day)), .endsOn(day))
    }

    func testProblemaDePagamentoComEmSemAcesso() {
        XCTAssertEqual(PlanSummaryRules.summary(.billingGrace(until: day)), .checkPayment)
        XCTAssertEqual(PlanSummaryRules.summary(.paused), .checkPayment)
    }

    func testPermanenteComOuSemAssinatura() {
        XCTAssertEqual(PlanSummaryRules.summary(.permanent(extra: .none)), .permanent)
        XCTAssertEqual(PlanSummaryRules.summary(.permanent(extra: .renewing(renewsOn: day))), .permanent)
        XCTAssertEqual(PlanSummaryRules.summary(.permanent(extra: .billingTrouble)), .permanent)
    }

    func testNaoConfirmadoComOuSemTolerancia() {
        XCTAssertEqual(PlanSummaryRules.summary(.unconfirmed(until: day)), .notConfirmed)
        XCTAssertEqual(PlanSummaryRules.summary(.notConfirmed), .notConfirmed)
    }

    func testEncerradaEmAnaliseERevogada() {
        XCTAssertEqual(PlanSummaryRules.summary(.ended), .ended)
        XCTAssertEqual(PlanSummaryRules.summary(.pending), .pending)
        XCTAssertEqual(PlanSummaryRules.summary(.revoked), .revoked)
    }
}
