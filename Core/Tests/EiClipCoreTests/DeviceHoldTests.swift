import XCTest
@testable import EiClipCore

final class DeviceHoldTests: XCTestCase {
    // Leituras típicas do acelerômetro (iOS): em pé y = -1; topo à esquerda (borda esquerda embaixo) x = -1;
    // topo à direita (borda direita embaixo) x = +1.
    private let emPe = (x: 0.02, y: -0.98, z: -0.1)
    private let topoEsquerda = (x: -0.98, y: 0.03, z: -0.1)
    private let topoDireita = (x: 0.98, y: -0.02, z: -0.1)
    private let deCabecaParaBaixo = (x: 0.01, y: 0.99, z: -0.1)
    private let naMesaParaCima = (x: 0.04, y: -0.05, z: -1.0)

    /// Alimenta a mesma leitura `times` vezes; devolve se mudou em alguma delas.
    @discardableResult
    private func feed(_ t: inout OrientationTracker, _ r: (x: Double, y: Double, z: Double), times: Int = 3) -> Bool {
        var changed = false
        for _ in 0..<times { if t.feed(x: r.x, y: r.y, z: r.z) { changed = true } }
        return changed
    }

    // MARK: matrizes do arquivo

    func testGiroDoArquivoPorPosicao() {
        XCTAssertEqual(DeviceHold.portrait.fileRotationDegrees, 90)
        XCTAssertEqual(DeviceHold.portraitUpsideDown.fileRotationDegrees, 270)
        XCTAssertEqual(DeviceHold.landscapeLeft.fileRotationDegrees, 0)
        XCTAssertEqual(DeviceHold.landscapeRight.fileRotationDegrees, 180)
    }

    func testMatrizCoincideComOGiroEExato() {
        for hold in DeviceHold.allCases {
            let m = hold.fileMatrix
            let rad = Double(hold.fileRotationDegrees) * .pi / 180
            XCTAssertEqual(m.a, cos(rad).rounded(), accuracy: 1e-9, "\(hold)")
            XCTAssertEqual(m.b, sin(rad).rounded(), accuracy: 1e-9, "\(hold)")
            XCTAssertEqual(m.c, -sin(rad).rounded(), accuracy: 1e-9, "\(hold)")
            XCTAssertEqual(m.d, cos(rad).rounded(), accuracy: 1e-9, "\(hold)")
        }
    }

    func testEmPeContinuaIgualAV038() {
        // Em pé tem que dar a mesma matriz que a etapa 1 gravava (giro de 90°).
        let m = DeviceHold.portrait.fileMatrix
        XCTAssertEqual(m.a, 0); XCTAssertEqual(m.b, 1); XCTAssertEqual(m.c, -1); XCTAssertEqual(m.d, 0)
    }

    // MARK: posição a partir da gravidade

    func testComecaEmPeSemMudar() {
        var t = OrientationTracker()
        XCTAssertEqual(t.current, .portrait)
        XCTAssertFalse(feed(&t, emPe, times: 20))
        XCTAssertEqual(t.current, .portrait)
    }

    func testAsQuatroPosicoes() {
        var t = OrientationTracker()
        XCTAssertTrue(feed(&t, topoEsquerda)); XCTAssertEqual(t.current, .landscapeLeft)
        XCTAssertTrue(feed(&t, deCabecaParaBaixo)); XCTAssertEqual(t.current, .portraitUpsideDown)
        XCTAssertTrue(feed(&t, topoDireita)); XCTAssertEqual(t.current, .landscapeRight)
        XCTAssertTrue(feed(&t, emPe)); XCTAssertEqual(t.current, .portrait)
    }

    func testTrocaExigeLeiturasSeguidas() {
        var t = OrientationTracker(confirmSamples: 3)
        XCTAssertFalse(t.feed(x: -0.98, y: 0.03, z: -0.1))
        XCTAssertFalse(t.feed(x: -0.98, y: 0.03, z: -0.1))
        XCTAssertEqual(t.current, .portrait)  // 2 leituras ainda não bastam
        XCTAssertTrue(t.feed(x: -0.98, y: 0.03, z: -0.1))
        XCTAssertEqual(t.current, .landscapeLeft)
    }

    func testSolavancoNaoTroca() {
        var t = OrientationTracker(confirmSamples: 3)
        // Leitura de "deitado" no meio de leituras em pé: o candidato é zerado a cada volta.
        for _ in 0..<5 {
            XCTAssertFalse(t.feed(x: -0.98, y: 0.03, z: -0.1))
            XCTAssertFalse(t.feed(x: -0.98, y: 0.03, z: -0.1))
            XCTAssertFalse(t.feed(x: 0.02, y: -0.98, z: -0.1))
        }
        XCTAssertEqual(t.current, .portrait)
    }

    func testHistereseNaFronteira() {
        // 50° para o lado: passou dos 45° "justos", mas não dos 55° da histerese → continua em pé.
        var t = OrientationTracker()
        let a = 50.0 * .pi / 180
        XCTAssertFalse(feed(&t, (x: -sin(a), y: -cos(a), z: 0), times: 10))
        XCTAssertEqual(t.current, .portrait)
        // 60° para o lado: passou da histerese → deitado.
        let b = 60.0 * .pi / 180
        XCTAssertTrue(feed(&t, (x: -sin(b), y: -cos(b), z: 0), times: 3))
        XCTAssertEqual(t.current, .landscapeLeft)
    }

    func testNaoVoltaNaFronteiraDeVolta() {
        var t = OrientationTracker()
        feed(&t, topoEsquerda)
        XCTAssertEqual(t.current, .landscapeLeft)
        // A 50° do centro de "topo à esquerda" (que fica a 90°), do lado de "em pé": passou dos 45° "justos",
        // mas a histerese segura e continua deitado.
        let a = 40.0 * .pi / 180
        XCTAssertFalse(feed(&t, (x: -sin(a), y: -cos(a), z: 0), times: 10))
        XCTAssertEqual(t.current, .landscapeLeft)
    }

    // MARK: aparelho deitado na mesa

    func testNaMesaMantemAUltimaPosicao() {
        var t = OrientationTracker()
        feed(&t, topoEsquerda)
        XCTAssertEqual(t.current, .landscapeLeft)
        // Pousa de bruços/para cima: a leitura é quase só z. Mantém "deitado, topo à esquerda".
        XCTAssertFalse(feed(&t, naMesaParaCima, times: 50))
        XCTAssertEqual(t.current, .landscapeLeft)
    }

    func testNaMesaDepoisDeEmPeMantemEmPe() {
        var t = OrientationTracker()
        feed(&t, emPe)
        feed(&t, naMesaParaCima, times: 30)
        XCTAssertEqual(t.current, .portrait)
    }

    func testNaMesaZeraLeiturasPendentes() {
        var t = OrientationTracker(confirmSamples: 3)
        t.feed(x: -0.98, y: 0.03, z: -0.1)
        t.feed(x: -0.98, y: 0.03, z: -0.1)  // 2 leituras de "deitado"
        t.feed(x: 0.04, y: -0.05, z: -1.0)  // pousou na mesa: zera a contagem
        XCTAssertFalse(t.feed(x: -0.98, y: 0.03, z: -0.1))  // só 1 depois da mesa
        XCTAssertEqual(t.current, .portrait)
    }

    func testInclinadoParaCimaAindaContaOPlano() {
        // Câmera apontada para cima (aparelho a ~60° da mesa, em pé): o plano da tela ainda tem gravidade de sobra.
        var t = OrientationTracker()
        XCTAssertFalse(feed(&t, (x: 0.0, y: -0.5, z: -0.86), times: 10))
        XCTAssertEqual(t.current, .portrait)
        // E em pé inclinado para o lado continua valendo a posição lateral.
        XCTAssertTrue(feed(&t, (x: -0.6, y: 0.0, z: -0.8), times: 3))
        XCTAssertEqual(t.current, .landscapeLeft)
    }

    func testPosicaoInicialConfiguravel() {
        var t = OrientationTracker(initial: .landscapeRight)
        feed(&t, naMesaParaCima, times: 10)
        XCTAssertEqual(t.current, .landscapeRight)
    }

    func testSinalDoEixoXConfereComOTesteNoAparelho() {
        // Medido no iPhone na v0.3.8 (clipes de 05/11): com x = -1,00 o arquivo precisou de giro 0° (o 180° saiu de cabeça
        // para baixo) e com x = +0,98 precisou de 180° (o 0° saiu de cabeça para baixo).
        var t = OrientationTracker()
        feed(&t, (x: -1.00, y: -0.02, z: 0.19))
        XCTAssertEqual(t.current, .landscapeLeft)
        XCTAssertEqual(t.current.fileRotationDegrees, 0)
        feed(&t, (x: 0.98, y: 0.05, z: -0.02))
        XCTAssertEqual(t.current, .landscapeRight)
        XCTAssertEqual(t.current.fileRotationDegrees, 180)
    }

    func testDistanciaAngularDaVolta() {
        XCTAssertEqual(OrientationTracker.angularDistance(170, -170), 20, accuracy: 1e-9)
        XCTAssertEqual(OrientationTracker.angularDistance(-90, 90), 180, accuracy: 1e-9)
        XCTAssertEqual(OrientationTracker.angularDistance(10, 0), 10, accuracy: 1e-9)
    }

    func testDeCabecaParaBaixoNaFronteira180() {
        // Em torno de ±180° (y = +1) tem que cair em "de cabeça para baixo", dos dois lados.
        XCTAssertEqual(DeviceHold.nearest(toAngle: 175), .portraitUpsideDown)
        XCTAssertEqual(DeviceHold.nearest(toAngle: -175), .portraitUpsideDown)
        XCTAssertEqual(DeviceHold.nearest(toAngle: 44), .portrait)
        XCTAssertEqual(DeviceHold.nearest(toAngle: -44), .portrait)
        XCTAssertEqual(DeviceHold.nearest(toAngle: -100), .landscapeRight)
    }
}
