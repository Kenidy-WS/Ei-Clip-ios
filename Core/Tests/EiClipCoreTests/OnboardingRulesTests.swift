import XCTest
@testable import EiClipCore

private final class MemoryStore: KeyValueStore {
    var values: [String: Any] = [:]
    func object(forKey key: String) -> Any? { values[key] }
    func set(_ value: Any?, forKey key: String) { values[key] = value }
}

final class OnboardingRulesTests: XCTestCase {
    func testMostraNaPrimeiraAbertura() {
        XCTAssertTrue(OnboardingRules.shouldShowAtLaunch(seen: false, launchRequestPending: false))
    }

    func testNaoMostraDepoisDeConcluido() {
        XCTAssertFalse(OnboardingRules.shouldShowAtLaunch(seen: true, launchRequestPending: false))
        XCTAssertFalse(OnboardingRules.shouldShowAtLaunch(seen: true, launchRequestPending: true))
    }

    func testPedidoDeAbrirCameraAdiaOTutorial() {
        XCTAssertFalse(OnboardingRules.shouldShowAtLaunch(seen: false, launchRequestPending: true))
    }

    func testTresTelasEUltima() {
        XCTAssertEqual(OnboardingRules.pageCount, 3)
        XCTAssertFalse(OnboardingRules.isLast(0))
        XCTAssertFalse(OnboardingRules.isLast(1))
        XCTAssertTrue(OnboardingRules.isLast(2))
    }

    func testSeguinteParaNaUltima() {
        XCTAssertEqual(OnboardingRules.next(after: 0), 1)
        XCTAssertEqual(OnboardingRules.next(after: 1), 2)
        XCTAssertEqual(OnboardingRules.next(after: 2), 2)
        XCTAssertEqual(OnboardingRules.next(after: -4), 1)  // tela inválida conta como a primeira
    }

    func testPreferenciaComecaComoNaoVistoEGuarda() {
        let store = MemoryStore()
        XCTAssertFalse(Preferences(store: store).onboardingSeen)
        Preferences(store: store).onboardingSeen = true
        XCTAssertTrue(Preferences(store: store).onboardingSeen)
    }
}
