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

    func testCarregandoNuncaAvisa() {
        XCTAssertEqual(BatteryRules.level(percent: 5, charging: true), .ok)
        var tracker = BatteryAlertTracker()
        XCTAssertNil(tracker.update(percent: 5, charging: true))
    }

    func testDescricao() {
        XCTAssertEqual(BatteryRules.describe(percent: 62, charging: false), "≈62% · na bateria")
        XCTAssertEqual(BatteryRules.describe(percent: 62, charging: true), "≈62% · carregando")
        XCTAssertEqual(BatteryRules.describe(percent: nil, charging: false), "desconhecida")
    }

    func testSemLeituraNaoAvisa() {
        var tracker = BatteryAlertTracker()
        XCTAssertNil(tracker.update(percent: nil, charging: false))
    }

    func testAvisaAoDescerEscalonado() {
        var tracker = BatteryAlertTracker()
        XCTAssertNil(tracker.update(percent: 50, charging: false))
        XCTAssertNil(tracker.update(percent: 21, charging: false))
        XCTAssertEqual(tracker.update(percent: 20, charging: false), .low)
        XCTAssertNil(tracker.update(percent: 19, charging: false))  // continua baixa: não repete
        XCTAssertEqual(tracker.update(percent: 10, charging: false), .critical)
        XCTAssertNil(tracker.update(percent: 9, charging: false))
    }

    func testOscilarEmTornoDoLimiteNaoRepeteOAviso() {
        var tracker = BatteryAlertTracker()
        XCTAssertEqual(tracker.update(percent: 20, charging: false), .low)
        XCTAssertNil(tracker.update(percent: 21, charging: false))  // dentro da margem: segue "baixa"
        XCTAssertNil(tracker.update(percent: 20, charging: false))  // não avisa de novo
        XCTAssertNil(tracker.update(percent: 22, charging: false))
        XCTAssertNil(tracker.update(percent: 21, charging: false))
    }

    func testPassarDaMargemLiberaUmNovoAviso() {
        var tracker = BatteryAlertTracker()
        XCTAssertEqual(tracker.update(percent: 20, charging: false), .low)
        XCTAssertNil(tracker.update(percent: 30, charging: false))  // bem acima: voltou ao normal
        XCTAssertEqual(tracker.update(percent: 20, charging: false), .low)  // caiu de novo: avisa
    }

    func testOscilarEmTornoDoLimiteCriticoNaoRepete() {
        var tracker = BatteryAlertTracker()
        XCTAssertEqual(tracker.update(percent: 10, charging: false), .critical)
        XCTAssertNil(tracker.update(percent: 11, charging: false))
        XCTAssertNil(tracker.update(percent: 10, charging: false))
        XCTAssertNil(tracker.update(percent: 12, charging: false))
    }

    func testCarregarZeraOsAvisos() {
        var tracker = BatteryAlertTracker()
        XCTAssertEqual(tracker.update(percent: 8, charging: false), .critical)
        XCTAssertNil(tracker.update(percent: 8, charging: true))  // ligou o carregador
        XCTAssertEqual(tracker.update(percent: 8, charging: false), .critical)  // tirou: avisa de novo
    }

    func testResetFazAvisarDeNovo() {
        var tracker = BatteryAlertTracker()
        XCTAssertEqual(tracker.update(percent: 15, charging: false), .low)
        tracker.reset()
        XCTAssertEqual(tracker.update(percent: 15, charging: false), .low)
    }
}
