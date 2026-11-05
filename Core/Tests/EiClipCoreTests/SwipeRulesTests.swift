import XCTest
@testable import EiClipCore

// Gabarito: bindPlayerSwipeDown em ui/clips-view.ts (12 pt, 1,2×, 130 pt, 0,6 pt/ms e 50 pt, 500 pt, 12% e 70%).
final class SwipeRulesTests: XCTestCase {
    func testArrastoParaBaixoPrecisaSerVerticalEPassarDe12() {
        XCTAssertTrue(SwipeRules.isDownDrag(dx: 0, dy: 20))
        XCTAssertTrue(SwipeRules.isDownDrag(dx: 10, dy: 12))
        XCTAssertFalse(SwipeRules.isDownDrag(dx: 0, dy: 11))
        XCTAssertFalse(SwipeRules.isDownDrag(dx: 30, dy: 20))  // 20 < 30 × 1,2
        XCTAssertFalse(SwipeRules.isDownDrag(dx: 0, dy: -40))  // para cima não conta
    }

    func testProgressoDoArrasto() {
        XCTAssertEqual(SwipeRules.dismissProgress(dy: 250), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SwipeRules.dismissProgress(dy: 600), 1)
        XCTAssertEqual(SwipeRules.dismissProgress(dy: -20), 0)
    }

    func testEscalaEOpacidade() {
        XCTAssertEqual(SwipeRules.dismissScale(progress: 0), 1)
        XCTAssertEqual(SwipeRules.dismissScale(progress: 1), 0.88, accuracy: 0.0001)
        XCTAssertEqual(SwipeRules.dismissOpacity(progress: 1), 0.3, accuracy: 0.0001)
    }

    func testFechaPassandoDe130Pontos() {
        XCTAssertTrue(SwipeRules.shouldClose(dy: 131, elapsedMs: 1_000))
        XCTAssertFalse(SwipeRules.shouldClose(dy: 130, elapsedMs: 1_000))
        XCTAssertFalse(SwipeRules.shouldClose(dy: 100, elapsedMs: 1_000))
    }

    func testArremessoRapidoFechaComMaisDe50Pontos() {
        XCTAssertTrue(SwipeRules.shouldClose(dy: 60, elapsedMs: 50))  // 1,2 pt/ms
        XCTAssertFalse(SwipeRules.shouldClose(dy: 40, elapsedMs: 20))  // rápido, mas curto
        XCTAssertFalse(SwipeRules.shouldClose(dy: 60, elapsedMs: 500))  // longo, mas lento
    }

    // MARK: - Trocar de clipe para os lados (v0.4.6). Gabarito: bindPlayerSwipeSides em ui/clips-view.ts.

    func testArrastoParaOLadoPrecisaSerHorizontalEPassarDe12() {
        XCTAssertTrue(SwipeRules.isSideDrag(dx: 20, dy: 0))
        XCTAssertTrue(SwipeRules.isSideDrag(dx: -12, dy: 5))
        XCTAssertFalse(SwipeRules.isSideDrag(dx: 11, dy: 0))
        XCTAssertFalse(SwipeRules.isSideDrag(dx: 20, dy: 30))  // 20 < 30 × 1,2
    }

    func testNaoVaiAPartirDaBorda() {
        XCTAssertTrue(SwipeRules.startsOnEdge(x: 10, width: 393))
        XCTAssertTrue(SwipeRules.startsOnEdge(x: 28, width: 393))
        XCTAssertTrue(SwipeRules.startsOnEdge(x: 365, width: 393))
        XCTAssertFalse(SwipeRules.startsOnEdge(x: 200, width: 393))
    }

    func testEsquerdaVaiAoProximoEDireitaAoAnterior() {
        XCTAssertEqual(SwipeRules.neighborDirection(dx: -80), 1)
        XCTAssertEqual(SwipeRules.neighborDirection(dx: 80), -1)
    }

    func testVizinhoNasPontasDaLista() {
        XCTAssertEqual(SwipeRules.neighborIndex(current: 2, direction: 1, count: 5), 3)
        XCTAssertEqual(SwipeRules.neighborIndex(current: 2, direction: -1, count: 5), 1)
        XCTAssertNil(SwipeRules.neighborIndex(current: 0, direction: -1, count: 5))  // primeiro: sem anterior
        XCTAssertNil(SwipeRules.neighborIndex(current: 4, direction: 1, count: 5))  // último: sem próximo
        XCTAssertNil(SwipeRules.neighborIndex(current: 0, direction: 1, count: 1))
    }

    func testResistenciaNasPontas() {
        XCTAssertEqual(SwipeRules.resistedOffset(dx: 90, hasNeighbor: true), 90)
        XCTAssertEqual(SwipeRules.resistedOffset(dx: 90, hasNeighbor: false), 30)
        XCTAssertEqual(SwipeRules.resistedOffset(dx: -60, hasNeighbor: false), -20)
    }

    func testOpacidadeDoDeslize() {
        XCTAssertEqual(SwipeRules.slideOpacity(offset: 0), 1)
        XCTAssertEqual(SwipeRules.slideOpacity(offset: -300), 0.5, accuracy: 0.0001)
        XCTAssertEqual(SwipeRules.slideOpacity(offset: 900), 0.5, accuracy: 0.0001)  // nunca abaixo de 50%
    }

    func testTrocaPassandoDe90PontosOuNumArremessoRapido() {
        XCTAssertTrue(SwipeRules.shouldChangeClip(dx: -91, elapsedMs: 1_000))
        XCTAssertFalse(SwipeRules.shouldChangeClip(dx: 90, elapsedMs: 1_000))
        XCTAssertTrue(SwipeRules.shouldChangeClip(dx: 50, elapsedMs: 50))  // 1 pt/ms
        XCTAssertFalse(SwipeRules.shouldChangeClip(dx: 30, elapsedMs: 10))  // rápido, mas curto
        XCTAssertFalse(SwipeRules.shouldChangeClip(dx: 50, elapsedMs: 400))  // longo, mas lento
    }
}
