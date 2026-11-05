import XCTest
@testable import EiClipCore

// Gabarito: tests/video-profile.test.ts, tests/timestamps.test.ts (clipFileName) e tests/format.test.ts.
final class ProfileAndNameTests: XCTestCase {
    func testPadraoDe1080pEm16Mbps() {
        XCTAssertEqual(videoBitrate(.p1080, fps: 30, level: .standard), 16_000_000)
    }

    func testSobeComQualidadeEcom60fps() {
        XCTAssertGreaterThan(
            videoBitrate(.p1080, fps: 30, level: .high), videoBitrate(.p1080, fps: 30, level: .standard))
        XCTAssertEqual(videoBitrate(.p1080, fps: 60, level: .standard), 20_000_000)
        XCTAssertEqual(videoBitrate(.p1080, fps: 60, level: .maximum), 35_000_000)
    }

    func testRespeitaOTetoDe50Mbps() {
        XCTAssertEqual(videoBitrate(.p2160, fps: 60, level: .maximum), 50_000_000)
    }

    func testTamanhosDeVideo() {
        XCTAssertEqual(VideoQuality.p1080.size.width, 1920)
        XCTAssertEqual(VideoQuality.p1080.size.height, 1080)
        XCTAssertEqual(VideoQuality.p2160.size.width, 3840)
    }

    func testNomeDoClipe() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Cuiaba")!
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 10
        parts.day = 29
        parts.hour = 7
        parts.minute = 5
        parts.second = 9
        parts.timeZone = cal.timeZone
        let date = cal.date(from: parts)!
        XCTAssertEqual(clipFileName(date, calendar: cal), "clip-20261029-070509.mp4")
    }

    func testFormatDuration() {
        XCTAssertEqual(formatDuration(0), "0:00")
        XCTAssertEqual(formatDuration(9.9), "0:09")
        XCTAssertEqual(formatDuration(75), "1:15")
        XCTAssertEqual(formatDuration(600), "10:00")
        XCTAssertEqual(formatDuration(-5), "0:00")
    }
}
