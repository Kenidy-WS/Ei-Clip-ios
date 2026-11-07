import XCTest
@testable import EiClipCore

final class StartWaitRulesTests: XCTestCase {
    func testEsperaAteODoisEMeio() {
        XCTAssertTrue(StartWaitRules.shouldKeepWaiting(waited: 0))
        XCTAssertTrue(StartWaitRules.shouldKeepWaiting(waited: 1.0))
        XCTAssertTrue(StartWaitRules.shouldKeepWaiting(waited: 2.49))
        XCTAssertFalse(StartWaitRules.shouldKeepWaiting(waited: 2.5))
        XCTAssertFalse(StartWaitRules.shouldKeepWaiting(waited: 4))
    }

    func testLimiteCobreUmKeyframePorSegundo() {
        XCTAssertGreaterThan(StartWaitRules.maxWaitSeconds, 1.0)
        XCTAssertLessThan(StartWaitRules.retryInterval, 0.5)
    }

    func testEsperaRealSoDepoisDeCincoCentesimos() {
        XCTAssertFalse(StartWaitRules.wasDelayed(waited: 0.01))
        XCTAssertTrue(StartWaitRules.wasDelayed(waited: 0.3))
    }
}
