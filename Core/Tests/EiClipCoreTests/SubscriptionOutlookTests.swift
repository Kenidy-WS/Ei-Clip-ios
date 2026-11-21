import XCTest
@testable import EiClipCore

final class SubscriptionOutlookTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400
    private let monthly = StoreProductID.monthly
    private let yearly = StoreProductID.yearly

    private func outlook(
        _ status: SubscriptionStatus, product: String? = nil, renews: Bool? = true, preference: String? = nil
    ) -> SubscriptionOutlook {
        SubscriptionOutlookRules.outlook(
            status: status, productID: product ?? monthly, willAutoRenew: renews,
            autoRenewPreference: preference, now: now)
    }

    // MARK: - Classificação

    func testAtivaERenovando() {
        let end = now.addingTimeInterval(20 * day)
        XCTAssertEqual(outlook(.active(periodEnd: end)), .renewing(productID: monthly, periodEnd: end))
        // Preferência igual ao plano atual não é troca.
        XCTAssertEqual(outlook(.active(periodEnd: end), preference: monthly), .renewing(productID: monthly, periodEnd: end))
    }

    func testAtivaECancelada() {
        let end = now.addingTimeInterval(20 * day)
        XCTAssertEqual(outlook(.active(periodEnd: end), renews: false), .canceledStillPaid(until: end))
        // Cancelada vale mais que qualquer preferência de troca.
        XCTAssertEqual(outlook(.active(periodEnd: end), renews: false, preference: yearly), .canceledStillPaid(until: end))
    }

    func testTrocaAgendadaDePlano() {
        let end = now.addingTimeInterval(200 * day)
        XCTAssertEqual(
            outlook(.active(periodEnd: end), product: yearly, preference: monthly),
            .renewingOtherPlan(from: yearly, to: monthly, periodEnd: end))
    }

    func testAtivaSemDadosDeRenovacaoNaoAfirmaNada() {
        let end = now.addingTimeInterval(5 * day)
        XCTAssertEqual(outlook(.active(periodEnd: end), renews: nil), .renewalUnknown(periodEnd: end))
    }

    func testCarenciaEDiferenteDeNovaTentativa() {
        let until = now.addingTimeInterval(3 * day)
        XCTAssertEqual(outlook(.inGracePeriod(until: until)), .billingGrace(until: until))
        XCTAssertEqual(outlook(.billingRetry), .billingRetry)
        // Carência que já passou não dá acesso (igual ao AccessGate).
        XCTAssertEqual(outlook(.inGracePeriod(until: now.addingTimeInterval(-day))), .billingRetry)
        XCTAssertEqual(outlook(.inGracePeriod(until: now)), .billingRetry)
    }

    func testTerminouERevogada() {
        XCTAssertEqual(outlook(.expired), .ended)
        XCTAssertEqual(outlook(.revoked), .revoked)
    }

    // MARK: - Concorda com o AccessGate

    func testPerspectivaConcordaComOAccessGate() {
        let future = now.addingTimeInterval(10 * day)
        let all: [SubscriptionStatus] = [
            .active(periodEnd: future), .inGracePeriod(until: future), .inGracePeriod(until: now.addingTimeInterval(-day)),
            .billingRetry, .expired, .revoked,
        ]
        let renewOptions: [Bool?] = [true, false, nil]
        for status in all {
            for renews in renewOptions {
                let result = AccessGate.evaluate(
                    store: .answered(permanent: false, subscription: status, purchasePending: false),
                    last: .none, now: now, freeClipsUsed: 10)
                let view = outlook(status, renews: renews)
                XCTAssertEqual(
                    view.grantsAccess, result.decision.allowsRecording,
                    "\(status) renova=\(String(describing: renews))")
            }
        }
    }

    // MARK: - Texto do Diagnóstico

    func testTextosDoDiagnostico() {
        let fmt: (Date) -> String = { _ in "DATA" }
        XCTAssertEqual(
            SubscriptionOutlook.renewing(productID: monthly, periodEnd: now).logText(date: fmt),
            "renovação ligada (app.eiclip.mensal): próxima renovação em DATA")
        XCTAssertEqual(
            SubscriptionOutlook.canceledStillPaid(until: now).logText(date: fmt),
            "renovação CANCELADA: acesso até DATA, sem nova cobrança")
        XCTAssertEqual(
            SubscriptionOutlook.renewingOtherPlan(from: yearly, to: monthly, periodEnd: now).logText(date: fmt),
            "renovação ligada, TROCA AGENDADA app.eiclip.anual → app.eiclip.mensal em DATA")
        XCTAssertEqual(
            SubscriptionOutlook.billingGrace(until: now).logText(date: fmt),
            "problema de cobrança, em carência: acesso até DATA")
        XCTAssertEqual(
            SubscriptionOutlook.billingRetry.logText(date: fmt),
            "problema de cobrança, nova tentativa da Apple: sem acesso")
    }

    // MARK: - Leitura da assinatura com o permanente

    func testFalhaNaAssinaturaComPermanenteMantemOPermanente() {
        let a = StoreAnswerBuilder.build(permanentOwned: true, read: .failed, pending: false)
        XCTAssertEqual(a, .answered(permanent: true, subscription: nil, purchasePending: false))
        // Mesmo sem nada confirmado antes, o permanente verificado agora libera.
        let r = AccessGate.evaluate(store: a, last: .none, now: now, freeClipsUsed: 10)
        XCTAssertEqual(r.decision, .allowPaid(.permanent))
    }

    func testFalhaNaAssinaturaSemPermanenteEEstadoDesconhecido() {
        XCTAssertEqual(StoreAnswerBuilder.build(permanentOwned: false, read: .failed, pending: false), .unavailable)
        // Estado desconhecido sem confirmação anterior não concede acesso.
        let r = AccessGate.evaluate(store: .unavailable, last: .none, now: now, freeClipsUsed: 10)
        XCTAssertFalse(r.decision.allowsRecording)
    }

    func testPermanenteMaisAssinaturaLidaGanhaOPermanente() {
        let end = now.addingTimeInterval(9 * day)
        for sub in [SubscriptionStatus.active(periodEnd: end), .expired, .billingRetry, .revoked] {
            let a = StoreAnswerBuilder.build(permanentOwned: true, read: .read([sub]), pending: false)
            XCTAssertEqual(a, .answered(permanent: true, subscription: sub, purchasePending: false))
            let r = AccessGate.evaluate(store: a, last: .none, now: now, freeClipsUsed: 10)
            XCTAssertEqual(r.decision, .allowPaid(.permanent), "\(sub)")
        }
    }

    func testLeituraValidaIgualAoCaminhoAntigo() {
        let end = now.addingTimeInterval(4 * day)
        let list: [SubscriptionStatus] = [.expired, .active(periodEnd: end)]
        XCTAssertEqual(
            StoreAnswerBuilder.build(permanentOwned: false, read: .read(list), pending: true),
            StoreAnswerBuilder.build(permanentOwned: false, subscriptions: list, pending: true))
    }

    func testIndiceDaMelhorSituacao() {
        let end = now.addingTimeInterval(4 * day)
        XCTAssertNil(StoreAnswerBuilder.bestIndex(of: []))
        XCTAssertEqual(StoreAnswerBuilder.bestIndex(of: [.expired, .active(periodEnd: end), .revoked]), 1)
        XCTAssertEqual(StoreAnswerBuilder.bestIndex(of: [.revoked, .billingRetry]), 1)
        XCTAssertEqual(StoreAnswerBuilder.bestIndex(of: [.expired]), 0)
    }
}
