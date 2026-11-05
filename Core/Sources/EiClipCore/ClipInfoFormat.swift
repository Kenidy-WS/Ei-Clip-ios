import Foundation

// Formatação dos detalhes do clipe (v0.4.4). Gabarito: `fillInfo` em `ui/clips-view.ts` do web app.

/// "12,3 MB" (megabytes de 1.048.576 bytes, vírgula decimal).
public func formatMegabytes(_ bytes: Int64) -> String {
    let value = String(format: "%.1f", Double(max(0, bytes)) / 1_048_576)
    return value.replacingOccurrences(of: ".", with: ",") + " MB"
}

/// "16,0 Mbps" a partir de bits por segundo.
public func formatMbps(_ bitsPerSecond: Double) -> String {
    let value = String(format: "%.1f", max(0, bitsPerSecond) / 1_000_000)
    return value.replacingOccurrences(of: ".", with: ",") + " Mbps"
}

/// "30 fps" (arredondado: 29,97 vira 30).
public func formatFps(_ fps: Double) -> String {
    "\(Int(max(0, fps).rounded())) fps"
}

/// "1080x1920", como o web app.
public func formatDimensions(width: Int, height: Int) -> String {
    "\(width)x\(height)"
}

/// "05 de nov. de 2026 11:22" (pt-BR, hora de 24 h).
public func formatDetailDate(_ date: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "pt_BR")
    f.calendar = calendar
    f.timeZone = calendar.timeZone
    f.dateFormat = "dd 'de' MMM 'de' yyyy HH:mm"
    return f.string(from: date)
}
