import XCTest
@testable import EiClipCore

// Gabarito: `fillInfo` em ui/clips-view.ts (tamanho com vírgula, taxa em Mbps, fluidez em fps).
final class ClipInfoFormatTests: XCTestCase {
    func testTamanhoEmMegabytes() {
        XCTAssertEqual(formatMegabytes(0), "0,0 MB")
        XCTAssertEqual(formatMegabytes(1_048_576), "1,0 MB")
        XCTAssertEqual(formatMegabytes(13_000_000), "12,4 MB")
        XCTAssertEqual(formatMegabytes(-5), "0,0 MB")
    }

    func testTaxaEmMbps() {
        XCTAssertEqual(formatMbps(16_000_000), "16,0 Mbps")
        XCTAssertEqual(formatMbps(20_500_000), "20,5 Mbps")
    }

    func testFluidezArredondada() {
        XCTAssertEqual(formatFps(30), "30 fps")
        XCTAssertEqual(formatFps(29.97), "30 fps")
        XCTAssertEqual(formatFps(60), "60 fps")
    }

    func testResolucao() {
        XCTAssertEqual(formatDimensions(width: 1080, height: 1920), "1080x1920")
    }

    func testDataDosDetalhes() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Cuiaba")!
        var parts = DateComponents()
        parts.year = 2026
        parts.month = 11
        parts.day = 5
        parts.hour = 11
        parts.minute = 22
        parts.timeZone = cal.timeZone
        let text = formatDetailDate(cal.date(from: parts)!, calendar: cal)
        XCTAssertTrue(text.contains("05") && text.lowercased().contains("nov") && text.contains("2026") && text.contains("11:22"), text)
    }
}
