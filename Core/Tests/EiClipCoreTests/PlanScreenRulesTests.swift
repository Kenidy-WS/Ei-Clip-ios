import XCTest
@testable import EiClipCore

final class PlanScreenRulesTests: XCTestCase {
    private let d1 = Date(timeIntervalSince1970: 1_800_000_000)
    private let d2 = Date(timeIntervalSince1970: 1_810_000_000)
    private let monthly = StoreProductID.monthly
    private let yearly = StoreProductID.yearly

    private func kind(_ s: AccessState?, _ o: SubscriptionOutlook? = nil) -> PlanScreenKind {
        PlanScreenRules.kind(state: s, outlook: o)
    }

    func testLoadingWithoutState() {
        XCTAssertEqual(kind(nil), .loading)
    }

    func testTrial() {
        XCTAssertEqual(kind(.freeClips(remaining: 4)), .trial(remaining: 4))
    }

    func testSubscribedKinds() {
        let s = AccessState.subscribed(periodEnd: d1)
        XCTAssertEqual(kind(s, .renewing(productID: monthly, periodEnd: d1)), .renewing(planID: monthly, renewsOn: d1))
        XCTAssertEqual(kind(s, .renewingOtherPlan(from: yearly, to: monthly, periodEnd: d1)),
                       .planChange(fromID: yearly, toID: monthly, changesOn: d1))
        XCTAssertEqual(kind(s, .canceledStillPaid(until: d1)), .canceled(until: d1))
    }

    func testSubscribedWithoutOutlookIsRenewalUnknown() {
        let s = AccessState.subscribed(periodEnd: d1)
        XCTAssertEqual(kind(s, nil), .renewalUnknown(until: d1))
        XCTAssertEqual(kind(s, .renewalUnknown(periodEnd: d2)), .renewalUnknown(until: d1))
        // Perspectiva incoerente com o gate (ex.: leitura antiga) nunca vira "renova": cai em "não sei".
        XCTAssertEqual(kind(s, .billingRetry), .renewalUnknown(until: d1))
    }

    func testBillingGraceVersusPaused() {
        XCTAssertEqual(kind(.billingProblem(graceUntil: d1)), .billingGrace(until: d1))
        XCTAssertEqual(kind(.billingProblem(graceUntil: nil)), .paused)
    }

    func testOtherStates() {
        XCTAssertEqual(kind(.subscribedUnconfirmed(periodEnd: d1, toleranceEnds: d2)), .unconfirmed(until: d1))
        XCTAssertEqual(kind(.subscriptionEnded), .ended)
        XCTAssertEqual(kind(.subscriptionNotConfirmed), .notConfirmed)
        XCTAssertEqual(kind(.accessRevoked), .revoked)
        XCTAssertEqual(kind(.purchasePending), .pending)
    }

    func testPermanentExtras() {
        XCTAssertEqual(kind(.permanent, nil), .permanent(extra: .none))
        XCTAssertEqual(kind(.permanent, .renewing(productID: monthly, periodEnd: d1)), .permanent(extra: .renewing(renewsOn: d1)))
        XCTAssertEqual(kind(.permanent, .renewingOtherPlan(from: yearly, to: monthly, periodEnd: d1)),
                       .permanent(extra: .renewing(renewsOn: d1)))
        XCTAssertEqual(kind(.permanent, .billingGrace(until: d1)), .permanent(extra: .billingTrouble))
        XCTAssertEqual(kind(.permanent, .billingRetry), .permanent(extra: .billingTrouble))
        // Sem risco de nova cobrança: nada a mostrar.
        XCTAssertEqual(kind(.permanent, .canceledStillPaid(until: d1)), .permanent(extra: .none))
        XCTAssertEqual(kind(.permanent, .ended), .permanent(extra: .none))
        XCTAssertEqual(kind(.permanent, .revoked), .permanent(extra: .none))
        XCTAssertEqual(kind(.permanent, .renewalUnknown(periodEnd: d1)), .permanent(extra: .none))
    }

    func testPurchaseWarningOnlyWhereChargeIsPossible() {
        XCTAssertEqual(PlanScreenRules.purchaseWarning(.renewing(planID: monthly, renewsOn: d1)), .renewing(renewsOn: d1))
        XCTAssertEqual(PlanScreenRules.purchaseWarning(.planChange(fromID: yearly, toID: monthly, changesOn: d1)), .renewing(renewsOn: d1))
        XCTAssertEqual(PlanScreenRules.purchaseWarning(.billingGrace(until: d1)), .mayCharge)
        XCTAssertEqual(PlanScreenRules.purchaseWarning(.paused), .mayCharge)
        XCTAssertEqual(PlanScreenRules.purchaseWarning(.renewalUnknown(until: d1)), .mayCharge)
        let none: [PlanScreenKind] = [
            .loading, .trial(remaining: 3), .canceled(until: d1), .permanent(extra: .none),
            .permanent(extra: .renewing(renewsOn: d1)), .unconfirmed(until: d1), .ended, .notConfirmed, .revoked, .pending,
        ]
        for k in none { XCTAssertEqual(PlanScreenRules.purchaseWarning(k), .none, "\(k)") }
    }

    func testPurchaseSections() {
        XCTAssertEqual(PlanScreenRules.purchaseSection(.trial(remaining: 0)), .allPlans)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.ended), .allPlans)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.revoked), .allPlans)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.notConfirmed), .allPlans)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.canceled(until: d1)), .permanentOnly)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.paused), .permanentOnly)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.pending), .permanentDisabled)
        // Quem já tem o permanente não vê a compra.
        XCTAssertEqual(PlanScreenRules.purchaseSection(.permanent(extra: .renewing(renewsOn: d1))), .none)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.unconfirmed(until: d1)), .none)
        XCTAssertEqual(PlanScreenRules.purchaseSection(.loading), .none)
    }

    /// Com assinatura que renova só se oferece o permanente: nunca Mensal/Anual (assim a compra não "agenda" troca de plano).
    func testNoSubscriptionPurchaseWhileSubscribed() {
        let subscribed: [PlanScreenKind] = [
            .renewing(planID: monthly, renewsOn: d1), .planChange(fromID: yearly, toID: monthly, changesOn: d1),
            .renewalUnknown(until: d1), .canceled(until: d1), .billingGrace(until: d1), .paused,
        ]
        for k in subscribed { XCTAssertEqual(PlanScreenRules.purchaseSection(k), .permanentOnly, "\(k)") }
    }

    func testManageActions() {
        XCTAssertEqual(PlanScreenRules.manageAction(.renewing(planID: monthly, renewsOn: d1)), .manage)
        XCTAssertEqual(PlanScreenRules.manageAction(.planChange(fromID: yearly, toID: monthly, changesOn: d1)), .manage)
        XCTAssertEqual(PlanScreenRules.manageAction(.billingGrace(until: d1)), .fixPayment)
        XCTAssertEqual(PlanScreenRules.manageAction(.paused), .fixPayment)
        XCTAssertEqual(PlanScreenRules.manageAction(.permanent(extra: .renewing(renewsOn: d1))), .manage)
        XCTAssertEqual(PlanScreenRules.manageAction(.permanent(extra: .billingTrouble)), .manage)
        // Cancelada, encerrada, permanente sozinho e teste: nada a gerenciar.
        XCTAssertEqual(PlanScreenRules.manageAction(.canceled(until: d1)), .none)
        XCTAssertEqual(PlanScreenRules.manageAction(.permanent(extra: .none)), .none)
        XCTAssertEqual(PlanScreenRules.manageAction(.ended), .none)
        XCTAssertEqual(PlanScreenRules.manageAction(.trial(remaining: 2)), .none)
    }

    func testToneNeverGreenForPaymentProblem() {
        XCTAssertEqual(PlanScreenRules.tone(.billingGrace(until: d1)), .amber)
        XCTAssertEqual(PlanScreenRules.tone(.paused), .red)
        XCTAssertEqual(PlanScreenRules.tone(.canceled(until: d1)), .amber)
        XCTAssertEqual(PlanScreenRules.tone(.renewing(planID: monthly, renewsOn: d1)), .green)
        XCTAssertEqual(PlanScreenRules.tone(.planChange(fromID: yearly, toID: monthly, changesOn: d1)), .green)
        XCTAssertEqual(PlanScreenRules.tone(.permanent(extra: .none)), .green)
    }

    func testRecheck() {
        XCTAssertTrue(PlanScreenRules.showsRecheck(.unconfirmed(until: d1)))
        XCTAssertTrue(PlanScreenRules.showsRecheck(.notConfirmed))
        XCTAssertFalse(PlanScreenRules.showsRecheck(.ended))
    }

    /// Estado do gate → tela: o acesso que a tela descreve é o mesmo que o gate concede.
    func testScreenAgreesWithGateAccess() {
        let gateAllows: [(AccessState, Bool)] = [
            (.permanent, true), (.subscribed(periodEnd: d1), true), (.billingProblem(graceUntil: d1), true),
            (.billingProblem(graceUntil: nil), false), (.subscriptionEnded, false), (.accessRevoked, false),
        ]
        for (s, allows) in gateAllows {
            let k = kind(s)
            let pausedLike: Bool = { if case .paused = k { return true }; if case .ended = k { return true }; if case .revoked = k { return true }; return false }()
            XCTAssertEqual(!pausedLike, allows, "\(s)")
        }
    }
}
