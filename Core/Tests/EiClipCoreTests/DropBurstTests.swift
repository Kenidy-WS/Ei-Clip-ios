import XCTest

@testable import EiClipCore

final class DropBurstTests: XCTestCase {
    func testPerdasSoltasNaoDisparam() {
        var burst = DropBurst(threshold: 30, window: 5)
        // 18 quadros em 23 minutos (pescaria de 15/11): nunca dispara.
        for i in 0..<18 { XCTAssertFalse(burst.drop(at: Double(i) * 76)) }
    }

    func testSequenciaDisparaUmaVez() {
        var burst = DropBurst(threshold: 30, window: 5)
        var fired = 0
        for i in 0..<100 where burst.drop(at: Double(i) * 0.05) { fired += 1 }
        XCTAssertEqual(fired, 1)
    }

    func testDisparaExatamenteNoLimite() {
        var burst = DropBurst(threshold: 3, window: 5)
        XCTAssertFalse(burst.drop(at: 0))
        XCTAssertFalse(burst.drop(at: 1))
        XCTAssertTrue(burst.drop(at: 2))
    }

    func testJanelaEsqueceOsAntigos() {
        var burst = DropBurst(threshold: 3, window: 5)
        XCTAssertFalse(burst.drop(at: 0))
        XCTAssertFalse(burst.drop(at: 1))
        XCTAssertFalse(burst.drop(at: 10))  // os dois primeiros já saíram da janela
        XCTAssertFalse(burst.drop(at: 11))
        XCTAssertTrue(burst.drop(at: 12))
    }

    func testResetRearma() {
        var burst = DropBurst(threshold: 2, window: 5)
        XCTAssertFalse(burst.drop(at: 0))
        XCTAssertTrue(burst.drop(at: 1))
        XCTAssertFalse(burst.drop(at: 2))
        burst.reset()
        XCTAssertFalse(burst.drop(at: 3))
        XCTAssertTrue(burst.drop(at: 4))
    }
}
