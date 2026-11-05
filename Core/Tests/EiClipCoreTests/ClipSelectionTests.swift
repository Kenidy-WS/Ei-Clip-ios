import XCTest
@testable import EiClipCore

final class ClipSelectionTests: XCTestCase {
    private let all = ["a", "b", "c", "d", "e"]

    func testTocarAlternaAEscolha() {
        var selection = ClipSelection()
        selection.toggle("b")
        XCTAssertTrue(selection.contains("b"))
        XCTAssertEqual(selection.count, 1)
        selection.toggle("b")
        XCTAssertTrue(selection.isEmpty)
    }

    func testSelecionarTodosELimpar() {
        var selection = ClipSelection()
        selection.selectAll(all)
        XCTAssertEqual(selection.count, 5)
        XCTAssertTrue(selection.allSelected(in: all))
        selection.clear()
        XCTAssertFalse(selection.allSelected(in: all))
        XCTAssertFalse(ClipSelection().allSelected(in: []))
    }

    func testOrdemEExistenciaNaLista() {
        var selection = ClipSelection()
        selection.toggle("d")
        selection.toggle("a")
        selection.toggle("zz")  // não existe mais na lista
        XCTAssertEqual(selection.ordered(in: all), ["a", "d"])
    }

    func testArrastoMarcaDoInicioAoDedo() {
        XCTAssertEqual(dragSelection(base: [], ids: all, anchor: 1, current: 3), ["b", "c", "d"])
        XCTAssertEqual(dragSelection(base: [], ids: all, anchor: 3, current: 1), ["b", "c", "d"])  // para trás
        XCTAssertEqual(dragSelection(base: [], ids: all, anchor: 2, current: 2), ["c"])
    }

    func testArrastoPreservaOQueJaEstavaEscolhidoEVoltarDesmarca() {
        XCTAssertEqual(dragSelection(base: ["a"], ids: all, anchor: 2, current: 4), ["a", "c", "d", "e"])
        XCTAssertEqual(dragSelection(base: ["a"], ids: all, anchor: 2, current: 3), ["a", "c", "d"])  // dedo voltou: "e" sai
    }

    func testArrastoForaDaListaFicaNosLimites() {
        XCTAssertEqual(dragSelection(base: [], ids: all, anchor: 3, current: 99), ["d", "e"])
        XCTAssertEqual(dragSelection(base: ["x"], ids: [], anchor: 0, current: 2), ["x"])
    }
}
