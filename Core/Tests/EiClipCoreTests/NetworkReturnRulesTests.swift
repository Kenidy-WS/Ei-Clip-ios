import XCTest
@testable import EiClipCore

final class NetworkReturnRulesTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    func testVoltouDeSemRedeParaComRedeRele() {
        XCTAssertTrue(NetworkReturnRules.shouldReread(previousOnline: false, nowOnline: true, lastReread: nil, now: now))
    }

    func testPrimeiraInformacaoDoIOSNaAberturaNaoConta() {
        XCTAssertFalse(NetworkReturnRules.shouldReread(previousOnline: nil, nowOnline: true, lastReread: nil, now: now))
    }

    func testJaComRedeNaoRele() {
        XCTAssertFalse(NetworkReturnRules.shouldReread(previousOnline: true, nowOnline: true, lastReread: nil, now: now))
    }

    func testPerderARedeNaoRele() {
        XCTAssertFalse(NetworkReturnRules.shouldReread(previousOnline: true, nowOnline: false, lastReread: nil, now: now))
        XCTAssertFalse(NetworkReturnRules.shouldReread(previousOnline: false, nowOnline: false, lastReread: nil, now: now))
    }

    func testOscilacaoRapidaNaoRelePorDuasVezes() {
        let recent = now.addingTimeInterval(-5)
        XCTAssertFalse(NetworkReturnRules.shouldReread(previousOnline: false, nowOnline: true, lastReread: recent, now: now))
    }

    func testDepoisDoIntervaloReleDeNovo() {
        let old = now.addingTimeInterval(-NetworkReturnRules.minGapSeconds - 1)
        XCTAssertTrue(NetworkReturnRules.shouldReread(previousOnline: false, nowOnline: true, lastReread: old, now: now))
    }
}
