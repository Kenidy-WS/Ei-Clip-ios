import Foundation

/// Nome do arquivo do clipe: clip-AAAAMMDD-HHMMSS.mp4 (horário local). Porta de `core/clip-name.ts`.
public func clipFileName(_ date: Date = Date(), calendar: Calendar = Calendar(identifier: .gregorian)) -> String {
    let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    return String(
        format: "clip-%04d%02d%02d-%02d%02d%02d.mp4",
        c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
}

/// Duração como m:ss (nunca negativa). Porta de `core/format.ts`.
public func formatDuration(_ seconds: Double) -> String {
    let total = Int(max(0, seconds).rounded(.down))
    return String(format: "%d:%02d", total / 60, total % 60)
}
