import XCTest
@testable import EiClipCore

final class DayGroupingTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, _ hour: Int, month: Int = 11, year: Int = 2026) -> Date {
        cal.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
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

    func testNenhumItemSePerdeNemSeRepete() {
        let dates: [Date?] = [date(5, 15), date(4, 20), date(4, 8), date(2, 9), date(30, 9, month: 10), nil]
        let groups = groupByDay(dates, now: date(5, 16), calendar: cal)
        var covered: [Int] = []
        for g in groups { covered += Array(g.range) }
        XCTAssertEqual(covered, Array(0..<dates.count))
    }

    // MARK: Título do dia

    func testPrimeiraLetraMaiuscula() {
        // 2 dias antes de uma quinta-feira (5/11/2026): terça-feira.
        XCTAssertEqual(dayGroupLabel(date(3, 10), now: date(5, 16), calendar: cal), "Terça-feira")
    }

    func testDataDoMesmoAnoNaoLevaAno() {
        XCTAssertEqual(dayGroupLabel(date(20, 10, month: 10), now: date(5, 16), calendar: cal), "20 de out.")
    }

    func testDataDeOutroAnoLevaAno() {
        XCTAssertEqual(
            dayGroupLabel(date(30, 10, month: 10, year: 2025), now: date(5, 16), calendar: cal), "30 de out. de 2025")
    }

    func testOntemDeOutroAnoNaoLevaAno() {
        // 1/1/2027 de manhã: "ontem" é 31/12/2026 e continua só "Ontem".
        let now = date(1, 9, month: 1, year: 2027)
        XCTAssertEqual(dayGroupLabel(date(31, 20, month: 12, year: 2026), now: now, calendar: cal), "Ontem")
    }
}
