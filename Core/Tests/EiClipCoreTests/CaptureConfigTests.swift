import XCTest
@testable import EiClipCore

final class CaptureConfigTests: XCTestCase {
    func testPadraoIgualAoDeAntes() {
        let c = CaptureConfig.standard
        XCTAssertEqual(c.quality, .p1080)
        XCTAssertEqual(c.fps, 30)
        XCTAssertEqual(c.imageLevel, .standard)
        XCTAssertEqual(c.position, .back)
        XCTAssertEqual(c.bitrate, 16_000_000)
        XCTAssertEqual(c.summary, "1080p · 30 fps · padrão")
        XCTAssertEqual(c.validated(), c)
    }

    func test4kFicaEm30Fps() {
        let c = CaptureConfig(quality: .p2160, fps: 60, imageLevel: .high, position: .back).validated()
        XCTAssertEqual(c.fps, 30)
        XCTAssertEqual(c.quality, .p2160)
    }

    func testFpsDesconhecidoVira30() {
        XCTAssertEqual(CaptureConfig(quality: .p1080, fps: 24, imageLevel: .standard, position: .back).validated().fps, 30)
    }

    func test1080Aceita60() {
        XCTAssertEqual(CaptureConfig(quality: .p1080, fps: 60, imageLevel: .standard, position: .back).validated().fps, 60)
    }

    func testTextoDaFaixaDoTopo() {
        XCTAssertEqual(CaptureConfig(quality: .p1080, fps: 60, imageLevel: .standard, position: .back).stripText(position: .back), "1080 60")
        XCTAssertEqual(CaptureConfig(quality: .p720, fps: 30, imageLevel: .standard, position: .back).stripText(position: .back), "720 30")
        // 4K fica em 30 fps mesmo que o 60 tenha sido escolhido antes.
        XCTAssertEqual(CaptureConfig(quality: .p2160, fps: 60, imageLevel: .standard, position: .back).stripText(position: .back), "4K 30")
    }

    func testTextoDaFaixaSegueACameraEmUso() {
        let c = CaptureConfig(quality: .p2160, fps: 30, imageLevel: .standard, position: .back)
        XCTAssertEqual(c.stripText(position: .back), "4K 30")
        XCTAssertEqual(c.stripText(position: .front), "1080 30")  // a frontal fica em no máximo 1080p
        XCTAssertEqual(c.position, .back)  // não altera a configuração original
    }

    func testFrontalNaoPassaDe1080() {
        let c = CaptureConfig(quality: .p2160, fps: 30, imageLevel: .standard, position: .front).validated()
        XCTAssertEqual(c.quality, .p1080)
    }

    func testResumoMostraFrontalEOutraCamera() {
        var c = CaptureConfig.standard
        XCTAssertFalse(c.summary.contains("frontal"))
        c.position = c.flipped
        XCTAssertEqual(c.position, .front)
        XCTAssertTrue(c.summary.contains("câmera frontal"))
        XCTAssertEqual(c.flipped, .back)
    }

    func testFrontalSempreComLentePrincipal() {
        var c = CaptureConfig.standard
        c.lens = .twoX
        XCTAssertTrue(c.summary.contains("lente 2×"))
        c.position = .front
        XCTAssertEqual(c.validated().lens, .wide)
        XCTAssertFalse(c.validated().summary.contains("lente"))
    }
}
