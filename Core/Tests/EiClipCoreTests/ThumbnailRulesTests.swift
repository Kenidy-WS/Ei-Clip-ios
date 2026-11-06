import XCTest
@testable import EiClipCore

final class ThumbnailRulesTests: XCTestCase {
    func testEscuroAbaixoDoLimite() {
        XCTAssertTrue(ThumbnailRules.isTooDark(0.02))
        XCTAssertFalse(ThumbnailRules.isTooDark(0.30))
    }

    func testInstantesFicamDentroDoClipeSemRepetir() {
        let times = ThumbnailRules.candidateTimes(preSec: 15.9, duration: 48.6)
        XCTAssertEqual(times.first!, 16.2, accuracy: 0.001)
        XCTAssertTrue(times.allSatisfy { $0 >= 0 && $0 <= 48.5 })
        XCTAssertEqual(Set(times.map { ($0 * 4).rounded() }).count, times.count)
    }

    func testClipeCurtoDaUmInstanteSoNoLimite() {
        let times = ThumbnailRules.candidateTimes(preSec: 0, duration: 2.4)
        XCTAssertTrue(times.allSatisfy { $0 <= 2.3 })
        XCTAssertGreaterThanOrEqual(times.count, 1)
        XCTAssertEqual(ThumbnailRules.candidateTimes(preSec: 0, duration: 0.1), [0])
    }

    func testEscolheAPrimeiraClaraOuAMaisClara() {
        XCTAssertEqual(ThumbnailRules.pick(lumas: [0.01, 0.4, 0.5]), 1)
        XCTAssertEqual(ThumbnailRules.pick(lumas: [0.01, 0.05, 0.03]), 1)
        XCTAssertEqual(ThumbnailRules.pick(lumas: [0.4]), 0)
        XCTAssertNil(ThumbnailRules.pick(lumas: []))
    }
}
