import XCTest
@testable import EiClipCore

final class RestartGuardTests: XCTestCase {
    func testTarefaLongaSempreReliga() {
        var g = RestartGuard()
        for _ in 0..<50 {
            XCTAssertTrue(g.taskEnded(lifeSec: 55))
        }
        XCTAssertEqual(g.quickFailures, 0)
    }

    func testDesisteDepoisDeMortesRapidasSeguidas() {
        var g = RestartGuard(minLifeSec: 1.0, maxQuickFailures: 5)
        for _ in 0..<4 {
            XCTAssertTrue(g.taskEnded(lifeSec: 0.2))
        }
        XCTAssertFalse(g.taskEnded(lifeSec: 0.2))  // a 5ª morte rápida seguida
    }

    func testTarefaLongaZeraAContagem() {
        var g = RestartGuard(minLifeSec: 1.0, maxQuickFailures: 3)
        XCTAssertTrue(g.taskEnded(lifeSec: 0.1))
        XCTAssertTrue(g.taskEnded(lifeSec: 0.1))
        XCTAssertTrue(g.taskEnded(lifeSec: 12))  // viveu de verdade: recomeça a contar
        XCTAssertEqual(g.quickFailures, 0)
        XCTAssertTrue(g.taskEnded(lifeSec: 0.1))
        XCTAssertTrue(g.taskEnded(lifeSec: 0.1))
        XCTAssertFalse(g.taskEnded(lifeSec: 0.1))
    }

    func testLimiteDeUmSegundoContaComoVida() {
        var g = RestartGuard(minLifeSec: 1.0, maxQuickFailures: 2)
        XCTAssertTrue(g.taskEnded(lifeSec: 0.99))
        XCTAssertTrue(g.taskEnded(lifeSec: 1.0))  // exatamente 1 s já não é morte rápida
        XCTAssertEqual(g.quickFailures, 0)
    }

    func testResetLibera() {
        var g = RestartGuard(minLifeSec: 1.0, maxQuickFailures: 2)
        _ = g.taskEnded(lifeSec: 0.1)
        XCTAssertFalse(g.taskEnded(lifeSec: 0.1))
        g.reset()
        XCTAssertTrue(g.taskEnded(lifeSec: 0.1))
    }
}
