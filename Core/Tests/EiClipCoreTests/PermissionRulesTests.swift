import XCTest
@testable import EiClipCore

final class PermissionRulesTests: XCTestCase {
    func testPermitidoNaoFazNada() {
        XCTAssertEqual(PermissionRules.photosAction(.granted), .none)
        XCTAssertEqual(PermissionRules.photosAction(.limited), .none)
    }

    func testAindaNaoPedidaPedeDeNovo() {
        XCTAssertEqual(PermissionRules.photosAction(.notAsked), .askAgain)
    }

    func testNegadaOuRestritaExplicaEMandaParaOsAjustes() {
        XCTAssertEqual(PermissionRules.photosAction(.denied), .explainDenied)
        XCTAssertEqual(PermissionRules.photosAction(.restricted), .explainDenied)
    }

    func testSoSalvaComAcessoTotalOuLimitado() {
        XCTAssertTrue(PermissionRules.canSaveToPhotos(.granted))
        XCTAssertTrue(PermissionRules.canSaveToPhotos(.limited))
        XCTAssertFalse(PermissionRules.canSaveToPhotos(.notAsked))
        XCTAssertFalse(PermissionRules.canSaveToPhotos(.denied))
        XCTAssertFalse(PermissionRules.canSaveToPhotos(.restricted))
    }

    func testPrimeiroPedidoSempreVale() {
        XCTAssertTrue(PermissionRules.shouldAskNow(lastAskUptime: nil, now: 5))
    }

    func testNaoEmpilhaPedidosDentroDoLimite() {
        XCTAssertFalse(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 105))
        XCTAssertFalse(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 109.9))
    }

    func testPedeDeNovoDepoisDoLimite() {
        XCTAssertTrue(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 110))
        XCTAssertTrue(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 400))
    }

    func testTimeoutDevolveOResultadoQuandoTermina() async {
        let value = await AsyncTimeout.run(seconds: 5) { () async -> Int in 42 }
        XCTAssertEqual(value, 42)
    }

    func testTimeoutDevolveNilQuandoEstoura() async {
        let value = await AsyncTimeout.run(seconds: 0.2) { () async -> Int in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            return 1
        }
        XCTAssertNil(value)
    }
}
