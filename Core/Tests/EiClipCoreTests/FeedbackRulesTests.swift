import XCTest
@testable import EiClipCore

final class FeedbackRulesTests: XCTestCase {
    func testVazioEEspacosNaoEnviam() {
        XCTAssertFalse(FeedbackRules.canSend(""))
        XCTAssertFalse(FeedbackRules.canSend("   \n  "))
    }

    func testMuitoCurtoNaoEnvia() {
        XCTAssertFalse(FeedbackRules.canSend("ok"))
        XCTAssertFalse(FeedbackRules.canSend("  ok \n"))
    }

    func testRelatoNormalEnvia() {
        XCTAssertTrue(FeedbackRules.canSend("A câmera travou"))
        XCTAssertTrue(FeedbackRules.canSend("abc"))
    }

    func testLimpaAsPontas() {
        XCTAssertEqual(FeedbackRules.clean("  oi, travou \n\n"), "oi, travou")
        XCTAssertEqual(FeedbackRules.clean("linha 1\nlinha 2"), "linha 1\nlinha 2")
    }

    func testLimiteCortaOExcesso() {
        let big = String(repeating: "a", count: FeedbackRules.maximumLength + 50)
        XCTAssertEqual(FeedbackRules.limited(big).count, FeedbackRules.maximumLength)
        XCTAssertEqual(FeedbackRules.limited("curto"), "curto")
    }
}
