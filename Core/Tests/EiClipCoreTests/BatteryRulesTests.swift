import XCTest
@testable import EiClipCore

final class BatteryRulesTests: XCTestCase {
    func testNiveis() {
        XCTAssertEqual(BatteryRules.level(percent: 80, charging: false), .ok)
        XCTAssertEqual(BatteryRules.level(percent: 21, charging: false), .ok)
        XCTAssertEqual(BatteryRules.level(percent: 20, charging: false), .low)
        XCTAssertEqual(BatteryRules.level(percent: 11, charging: false), .low)
        XCTAssertEqual(BatteryRules.level(percent: 10, charging: false), .critical)
        XCTAssertEqual(BatteryRules.level(percent: 1, charging: false), .critical)
    }

    func testDescricao() {
        XCTAssertEqual(BatteryRules.describe(percent: 62, charging: false), "≈62% · na bateria")
        XCTAssertEqual(BatteryRules.describe(percent: 62, charging: true), "≈62% · carregando")
        XCTAssertEqual(BatteryRules.describe(percent: nil, charging: false), "desconhecida")
    }

    func testSemLeituraNaoAvisa() {
        var tracker = BatteryStepTracker()
        XCTAssertNil(tracker.update(percent: nil, charging: false))
    }

    func testCarregandoNuncaAvisa() {
        var tracker = BatteryStepTracker()
        XCTAssertNil(tracker.update(percent: 5, charging: true))
    }

    func testAvisaUmaVezEmCadaDegrau() {
        var tracker = BatteryStepTracker()
        XCTAssertNil(tracker.update(percent: 25, charging: false))
        XCTAssertEqual(tracker.update(percent: 20, charging: false), 20)
        XCTAssertNil(tracker.update(percent: 20, charging: false))  // mesma leitura: não repete
        XCTAssertEqual(tracker.update(percent: 15, charging: false), 15)
        XCTAssertNil(tracker.update(percent: 15, charging: false))
        XCTAssertEqual(tracker.update(percent: 10, charging: false), 10)
        XCTAssertEqual(tracker.update(percent: 5, charging: false), 5)
        XCTAssertNil(tracker.update(percent: 5, charging: false))
        XCTAssertNil(tracker.update(percent: 0, charging: false))
    }

    func testAbrirJaNoMeioDosDegrausAvisaSoOAtual() {
        var tracker = BatteryStepTracker()
        XCTAssertEqual(tracker.update(percent: 10, charging: false), 10)  // não empilha 20 e 15
        XCTAssertNil(tracker.update(percent: 10, charging: false))
        XCTAssertEqual(tracker.update(percent: 5, charging: false), 5)
    }

    func testLeituraEntreDegrausUsaODegrauMaisFundo() {
        XCTAssertEqual(BatteryStepTracker.step(for: 12), 15)
        XCTAssertEqual(BatteryStepTracker.step(for: 20), 20)
        XCTAssertEqual(BatteryStepTracker.step(for: 21), nil)
        XCTAssertEqual(BatteryStepTracker.step(for: 3), 5)
    }

    func testCarregarZeraEAvisaDeNovoAoDescer() {
        var tracker = BatteryStepTracker()
        XCTAssertEqual(tracker.update(percent: 15, charging: false), 15)
        XCTAssertNil(tracker.update(percent: 18, charging: true))
        XCTAssertEqual(tracker.update(percent: 20, charging: false), 20)
        XCTAssertEqual(tracker.update(percent: 15, charging: false), 15)
    }

    func testSubirAcimaDe25ZeraSemCarregador() {
        var tracker = BatteryStepTracker(lowestWarned: 10)
        XCTAssertNil(tracker.update(percent: 20, charging: false))  // 20 não é novo degrau (já passou do 10)
        XCTAssertNil(tracker.update(percent: 30, charging: false))
        XCTAssertEqual(tracker.lowestWarned, BatteryStepTracker.none)
        XCTAssertEqual(tracker.update(percent: 20, charging: false), 20)
    }

    func testValorGuardadoEvitaRepetirAoReabrirOApp() {
        var tracker = BatteryStepTracker(lowestWarned: 15)  // valor lido do aparelho
        XCTAssertNil(tracker.update(percent: 15, charging: false))
        XCTAssertEqual(tracker.update(percent: 10, charging: false), 10)
    }

    func testPesoDoDegrau() {
        XCTAssertEqual(BatteryStepTracker.level(forStep: 20), .low)
        XCTAssertEqual(BatteryStepTracker.level(forStep: 15), .low)
        XCTAssertEqual(BatteryStepTracker.level(forStep: 10), .critical)
        XCTAssertEqual(BatteryStepTracker.level(forStep: 5), .critical)
    }
}
