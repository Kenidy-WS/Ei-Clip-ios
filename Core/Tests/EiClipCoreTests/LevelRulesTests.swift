import XCTest
@testable import EiClipCore

final class LevelRulesTests: XCTestCase {
    func testEmPeRetoDaZero() {
        XCTAssertEqual(LevelRules.tilt(x: 0, y: -1, z: 0)!, 0, accuracy: 0.001)
    }

    func testGiradoNoSentidoHorarioDaPositivo() {
        // Gravidade puxando para a direita do aparelho: girado no sentido horário.
        let t = LevelRules.tilt(x: sin(10 * .pi / 180), y: -cos(10 * .pi / 180), z: 0)!
        XCTAssertEqual(t, 10, accuracy: 0.01)
        let u = LevelRules.tilt(x: -sin(10 * .pi / 180), y: -cos(10 * .pi / 180), z: 0)!
        XCTAssertEqual(u, -10, accuracy: 0.01)
    }

    func testDeitadoDeLadoMedeEmRelacaoAoLado() {
        // Deitado (topo à esquerda): gravidade para -x; 3° fora do reto.
        let a = (90.0 + 3) * .pi / 180
        let t = LevelRules.tilt(x: sin(a), y: -cos(a), z: 0)!
        XCTAssertEqual(t, 3, accuracy: 0.01)
        XCTAssertEqual(LevelRules.tilt(x: 1, y: 0, z: 0)!, 0, accuracy: 0.001)
    }

    func testDeCabecaParaBaixoTambemMede() {
        XCTAssertEqual(LevelRules.tilt(x: 0, y: 1, z: 0)!, 0, accuracy: 0.001)
    }

    func testNaMesaNaoTemHorizonte() {
        XCTAssertNil(LevelRules.tilt(x: 0.02, y: -0.05, z: -0.99))
        XCTAssertNil(LevelRules.tilt(x: 0, y: 0, z: 0))
    }

    func testRetoComTolerancia() {
        XCTAssertTrue(LevelRules.isLevel(0.9))
        XCTAssertTrue(LevelRules.isLevel(-1.0))
        XCTAssertFalse(LevelRules.isLevel(1.5))
    }

    func testSuavizacao() {
        XCTAssertEqual(LevelRules.smoothed(previous: nil, new: 8), 8)
        XCTAssertEqual(LevelRules.smoothed(previous: 0, new: 8), 4, accuracy: 0.0001)
    }

    func testSuavizacaoAlcancaOAlvoRapido() {
        // v0.6.18: salto de 10° chega a 90% em 4 leituras (~0,4 s a 10 leituras por segundo).
        var v: Double? = 0
        for _ in 0..<4 { v = LevelRules.smoothed(previous: v, new: 10) }
        XCTAssertGreaterThan(v!, 9.0)
    }

    func testZonaMortaDaPublicacao() {
        XCTAssertLessThan(LevelRules.publishDeadband, 0.5)
        XCTAssertTrue(LevelRules.shouldPublish(shown: nil, new: 0))
        XCTAssertFalse(LevelRules.shouldPublish(shown: 1.0, new: 1.1))
        XCTAssertTrue(LevelRules.shouldPublish(shown: 1.0, new: 1.25))
        XCTAssertTrue(LevelRules.shouldPublish(shown: 1.0, new: 0.7))
    }

    func testTextos() {
        XCTAssertEqual(LevelRules.describe(0.2), "reto")
        XCTAssertEqual(LevelRules.describe(2.34), "2,3° no sentido horário")
        XCTAssertEqual(LevelRules.describe(-5), "5,0° no sentido anti-horário")
        XCTAssertEqual(LevelRules.describe(nil), "sem horizonte (aparelho deitado)")
    }
}
