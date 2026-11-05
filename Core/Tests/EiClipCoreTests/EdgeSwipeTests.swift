import XCTest
@testable import EiClipCore

final class EdgeSwipeTests: XCTestCase {
    func testPrecisaAndar70PontosParaDentro() {
        XCTAssertTrue(EdgeSwipe.accepts(dx: 70, dy: 0, seconds: 0.3))
        XCTAssertFalse(EdgeSwipe.accepts(dx: 69, dy: 0, seconds: 0.3))
        XCTAssertFalse(EdgeSwipe.accepts(dx: -90, dy: 0, seconds: 0.3))  // para fora da tela
    }

    func testPrecisaSerRapido() {
        XCTAssertTrue(EdgeSwipe.accepts(dx: 100, dy: 0, seconds: 0.7))
        XCTAssertFalse(EdgeSwipe.accepts(dx: 100, dy: 0, seconds: 0.71))
    }

    func testPrecisaSerMaisHorizontalQueVertical() {
        XCTAssertTrue(EdgeSwipe.accepts(dx: 100, dy: 60, seconds: 0.3))  // 60 = 0,6 × 100
        XCTAssertFalse(EdgeSwipe.accepts(dx: 100, dy: 61, seconds: 0.3))
        XCTAssertTrue(EdgeSwipe.accepts(dx: 100, dy: -50, seconds: 0.3))  // para cima também
    }
}
