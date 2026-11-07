import XCTest
@testable import EiClipCore

final class LaunchRulesTests: XCTestCase {
    private func act(
        route: AppRoute = AppRoute(), cameraOpen: Bool = false, overlay: Bool = false, opening: Bool = false,
        test: Bool = false
    ) -> LaunchAction {
        LaunchRules.action(route: route, cameraOpen: cameraOpen, overlayPresented: overlay, opening: opening, testRunning: test)
    }

    func testDoInicioAbreACamera() {
        XCTAssertEqual(act(), .openFromHome)
    }

    func testCameraJaAbertaNaoFazNada() {
        XCTAssertEqual(act(cameraOpen: true), .alreadyOpen)
    }

    func testDaGaleriaVoltaACamera() {
        var route = AppRoute()
        route.showGallery()
        XCTAssertEqual(act(route: route), .openFromGallery)
    }

    func testPlayerAbertoPelaCameraIgnora() {
        var route = AppRoute()
        route.park()
        guard case .ignored = act(route: route) else { return XCTFail("deveria ignorar") }
    }

    func testTelaPorCimaIgnoraEmQualquerLugar() {
        var gallery = AppRoute()
        gallery.showGallery()
        for route in [AppRoute(), gallery] {
            for cameraOpen in [false, true] {
                guard case .ignored = act(route: route, cameraOpen: cameraOpen, overlay: true) else {
                    return XCTFail("deveria ignorar com tela por cima")
                }
            }
        }
    }

    func testAbrindoOuEmTesteIgnora() {
        guard case .ignored = act(opening: true) else { return XCTFail("abrindo") }
        guard case .ignored = act(test: true) else { return XCTFail("teste") }
        // Câmera aberta e abrindo ao mesmo tempo: ainda ignora (não repete a abertura).
        guard case .ignored = act(cameraOpen: true, opening: true) else { return XCTFail("abrindo com câmera") }
    }

    func testPedidoVelhoEDescartado() {
        XCTAssertTrue(LaunchRules.isFresh(age: 0))
        XCTAssertTrue(LaunchRules.isFresh(age: 15))
        XCTAssertFalse(LaunchRules.isFresh(age: 15.1))
        XCTAssertFalse(LaunchRules.isFresh(age: -1))
    }

    func testTelaPretaSoQuandoACameraVaiAbrir() {
        XCTAssertTrue(LaunchAction.openFromHome.keepsCover)
        XCTAssertTrue(LaunchAction.openFromGallery.keepsCover)
        XCTAssertFalse(LaunchAction.alreadyOpen.keepsCover)
        XCTAssertFalse(LaunchAction.ignored("x").keepsCover)
        XCTAssertEqual(LaunchRules.coverTimeout, 4)
    }

    func testTextosDoDiagnostico() {
        XCTAssertEqual(LaunchAction.openFromHome.text, "abrir a câmera (estava no Início)")
        XCTAssertEqual(LaunchAction.alreadyOpen.text, "a câmera já está aberta")
        XCTAssertEqual(LaunchAction.ignored("x").text, "ignorado: x")
    }
}
