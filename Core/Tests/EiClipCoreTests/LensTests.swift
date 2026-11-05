import XCTest
@testable import EiClipCore

final class LensTests: XCTestCase {
    func testLentesOferecidas() {
        XCTAssertEqual(LensRules.available(position: .back, hasUltraWide: true), [.ultraWide, .wide, .twoX])
        XCTAssertEqual(LensRules.available(position: .back, hasUltraWide: false), [.wide, .twoX])
        XCTAssertEqual(LensRules.available(position: .front, hasUltraWide: true), [.wide])
    }

    func testReabreSoQuandoMudaOAparelho() {
        XCTAssertTrue(LensRules.needsReopen(from: .wide, to: .ultraWide))
        XCTAssertTrue(LensRules.needsReopen(from: .ultraWide, to: .twoX))
        XCTAssertFalse(LensRules.needsReopen(from: .wide, to: .twoX))
    }

    func testGravandoSoTrocaAproximacao() {
        XCTAssertTrue(LensRules.canSwitch(from: .wide, to: .twoX, recording: true))
        XCTAssertFalse(LensRules.canSwitch(from: .wide, to: .ultraWide, recording: true))
        XCTAssertTrue(LensRules.canSwitch(from: .wide, to: .ultraWide, recording: false))
        XCTAssertFalse(LensRules.canSwitch(from: .wide, to: .wide, recording: false))
    }

    func testLenteIndisponivelVoltaParaPrincipal() {
        XCTAssertEqual(LensRules.resolved(.ultraWide, position: .back, hasUltraWide: false), .wide)
        XCTAssertEqual(LensRules.resolved(.twoX, position: .front, hasUltraWide: true), .wide)
        XCTAssertEqual(LensRules.resolved(.ultraWide, position: .back, hasUltraWide: true), .ultraWide)
    }

    func testRotulosEAproximacao() {
        XCTAssertEqual(Lens.allCases.map(\.label), ["0,5×", "1×", "2×"])
        XCTAssertEqual(Lens.twoX.zoomFactor, 2.0)
        XCTAssertEqual(Lens.ultraWide.zoomFactor, 1.0)
    }

    func testRotuloCurtoSemOX() {
        XCTAssertEqual(Lens.allCases.map(\.shortLabel), ["0,5", "1", "2"])
    }
}
