import XCTest
@testable import EiClipCore

final class SheetLayoutRulesTests: XCTestCase {
    func testSheetHeightByScreen() {
        XCTAssertEqual(SheetLayoutRules.sheetHeight(screenHeight: 932), 640)  // Pro Max
        XCTAssertEqual(SheetLayoutRules.sheetHeight(screenHeight: 852), 640)  // iPhone 15
        XCTAssertEqual(SheetLayoutRules.sheetHeight(screenHeight: 667), 557)  // SE: sobra margem no topo
        XCTAssertEqual(SheetLayoutRules.sheetHeight(screenHeight: 568), 520)  // tela muito baixa: mínimo
    }

    func testSheetAlwaysLeavesTopMarginWhenPossible() {
        for screen in stride(from: 640.0, through: 1000.0, by: 20.0) {
            let h = SheetLayoutRules.sheetHeight(screenHeight: screen)
            XCTAssertLessThanOrEqual(h, SheetLayoutRules.preferredHeight)
            XCTAssertGreaterThanOrEqual(h, SheetLayoutRules.minimumHeight)
            XCTAssertLessThanOrEqual(h, screen - SheetLayoutRules.minTopMargin + 0.001, "tela \(screen)")
        }
    }

    func testMoreBelow() {
        XCTAssertTrue(SheetLayoutRules.hasMoreBelow(contentBottom: 900, viewport: 500))
        XCTAssertFalse(SheetLayoutRules.hasMoreBelow(contentBottom: 500, viewport: 500))
        XCTAssertFalse(SheetLayoutRules.hasMoreBelow(contentBottom: 508, viewport: 500))  // arredondamento
        XCTAssertTrue(SheetLayoutRules.hasMoreBelow(contentBottom: 520, viewport: 500))
        XCTAssertFalse(SheetLayoutRules.hasMoreBelow(contentBottom: 300, viewport: 500))  // conteúdo curto
    }
}
