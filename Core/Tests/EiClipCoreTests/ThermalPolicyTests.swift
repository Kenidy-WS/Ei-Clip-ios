import XCTest
@testable import EiClipCore

final class ThermalPolicyTests: XCTestCase {
    private func config(_ q: VideoQuality, _ fps: Int, _ level: ImageQuality) -> CaptureConfig {
        CaptureConfig(quality: q, fps: fps, imageLevel: level, position: .back).validated()
    }

    // MARK: Degraus

    func testDegrausDoQuePesaMais() {
        let start = config(.p1080, 60, .maximum)
        XCTAssertEqual(start.lowered(by: 1), config(.p1080, 30, .maximum))
        XCTAssertEqual(start.lowered(by: 2), config(.p1080, 30, .high))
        XCTAssertEqual(start.lowered(by: 3), config(.p1080, 30, .standard))
        XCTAssertEqual(start.lowered(by: 4), config(.p720, 30, .standard))
        XCTAssertEqual(start.lowered(by: 99), config(.p720, 30, .standard))  // para no piso
    }

    func test4KCaiParaOMesmoNivelEmFullHD() {
        let start = config(.p2160, 30, .high)
        XCTAssertEqual(start.lowered(by: 1), config(.p1080, 30, .high))
    }

    func testPadraoNaoTemDegrauSem720() {
        XCTAssertEqual(CaptureConfig.standard.availableLowerSteps(allow720: false), 0)
        XCTAssertEqual(CaptureConfig.standard.availableLowerSteps(allow720: true), 1)
        XCTAssertEqual(CaptureConfig.standard.lowered(by: 1).quality, .p720)
    }

    func testZeroPassosNaoMudaNada() {
        let c = config(.p2160, 30, .maximum)
        XCTAssertEqual(c.lowered(by: 0), c)
    }

    func testContaDePassosDisponiveis() {
        XCTAssertEqual(config(.p2160, 30, .maximum).availableLowerSteps(allow720: false), 3)  // 1080p, alta, padrão
        XCTAssertEqual(config(.p2160, 30, .maximum).availableLowerSteps(allow720: true), 4)
        XCTAssertEqual(config(.p1080, 60, .standard).availableLowerSteps(allow720: false), 1)  // 30 fps
    }

    func testConfiguracaoPesada() {
        XCTAssertFalse(CaptureConfig.standard.isHeavy)
        XCTAssertTrue(config(.p2160, 30, .standard).isHeavy)
        XCTAssertTrue(config(.p1080, 60, .standard).isHeavy)
        XCTAssertTrue(config(.p1080, 30, .maximum).isHeavy)
        XCTAssertFalse(config(.p720, 30, .high).isHeavy)
    }

    // MARK: Reação ao calor

    func testPadraoQuenteSoAvisaECriticoVaiPara720() {
        var gov = ThermalGovernor()
        let chosen = CaptureConfig.standard
        XCTAssertEqual(gov.react(level: .nominal, chosen: chosen, recording: false), ThermalAction())
        XCTAssertEqual(gov.react(level: .fair, chosen: chosen, recording: false), ThermalAction())  // leve e não pesado
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .hotAtFloor))
        XCTAssertEqual(
            gov.react(level: .critical, chosen: chosen, recording: false), ThermalAction(notice: .critical, lowerTo: 1))
        XCTAssertEqual(gov.appliedSteps, 1)
    }

    func testDescricaoDaReducao() {
        XCTAssertEqual(
            reductionDescription(from: config(.p1080, 60, .maximum), to: config(.p1080, 30, .maximum)), "60 → 30 fps")
        XCTAssertEqual(
            reductionDescription(from: config(.p2160, 30, .high), to: config(.p1080, 30, .high)), "4K → 1080p")
        XCTAssertEqual(
            reductionDescription(from: config(.p1080, 30, .maximum), to: config(.p1080, 30, .high)),
            "qualidade Máxima → Alta")
        XCTAssertEqual(
            reductionDescription(from: config(.p1080, 60, .maximum), to: config(.p1080, 30, .high)),
            "60 → 30 fps, qualidade Máxima → Alta")
        XCTAssertNil(reductionDescription(from: config(.p1080, 30, .high), to: config(.p1080, 30, .high)))
    }

    func testSemReducaoAutomaticaQuenteSoAvisa() {
        var gov = ThermalGovernor()
        let chosen = config(.p1080, 60, .maximum)
        XCTAssertEqual(
            gov.react(level: .serious, chosen: chosen, recording: false, autoReduce: false),
            ThermalAction(notice: .hotAdvice))
        XCTAssertEqual(gov.appliedSteps, 0)
    }

    // v0.9.11: sem a redução automática, o crítico só avisa (a escolha do usuário vale).
    func testSemReducaoAutomaticaCriticoSoAvisa() {
        var gov = ThermalGovernor()
        let chosen = config(.p1080, 60, .maximum)
        _ = gov.react(level: .serious, chosen: chosen, recording: false, autoReduce: false)
        XCTAssertEqual(
            gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false), ThermalAction(notice: .critical))
        XCTAssertEqual(gov.appliedSteps, 0)
    }

    // v0.9.11: reserva. A câmera falhou no calor: 2 passos, mesmo com a redução automática desligada.
    func testFalhaDaCameraNoCriticoReduzDoisPassos() {
        var gov = ThermalGovernor()
        let chosen = config(.p1080, 60, .maximum)
        _ = gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false)
        gov.noteCameraFailure()
        XCTAssertEqual(
            gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false),
            ThermalAction(notice: .critical, lowerTo: 2))
        XCTAssertEqual(chosen.lowered(by: gov.appliedSteps), config(.p1080, 30, .high))
        // Não desce de novo sozinha.
        XCTAssertEqual(gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false), ThermalAction())
    }

    func testFalhaDaCameraNoQuenteReduzDoisPassos() {
        var gov = ThermalGovernor()
        let chosen = config(.p2160, 30, .maximum)
        _ = gov.react(level: .serious, chosen: chosen, recording: false, autoReduce: false)
        gov.noteCameraFailure()
        XCTAssertEqual(
            gov.react(level: .serious, chosen: chosen, recording: false, autoReduce: false),
            ThermalAction(notice: .reduced, lowerTo: 2))
        XCTAssertEqual(chosen.lowered(by: gov.appliedSteps), config(.p1080, 30, .high))
    }

    func testFalhaDaCameraGravandoEsperaOFim() {
        var gov = ThermalGovernor()
        let chosen = config(.p1080, 60, .maximum)
        _ = gov.react(level: .critical, chosen: chosen, recording: true, autoReduce: false)
        gov.noteCameraFailure()
        XCTAssertEqual(gov.react(level: .critical, chosen: chosen, recording: true, autoReduce: false), ThermalAction())
        XCTAssertEqual(gov.appliedSteps, 0)
        XCTAssertEqual(
            gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false),
            ThermalAction(notice: .critical, lowerTo: 2))
    }

    func testFalhaDaCameraSemCalorNaoReduz() {
        var gov = ThermalGovernor()
        let chosen = config(.p1080, 60, .maximum)
        gov.noteCameraFailure()
        XCTAssertEqual(gov.react(level: .fair, chosen: chosen, recording: false, autoReduce: false), ThermalAction())
        XCTAssertEqual(gov.appliedSteps, 0)
    }

    // v0.9.11: escolher a qualidade de novo zera a redução e a falha; o crítico volta a só avisar.
    func testEscolherDeNovoZeraAReserva() {
        var gov = ThermalGovernor()
        let chosen = config(.p1080, 60, .maximum)
        gov.noteCameraFailure()
        _ = gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false)
        XCTAssertEqual(gov.appliedSteps, 2)
        gov.reset()
        XCTAssertEqual(gov.appliedSteps, 0)
        XCTAssertFalse(gov.cameraFailed)
        XCTAssertEqual(
            gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false), ThermalAction(notice: .critical))
    }

    func testSemReducaoAutomaticaNoPisoSoCuidado() {
        var gov = ThermalGovernor()
        XCTAssertEqual(
            gov.react(level: .serious, chosen: .standard, recording: false, autoReduce: false),
            ThermalAction(notice: .hotAtFloor))
    }

    func test4KQuenteReduzParaFullHDEcriticoParaHD() {
        var gov = ThermalGovernor()
        let chosen = config(.p2160, 30, .standard)
        XCTAssertEqual(gov.react(level: .fair, chosen: chosen, recording: false), ThermalAction())
        XCTAssertEqual(
            gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .reduced, lowerTo: 1))
        XCTAssertEqual(
            gov.react(level: .critical, chosen: chosen, recording: false), ThermalAction(notice: .critical, lowerTo: 2))
        XCTAssertEqual(chosen.lowered(by: gov.appliedSteps).quality, .p720)
    }

    func testGravandoAdiaAReducaoEAplicaDepois() {
        var gov = ThermalGovernor()
        let chosen = config(.p2160, 30, .standard)
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: true), ThermalAction(notice: .reducePending))
        XCTAssertEqual(gov.appliedSteps, 0)  // nada mudou no meio do clipe
        // Repete a mesma leitura durante a gravação: não avisa de novo.
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: true), ThermalAction())
        // A gravação terminou: aplica e avisa.
        XCTAssertEqual(
            gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .reduced, lowerTo: 1))
    }

    func testEsfriarNaoSobeAQualidadeSozinho() {
        var gov = ThermalGovernor()
        let chosen = config(.p2160, 30, .standard)
        _ = gov.react(level: .serious, chosen: chosen, recording: false)
        XCTAssertEqual(gov.react(level: .nominal, chosen: chosen, recording: false), ThermalAction())
        XCTAssertEqual(gov.appliedSteps, 1)
    }

    func testOscilacaoNaoRepeteAviso() {
        var gov = ThermalGovernor()
        let chosen = CaptureConfig.standard
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .hotAtFloor))
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction())
        XCTAssertEqual(gov.react(level: .fair, chosen: chosen, recording: false), ThermalAction())
        // Piorou de novo depois de esfriar um pouco: avisa.
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .hotAtFloor))
    }

    func testResetZeraARedução() {
        var gov = ThermalGovernor()
        let chosen = config(.p2160, 30, .standard)
        _ = gov.react(level: .serious, chosen: chosen, recording: false)
        gov.reset()
        XCTAssertEqual(gov.appliedSteps, 0)
        // Depois do reset o mesmo calor reduz de novo.
        XCTAssertEqual(
            gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .reduced, lowerTo: 1))
    }

    func testSemPassosNoPisoCriticoSoAvisa() {
        var gov = ThermalGovernor()
        let floor = config(.p720, 30, .standard)
        XCTAssertEqual(gov.react(level: .critical, chosen: floor, recording: false), ThermalAction(notice: .critical))
    }

    func testAbrirJaQuenteNaoAvisaMasPiorarAvisa() {
        var gov = ThermalGovernor()
        let chosen = CaptureConfig.standard
        XCTAssertTrue(gov.quietOpening(level: .serious))
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: false, autoReduce: false), ThermalAction())
        // Piorou depois da abertura: avisa.
        XCTAssertEqual(gov.react(level: .critical, chosen: chosen, recording: false, autoReduce: false), ThermalAction(notice: .critical))
    }

    func testAbrirJaQuenteEsfriarEEsquentarDeNovoAvisa() {
        var gov = ThermalGovernor()
        let chosen = CaptureConfig.standard
        gov.quietOpening(level: .serious)
        _ = gov.react(level: .serious, chosen: chosen, recording: false)
        _ = gov.react(level: .fair, chosen: chosen, recording: false)
        XCTAssertEqual(gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .hotAtFloor))
    }

    func testAbrirCriticoOuMornoNaoAdiaNada() {
        var gov = ThermalGovernor()
        XCTAssertFalse(gov.quietOpening(level: .critical))
        XCTAssertFalse(gov.quietOpening(level: .fair))
        XCTAssertEqual(
            gov.react(level: .critical, chosen: .standard, recording: false, autoReduce: false), ThermalAction(notice: .critical))
    }

    func testReaberturaNaoBaixaOUltimoNivel() {
        var gov = ThermalGovernor()
        _ = gov.react(level: .critical, chosen: .standard, recording: false)
        XCTAssertFalse(gov.quietOpening(level: .serious))
        // Continua crítico: nada novo (não repete o aviso).
        XCTAssertEqual(gov.react(level: .critical, chosen: .standard, recording: false), ThermalAction())
    }

    func testAbrirJaQuenteComReducaoAutomaticaAindaReduz() {
        var gov = ThermalGovernor()
        let chosen = CaptureConfig(quality: .p2160, fps: 30, imageLevel: .standard, position: .back, stabilize: false)
        gov.quietOpening(level: .serious)
        XCTAssertEqual(
            gov.react(level: .serious, chosen: chosen, recording: false), ThermalAction(notice: .reduced, lowerTo: 1))
    }
}
