import XCTest
@testable import EiClipCore

final class PlansScreenRulesTests: XCTestCase {
    private func result(_ state: AccessState, _ decision: AccessDecision) -> AccessResult {
        AccessResult(state: state, decision: decision)
    }

    // MARK: - Início da gravação

    func testSemLeituraDaAppleGravaSemContar() {
        XCTAssertEqual(StartGateRules.decide(nil), .proceed(consumesFree: false))
    }

    func testAcessoPagoGravaSemContar() {
        XCTAssertEqual(StartGateRules.decide(result(.permanent, .allowPaid(.permanent))), .proceed(consumesFree: false))
    }

    func testClipeGratuitoGravaEConta() {
        XCTAssertEqual(
            StartGateRules.decide(result(.freeClips(remaining: 4), .allowFree(remaining: 4))), .proceed(consumesFree: true))
    }

    func testDezUsadosAbreAEscolha() {
        XCTAssertEqual(
            StartGateRules.decide(result(.freeClips(remaining: 0), .showPlans(.freeClipsUsed))), .openPlans(.freeClipsUsed))
    }

    func testCompraPendenteSemClipesAbreOPainelEmAnalise() {
        XCTAssertEqual(
            StartGateRules.decide(result(.purchasePending, .showPlans(.freeClipsUsed))), .openPending)
    }

    func testCompraPendenteComClipesRestantesAindaGrava() {
        XCTAssertEqual(
            StartGateRules.decide(result(.purchasePending, .allowFree(remaining: 2))), .proceed(consumesFree: true))
    }

    func testAssinaturaEncerradaAbreAEscolhaComOMotivo() {
        XCTAssertEqual(
            StartGateRules.decide(result(.subscriptionEnded, .showPlans(.subscriptionEnded))), .openPlans(.subscriptionEnded))
    }

    func testRecuperadoNaoContaComAcessoPagoConfirmado() {
        XCTAssertFalse(StartGateRules.countsRecoveredClip(result(.permanent, .allowPaid(.permanent))))
        XCTAssertTrue(StartGateRules.countsRecoveredClip(result(.freeClips(remaining: 5), .allowFree(remaining: 5))))
        XCTAssertTrue(StartGateRules.countsRecoveredClip(nil))
    }

    // MARK: - Aviso do 7º ao 10º clipe

    func testAvisoSoDoSetimoAoDecimo() {
        XCTAssertNil(FreeClipNotice.remainingToAnnounce(usedAfter: 6))
        XCTAssertEqual(FreeClipNotice.remainingToAnnounce(usedAfter: 7), 3)
        XCTAssertEqual(FreeClipNotice.remainingToAnnounce(usedAfter: 9), 1)
        XCTAssertEqual(FreeClipNotice.remainingToAnnounce(usedAfter: 10), 0)
    }

    // MARK: - Chip

    func testChipCinzaComQuatroOuMais() {
        let chip = HomeChipRules.chip(for: .freeClips(remaining: 4))
        XCTAssertEqual(chip, HomeChip(kind: .remaining(4), isAttention: false, opensPlans: false))
        XCTAssertEqual(HomeChipRules.chip(for: .freeClips(remaining: 10))?.isAttention, false)
    }

    func testChipAmareloComTresOuMenos() {
        XCTAssertEqual(
            HomeChipRules.chip(for: .freeClips(remaining: 3)), HomeChip(kind: .remaining(3), isAttention: true, opensPlans: true))
        XCTAssertEqual(
            HomeChipRules.chip(for: .freeClips(remaining: 1)), HomeChip(kind: .remaining(1), isAttention: true, opensPlans: true))
    }

    func testChipComZeroAbreAEscolha() {
        XCTAssertEqual(
            HomeChipRules.chip(for: .freeClips(remaining: 0)), HomeChip(kind: .used, isAttention: true, opensPlans: true))
    }

    func testChipDeAssinaturaEncerradaERevogada() {
        XCTAssertEqual(HomeChipRules.chip(for: .subscriptionEnded)?.kind, .ended)
        XCTAssertEqual(HomeChipRules.chip(for: .accessRevoked)?.kind, .revoked)
        XCTAssertEqual(HomeChipRules.chip(for: .subscriptionNotConfirmed)?.kind, .notConfirmed)
    }

    func testChipDaCompraPendenteECinza() {
        XCTAssertEqual(HomeChipRules.chip(for: .purchasePending), HomeChip(kind: .pending, isAttention: false, opensPlans: true))
    }

    func testSemChipComAcessoPagoOuSemLeitura() {
        let end = Date(timeIntervalSince1970: 1_900_000_000)
        XCTAssertNil(HomeChipRules.chip(for: nil))
        XCTAssertNil(HomeChipRules.chip(for: .permanent))
        XCTAssertNil(HomeChipRules.chip(for: .subscribed(periodEnd: end)))
        XCTAssertNil(HomeChipRules.chip(for: .subscribedUnconfirmed(periodEnd: end, toleranceEnds: end)))
        XCTAssertNil(HomeChipRules.chip(for: .billingProblem(graceUntil: end)))
    }

    func testProblemaDePagamentoSemCarenciaAbreAEscolha() {
        XCTAssertEqual(HomeChipRules.chip(for: .billingProblem(graceUntil: nil))?.kind, .billing)
    }

    func testMotivoDaEscolhaPeloChip() {
        XCTAssertNil(HomeChipRules.chip(for: .freeClips(remaining: 2))?.plansReason)
        XCTAssertEqual(HomeChipRules.chip(for: .freeClips(remaining: 0))?.plansReason, .freeClipsUsed)
        XCTAssertEqual(HomeChipRules.chip(for: .subscriptionEnded)?.plansReason, .subscriptionEnded)
        XCTAssertEqual(HomeChipRules.chip(for: .accessRevoked)?.plansReason, .accessRevoked)
        XCTAssertNil(HomeChipRules.chip(for: .purchasePending)?.plansReason)
    }

    // MARK: - Economia e valor mensal

    func testEconomiaDoAnualFrenteAoMensal() {
        // 9,90 x 12 = 118,80; anual 59,90 => ~49,6 % => "cerca de 50 %".
        XCTAssertEqual(PlansScreenRules.savingsPercent(monthly: Decimal(string: "9.90")!, yearly: Decimal(string: "59.90")!), 50)
    }

    func testEconomiaPequenaNaoAparece() {
        XCTAssertNil(PlansScreenRules.savingsPercent(monthly: 10, yearly: 110))
        XCTAssertNil(PlansScreenRules.savingsPercent(monthly: 10, yearly: 120))
        XCTAssertNil(PlansScreenRules.savingsPercent(monthly: 0, yearly: 60))
    }

    func testEconomiaDeQuinzePorCentoAparece() {
        XCTAssertEqual(PlansScreenRules.savingsPercent(monthly: 10, yearly: 100), 15)
    }

    func testValorMensalEquivalente() {
        XCTAssertEqual(PlansScreenRules.monthlyEquivalent(yearly: Decimal(string: "59.90")!), Decimal(string: "4.99")!)
    }

    // MARK: - Seleção e botão

    func testNadaVemEscolhidoComVariosProdutos() {
        let all = [StoreProductID.monthly, StoreProductID.yearly, StoreProductID.permanent]
        XCTAssertNil(PlansScreenRules.autoSelection(productIDs: all))
        XCTAssertEqual(PlansScreenRules.action(selected: nil), .choose)
    }

    func testUmUnicoProdutoJaVemEscolhido() {
        XCTAssertEqual(PlansScreenRules.autoSelection(productIDs: [StoreProductID.permanent]), StoreProductID.permanent)
    }

    func testAcaoDoBotaoPeloProdutoEscolhido() {
        XCTAssertEqual(PlansScreenRules.action(selected: StoreProductID.yearly), .subscribeYearly)
        XCTAssertEqual(PlansScreenRules.action(selected: StoreProductID.monthly), .subscribeMonthly)
        XCTAssertEqual(PlansScreenRules.action(selected: StoreProductID.permanent), .buyPermanent)
        XCTAssertEqual(PlansScreenRules.action(selected: "outro"), .choose)
    }
}
