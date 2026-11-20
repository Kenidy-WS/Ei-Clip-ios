import Foundation

/// Identificador de cada gravação (C2, etapa 2). O UUID nasce quando a gravação começa e viaja no nome do arquivo:
/// clip-AAAAMMDD-HHMMSS-<UUID>.mp4. Assim, um arquivo recuperado depois de uma falha traz o MESMO identificador
/// e não é contado duas vezes.
public enum RecordingID {
    /// Nome do arquivo de uma gravação com identificador.
    public static func fileName(
        _ date: Date = Date(), id: UUID, calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> String {
        let base = clipFileName(date, calendar: calendar)
        return String(base.dropLast(4)) + "-" + id.uuidString + ".mp4"
    }

    /// O identificador gravado no nome, se houver (arquivos de versões antigas não têm).
    public static func id(fromFileName name: String) -> UUID? {
        guard name.lowercased().hasSuffix(".mp4") else { return nil }
        let base = String(name.dropLast(4))
        guard base.count >= 36 else { return nil }
        return UUID(uuidString: String(base.suffix(36)))
    }

    /// O identificador do nome ou, para arquivos antigos sem ele, um identificador sempre igual para o mesmo nome
    /// (assim uma recuperação repetida do mesmo arquivo não conta duas vezes).
    public static func idOrLegacy(fromFileName name: String) -> UUID {
        if let id = id(fromFileName: name) { return id }
        var h1: UInt64 = 0xcbf2_9ce4_8422_2325
        var h2: UInt64 = 0x8422_2325_cbf2_9ce4
        for b in name.utf8 {
            h1 = (h1 ^ UInt64(b)) &* 0x0000_0100_0000_01b3
            h2 = (h2 &+ UInt64(b)) &* 0x9e37_79b9_7f4a_7c15
        }
        let a = withUnsafeBytes(of: h1.bigEndian) { Array($0) }
        let b = withUnsafeBytes(of: h2.bigEndian) { Array($0) }
        let x = a + b
        return UUID(uuid: (x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7], x[8], x[9], x[10], x[11], x[12], x[13], x[14], x[15]))
    }
}
