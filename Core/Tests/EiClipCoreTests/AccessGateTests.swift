import XCTest
@testable import EiClipCore

final class AccessGateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    private func eval(
        _ store: StoreAnswer, last: LastConfirmed = .none, used: Int = 0, at: Date? = nil
    ) -> AccessResult {
        AccessGate.evaluate(store: store, last: last, now: at ?? now, freeClipsUsed: used)
    }

    private func answered(
        permanent: Bool = false, sub: SubscriptionStatus? = nil, pending: Bool = false
    ) -> StoreAnswer {
        .answered(permanent: permanent, subscription: sub, purchasePending: pending)
    }

    // MARK: - Teste (clipes gratuitos)

    func testSemAcessoComClipesRestantesGrava() {
        let r = eval(answered(), used: 3)
        XCTAssertEqual(r.state, .freeClips(remaining: 7))
        XCTAssertEqual(r.decision, .allowFree(remaining: 7))
        XCTAssertTrue(r.decision.consumesFreeClip)
    }

    func testDoPrimeiroAoDecimoClipeGrava() {
        for used in 0..<10 {
            XCTAssertEqual(eval(answered(), used: used).decision, .allowFree(remaining: 10 - used))
        }
    }

    func testDepoisDoDecimoAbreAEscolhaDeAcesso() {
        let r = eval(answered(), used: 10)
        XCTAssertEqual(r.state, .freeClips(remaining: 0))
        XCTAssertEqual(r.decision, .showPlans(.freeClipsUsed))
        XCTAssertFalse(r.decision.allowsRecording)
    }

    func testContadorAlemDeDezNaoQuebra() {
        XCTAssertEqual(eval(answered(), used: 25).decision, .showPlans(.freeClipsUsed))
        XCTAssertEqual(eval(answered(), used: -3).decision, .allowFree(remaining: 10))
    }

    // MARK: - Acesso pago não consome os gratuitos

    func testPermanenteGravaSemConsumirGratuitos() {
        let r = eval(answered(permanent: true), used: 10)
        XCTAssertEqual(r.state, .permanent)
        XCTAssertEqual(r.decision, .allowPaid(.permanent))
        XCTAssertFalse(r.decision.consumesFreeClip)
    }

    func testAssinaturaAtivaGravaSemConsumirGratuitos() {
        let end = now.addingTimeInterval(20 * day)
        let r = eval(answered(sub: .active(periodEnd: end)), used: 10)
        XCTAssertEqual(r.state, .subscribed(periodEnd: end))
        XCTAssertEqual(r.decision, .allowPaid(.subscription))
        XCTAssertFalse(r.decision.consumesFreeClip)
    }

    // MARK: - Assinatura que terminou: os gratuitos não usados voltam

    func testAssinaturaTerminouMasHaGratuitosNaoUsados() {
        let r = eval(answered(sub: .expired), used: 4)
        XCTAssertEqual(r.state, .subscriptionEnded)
        XCTAssertEqual(r.decision, .allowFree(remaining: 6))
    }

    func testAssinaturaTerminouEGratuitosEsgotados() {
        let r = eval(answered(sub: .expired), used: 10)
        XCTAssertEqual(r.decision, .showPlans(.subscriptionEnded))
    }

    func testRespostaSemNadaAtivoDepoisDeTerAssinadoContaComoTerminada() {
        let last = LastConfirmed(subscriptionPeriodEnd: now.addingTimeInterval(-1 * day))
        let r = eval(answered(), last: last, used: 10)
        XCTAssertEqual(r.state, .subscriptionEnded)
        XCTAssertEqual(r.decision, .showPlans(.subscriptionEnded))
    }

    // MARK: - Revogação e reembolso: sem tolerância

    func testAssinaturaRevogadaNaoRecebeTolerancia() {
        let last = LastConfirmed(subscriptionPeriodEnd: now.addingTimeInterval(10 * day))
        let r = eval(answered(sub: .revoked), last: last, used: 10)
        XCTAssertEqual(r.state, .accessRevoked)
        XCTAssertEqual(r.decision, .showPlans(.accessRevoked))
    }

    func testPermanenteReembolsadoPerdeOAcessoAoConfirmar() {
        let last = LastConfirmed(permanent: true)
        let r = eval(answered(), last: last, used: 10)
        XCTAssertEqual(r.state, .accessRevoked)
        XCTAssertEqual(r.decision, .showPlans(.accessRevoked))
    }

    func testRevogadoComGratuitosNaoUsadosVoltaAoTeste() {
        let r = eval(answered(sub: .revoked), used: 2)
        XCTAssertEqual(r.decision, .allowFree(remaining: 8))
    }

    // MARK: - Compra pendente e problema de pagamento

    func testCompraPendenteNaoLiberaAcesso() {
        let r = eval(answered(pending: true), used: 10)
        XCTAssertEqual(r.state, .purchasePending)
        XCTAssertEqual(r.decision, .showPlans(.freeClipsUsed))
    }

    func testCompraPendenteComGratuitosRestantesSegueATeste() {
        let r = eval(answered(pending: true), used: 5)
        XCTAssertEqual(r.state, .purchasePending)
        XCTAssertEqual(r.decision, .allowFree(remaining: 5))
    }

    func testCarenciaDeCobrancaDaAcessoAteAData() {
        let until = now.addingTimeInterval(3 * day)
        let r = eval(answered(sub: .inGracePeriod(until: until)), used: 10)
        XCTAssertEqual(r.state, .billingProblem(graceUntil: until))
        XCTAssertEqual(r.decision, .allowPaid(.gracePeriod))
    }

    func testCarenciaVencidaNaoDaAcesso() {
        let until = now.addingTimeInterval(-1)
        let r = eval(answered(sub: .inGracePeriod(until: until)), used: 10)
        XCTAssertEqual(r.state, .billingProblem(graceUntil: nil))
        XCTAssertEqual(r.decision, .showPlans(.billingProblem))
    }

    func testCobrancaEmNovaTentativaSemAcesso() {
        let r = eval(answered(sub: .billingRetry), used: 10)
        XCTAssertEqual(r.decision, .showPlans(.billingProblem))
    }

    // MARK: - StoreKit sem resposta: desconhecido não é "sem direito"

    func testSemRespostaENuncaHouveAcessoNaoConcedeNada() {
        let r = eval(.unavailable, used: 10)
        XCTAssertEqual(r.decision, .showPlans(.freeClipsUsed))
    }

    func testSemRespostaENuncaHouveAcessoSegueARegraDosGratuitos() {
        let r = eval(.unavailable, used: 3)
        XCTAssertEqual(r.state, .freeClips(remaining: 7))
        XCTAssertEqual(r.decision, .allowFree(remaining: 7))
    }

    func testPermanenteJaConfirmadoContinuaLiberadoSemInternet() {
        let last = LastConfirmed(permanent: true)
        let r = eval(.unavailable, last: last, used: 10)
        XCTAssertEqual(r.state, .permanent)
        XCTAssertEqual(r.decision, .allowPaid(.offlinePermanent))
    }

    func testPermanenteNaoUsaATolerancaDeSeteDias() {
        let last = LastConfirmed(permanent: true)
        for days in [1.0, 8.0, 30.0, 400.0, 3650.0] {
            let r = eval(.unavailable, last: last, used: 10, at: now.addingTimeInterval(days * day))
            XCTAssertEqual(r.decision, .allowPaid(.offlinePermanent), "dia \(days)")
        }
    }

    func testPermanenteTemPrioridadeSobreAssinaturaVelha() {
        let last = LastConfirmed(permanent: true, subscriptionPeriodEnd: now.addingTimeInterval(-100 * day))
        let r = eval(.unavailable, last: last, used: 10)
        XCTAssertEqual(r.decision, .allowPaid(.offlinePermanent))
    }

    func testAssinaturaDentroDoPeriodoPagoSemInternet() {
        let end = now.addingTimeInterval(40 * day)
        let r = eval(.unavailable, last: LastConfirmed(subscriptionPeriodEnd: end), used: 10)
        XCTAssertEqual(r.state, .subscribed(periodEnd: end))
        XCTAssertEqual(r.decision, .allowPaid(.offlinePaidPeriod))
    }

    func testAssinaturaVencidaHaMenosDeSeteDiasSemInternetUsaTolerancia() {
        let end = now.addingTimeInterval(-6 * day)
        let r = eval(.unavailable, last: LastConfirmed(subscriptionPeriodEnd: end), used: 10)
        XCTAssertEqual(r.state, .subscribedUnconfirmed(periodEnd: end, toleranceEnds: end.addingTimeInterval(7 * day)))
        XCTAssertEqual(r.decision, .allowPaid(.offlineTolerance))
    }

    func testToleranciaTermina7DiasDepoisDoFimDoPeriodo() {
        let end = now.addingTimeInterval(-7 * day)
        let last = LastConfirmed(subscriptionPeriodEnd: end)
        XCTAssertEqual(eval(.unavailable, last: last, used: 10).decision, .allowPaid(.offlineTolerance))
        let late = now.addingTimeInterval(1)
        let r = eval(.unavailable, last: last, used: 10, at: late)
        XCTAssertEqual(r.state, .subscriptionNotConfirmed)
        XCTAssertEqual(r.decision, .showPlans(.subscriptionNotConfirmed))
    }

    func testToleranciaAcabouMasHaGratuitosNaoUsados() {
        let end = now.addingTimeInterval(-30 * day)
        let r = eval(.unavailable, last: LastConfirmed(subscriptionPeriodEnd: end), used: 4)
        XCTAssertEqual(r.state, .subscriptionNotConfirmed)
        XCTAssertEqual(r.decision, .allowFree(remaining: 6))
    }

    // MARK: - Tolerância só vale para "sem resposta", nunca para "a Apple disse que terminou"

    func testAppleDisseQueExpirouNaoHaTolerancia() {
        let end = now.addingTimeInterval(-2 * day)
        let r = eval(answered(sub: .expired), last: LastConfirmed(subscriptionPeriodEnd: end), used: 10)
        XCTAssertEqual(r.state, .subscriptionEnded)
        XCTAssertEqual(r.decision, .showPlans(.subscriptionEnded))
    }

    func testSemRespostaDepoisRespostaDeExpirouTerminaNaHora() {
        let end = now.addingTimeInterval(-2 * day)
        let last = LastConfirmed(subscriptionPeriodEnd: end)
        XCTAssertEqual(eval(.unavailable, last: last, used: 10).decision, .allowPaid(.offlineTolerance))
        XCTAssertEqual(eval(answered(sub: .expired), last: last, used: 10).decision, .showPlans(.subscriptionEnded))
    }

    // MARK: - Constantes e texto

    func testToleranciaESeteDias() {
        XCTAssertEqual(AccessGate.offlineToleranceDays, 7)
        XCTAssertEqual(AccessGate.offlineTolerance, 7 * 86_400)
    }

    func testSoOGratuitoConsomeClipe() {
        XCTAssertTrue(AccessDecision.allowFree(remaining: 1).consumesFreeClip)
        XCTAssertFalse(AccessDecision.allowPaid(.permanent).consumesFreeClip)
        XCTAssertFalse(AccessDecision.allowPaid(.offlineTolerance).consumesFreeClip)
        XCTAssertFalse(AccessDecision.showPlans(.freeClipsUsed).consumesFreeClip)
        XCTAssertTrue(AccessDecision.allowPaid(.permanent).allowsRecording)
        XCTAssertTrue(AccessDecision.allowFree(remaining: 1).allowsRecording)
    }

    func testTextoDoDiagnosticoNaoVemVazio() {
        XCTAssertTrue(eval(answered(), used: 10).logText.contains("escolha de acesso"))
        XCTAssertTrue(eval(answered(permanent: true)).logText.contains("permanente"))
        XCTAssertTrue(eval(answered(), used: 2).logText.contains("gratuito"))
    }
}
