import XCTest
@testable import EiClipCore

final class TorchRulesTests: XCTestCase {
    func testSoExisteNaTraseiraComLanterna() {
        XCTAssertTrue(TorchRules.isAvailable(position: .back, hasTorch: true))
        XCTAssertFalse(TorchRules.isAvailable(position: .back, hasTorch: false))
        XCTAssertFalse(TorchRules.isAvailable(position: .front, hasTorch: true))
    }

    func testApagaSozinhaComBateriaCriticaOuCalor() {
        XCTAssertNil(TorchRules.autoOffReason(batteryCritical: false, tooHot: false))
        XCTAssertEqual(TorchRules.autoOffReason(batteryCritical: true, tooHot: false), .batteryCritical)
        XCTAssertEqual(TorchRules.autoOffReason(batteryCritical: false, tooHot: true), .tooHot)
        XCTAssertEqual(TorchRules.autoOffReason(batteryCritical: true, tooHot: true), .tooHot)
    }
}
