import XCTest
@testable import EiClipCore

final class StallDetectorTests: XCTestCase {
    func testComSinalDeVidaNaoAvisa() {
        var d = StallDetector(threshold: 1)
        XCTAssertNil(d.beat(at: 0))
        XCTAssertNil(d.check(at: 0.5))
        XCTAssertNil(d.beat(at: 0.5))
        XCTAssertNil(d.check(at: 1.4))
    }

    func testAvisaAoPassarDoLimiteUmaVez() {
        var d = StallDetector(threshold: 1)
        _ = d.beat(at: 0)
        XCTAssertNil(d.check(at: 0.9))
        XCTAssertEqual(d.check(at: 1.2), .stalled(seconds: 1.2))
        XCTAssertNil(d.check(at: 1.7))  // não repete antes de 5 s
    }

    func testRepeteACadaCincoSegundos() {
        var d = StallDetector(threshold: 1, repeatEvery: 5)
        _ = d.beat(at: 0)
        XCTAssertNotNil(d.check(at: 1.2))
        XCTAssertNil(d.check(at: 6.0))
        XCTAssertEqual(d.check(at: 6.3), .stalled(seconds: 6.3))
    }

    func testVoltaAResponder() {
        var d = StallDetector(threshold: 1)
        _ = d.beat(at: 0)
        _ = d.check(at: 2)
        XCTAssertEqual(d.beat(at: 3), .recovered(seconds: 3))
        XCTAssertNil(d.beat(at: 3.5))
    }

    func testSemAvisoNaoHaRecuperacao() {
        var d = StallDetector(threshold: 1)
        _ = d.beat(at: 0)
        XCTAssertNil(d.beat(at: 0.5))
    }

    func testPrimeiraConferenciaSoMarcaOInicio() {
        var d = StallDetector(threshold: 1)
        XCTAssertNil(d.check(at: 100))
        XCTAssertNil(d.check(at: 100.5))
        XCTAssertNotNil(d.check(at: 101.2))
    }
}
