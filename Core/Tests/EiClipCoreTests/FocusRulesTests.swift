import XCTest
@testable import EiClipCore

final class FocusRulesTests: XCTestCase {
    func testRecortaPontoParaZeroAUm() {
        let p = FocusRules.clamp(x: -0.2, y: 1.4)
        XCTAssertEqual(p.x, 0)
        XCTAssertEqual(p.y, 1)
        let q = FocusRules.clamp(x: 0.3, y: 0.7)
        XCTAssertEqual(q.x, 0.3)
        XCTAssertEqual(q.y, 0.7)
    }

    func testSoFocaComCameraAbertaETelaAcesa() {
        XCTAssertTrue(FocusRules.canFocus(cameraOpen: true, dimmed: false, testRunning: false, reconfiguring: false))
        XCTAssertFalse(FocusRules.canFocus(cameraOpen: false, dimmed: false, testRunning: false, reconfiguring: false))
        XCTAssertFalse(FocusRules.canFocus(cameraOpen: true, dimmed: true, testRunning: false, reconfiguring: false))
        XCTAssertFalse(FocusRules.canFocus(cameraOpen: true, dimmed: false, testRunning: true, reconfiguring: false))
        XCTAssertFalse(FocusRules.canFocus(cameraOpen: true, dimmed: false, testRunning: false, reconfiguring: true))
    }

    func testAnelSomeDepoisDoTempo() {
        let mark = FocusMark(id: 1, x: 10, y: 20, at: 100)
        XCTAssertTrue(mark.isVisible(now: 100.5))
        XCTAssertFalse(mark.isVisible(now: 101.3))
    }
}
