import XCTest
@testable import EiClipCore

final class NoticeRulesTests: XCTestCase {
    func testDuracaoPorPeso() {
        XCTAssertEqual(NoticeLevel.info.seconds, 3)
        XCTAssertEqual(NoticeLevel.attention.seconds, 6)
        XCTAssertEqual(NoticeLevel.critical.seconds, 10)
    }

    func testTextoCurtoFicaNoMinimoDoPeso() {
        XCTAssertEqual(NoticeRules.duration(level: .info, text: "Clipe salvo."), 3)
        XCTAssertEqual(NoticeRules.duration(level: .attention, text: "Bateria baixa."), 6)
        XCTAssertEqual(NoticeRules.duration(level: .critical, text: "Sem espaço."), 10)
    }

    func testTextoLongoFicaMaisTempo() {
        // Aviso de calor de 22 palavras: 1,5 + 22 × 0,35 = 9,2 s (o mínimo de atenção, 6 s, era curto).
        let text = Array(repeating: "palavra", count: 22).joined(separator: " ")
        XCTAssertEqual(NoticeRules.duration(level: .attention, text: text), 9.2, accuracy: 0.001)
    }

    func testNuncaPassaDoTeto() {
        let text = Array(repeating: "palavra", count: 200).joined(separator: " ")
        XCTAssertEqual(NoticeRules.duration(level: .info, text: text), 12)
    }

    func testArrastarParaCimaFechaOAviso() {
        XCTAssertTrue(NoticeRules.isDismissSwipe(translationY: -20))
        XCTAssertTrue(NoticeRules.isDismissSwipe(translationY: -80))
        XCTAssertFalse(NoticeRules.isDismissSwipe(translationY: -10))
        XCTAssertFalse(NoticeRules.isDismissSwipe(translationY: 40))
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
