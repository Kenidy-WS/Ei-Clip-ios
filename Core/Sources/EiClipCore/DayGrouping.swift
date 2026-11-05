import Foundation

/// Um trecho seguido da lista que cai no mesmo dia (v0.6.4: a Galeria por dia).
public struct DayGroup: Equatable {
    public let label: String
    public let range: Range<Int>
}

/// O título do dia na Galeria: como `dayLabel` ("Hoje", "Ontem", "Sexta-feira", "30 de out."), com a primeira letra maiúscula e,
/// para datas de outro ano, o ano ("30 de out. de 2025").
public func dayGroupLabel(
    _ date: Date, now: Date = Date(), calendar: Calendar = Calendar(identifier: .gregorian)
) -> String {
    var label = dayLabel(date, now: now, calendar: calendar)
    let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
    let year = calendar.component(.year, from: date)
    if days >= 7 && year != calendar.component(.year, from: now) { label += " de \(year)" }
    guard let first = label.first else { return label }
    return first.uppercased() + label.dropFirst()
}

/// Agrupa uma lista JÁ ordenada por data (do mais novo ao mais antigo) em dias seguidos. Datas fora de ordem abrem um grupo
/// novo (nunca se perde nem se repete um item). `nil` conta como "agora".
public func groupByDay(
    _ dates: [Date?], now: Date = Date(), calendar: Calendar = Calendar(identifier: .gregorian)
) -> [DayGroup] {
    var groups: [DayGroup] = []
    var start = 0
    var currentDay: Date?
    for (index, optional) in dates.enumerated() {
        let day = calendar.startOfDay(for: optional ?? now)
        if let currentDay, currentDay != day {
            groups.append(
                DayGroup(label: dayGroupLabel(dates[start] ?? now, now: now, calendar: calendar), range: start..<index))
            start = index
        }
        currentDay = day
    }
    if !dates.isEmpty {
        groups.append(
            DayGroup(label: dayGroupLabel(dates[start] ?? now, now: now, calendar: calendar), range: start..<dates.count))
    }
    return groups
}
