import XCTest
@testable import EiClipCore

final class ZoomRulesTests: XCTestCase {
    func testFatoresDaTelaEDoAparelho() {
        XCTAssertEqual(ZoomRules.screenFactor(device: 1.0, main: 2.0), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.screenFactor(device: 2.0, main: 2.0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.screenFactor(device: 4.0, main: 2.0), 2.0, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.deviceFactor(screen: 0.5, main: 2.0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.deviceFactor(screen: 3.0, main: 2.0), 6.0, accuracy: 1e-9)
        // Sem câmera combinada os dois são iguais.
        XCTAssertEqual(ZoomRules.screenFactor(device: 1.7, main: nil), 1.7, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.deviceFactor(screen: 1.7, main: nil), 1.7, accuracy: 1e-9)
    }

    func testFaixaDaPinca() {
        // Combinada com formato que chega a 16× no aparelho: 0,5× a 6× (o teto manda).
        XCTAssertEqual(ZoomRules.range(main: 2.0, deviceMax: 16.0), 0.5...6.0)
        // Formato mais curto (ex.: 4K): o teto é o do formato.
        XCTAssertEqual(ZoomRules.range(main: 2.0, deviceMax: 10.0), 0.5...5.0)
        // Sem combinada: de 1× até 6×, ou menos se o formato for curto.
        XCTAssertEqual(ZoomRules.range(main: nil, deviceMax: 12.0), 1.0...6.0)
        XCTAssertEqual(ZoomRules.range(main: nil, deviceMax: 3.0), 1.0...3.0)
        // Nunca uma faixa invertida.
        XCTAssertEqual(ZoomRules.range(main: nil, deviceMax: 0.5), 1.0...1.0)
    }

    func testAlvoDaPinca() {
        let range = ZoomRules.range(main: 2.0, deviceMax: 16.0)
        XCTAssertEqual(ZoomRules.pinchTarget(start: 1.0, scale: 1.5, range: range), 1.5, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.pinchTarget(start: 1.0, scale: 0.2, range: range), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.pinchTarget(start: 2.0, scale: 10, range: range), 6.0, accuracy: 1e-9)
        // Escala inválida não muda o zoom.
        XCTAssertEqual(ZoomRules.pinchTarget(start: 1.3, scale: 0, range: range), 1.3, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.pinchTarget(start: 1.3, scale: .nan, range: range), 1.3, accuracy: 1e-9)
    }

    func testPontosDasLentes() {
        XCTAssertEqual(ZoomRules.screenPoint(of: .ultraWide, main: 2.0), 0.5, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.screenPoint(of: .wide, main: 2.0), 1.0, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.screenPoint(of: .twoX, main: 2.0), 2.0, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.screenPoint(of: .wide, main: nil), 1.0, accuracy: 1e-9)
        XCTAssertEqual(ZoomRules.screenPoint(of: .twoX, main: nil), 2.0, accuracy: 1e-9)
    }

    func testLenteEmUsoPeloZoom() {
        let all: [Lens] = [.ultraWide, .wide, .twoX]
        XCTAssertEqual(ZoomRules.lens(forScreen: 0.5, available: all, main: 2.0), .ultraWide)
        XCTAssertEqual(ZoomRules.lens(forScreen: 0.9, available: all, main: 2.0), .ultraWide)
        XCTAssertEqual(ZoomRules.lens(forScreen: 0.99, available: all, main: 2.0), .wide)  // folga de 0,02
        XCTAssertEqual(ZoomRules.lens(forScreen: 1.4, available: all, main: 2.0), .wide)
        XCTAssertEqual(ZoomRules.lens(forScreen: 2.0, available: all, main: 2.0), .twoX)
        XCTAssertEqual(ZoomRules.lens(forScreen: 5.9, available: all, main: 2.0), .twoX)
        // Sem combinada a ultra-angular nunca entra.
        XCTAssertEqual(ZoomRules.lens(forScreen: 1.0, available: all, main: nil), .wide)
        XCTAssertEqual(ZoomRules.lens(forScreen: 2.5, available: all, main: nil), .twoX)
        // Frontal: só a principal.
        XCTAssertEqual(ZoomRules.lens(forScreen: 3.0, available: [.wide], main: nil), .wide)
        // Lista vazia cai na principal.
        XCTAssertEqual(ZoomRules.lens(forScreen: 1.0, available: [], main: 2.0), .wide)
    }

    func testEmCimaDoPonto() {
        XCTAssertTrue(ZoomRules.isAtPoint(2.0, lens: .twoX, main: 2.0))
        XCTAssertTrue(ZoomRules.isAtPoint(1.01, lens: .wide, main: 2.0))
        XCTAssertFalse(ZoomRules.isAtPoint(3.0, lens: .twoX, main: 2.0))
        XCTAssertFalse(ZoomRules.isAtPoint(1.2, lens: .wide, main: 2.0))
    }

    func testSoMandaQuandoMuda() {
        XCTAssertFalse(ZoomRules.shouldSend(current: 1.0, new: 1.002))
        XCTAssertTrue(ZoomRules.shouldSend(current: 1.0, new: 1.01))
        XCTAssertTrue(ZoomRules.shouldSend(current: 2.0, new: 1.99))
    }

    func testTextoDoZoom() {
        XCTAssertEqual(ZoomRules.label(0.5), "0,5×")
        XCTAssertEqual(ZoomRules.label(1.0), "1×")
        XCTAssertEqual(ZoomRules.label(1.04), "1×")
        XCTAssertEqual(ZoomRules.label(1.44), "1,4×")
        XCTAssertEqual(ZoomRules.label(1.46), "1,5×")
        XCTAssertEqual(ZoomRules.label(2.0), "2×")
        XCTAssertEqual(ZoomRules.label(6.0), "6×")
    }

    func testMotivoDeBloqueio() {
        func reason(
            open: Bool = true, dimmed: Bool = false, test: Bool = false, reconf: Bool = false, rec: Bool = false, ultra: Bool = false
        ) -> String? {
            ZoomRules.blockedReason(
                cameraOpen: open, dimmed: dimmed, testRunning: test, reconfiguring: reconf, recording: rec, ultraWideAlone: ultra)
        }
        XCTAssertNil(reason())
        XCTAssertNotNil(reason(open: false))
        XCTAssertNotNil(reason(dimmed: true))
        XCTAssertNotNil(reason(test: true))
        XCTAssertNotNil(reason(reconf: true))
        XCTAssertNotNil(reason(rec: true))
        XCTAssertNotNil(reason(ultra: true))
    }
}
