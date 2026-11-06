import XCTest
@testable import EiClipCore

final class StackTextTests: XCTestCase {
    func testLinhaJuntaDoTopoParaABase() {
        XCTAssertEqual(StackText.line(label: "principal", symbols: ["a", "b", "c"]), "principal: a < b < c")
    }

    func testPilhaVazia() {
        XCTAssertEqual(StackText.line(label: "thread 3", symbols: []), "thread 3: (sem pilha)")
    }

    func testCortaPilhaELimiteDoNome() {
        let many = (0..<20).map { "f\($0)" }
        let line = StackText.line(label: "x", symbols: many, maxFrames: 3)
        XCTAssertEqual(line, "x: f0 < f1 < f2")
        let long = String(repeating: "n", count: 100)
        let cut = StackText.line(label: "x", symbols: [long], maxSymbolLength: 10)
        XCTAssertEqual(cut, "x: nnnnnnnnn…")
    }

    func testOciosa() {
        XCTAssertTrue(StackText.isIdle(topSymbol: "__workq_kernreturn"))
        XCTAssertFalse(StackText.isIdle(topSymbol: "__psynch_mutexwait"))
    }
}
