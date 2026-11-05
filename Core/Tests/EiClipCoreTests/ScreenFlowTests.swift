import XCTest
@testable import EiClipCore

// Gabarito: `showView` em src/ui/transitions.ts (dir = view === 'home' ? 'back' : prev === 'home' ? 'fwd' : 'fade').
final class ScreenFlowTests: XCTestCase {
    func testSairDoInicioAvanca() {
        XCTAssertEqual(screenTransition(from: .home, to: .camera), .forward)
        XCTAssertEqual(screenTransition(from: .home, to: .gallery), .forward)
    }

    func testVoltarAoInicioRecua() {
        XCTAssertEqual(screenTransition(from: .camera, to: .home), .back)
        XCTAssertEqual(screenTransition(from: .gallery, to: .home), .back)
    }

    func testEntreCameraEGaleriaSoEsmaece() {
        XCTAssertEqual(screenTransition(from: .camera, to: .gallery), .fade)
        XCTAssertEqual(screenTransition(from: .gallery, to: .camera), .fade)
    }

    func testMesmaTelaNaoTroca() {
        XCTAssertEqual(screenTransition(from: .home, to: .home), .none)
        XCTAssertEqual(screenTransition(from: .camera, to: .camera), .none)
        XCTAssertEqual(screenTransition(from: .gallery, to: .gallery), .none)
    }

    func testMedidasIguaisAsDoWeb() {
        XCTAssertEqual(ScreenMotion.duration, 0.3)
        XCTAssertEqual(ScreenMotion.enterOffsetFraction, 0.26)
        XCTAssertEqual(ScreenMotion.exitOffsetFraction, 0.14)
    }
}
