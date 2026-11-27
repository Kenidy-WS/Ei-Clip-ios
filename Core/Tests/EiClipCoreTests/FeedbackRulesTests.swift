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

    func testRodadaAnteriorVaziaDizQueNaoHa() {
        let out = FeedbackRules.previousSection("  \n ")
        XCTAssertTrue(out.contains("== Rodada anterior =="))
        XCTAssertTrue(out.contains("não há rodada anterior"))
    }

    func testRodadaAnteriorPequenaVaiCompleta() {
        let out = FeedbackRules.previousSection("linha 1\nlinha 2\nlinha 3")
        XCTAssertTrue(out.contains("(completa: 3 linhas)"))
        XCTAssertTrue(out.contains("linha 1\nlinha 2\nlinha 3"))
    }

    func testRodadaAnteriorGrandeMantemOFinalEmLinhasInteiras() {
        let lines = (1...100).map { "linha \($0) xxxxxxxxxx" }
        let out = FeedbackRules.previousSection(lines.joined(separator: "\n"), maxBytes: 200)
        XCTAssertTrue(out.contains("mais antigas cortadas"))
        XCTAssertTrue(out.contains("linha 100 xxxxxxxxxx"))
        XCTAssertFalse(out.contains("linha 1 xxxxxxxxxx"))
        let body = out.components(separatedBy: "cortadas)\n").last ?? ""
        XCTAssertLessThanOrEqual(body.utf8.count, 200 + 1)
        for line in body.split(separator: "\n") { XCTAssertTrue(line.hasPrefix("linha ")) }
    }
}
