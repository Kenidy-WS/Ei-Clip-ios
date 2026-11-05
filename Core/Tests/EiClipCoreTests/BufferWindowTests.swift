import XCTest
@testable import EiClipCore

final class BufferWindowTests: XCTestCase {
    func testValoresValidosSaoMantidos() {
        XCTAssertEqual(BufferWindow.sanitized(15), 15)
        XCTAssertEqual(BufferWindow.sanitized(30), 30)
    }

    func testAusenteOuInvalidoVoltaAoPadrao() {
        XCTAssertEqual(BufferWindow.sanitized(nil), 15)
        XCTAssertEqual(BufferWindow.sanitized(0), 15)
        XCTAssertEqual(BufferWindow.sanitized(20), 15)
        XCTAssertEqual(BufferWindow.sanitized(-30), 15)
    }
}

final class BufferWindowMemoriaTests: XCTestCase {
    func testSessentaValeENaoVira15() {
        XCTAssertEqual(BufferWindow.sanitized(60), 60)
    }

    func testRingBytes1080p() {
        // (60 + 3) s x (2.000.000 + 192.000) = 138.096.000
        XCTAssertEqual(BufferWindow.ringBytes(windowSec: 60, videoBitrate: 16_000_000), 138_096_000)
    }

    func test1080pAguenta60s() {
        XCTAssertEqual(BufferWindow.maxAllowed(videoBitrate: 16_000_000), 60)
        XCTAssertEqual(BufferWindow.effective(requested: 60, videoBitrate: 16_000_000), 60)
    }

    func test4KLimitaA30s() {
        // 45 Mbps: 63 s = 63 x 5.817.000 ≈ 366 MB (estoura); 33 s ≈ 192 MB (cabe).
        XCTAssertEqual(BufferWindow.maxAllowed(videoBitrate: 45_000_000), 30)
        XCTAssertEqual(BufferWindow.effective(requested: 60, videoBitrate: 45_000_000), 30)
        XCTAssertEqual(BufferWindow.effective(requested: 15, videoBitrate: 45_000_000), 15)
    }

    func testTaxaAbsurdaNuncaDaMenosQue15() {
        XCTAssertEqual(BufferWindow.maxAllowed(videoBitrate: 400_000_000), 15)
    }

    func test1080p60MaximaAgora60s() {
        // 28 Mbps x 1,25 = 35 Mbps: (4.375.000 + 192.000) x 63 ≈ 288 MB, cabe em 350 MB.
        let bitrate = videoBitrate(.p1080, fps: 60, level: .maximum)
        XCTAssertEqual(BufferWindow.maxAllowed(videoBitrate: bitrate), 60)
    }

    func test4KMaximaContinuaEm30s() {
        let bitrate = videoBitrate(.p2160, fps: 30, level: .maximum)
        XCTAssertEqual(BufferWindow.maxAllowed(videoBitrate: bitrate), 30)
    }

    func test4KPadraoAguenta60s() {
        let bitrate = videoBitrate(.p2160, fps: 30, level: .standard)
        XCTAssertEqual(BufferWindow.maxAllowed(videoBitrate: bitrate), 60)
    }
}
