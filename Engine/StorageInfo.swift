import Foundation

/// v0.6.0: leitura do espaço livre do aparelho. Só leitura; nada aqui pede permissão.
enum StorageInfo {
    /// Bytes livres para gravar. Conta o que o iOS pode liberar sozinho (caches), que é o espaço que uma gravação de fato
    /// consegue usar. Nulo se o sistema não respondeu.
    static func freeBytes() -> Int64? {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
            let important = values.volumeAvailableCapacityForImportantUsage
        {
            return important
        }
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
            let free = attributes[.systemFreeSize] as? NSNumber
        {
            return free.int64Value
        }
        return nil
    }
}
