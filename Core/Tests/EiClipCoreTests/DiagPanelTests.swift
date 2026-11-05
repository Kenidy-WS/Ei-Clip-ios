import XCTest
@testable import EiClipCore

final class DiagPanelTests: XCTestCase {
    /// Câmera aberta há 10 s, tudo normal.
    private func ok() -> DiagSnapshot {
        var s = DiagSnapshot()
        s.appVersion = "v0.3.10 (28)"
        s.cameraOpen = true
        s.cameraOpenSec = 10
        s.framesIn = 300
        s.framesEncoded = 299
        s.fpsOut = 30
        s.audioBlocks = 450
        s.micPeak = 0.0143
        return s
    }

    private func titles(_ s: DiagSnapshot) -> [String] { DiagPanel.sections(s).map { $0.title } }

    // MARK: Atenção

    func testSemProblemasNaoTemSecaoAtencao() {
        XCTAssertTrue(DiagPanel.alerts(ok()).isEmpty)
        XCTAssertFalse(titles(ok()).contains("Atenção"))
    }

    func testAtencaoVemPrimeiraQuandoHaProblema() {
        var s = ok()
        s.dropped = 2
        let sec = DiagPanel.sections(s)
        XCTAssertEqual(sec.first?.title, "Atenção")
        XCTAssertEqual(sec.first?.alert, true)
        XCTAssertEqual(sec.first?.lines, ["2 quadro(s) de vídeo descartado(s)"])
    }

    func testMicrofoneMudoSoDepoisDe3Segundos() {
        var s = ok()
        s.micPeak = 0.0003
        s.cameraOpenSec = 2
        XCTAssertTrue(DiagPanel.alerts(s).isEmpty)  // ainda dentro da tolerância
        s.cameraOpenSec = 3.5
        XCTAssertEqual(DiagPanel.alerts(s), ["Microfone MUDO (pico 0.0003)"])
        XCTAssertEqual(DiagPanel.micState(s), "MUDO")
    }

    func testMicrofoneSemBlocos() {
        var s = ok()
        s.audioBlocks = 0
        XCTAssertEqual(DiagPanel.alerts(s), ["O microfone não entregou nenhum bloco de áudio"])
        s.cameraOpenSec = 1
        XCTAssertTrue(DiagPanel.alerts(s).isEmpty)
        XCTAssertEqual(DiagPanel.micState(s), "aguardando")
    }

    func testCameraSemQuadros() {
        var s = ok()
        s.framesIn = 0
        XCTAssertEqual(DiagPanel.alerts(s), ["A câmera está aberta mas não entregou nenhum quadro"])
    }

    func testContadoresDeCapturaIgnoradosComCameraFechada() {
        var s = ok()
        s.cameraOpen = false
        s.framesIn = 0
        s.audioBlocks = 0
        s.dropped = 5
        s.encoderErrors = 1
        XCTAssertTrue(DiagPanel.alerts(s).isEmpty)
        XCTAssertEqual(DiagPanel.micState(s), "-")
    }

    func testPermissoesETemperaturaEAvisoSaemComCameraFechada() {
        var s = DiagSnapshot()
        s.cameraDenied = true
        s.micDenied = true
        s.photosNotFull = true
        s.thermalSevere = true
        s.thermal = "crítico"
        s.message = "Não foi possível abrir a câmera."
        let a = DiagPanel.alerts(s)
        XCTAssertEqual(a.count, 5)
        XCTAssertTrue(a.contains("Temperatura do aparelho: crítico"))
        XCTAssertTrue(a.contains("Aviso do app: Não foi possível abrir a câmera."))
    }

    func testErrosDoCodificadorECopiasDeAudio() {
        var s = ok()
        s.encoderErrors = 3
        s.audioCopyFails = 1
        let a = DiagPanel.alerts(s)
        XCTAssertTrue(a.contains("3 erro(s) do codificador de vídeo"))
        XCTAssertTrue(a.contains("1 bloco(s) de áudio não copiado(s)"))
    }

    // MARK: Seções

    func testOrdemDasSecoes() {
        XCTAssertEqual(
            titles(ok()),
            ["Resumo", "Vídeo", "Áudio", "Comando de voz", "Ajustes", "Orientação", "Permissões e ciclo de vida"])
    }

    func testResumoComCameraFechadaTemDica() {
        let resumo = DiagPanel.sections(DiagSnapshot()).first { $0.title == "Resumo" }
        XCTAssertEqual(resumo?.rows.first { $0.label == "Câmera" }?.value, "desligada")
        XCTAssertNotNil(resumo?.rows.first { $0.label == "Dica" })
    }

    func testResumoComCameraAbertaNaoTemDica() {
        let resumo = DiagPanel.sections(ok()).first { $0.title == "Resumo" }
        XCTAssertEqual(resumo?.rows.first { $0.label == "Câmera" }?.value, "ligada há 10 s")
        XCTAssertNil(resumo?.rows.first { $0.label == "Dica" })
    }

    func testVozDesativadaNosAjustes() {
        var s = ok()
        s.voiceEnabled = false
        s.voiceMode = "desligada"
        let resumo = DiagPanel.sections(s).first { $0.title == "Resumo" }
        XCTAssertEqual(resumo?.rows.first { $0.label == "Voz" }?.value, "desativada nos Ajustes")
    }

    func testLinhasDeVozECicloDeVidaViramLinhasDaSecao() {
        var s = ok()
        s.voiceLog = ["a", "b"]
        s.lifecycle = ["c"]
        let sec = DiagPanel.sections(s)
        XCTAssertEqual(sec.first { $0.title == "Comando de voz" }?.lines, ["a", "b"])
        XCTAssertEqual(sec.first { $0.title == "Permissões e ciclo de vida" }?.lines, ["c"])
    }

    func testRotulosUnicosDentroDeCadaSecao() {
        for sec in DiagPanel.sections(ok()) {
            let labels = sec.rows.map { $0.label }
            XCTAssertEqual(Set(labels).count, labels.count, sec.title)
        }
        let all = DiagPanel.sections(ok()).map { $0.title }
        XCTAssertEqual(Set(all).count, all.count)
    }

    func testOrientacaoMostraOGiro() {
        var s = ok()
        s.holdLabel = "deitado, topo à direita"
        s.fileRotationDegrees = 180
        let o = DiagPanel.sections(s).first { $0.title == "Orientação" }
        XCTAssertEqual(o?.rows.first { $0.label == "Aparelho" }?.value, "deitado, topo à direita")
        XCTAssertEqual(o?.rows.first { $0.label == "Giro do próximo clipe" }?.value, "180°")
    }

    // MARK: Texto

    func testTextoSimples() {
        let text = DiagPanel.text([
            DiagSection(title: "Resumo", rows: [DiagRow("App", "v1"), DiagRow("Gravando", "não")], lines: ["linha 1"]),
            DiagSection(title: "Outra", rows: [DiagRow("X", "y")]),
        ])
        XCTAssertEqual(text, "== Resumo ==\nApp: v1\nGravando: não\n  linha 1\n\n== Outra ==\nX: y")
    }

    func testTextoDoPainelCompletoTemTodasAsSecoes() {
        let text = DiagPanel.text(DiagPanel.sections(ok()))
        for title in ["Resumo", "Vídeo", "Áudio", "Comando de voz", "Ajustes", "Orientação", "Permissões e ciclo de vida"] {
            XCTAssertTrue(text.contains("== \(title) =="), title)
        }
    }
}
