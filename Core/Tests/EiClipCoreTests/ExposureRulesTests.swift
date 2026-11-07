import XCTest
@testable import EiClipCore

final class ExposureRulesTests: XCTestCase {
    func testIntervaloLimitadoAMenosDoisAMaisDois() throws {
        let r = try XCTUnwrap(ExposureRules.range(deviceMin: -8, deviceMax: 8))
        XCTAssertEqual(r.lowerBound, -2)
        XCTAssertEqual(r.upperBound, 2)
    }

    func testIntervaloMenorQueODoisFicaComoOAparelhoInforma() throws {
        let r = try XCTUnwrap(ExposureRules.range(deviceMin: -1.5, deviceMax: 1))
        XCTAssertEqual(r.lowerBound, -1.5)
        XCTAssertEqual(r.upperBound, 1)
    }

    func testAparelhoSemAjusteDeBrilhoDevolveNil() {
        XCTAssertNil(ExposureRules.range(deviceMin: 0, deviceMax: 0))
        XCTAssertNil(ExposureRules.range(deviceMin: 0, deviceMax: 2))
        XCTAssertNil(ExposureRules.range(deviceMin: -2, deviceMax: 0))
        XCTAssertNil(ExposureRules.range(deviceMin: .nan, deviceMax: 2))
        XCTAssertNil(ExposureRules.range(deviceMin: -2, deviceMax: .infinity))
    }

    func testClampArredondaAoPassoERecorta() {
        let r = -2.0...2.0
        XCTAssertEqual(ExposureRules.clamp(0.34, in: r), 0.3)
        XCTAssertEqual(ExposureRules.clamp(0.36, in: r), 0.4)
        XCTAssertEqual(ExposureRules.clamp(5, in: r), 2)
        XCTAssertEqual(ExposureRules.clamp(-9, in: r), -2)
        XCTAssertEqual(ExposureRules.clamp(.nan, in: r), 0)
        XCTAssertEqual(ExposureRules.clamp(-0.02, in: r), 0)
        XCTAssertEqual(ExposureRules.clamp(3, in: -1.5...1), 1)
    }

    func testArrastarParaCimaAumentaOBrilho() {
        let r = -2.0...2.0
        XCTAssertEqual(ExposureRules.value(start: 0, translation: -30, in: r), 1)
        XCTAssertEqual(ExposureRules.value(start: 0, translation: 30, in: r), -1)
        XCTAssertEqual(ExposureRules.value(start: 0.5, translation: -15, in: r), 1)
        XCTAssertEqual(ExposureRules.value(start: 0, translation: -500, in: r), 2)
        XCTAssertEqual(ExposureRules.value(start: 0, translation: 500, in: r), -2)
        XCTAssertEqual(ExposureRules.value(start: 0, translation: 0, in: r), 0)
    }

    func testSolAcompanhaODedo() {
        // O sol anda o mesmo que o dedo: arrastar N pontos para cima leva o sol N pontos para cima.
        let r = -2.0...2.0
        let v = ExposureRules.value(start: 0, translation: -45, in: r)
        XCTAssertEqual(ExposureRules.sunOffset(for: v), -45, accuracy: 0.001)
        XCTAssertEqual(ExposureRules.sunOffset(for: 0), 0)
    }

    func testTextoDoValor() {
        XCTAssertEqual(ExposureRules.label(0), "0,0")
        XCTAssertEqual(ExposureRules.label(0.7), "+0,7")
        XCTAssertEqual(ExposureRules.label(-1.2), "-1,2")
        XCTAssertEqual(ExposureRules.label(2), "+2,0")
        XCTAssertEqual(ExposureRules.label(0.04), "0,0")
    }

    func testNeutro() {
        XCTAssertTrue(ExposureRules.isNeutral(0))
        XCTAssertFalse(ExposureRules.isNeutral(0.1))
        XCTAssertFalse(ExposureRules.isNeutral(-0.1))
    }

    func testQuadradoSomeDepoisDoUltimoToqueOuArraste() {
        XCTAssertFalse(ExposureRules.isExpired(markAt: 100, lastTouchAt: 0, now: 102))
        XCTAssertTrue(ExposureRules.isExpired(markAt: 100, lastTouchAt: 0, now: 103.1))
        // Arrastar o sol renova o prazo.
        XCTAssertFalse(ExposureRules.isExpired(markAt: 100, lastTouchAt: 102.5, now: 104))
        XCTAssertTrue(ExposureRules.isExpired(markAt: 100, lastTouchAt: 102.5, now: 105.6))
    }

    func testSoAjustaComTudoPronto() {
        XCTAssertTrue(ExposureRules.canAdjust(supported: true, cameraOpen: true, dimmed: false, testRunning: false, reconfiguring: false))
        XCTAssertFalse(ExposureRules.canAdjust(supported: false, cameraOpen: true, dimmed: false, testRunning: false, reconfiguring: false))
        XCTAssertFalse(ExposureRules.canAdjust(supported: true, cameraOpen: true, dimmed: false, testRunning: false, reconfiguring: true))
        XCTAssertFalse(ExposureRules.canAdjust(supported: true, cameraOpen: true, dimmed: true, testRunning: false, reconfiguring: false))
    }

    func testSolVaiParaAEsquerdaPertoDaBordaDireita() {
        XCTAssertTrue(ExposureRules.sunOnRight(markX: 150, screenWidth: 393))
        XCTAssertFalse(ExposureRules.sunOnRight(markX: 330, screenWidth: 393))
    }
}
