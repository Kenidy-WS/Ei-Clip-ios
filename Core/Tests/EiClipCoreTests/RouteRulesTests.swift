import XCTest
@testable import EiClipCore

final class RouteRulesTests: XCTestCase {
    func testTelaPelaRotaEPeloMotor() {
        var route = AppRoute()
        XCTAssertEqual(route.screen(cameraOpen: false), .home)
        XCTAssertEqual(route.screen(cameraOpen: true), .camera)
        route.showGallery()
        XCTAssertEqual(route.screen(cameraOpen: false), .gallery)
        XCTAssertEqual(route.screen(cameraOpen: true), .gallery)
        route.hideGallery()
        route.park()
        XCTAssertEqual(route.screen(cameraOpen: false), .gallery)  // tela preta no lugar da câmera, não o Início
        route.unpark()
        XCTAssertEqual(route.screen(cameraOpen: true), .camera)
    }

    func testOrigemDaGaleria() {
        var route = AppRoute()
        route.markGalleryOrigin(fromCamera: true)
        XCTAssertTrue(route.galleryFromCamera)
        route.markGalleryOrigin(fromCamera: false)
        XCTAssertFalse(route.galleryFromCamera)
    }

    func testVoltarPelaBorda() {
        XCTAssertEqual(edgeBackAction(inGallery: true, selecting: true, cameraOpen: false, recording: false), .exitSelection)
        XCTAssertEqual(edgeBackAction(inGallery: true, selecting: false, cameraOpen: false, recording: false), .leaveGallery)
        XCTAssertEqual(edgeBackAction(inGallery: false, selecting: false, cameraOpen: true, recording: false), .closeCamera)
        XCTAssertEqual(edgeBackAction(inGallery: false, selecting: false, cameraOpen: true, recording: true), .none)
        XCTAssertEqual(edgeBackAction(inGallery: false, selecting: false, cameraOpen: false, recording: false), .none)
    }

    func testAvancarPelaBorda() {
        let home = AppRoute()
        XCTAssertEqual(
            edgeForwardAction(route: home, playerOpen: false, opening: false, testRunning: false, cameraOpen: false, recording: false),
            .galleryFromHome)
        XCTAssertEqual(
            edgeForwardAction(route: home, playerOpen: false, opening: false, testRunning: false, cameraOpen: true, recording: false),
            .galleryFromCamera)
        XCTAssertEqual(
            edgeForwardAction(route: home, playerOpen: false, opening: false, testRunning: false, cameraOpen: true, recording: true),
            .none)
    }

    func testAvancarIgnoradoForaDoMomento() {
        var gallery = AppRoute()
        gallery.showGallery()
        XCTAssertEqual(
            edgeForwardAction(route: gallery, playerOpen: false, opening: false, testRunning: false, cameraOpen: false, recording: false),
            .none)
        var parked = AppRoute()
        parked.park()
        XCTAssertEqual(
            edgeForwardAction(route: parked, playerOpen: false, opening: false, testRunning: false, cameraOpen: false, recording: false),
            .none)
        let home = AppRoute()
        XCTAssertEqual(
            edgeForwardAction(route: home, playerOpen: true, opening: false, testRunning: false, cameraOpen: false, recording: false),
            .none)
        XCTAssertEqual(
            edgeForwardAction(route: home, playerOpen: false, opening: true, testRunning: false, cameraOpen: false, recording: false),
            .none)
        XCTAssertEqual(
            edgeForwardAction(route: home, playerOpen: false, opening: false, testRunning: true, cameraOpen: false, recording: false),
            .none)
    }
    // MARK: Tela escura (v0.6.3)

    func testComATelaEscuraOGestoDeVoltarSoAcende() {
        XCTAssertEqual(
            edgeBackAction(inGallery: false, selecting: false, cameraOpen: true, recording: false, dimmed: true), .wakeScreen)
        // Gravando também: acende (nunca navega nem para a gravação).
        XCTAssertEqual(
            edgeBackAction(inGallery: false, selecting: false, cameraOpen: true, recording: true, dimmed: true), .wakeScreen)
    }

    func testSemTelaEscuraOGestoDeVoltarContinuaIgual() {
        XCTAssertEqual(
            edgeBackAction(inGallery: false, selecting: false, cameraOpen: true, recording: false), .closeCamera)
        XCTAssertEqual(
            edgeBackAction(inGallery: false, selecting: false, cameraOpen: true, recording: false, dimmed: false), .closeCamera)
    }

    func testComATelaEscuraOGestoDeAvancarNaoFazNada() {
        XCTAssertEqual(
            edgeForwardAction(
                route: AppRoute(), playerOpen: false, opening: false, testRunning: false, cameraOpen: true, recording: false,
                dimmed: true), .none)
        XCTAssertEqual(
            edgeForwardAction(
                route: AppRoute(), playerOpen: false, opening: false, testRunning: false, cameraOpen: true, recording: false),
            .galleryFromCamera)
    }

    func testSoEscurecComACameraAbertaEForaDoTeste() {
        XCTAssertTrue(canDimScreen(cameraOpen: true, testRunning: false))
        XCTAssertFalse(canDimScreen(cameraOpen: false, testRunning: false))
        XCTAssertFalse(canDimScreen(cameraOpen: true, testRunning: true))
    }
}
