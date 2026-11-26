import XCTest
@testable import EiClipCore

final class EnvironmentRulesTests: XCTestCase {
    func testLojaDescartaRegistroSandbox() {
        XCTAssertEqual(EnvironmentRules.decide(recorded: .sandbox, current: .production), .discard)
    }

    func testLojaDescartaRegistroSemMarca() {
        XCTAssertEqual(EnvironmentRules.decide(recorded: nil, current: .production), .discard)
    }

    func testLojaMantemRegistroDeProducao() {
        XCTAssertEqual(EnvironmentRules.decide(recorded: .production, current: .production), .keep)
    }

    func testTestFlightNuncaDescarta() {
        XCTAssertEqual(EnvironmentRules.decide(recorded: .sandbox, current: .sandbox), .keep)
        XCTAssertEqual(EnvironmentRules.decide(recorded: nil, current: .sandbox), .keep)
        XCTAssertEqual(EnvironmentRules.decide(recorded: .production, current: .sandbox), .keep)
    }

    func testAmbienteDesconhecidoNuncaDescarta() {
        XCTAssertEqual(EnvironmentRules.decide(recorded: .sandbox, current: nil), .keep)
        XCTAssertEqual(EnvironmentRules.decide(recorded: nil, current: nil), .keep)
    }

    func testDeteccaoPeloNomeDoRecibo() {
        XCTAssertEqual(EnvironmentRules.detect(receiptFileName: "sandboxReceipt"), .sandbox)
        XCTAssertEqual(EnvironmentRules.detect(receiptFileName: "receipt"), .production)
        XCTAssertNil(EnvironmentRules.detect(receiptFileName: nil))
        XCTAssertNil(EnvironmentRules.detect(receiptFileName: "outroNome"))
    }

    func testRegistrosAntigosSemAmbienteAindaSaoLidos() throws {
        let ledger = FreeClipLedger.load(from: Data(#"{"clipIDs":[]}"#.utf8))
        XCTAssertEqual(ledger, .loaded(FreeClipLedger()))
        let old = try JSONEncoder().encode(LastConfirmed(permanent: true))
        if case .loaded(let last) = ConfirmedAccessRules.load(from: old) { XCTAssertTrue(last.permanent) } else { XCTFail() }
    }

    func testAmbienteSobreviveAoGravarELer() {
        let ledger = FreeClipLedger(clipIDs: [UUID()], environment: .production)
        XCTAssertEqual(FreeClipLedger.load(from: ledger.encoded()), .loaded(ledger))
        var last = LastConfirmed(permanent: true)
        last.environment = .sandbox
        XCTAssertEqual(ConfirmedAccessRules.load(from: ConfirmedAccessRules.encoded(last)), .loaded(last))
    }
}
