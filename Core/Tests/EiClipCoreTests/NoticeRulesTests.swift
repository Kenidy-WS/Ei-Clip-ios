import XCTest
@testable import EiClipCore

final class NoticeRulesTests: XCTestCase {
    func testDuracaoPorPeso() {
        XCTAssertEqual(NoticeLevel.info.seconds, 3)
        XCTAssertEqual(NoticeLevel.attention.seconds, 6)
        XCTAssertEqual(NoticeLevel.critical.seconds, 10)
    }

    func testOrdemDosPesos() {
        XCTAssertTrue(NoticeLevel.info < .attention)
        XCTAssertTrue(NoticeLevel.attention < .critical)
    }

    func testSemAvisoNaTelaQualquerUmEntra() {
        XCTAssertTrue(NoticeRules.accepts(new: .info, over: nil))
        XCTAssertTrue(NoticeRules.accepts(new: .critical, over: nil))
    }

    func testAvisoMaisLeveNaoApagaOMaisPesado() {
        XCTAssertFalse(NoticeRules.accepts(new: .info, over: .attention))
        XCTAssertFalse(NoticeRules.accepts(new: .info, over: .critical))
        XCTAssertFalse(NoticeRules.accepts(new: .attention, over: .critical))
    }

    func testMesmoPesoOuMaiorSubstitui() {
        XCTAssertTrue(NoticeRules.accepts(new: .info, over: .info))
        XCTAssertTrue(NoticeRules.accepts(new: .attention, over: .info))
        XCTAssertTrue(NoticeRules.accepts(new: .critical, over: .attention))
        XCTAssertTrue(NoticeRules.accepts(new: .critical, over: .critical))
    }
}
