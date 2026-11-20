import XCTest
@testable import EiClipCore

final class FreeClipLedgerTests: XCTestCase {
    func testComecaVazio() {
        let ledger = FreeClipLedger()
        XCTAssertEqual(ledger.used, 0)
        XCTAssertEqual(ledger.remaining, 10)
    }

    func testContaUmClipe() {
        var ledger = FreeClipLedger()
        XCTAssertEqual(ledger.record(UUID()), .counted)
        XCTAssertEqual(ledger.used, 1)
        XCTAssertEqual(ledger.remaining, 9)
    }

    func testMesmoClipeNaoContaDuasVezes() {
        var ledger = FreeClipLedger()
        let id = UUID()
        XCTAssertEqual(ledger.record(id), .counted)
        XCTAssertEqual(ledger.record(id), .alreadyCounted)
        XCTAssertEqual(ledger.record(id), .alreadyCounted)
        XCTAssertEqual(ledger.used, 1)
        XCTAssertTrue(ledger.contains(id))
    }

    func testNaoPassaDeDez() {
        var ledger = FreeClipLedger()
        for _ in 0..<10 { XCTAssertEqual(ledger.record(UUID()), .counted) }
        XCTAssertEqual(ledger.used, 10)
        XCTAssertEqual(ledger.remaining, 0)
        let eleventh = UUID()
        XCTAssertEqual(ledger.record(eleventh), .limitReached)
        XCTAssertEqual(ledger.used, 10)
        XCTAssertFalse(ledger.contains(eleventh))
    }

    func testClipeJaContadoNoLimiteContinuaJaContado() {
        var ledger = FreeClipLedger()
        let ids = (0..<10).map { _ in UUID() }
        for id in ids { ledger.record(id) }
        XCTAssertEqual(ledger.record(ids[3]), .alreadyCounted)
        XCTAssertEqual(ledger.used, 10)
    }

    func testMontagemDescartaRepetidosEExcesso() {
        let a = UUID()
        let b = UUID()
        var list = [a, b, a, b]
        for _ in 0..<12 { list.append(UUID()) }
        let ledger = FreeClipLedger(clipIDs: list)
        XCTAssertEqual(ledger.used, 10)
        XCTAssertEqual(Set(ledger.clipIDs).count, 10)
        XCTAssertEqual(Array(ledger.clipIDs.prefix(2)), [a, b])
    }

    func testMantemAOrdemDeChegada() {
        var ledger = FreeClipLedger()
        let ids = (0..<4).map { _ in UUID() }
        for id in ids { ledger.record(id) }
        XCTAssertEqual(ledger.clipIDs, ids)
    }

    func testRegistroSobreviveAoCodificarEDecodificar() throws {
        var ledger = FreeClipLedger()
        for _ in 0..<7 { ledger.record(UUID()) }
        let data = try JSONEncoder().encode(ledger)
        let back = try JSONDecoder().decode(FreeClipLedger.self, from: data)
        XCTAssertEqual(back, ledger)
        XCTAssertEqual(back.remaining, 3)
    }

    func testLimiteEDezClipes() {
        XCTAssertEqual(FreeClipLedger.limit, 10)
    }
}
