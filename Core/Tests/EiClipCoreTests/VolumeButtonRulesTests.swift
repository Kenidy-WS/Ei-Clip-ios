import XCTest
@testable import EiClipCore

final class VolumeButtonRulesTests: XCTestCase {
    private func act(
        enabled: Bool = true, open: Bool = true, test: Bool = false, reconf: Bool = false, overlay: Bool = false,
        rec: Bool = false, stopping: Bool = false, pending: Bool = false, since: TimeInterval = 10
    ) -> VolumeAction {
        VolumeButtonRules.action(
            enabled: enabled, cameraOpen: open, testRunning: test, reconfiguring: reconf, overlayPresented: overlay,
            recording: rec, stopping: stopping, startPending: pending, sinceLast: since)
    }

    private func isIgnored(_ a: VolumeAction) -> Bool {
        if case .ignored = a { return true }
        return false
    }

    func testParadoInicia() { XCTAssertEqual(act(), .start) }

    func testGravandoPara() { XCTAssertEqual(act(rec: true), .stop) }

    func testChaveDesligadaIgnora() { XCTAssertTrue(isIgnored(act(enabled: false))) }

    func testCameraFechadaOuTesteIgnora() {
        XCTAssertTrue(isIgnored(act(open: false)))
        XCTAssertTrue(isIgnored(act(test: true)))
    }

    func testTelaPorCimaEReconfiguracaoIgnoram() {
        XCTAssertTrue(isIgnored(act(overlay: true)))
        XCTAssertTrue(isIgnored(act(reconf: true)))
        XCTAssertTrue(isIgnored(act(reconf: true, rec: true)))
    }

    func testApertoRepetidoIgnora() {
        XCTAssertTrue(isIgnored(act(since: 0.5)))
        XCTAssertTrue(isIgnored(act(rec: true, since: 0.79)))
        XCTAssertEqual(act(since: 0.8), .start)
    }

    func testEncerrandoOuIniciandoNaoRepete() {
        XCTAssertTrue(isIgnored(act(rec: true, stopping: true)))
        XCTAssertTrue(isIgnored(act(pending: true)))
    }

    func testSuporteAPartirDoIOS17ponto2() {
        XCTAssertFalse(VolumeButtonRules.isSupported(major: 16, minor: 9))
        XCTAssertFalse(VolumeButtonRules.isSupported(major: 17, minor: 1))
        XCTAssertTrue(VolumeButtonRules.isSupported(major: 17, minor: 2))
        XCTAssertTrue(VolumeButtonRules.isSupported(major: 18, minor: 0))
        XCTAssertTrue(VolumeButtonRules.isSupported(major: 27, minor: 0))
    }
}
