import Foundation

/// Um trecho seguido da lista que cai no mesmo dia (v0.6.1: a Galeria por dia).
public struct DayGroup: Equatable {
    public let label: String
    public let range: Range<Int>
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
            groups.append(DayGroup(label: dayLabel(dates[start] ?? now, now: now, calendar: calendar), range: start..<index))
            start = index
        }
        currentDay = day
    }
    if !dates.isEmpty {
        groups.append(DayGroup(label: dayLabel(dates[start] ?? now, now: now, calendar: calendar), range: start..<dates.count))
    }
    return groups
}
