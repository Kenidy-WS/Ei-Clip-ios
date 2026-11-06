import XCTest
@testable import EiClipCore

final class ReconfigureGateTests: XCTestCase {
    func testSoUmDonoPorVez() {
        var gate = ReconfigureGate()
        XCTAssertTrue(gate.tryBegin())
        XCTAssertFalse(gate.tryBegin())
        XCTAssertTrue(gate.busy)
    }

    func testLiberaEPodePegarDeNovo() {
        var gate = ReconfigureGate()
        XCTAssertTrue(gate.tryBegin())
        gate.end()
        XCTAssertFalse(gate.busy)
        XCTAssertTrue(gate.tryBegin())
    }

    func testToquesSeguidosSoUmPassa() {
        var gate = ReconfigureGate()
        let passed = (0..<17).filter { _ in gate.tryBegin() }.count
        XCTAssertEqual(passed, 1)
    }

    func testFimSemInicioNaoQuebra() {
        var gate = ReconfigureGate()
        gate.end()
        XCTAssertFalse(gate.busy)
    }
}
