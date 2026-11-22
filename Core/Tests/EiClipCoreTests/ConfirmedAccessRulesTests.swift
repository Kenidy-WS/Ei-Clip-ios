import XCTest
@testable import EiClipCore

final class ConfirmedAccessRulesTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    private func answered(
        permanent: Bool = false, sub: SubscriptionStatus? = nil, pending: Bool = false
    ) -> StoreAnswer {
        .answered(permanent: permanent, subscription: sub, purchasePending: pending)
    }

    private func gate(_ store: StoreAnswer, _ last: LastConfirmed, at now: Date) -> AccessDecision {
        let n = ConfirmedAccessRules.effectiveNow(now: now, last: last)
        return AccessGate.evaluate(store: store, last: last, now: n, freeClipsUsed: 10).decision
    }

    // MARK: - Registro

    func testRespostaAtivaGuardaOFimDoPeriodo() {
        let end = t0.addingTimeInterval(30 * day)
        let r = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        XCTAssertEqual(r.subscriptionPeriodEnd, end)
        XCTAssertTrue(r.everSubscribed)
        XCTAssertEqual(r.latestSeen, t0)
    }

    func testPermanenteConfirmadoFicaGuardado() {
        let r = ConfirmedAccessRules.updated(.none, with: answered(permanent: true), now: t0)
        XCTAssertTrue(r.permanent)
        XCTAssertTrue(r.everPermanent)
    }

    func testSemRespostaNaoMudaNada() {
        let end = t0.addingTimeInterval(day)
        let before = LastConfirmed(permanent: false, subscriptionPeriodEnd: end, latestSeen: t0)
        let r = ConfirmedAccessRules.updated(before, with: .unavailable, now: t0.addingTimeInterval(100))
        XCTAssertEqual(r.subscriptionPeriodEnd, end)
        XCTAssertEqual(r.latestSeen, t0.addingTimeInterval(100))
    }

    func testExpiradaOuRevogadaApagaOPeriodoConfirmado() {
        let end = t0.addingTimeInterval(day)
        let before = LastConfirmed(subscriptionPeriodEnd: end)
        for status in [SubscriptionStatus.expired, .revoked, .billingRetry] {
            let r = ConfirmedAccessRules.updated(before, with: answered(sub: status), now: t0)
            XCTAssertNil(r.subscriptionPeriodEnd, "\(status)")
            XCTAssertTrue(r.everSubscribed)
        }
    }

    func testRespostaSemAssinaturaApagaOPeriodoConfirmado() {
        let before = LastConfirmed(subscriptionPeriodEnd: t0.addingTimeInterval(day))
        let r = ConfirmedAccessRules.updated(before, with: answered(), now: t0)
        XCTAssertNil(r.subscriptionPeriodEnd)
        XCTAssertTrue(r.everSubscribed)
    }

    func testCarenciaMantemOFimDoPeriodoPagoAnterior() {
        let paidEnd = t0.addingTimeInterval(-day)
        let before = LastConfirmed(subscriptionPeriodEnd: paidEnd)
        let r = ConfirmedAccessRules.updated(before, with: answered(sub: .inGracePeriod(until: t0.addingTimeInterval(5 * day))), now: t0)
        XCTAssertEqual(r.subscriptionPeriodEnd, paidEnd)
    }

    func testCarenciaSemPeriodoAnteriorUsaOFimDaCarencia() {
        let until = t0.addingTimeInterval(5 * day)
        let r = ConfirmedAccessRules.updated(.none, with: answered(sub: .inGracePeriod(until: until)), now: t0)
        XCTAssertEqual(r.subscriptionPeriodEnd, until)
    }

    func testPendenteNaoMudaOPeriodo() {
        let end = t0.addingTimeInterval(day)
        let before = LastConfirmed(subscriptionPeriodEnd: end)
        let r = ConfirmedAccessRules.updated(before, with: answered(sub: .active(periodEnd: end), pending: true), now: t0)
        XCTAssertEqual(r.subscriptionPeriodEnd, end)
    }

    // MARK: - Relógio

    func testRelogioAtrasadoNaoDevolveAcesso() {
        // Período terminou há 8 dias (passou a tolerância); o usuário volta o relógio para dentro do período.
        let end = t0
        let last = LastConfirmed(subscriptionPeriodEnd: end, latestSeen: t0.addingTimeInterval(8 * day))
        let back = t0.addingTimeInterval(-2 * day)
        XCTAssertEqual(gate(.unavailable, last, at: back), .showPlans(.subscriptionNotConfirmed))
    }

    func testRelogioCertoDentroDaToleranciaLibera() {
        let last = LastConfirmed(subscriptionPeriodEnd: t0, latestSeen: t0)
        XCTAssertEqual(gate(.unavailable, last, at: t0.addingTimeInterval(6 * day)), .allowPaid(.offlineTolerance))
    }

    func testAvancarMantemAMaiorData() {
        let last = LastConfirmed(latestSeen: t0)
        XCTAssertEqual(ConfirmedAccessRules.advance(last, now: t0.addingTimeInterval(-50)).record.latestSeen, t0)
        XCTAssertFalse(ConfirmedAccessRules.advance(last, now: t0.addingTimeInterval(-50)).shouldPersist)
    }

    func testAvancarSoGravaDeHoraEmHora() {
        let last = LastConfirmed(latestSeen: t0)
        XCTAssertFalse(ConfirmedAccessRules.advance(last, now: t0.addingTimeInterval(600)).shouldPersist)
        XCTAssertTrue(ConfirmedAccessRules.advance(last, now: t0.addingTimeInterval(3600)).shouldPersist)
        XCTAssertTrue(ConfirmedAccessRules.advance(.none, now: t0).shouldPersist)
    }

    func testRespostaValidaCorrigeRelogioQueFicouAFrente() {
        let last = LastConfirmed(latestSeen: t0.addingTimeInterval(90 * day))
        let r = ConfirmedAccessRules.updated(last, with: answered(), now: t0)
        XCTAssertEqual(r.latestSeen, t0)
    }

    // MARK: - Cenários do roteiro da etapa 6

    func testModoAviaoComAssinaturaDentroDoPeriodo() {
        let end = t0.addingTimeInterval(10 * day)
        let last = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        XCTAssertEqual(gate(.unavailable, last, at: t0.addingTimeInterval(day)), .allowPaid(.offlinePaidPeriod))
    }

    func testOfflineDepoisDoFimDentroDos7Dias() {
        let end = t0.addingTimeInterval(day)
        let last = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        XCTAssertEqual(gate(.unavailable, last, at: end.addingTimeInterval(3 * day)), .allowPaid(.offlineTolerance))
    }

    func testOfflineDepoisDos7DiasBloqueia() {
        let end = t0.addingTimeInterval(day)
        let last = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        XCTAssertEqual(gate(.unavailable, last, at: end.addingTimeInterval(7 * day + 60)), .showPlans(.subscriptionNotConfirmed))
    }

    func testReinstalacaoOfflineComRegistroRestauradoLibera() {
        let end = t0.addingTimeInterval(5 * day)
        let saved = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        let data = ConfirmedAccessRules.encoded(saved)
        guard case .loaded(let restored) = ConfirmedAccessRules.load(from: data) else { return XCTFail("registro não leu") }
        XCTAssertEqual(restored, saved)
        XCTAssertEqual(gate(.unavailable, restored, at: t0.addingTimeInterval(day)), .allowPaid(.offlinePaidPeriod))
    }

    func testOnlineExpiradaNaoTemTolerancia() {
        let end = t0
        let last = ConfirmedAccessRules.updated(
            LastConfirmed(subscriptionPeriodEnd: end), with: answered(sub: .expired), now: t0.addingTimeInterval(2 * day))
        XCTAssertEqual(gate(answered(sub: .expired), last, at: t0.addingTimeInterval(2 * day)), .showPlans(.subscriptionEnded))
    }

    func testOnlineRevogadaNaoTemTolerancia() {
        let last = ConfirmedAccessRules.updated(
            LastConfirmed(subscriptionPeriodEnd: t0.addingTimeInterval(day)), with: answered(sub: .revoked), now: t0)
        XCTAssertEqual(gate(answered(sub: .revoked), last, at: t0), .showPlans(.accessRevoked))
    }

    func testOfflineDepoisConectaEEncontraExpiracaoEncerraNaHora() {
        let end = t0.addingTimeInterval(day)
        var last = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        let later = end.addingTimeInterval(2 * day)
        XCTAssertEqual(gate(.unavailable, last, at: later), .allowPaid(.offlineTolerance))
        last = ConfirmedAccessRules.updated(last, with: answered(sub: .expired), now: later)
        XCTAssertEqual(gate(answered(sub: .expired), last, at: later), .showPlans(.subscriptionEnded))
        // Perdeu a internet de novo no dia seguinte: a tolerância NÃO volta.
        XCTAssertEqual(gate(.unavailable, last, at: later.addingTimeInterval(day)), .showPlans(.freeClipsUsed))
    }

    func testCanceladaSoNotadaAoConectar() {
        // Cancelou, mas o período pago segue até o fim: offline, libera dentro do período.
        let end = t0.addingTimeInterval(20 * day)
        let last = ConfirmedAccessRules.updated(.none, with: answered(sub: .active(periodEnd: end)), now: t0)
        XCTAssertEqual(gate(.unavailable, last, at: t0.addingTimeInterval(10 * day)), .allowPaid(.offlinePaidPeriod))
    }

    func testPermanenteIndependenteDoRelogioEDaAssinatura() {
        let last = ConfirmedAccessRules.updated(.none, with: answered(permanent: true), now: t0)
        XCTAssertEqual(gate(.unavailable, last, at: t0.addingTimeInterval(400 * day)), .allowPaid(.offlinePermanent))
    }

    func testPermanenteRevogadoDepoisDeRespostaValidaNaoVoltaOffline() {
        var last = ConfirmedAccessRules.updated(.none, with: answered(permanent: true), now: t0)
        last = ConfirmedAccessRules.updated(last, with: answered(), now: t0.addingTimeInterval(day))
        XCTAssertFalse(last.permanent)
        XCTAssertEqual(gate(answered(), last, at: t0.addingTimeInterval(day)), .showPlans(.accessRevoked))
        XCTAssertEqual(gate(.unavailable, last, at: t0.addingTimeInterval(2 * day)), .showPlans(.freeClipsUsed))
    }

    func testRegistroIlegivelOuAusente() {
        XCTAssertEqual(ConfirmedAccessRules.load(from: nil), .fresh)
        XCTAssertEqual(ConfirmedAccessRules.load(from: Data("lixo".utf8)), .corrupt)
    }
}
