import Foundation

/// Pasta das gravações em andamento (v0.6.12): dentro de Application Support, fora do backup do iCloud e da pasta temporária.
enum RecordingFolder {
    static func url() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        var folder = base.appendingPathComponent(RecordingFiles.folderName, isDirectory: true)
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? folder.setResourceValues(values)
        }
        return folder
    }
}
