import XCTest
@testable import EiClipCore

final class DayGroupingTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, _ hour: Int) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func testListaVazia() {
        XCTAssertEqual(groupByDay([], now: date(5, 12), calendar: cal), [])
    }

    func testAgrupaPorDiaMantendoOrdem() {
        let dates: [Date?] = [date(5, 15), date(5, 9), date(4, 20), date(1, 10), date(1, 8)]
        let groups = groupByDay(dates, now: date(5, 16), calendar: cal)
        XCTAssertEqual(groups.map(\.range), [0..<2, 2..<3, 3..<5])
        XCTAssertEqual(groups[0].label, "Hoje")
        XCTAssertEqual(groups[1].label, "Ontem")
    }

    func testTodosNoMesmoDia() {
        let groups = groupByDay([date(5, 15), date(5, 14), date(5, 1)], now: date(5, 16), calendar: cal)
        XCTAssertEqual(groups.map(\.range), [0..<3])
    }

    func testSemDataContaComoAgora() {
        let groups = groupByDay([nil, date(5, 3)], now: date(5, 16), calendar: cal)
        XCTAssertEqual(groups.map(\.range), [0..<2])
        XCTAssertEqual(groups[0].label, "Hoje")
    }

    func testDataForaDeOrdemAbreGrupoNovo() {
        let groups = groupByDay([date(5, 10), date(4, 10), date(5, 8)], now: date(5, 16), calendar: cal)
        XCTAssertEqual(groups.map(\.range), [0..<1, 1..<2, 2..<3])
    }
}
