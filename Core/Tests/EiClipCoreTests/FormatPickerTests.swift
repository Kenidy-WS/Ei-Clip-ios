import XCTest
@testable import EiClipCore

final class FormatPickerTests: XCTestCase {
    private let formats = [
        FormatInfo(width: 1920, height: 1080, minFps: 1, maxFps: 30),
        FormatInfo(width: 1920, height: 1080, minFps: 1, maxFps: 60),
        FormatInfo(width: 1920, height: 1080, minFps: 1, maxFps: 240),
        FormatInfo(width: 3840, height: 2160, minFps: 1, maxFps: 30),
    ]

    func test1080p30EscolheOFormatoDe30() {
        XCTAssertEqual(FormatPicker.pick(formats, width: 1920, height: 1080, fps: 30), 0)
    }

    func test1080p60EvitaOFormatoDeCameraLenta() {
        XCTAssertEqual(FormatPicker.pick(formats, width: 1920, height: 1080, fps: 60), 1)
    }

    func test4KSem60Falha() {
        XCTAssertNil(FormatPicker.pick(formats, width: 3840, height: 2160, fps: 60))
        XCTAssertEqual(FormatPicker.effectiveFps(formats, width: 3840, height: 2160, requested: 60), 30)
    }

    func testTamanhoInexistente() {
        XCTAssertNil(FormatPicker.pick(formats, width: 1280, height: 720, fps: 30))
    }

    func testFpsEfetivoMantemOPedidoQuandoExiste() {
        XCTAssertEqual(FormatPicker.effectiveFps(formats, width: 1920, height: 1080, requested: 60), 60)
    }
}
