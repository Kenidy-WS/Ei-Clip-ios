import XCTest
@testable import EiClipCore

// Gabarito: tests/day-label.test.ts e o ciclo de velocidades de ui/clips-view.ts.
final class PlayerLogicTests: XCTestCase {
    private var cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Cuiaba")!
        return c
    }()

    private func date(_ month: Int, _ day: Int, _ hour: Int = 10) -> Date {
        var parts = DateComponents()
        parts.year = 2026
        parts.month = month
        parts.day = day
        parts.hour = hour
        parts.timeZone = cal.timeZone
        return cal.date(from: parts)!
    }

    /// Domingo, 1 de novembro de 2026, 20h (o mesmo "agora" do teste do web app).
    private var now: Date { date(11, 1, 20) }

    func testHojeEOntem() {
        XCTAssertEqual(dayLabel(date(11, 1, 8), now: now, calendar: cal), "Hoje")
        XCTAssertEqual(dayLabel(date(10, 31, 23), now: now, calendar: cal), "Ontem")
    }

    func testNaUltimaSemanaMostraODiaDaSemana() {
        XCTAssertTrue(dayLabel(date(10, 30), now: now, calendar: cal).lowercased().contains("sexta"))
        XCTAssertTrue(dayLabel(date(10, 26), now: now, calendar: cal).lowercased().contains("segunda"))
    }

    func testCom7DiasOuMaisMostraAData() {
        let a = dayLabel(date(10, 25), now: now, calendar: cal)
        XCTAssertTrue(a.contains("25") && a.lowercased().contains("out"), a)
        let b = dayLabel(date(9, 1), now: now, calendar: cal)
        XCTAssertTrue(b.contains("01") && b.lowercased().contains("set"), b)
    }

    func testCicloDeVelocidades() {
        XCTAssertEqual(PlaybackRate.next(after: 1), 1.5)
        XCTAssertEqual(PlaybackRate.next(after: 1.5), 2)
        XCTAssertEqual(PlaybackRate.next(after: 2), 0.5)
        XCTAssertEqual(PlaybackRate.next(after: 0.5), 1)
        XCTAssertEqual(PlaybackRate.next(after: 3), 1)  // fora da lista volta a 1×
    }

    func testRotuloDaVelocidade() {
        XCTAssertEqual(PlaybackRate.label(1), "1×")
        XCTAssertEqual(PlaybackRate.label(1.5), "1,5×")
        XCTAssertEqual(PlaybackRate.label(2), "2×")
        XCTAssertEqual(PlaybackRate.label(0.5), "0,5×")
    }
}
