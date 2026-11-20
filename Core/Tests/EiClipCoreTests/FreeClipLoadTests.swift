import XCTest
@testable import EiClipCore

final class FreeClipLoadTests: XCTestCase {
    func testSemDadosComecaDoZero() {
        XCTAssertEqual(FreeClipLedger.load(from: nil), .fresh)
    }

    func testRegistroGuardadoVoltaIgual() {
        var ledger = FreeClipLedger()
        for _ in 0..<4 { ledger.record(UUID()) }
        let data = ledger.encoded()
        XCTAssertNotNil(data)
        XCTAssertEqual(FreeClipLedger.load(from: data), .loaded(ledger))
    }

    func testDadosIlegiveisViramCorrupt() {
        XCTAssertEqual(FreeClipLedger.load(from: Data("isto nao e json".utf8)), .corrupt)
        XCTAssertEqual(FreeClipLedger.load(from: Data("{\"clipIDs\":[\"nao-e-uuid\"]}".utf8)), .corrupt)
        XCTAssertEqual(FreeClipLedger.load(from: Data()), .corrupt)
    }

    func testRegistroAdulteradoComMaisDeDezNaoPassaDeDez() {
        let ids = (0..<13).map { _ in "\"\(UUID().uuidString)\"" }.joined(separator: ",")
        let json = "{\"clipIDs\":[\(ids)]}"
        guard case .loaded(let ledger) = FreeClipLedger.load(from: Data(json.utf8)) else { return XCTFail("deveria ler") }
        XCTAssertEqual(ledger.used, 10)
        XCTAssertEqual(ledger.remaining, 0)
    }

    func testRegistroComRepetidosContaUmaVez() {
        let id = UUID().uuidString
        let json = "{\"clipIDs\":[\"\(id)\",\"\(id)\",\"\(id)\"]}"
        guard case .loaded(let ledger) = FreeClipLedger.load(from: Data(json.utf8)) else { return XCTFail("deveria ler") }
        XCTAssertEqual(ledger.used, 1)
    }

    func testClipeValidoConta() {
        XCTAssertTrue(FreeClipRules.isCountable(bytes: 5_000_000, durationSec: 12.0))
        XCTAssertTrue(FreeClipRules.isCountable(bytes: RecordingFiles.minRecoverableBytes, durationSec: 1.0))
    }

    func testClipeVazioOuCurtoNaoConta() {
        XCTAssertFalse(FreeClipRules.isCountable(bytes: 0, durationSec: 0))
        XCTAssertFalse(FreeClipRules.isCountable(bytes: 10_000, durationSec: 5))
        XCTAssertFalse(FreeClipRules.isCountable(bytes: 5_000_000, durationSec: 0.4))
        XCTAssertFalse(FreeClipRules.isCountable(bytes: 5_000_000, durationSec: .nan))
        XCTAssertFalse(FreeClipRules.isCountable(bytes: 5_000_000, durationSec: .infinity))
    }
}
