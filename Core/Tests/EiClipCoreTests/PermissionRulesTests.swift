import XCTest
@testable import EiClipCore

private final class LedgerMemoryStore: KeyValueStore {
    private var values: [String: Any] = [:]
    func object(forKey key: String) -> Any? { values[key] }
    func set(_ value: Any?, forKey key: String) { values[key] = value }
}

final class PermissionRulesTests: XCTestCase {
    // MARK: Fotos ao gravar

    func testPermitidoNaoFazNada() {
        XCTAssertEqual(PermissionRules.photosAction(.granted), .none)
        XCTAssertEqual(PermissionRules.photosAction(.limited), .none)
    }

    func testAindaNaoPedidaPedeDeNovo() {
        XCTAssertEqual(PermissionRules.photosAction(.notAsked), .askAgain)
    }

    func testNegadaOuRestritaExplica() {
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

    // MARK: Problema de cada permissão (a regra dos três estados)

    func testPermitidaNaoTemProblema() {
        XCTAssertNil(PermissionRules.problem(state: .granted, askedBefore: true))
        XCTAssertNil(PermissionRules.problem(state: .granted, askedBefore: false))
    }

    func testAcessoLimitadoEProblemaPorqueOAlbumPrecisaDeAcessoCompleto() {
        XCTAssertEqual(PermissionRules.problem(state: .limited, askedBefore: true), .limited)
        XCTAssertEqual(PermissionRules.problem(state: .limited, askedBefore: false), .limited)
    }

    func testNegadaOuRestritaSempreTemProblemaDeNegada() {
        for asked in [false, true] {
            XCTAssertEqual(PermissionRules.problem(state: .denied, askedBefore: asked), .denied)
            XCTAssertEqual(PermissionRules.problem(state: .restricted, askedBefore: asked), .denied)
        }
    }

    func testAindaNaoPedidaNaPrimeiraVezNaoEProblema() {
        XCTAssertNil(PermissionRules.problem(state: .notAsked, askedBefore: false))
    }

    func testAindaNaoPedidaDepoisDeJaTerPedidoESemResposta() {
        XCTAssertEqual(PermissionRules.problem(state: .notAsked, askedBefore: true), .unanswered)
    }

    // MARK: Lista do aviso

    func testListaSoTrazOQueTemProblemaNaOrdemRecebida() {
        let list = PermissionRules.issues(in: [
            PermissionStatus(kind: .camera, state: .granted, askedBefore: true),
            PermissionStatus(kind: .microphone, state: .denied, askedBefore: true),
            PermissionStatus(kind: .speech, state: .notAsked, askedBefore: true),
            PermissionStatus(kind: .photos, state: .notAsked, askedBefore: false),
        ])
        XCTAssertEqual(
            list,
            [
                PermissionIssue(kind: .microphone, problem: .denied),
                PermissionIssue(kind: .speech, problem: .unanswered),
            ])
    }

    func testTudoCertoDeixaAListaVazia() {
        let list = PermissionRules.issues(
            in: PermissionKind.allCases.map { PermissionStatus(kind: $0, state: .granted, askedBefore: true) })
        XCTAssertTrue(list.isEmpty)
    }

    func testPrimeiraAberturaNaoTemAviso() {
        let list = PermissionRules.issues(
            in: PermissionKind.allCases.map { PermissionStatus(kind: $0, state: .notAsked, askedBefore: false) })
        XCTAssertTrue(list.isEmpty)
    }

    func testSoACameraNegadaImpedeAbrir() {
        XCTAssertTrue(PermissionRules.blocksCamera([PermissionIssue(kind: .camera, problem: .denied)]))
        XCTAssertFalse(PermissionRules.blocksCamera([PermissionIssue(kind: .camera, problem: .unanswered)]))
        XCTAssertFalse(PermissionRules.blocksCamera([PermissionIssue(kind: .microphone, problem: .denied)]))
        XCTAssertFalse(PermissionRules.blocksCamera([]))
    }

    // MARK: Pedidos repetidos

    func testPrimeiroPedidoSempreVale() {
        XCTAssertTrue(PermissionRules.shouldAskNow(lastAskUptime: nil, now: 5))
    }

    func testNaoEmpilhaPedidosNoMesmoInstante() {
        XCTAssertFalse(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 100.5))
        XCTAssertFalse(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 101.9))
    }

    func testPedeDeNovoDepoisDoIntervalo() {
        XCTAssertTrue(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 102))
        XCTAssertTrue(PermissionRules.shouldAskNow(lastAskUptime: 100, now: 400))
    }

    // MARK: Registro de "já pedida"

    func testRegistroComecaVazio() {
        let ledger = PermissionLedger(store: LedgerMemoryStore())
        for kind in PermissionKind.allCases { XCTAssertFalse(ledger.wasAsked(kind)) }
    }

    func testRegistroLembraSoQuemFoiMarcado() {
        let ledger = PermissionLedger(store: LedgerMemoryStore())
        ledger.mark(.camera)
        ledger.mark(.photos)
        XCTAssertTrue(ledger.wasAsked(.camera))
        XCTAssertTrue(ledger.wasAsked(.photos))
        XCTAssertFalse(ledger.wasAsked(.microphone))
        XCTAssertFalse(ledger.wasAsked(.speech))
    }

    func testRegistroSobreviveAUmNovoObjetoNaMesmaLoja() {
        let store = LedgerMemoryStore()
        PermissionLedger(store: store).mark(.speech)
        XCTAssertTrue(PermissionLedger(store: store).wasAsked(.speech))
    }
}
