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

    // MARK: Câmera combinada (v0.7.9)

    func testCombinadaNaoReabreEmNenhumaTroca() {
        for a in Lens.allCases {
            for b in Lens.allCases {
                XCTAssertFalse(LensRules.needsReopen(from: a, to: b, combined: true))
            }
        }
        XCTAssertTrue(LensRules.needsReopen(from: .wide, to: .ultraWide, combined: false))
    }

    func testGravandoAindaNaoTrocaParaAUltraAngular() {
        // A troca gravando entre aparelhos continua bloqueada na v0.7.9 (fica para a v0.7.10).
        XCTAssertFalse(LensRules.canSwitch(from: .wide, to: .ultraWide, recording: true))
    }

    func testPontoDeTrocaDaPrincipal() {
        XCTAssertEqual(LensZoom.mainFactor(switchOvers: [2.0]), 2.0)
        XCTAssertEqual(LensZoom.mainFactor(switchOvers: [2.0, 6.0]), 2.0)
        XCTAssertNil(LensZoom.mainFactor(switchOvers: []))
        XCTAssertNil(LensZoom.mainFactor(switchOvers: [1.0]))
    }

    func testFatoresNaCombinada() {
        XCTAssertEqual(LensZoom.factor(for: .ultraWide, mainFactor: 2.0), 1.0)
        XCTAssertEqual(LensZoom.factor(for: .wide, mainFactor: 2.0), 2.0)
        XCTAssertEqual(LensZoom.factor(for: .twoX, mainFactor: 2.0), 4.0)
        XCTAssertEqual(LensZoom.factor(for: .twoX, mainFactor: 1.5), 3.0)
    }

    func testFatoresNoAparelhoSimples() {
        XCTAssertEqual(LensZoom.factor(for: .ultraWide, mainFactor: nil), 1.0)
        XCTAssertEqual(LensZoom.factor(for: .wide, mainFactor: nil), 1.0)
        XCTAssertEqual(LensZoom.factor(for: .twoX, mainFactor: nil), 2.0)
    }

    func testFormatoPrecisaChegarAoDobroDaPrincipal() {
        XCTAssertTrue(LensZoom.fits(main: 2.0, maxZoom: 4.0))
        XCTAssertTrue(LensZoom.fits(main: 2.0, maxZoom: 16.0))
        XCTAssertFalse(LensZoom.fits(main: 2.0, maxZoom: 3.9))
    }
}
