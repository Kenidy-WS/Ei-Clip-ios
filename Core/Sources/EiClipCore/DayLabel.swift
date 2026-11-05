import Foundation

/// Como na Fotos: "Hoje", "Ontem", na última semana o dia da semana ("sexta-feira"); antes disso a data ("30 de out.").
/// Porta de `core/day-label.ts`.
public func dayLabel(
    _ date: Date, now: Date = Date(), calendar: Calendar = Calendar(identifier: .gregorian)
) -> String {
    let start = calendar.startOfDay(for: date)
    let today = calendar.startOfDay(for: now)
    let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
    if days == 0 { return "Hoje" }
    if days == 1 { return "Ontem" }
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.dateFormat = (days > 1 && days < 7) ? "EEEE" : "dd 'de' MMM"
    return f.string(from: date)
}
