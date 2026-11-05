import XCTest
@testable import EiClipCore

// Gabarito: bindPlayerSwipeDown em ui/clips-view.ts (12 pt, 1,2×, 130 pt, 0,6 pt/ms e 50 pt, 500 pt, 12% e 70%).
final class SwipeRulesTests: XCTestCase {
    func testArrastoParaBaixoPrecisaSerVerticalEPassarDe12() {
        XCTAssertTrue(SwipeRules.isDownDrag(dx: 0, dy: 20))
        XCTAssertTrue(SwipeRules.isDownDrag(dx: 10, dy: 12))
        XCTAssertFalse(SwipeRules.isDownDrag(dx: 0, dy: 11))
        XCTAssertFalse(SwipeRules.isDownDrag(dx: 30, dy: 20))  // 20 < 30 × 1,2
        XCTAssertFalse(SwipeRules.isDownDrag(dx: 0, dy: -40))  // para cima não conta
    }

    func testProgressoDoArrasto() {
        XCTAssertEqual(SwipeRules.dismissProgress(dy: 250), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SwipeRules.dismissProgress(dy: 600), 1)
        XCTAssertEqual(SwipeRules.dismissProgress(dy: -20), 0)
    }

    func testEscalaEOpacidade() {
        XCTAssertEqual(SwipeRules.dismissScale(progress: 0), 1)
        XCTAssertEqual(SwipeRules.dismissScale(progress: 1), 0.88, accuracy: 0.0001)
        XCTAssertEqual(SwipeRules.dismissOpacity(progress: 1), 0.3, accuracy: 0.0001)
    }

    func testFechaPassandoDe130Pontos() {
        XCTAssertTrue(SwipeRules.shouldClose(dy: 131, elapsedMs: 1_000))
        XCTAssertFalse(SwipeRules.shouldClose(dy: 130, elapsedMs: 1_000))
        XCTAssertFalse(SwipeRules.shouldClose(dy: 100, elapsedMs: 1_000))
    }

    func testArremessoRapidoFechaComMaisDe50Pontos() {
        XCTAssertTrue(SwipeRules.shouldClose(dy: 60, elapsedMs: 50))  // 1,2 pt/ms
        XCTAssertFalse(SwipeRules.shouldClose(dy: 40, elapsedMs: 20))  // rápido, mas curto
        XCTAssertFalse(SwipeRules.shouldClose(dy: 60, elapsedMs: 500))  // longo, mas lento
    }
}
