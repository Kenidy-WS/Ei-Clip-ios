import XCTest
@testable import EiClipCore

final class TimelineStatsTests: XCTestCase {
    func testVazio() {
        let s = TimelineStats()
        XCTAssertEqual(s.count, 0)
        XCTAssertEqual(s.span, 0)
        XCTAssertEqual(s.summary, "sem amostras")
    }

    func testSequenciaRegularDeVideo30fps() {
        var s = TimelineStats()
        for i in 0...30 { s.add(Double(i) / 30.0) }
        XCTAssertEqual(s.count, 31)
        XCTAssertEqual(s.span, 1.0, accuracy: 1e-9)
        XCTAssertEqual(s.maxGap, 1.0 / 30.0, accuracy: 1e-9)
        XCTAssertEqual(s.bigGaps, 0)
        XCTAssertEqual(s.backwards, 0)
    }

    func testBuracoGrandeEhDetectadoEOndeComecou() {
        var s = TimelineStats()
        for t in [0.0, 0.033, 0.066, 12.8, 12.833] { s.add(t) }
        XCTAssertEqual(s.count, 5)
        XCTAssertEqual(s.bigGaps, 1)
        XCTAssertEqual(s.maxGap, 12.734, accuracy: 1e-6)
        XCTAssertEqual(s.maxGapAt, 0.066, accuracy: 1e-9)
        XCTAssertEqual(s.span, 12.833, accuracy: 1e-9)
    }

    func testRetrocessoEhContadoENaoViraSalto() {
        var s = TimelineStats()
        for t in [0.0, 1.0, 0.5, 1.5] { s.add(t) }
        XCTAssertEqual(s.backwards, 1)
        // 0 → 1 (salto de 1 s) e 0,5 → 1,5 (salto de 1 s): o retrocesso 1 → 0,5 não conta como salto.
        XCTAssertEqual(s.bigGaps, 2)
        XCTAssertEqual(s.maxGap, 1.0, accuracy: 1e-9)
    }

    func testLimiteDeBuracoPodeSerAjustado() {
        var s = TimelineStats(gapLimit: 1.0)
        for t in [0.0, 0.5, 1.2] { s.add(t) }
        XCTAssertEqual(s.bigGaps, 0)
        XCTAssertEqual(s.maxGap, 0.7, accuracy: 1e-9)
    }

    func testResumoMostraOsContadores() {
        var s = TimelineStats()
        for t in [0.0, 1.0, 0.5] { s.add(t) }
        let text = s.summary
        XCTAssertTrue(text.contains("3 amostras"), text)
        XCTAssertTrue(text.contains("saltos > 0.25 s: 1"), text)
        XCTAssertTrue(text.contains("retrocessos: 1"), text)
    }
}
