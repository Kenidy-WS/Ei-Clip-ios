import XCTest
@testable import EiClipCore

/// Sequências de texto reais da sonda da v0.2.0 (iPhone 15, iOS 27): "Ei" → "Ei cli" → "Ei clipe", texto que zera e que acumula.
final class WakeTrackerTests: XCTestCase {
    private func run(_ word: WakeWord, _ steps: [(Double, String)], minGapMs: Double = 1500) -> [WakeKind?] {
        var t = WakeTracker(word: word, minGapMs: minGapMs)
        return steps.map { t.feed($0.1, nowMs: $0.0) }
    }

    func testUmaFalaDaUmSoAcerto() {
        // Log real: 3,5 s "Ei", 3,7 s "Ei cli", 4,2 s "Ei clipe".
        let r = run(.clip, [(0, "Ei"), (300, "Ei cli"), (800, "Ei clipe")])
        XCTAssertEqual(r, [nil, .early, nil])
    }

    func testFalaSemParcialDaAcertoCompleto() {
        let r = run(.clip, [(0, "Ei clipe"), (200, "Ei clipe")])
        XCTAssertEqual(r, [.full, nil])
    }

    func testTextoQueZeraDepoisDeUmaPausaContaComoFalaNova() {
        // Log real: depois de "Ei clipe" o texto volta a "Ei" cerca de 3 s depois.
        let r = run(
            .clip,
            [(0, "Ei"), (300, "Ei cli"), (800, "Ei clipe"), (3900, "Ei"), (4200, "Ei cli"), (4700, "Ei clipe")])
        XCTAssertEqual(r, [nil, .early, nil, nil, .early, nil])
    }

    func testTextoQueAcumulaNaoRepeteOQueJaFoiGasto() {
        // Log real: "Ei clipe ei" → "Ei clipe ei cli" → "Ei clipe ei clipe".
        let r = run(
            .clip,
            [(0, "Ei clipe"), (3000, "Ei clipe ei"), (3300, "Ei clipe ei cli"), (3800, "Ei clipe ei clipe")])
        XCTAssertEqual(r, [.full, nil, .early, nil])
    }

    func testRevisaoDoReconhecedorNaoDisparaDeNovo() {
        let r = run(.clip, [(0, "Ei cli"), (300, "Ei clipe"), (600, "Ei clipe")])
        XCTAssertEqual(r, [.early, nil, nil])
    }

    func testTravaDeIntervaloBarraEGastaOAcerto() {
        // Segunda fala 500 ms depois da primeira: barrada, e não dispara mais tarde com o mesmo texto.
        let r = run(.clip, [(0, "Ei clipe"), (500, "Ei"), (700, "Ei cli"), (1200, "Ei clipe")])
        XCTAssertEqual(r, [.full, nil, nil, nil])
    }

    func testClipSoltoSoComeca() {
        let r = run(.clip, [(0, "clipe")])
        XCTAssertEqual(r, [.loose])
    }

    func testFrasesQueNaoSaoPalavraDeAtivacaoNaoDisparam() {
        let r = run(.clip, [(0, "Ei"), (300, "Ei Felipe"), (900, "oi tudo bem")])
        XCTAssertEqual(r, [nil, nil, nil])
    }

    func testCameraAcaoSoValeAFraseCompleta() {
        let r = run(.cameraAcao, [(0, "Câmera"), (300, "Câmera ação"), (4000, "Ei clipe")])
        XCTAssertEqual(r, [nil, .full, nil])
    }

    func testEiCameraNaoAceitaAFraseSoltaNemAChamadaComum() {
        let r = run(.eiCamera, [(0, "a câmera está ligada"), (4000, "Ei"), (4300, "Ei câmera")])
        XCTAssertEqual(r, [nil, nil, .full])
    }

    func testResetRecomecaOTexto() {
        var t = WakeTracker(word: .clip, minGapMs: 1500)
        XCTAssertEqual(t.feed("Ei clipe", nowMs: 0), .full)
        t.reset()  // tarefa nova do reconhecedor: o texto recomeça; a trava de intervalo continua
        XCTAssertNil(t.feed("Ei clipe", nowMs: 500))
        XCTAssertEqual(t.feed("Ei clipe", nowMs: 5000), nil)  // mesmo texto já gasto nesta tarefa
        XCTAssertEqual(t.feed("Ei", nowMs: 6000), nil)
        XCTAssertEqual(t.feed("Ei clipe", nowMs: 6500), .full)
    }

    // MARK: - Com gravação em andamento (v0.2.2)

    private let gravando5s = WakeState(recording: true, recordingMs: 5000, finalizing: false)

    func testGravandoSoAFraseCompletaPara() {
        // O "ei cli" parcial NÃO pode ser gasto durante a gravação: senão o "ei clipe" completo nunca viria a parar.
        var t = WakeTracker(word: .clip, minGapMs: 1500)
        XCTAssertNil(t.feed("Ei", nowMs: 0, state: gravando5s))
        XCTAssertNil(t.feed("Ei cli", nowMs: 300, state: gravando5s))
        XCTAssertEqual(t.feed("Ei clipe", nowMs: 800, state: gravando5s), .full)
    }

    func testClipSoltoSoParaDepoisDe3500ms() {
        var t = WakeTracker(word: .clip, minGapMs: 1500)
        let cedo = WakeState(recording: true, recordingMs: 3000, finalizing: false)
        let tarde = WakeState(recording: true, recordingMs: 3600, finalizing: false)
        XCTAssertNil(t.feed("clipe", nowMs: 0, state: cedo))
        XCTAssertEqual(t.feed("clipe", nowMs: 700, state: tarde), .loose)
    }

    func testEncerrandoEngoleOQueFoiDitoSemDisparar() {
        var t = WakeTracker(word: .clip, minGapMs: 1500)
        let encerrando = WakeState(recording: true, recordingMs: 9000, finalizing: true)
        XCTAssertNil(t.feed("Ei clipe", nowMs: 0, state: encerrando))
        // Terminou de encerrar: o mesmo texto não pode ligar a gravação de novo.
        XCTAssertNil(t.feed("Ei clipe", nowMs: 1200))
        // Uma fala nova depois vale.
        XCTAssertNil(t.feed("Ei", nowMs: 5000))
        XCTAssertEqual(t.feed("Ei clipe", nowMs: 5300), .full)
    }

    func testLigaPorVozEDepoisParaPorVoz() {
        var t = WakeTracker(word: .clip, minGapMs: 1500)
        // Liga: o começo parcial basta.
        XCTAssertNil(t.feed("Ei", nowMs: 0))
        XCTAssertEqual(t.feed("Ei cli", nowMs: 300), .early)
        XCTAssertNil(t.feed("Ei clipe", nowMs: 800))
        // Para, 4 s depois, já gravando: o texto zera e a frase completa é que vale.
        let gravando = WakeState(recording: true, recordingMs: 3700, finalizing: false)
        XCTAssertNil(t.feed("Ei", nowMs: 4000, state: gravando))
        XCTAssertNil(t.feed("Ei cli", nowMs: 4300, state: gravando))
        XCTAssertEqual(t.feed("Ei clipe", nowMs: 4800, state: gravando), .full)
    }

    func testOutrasPalavrasValemGravando() {
        var t = WakeTracker(word: .cameraAcao, minGapMs: 1500)
        XCTAssertNil(t.feed("Câmera", nowMs: 0, state: gravando5s))
        XCTAssertEqual(t.feed("Câmera ação", nowMs: 500, state: gravando5s), .full)
    }
}
