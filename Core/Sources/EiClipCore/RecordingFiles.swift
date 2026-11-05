import Foundation

/// Arquivos de gravação em andamento (v0.6.12): ficam numa pasta própria do app (não na pasta temporária, que o iOS pode
/// esvaziar), em partes de poucos segundos, para que um clipe longo sobreviva se o app fechar no meio.
public enum RecordingFiles {
    /// Pasta (dentro de Application Support) onde ficam as gravações em andamento.
    public static let folderName = "Gravando"
    /// A cada quantos segundos o arquivo ganha uma parte completa (o que passou daí já é legível se o app fechar).
    public static let fragmentSeconds = 5.0
    /// Menor arquivo que vale tentar recuperar (abaixo disto não há nem o cabeçalho de um vídeo).
    public static let minRecoverableBytes = 20_000

    /// É um arquivo de clipe (e não lixo do sistema)?
    public static func isClipFile(_ name: String) -> Bool {
        !name.hasPrefix(".") && name.lowercased().hasSuffix(".mp4")
    }

    /// Vale tentar recuperar este arquivo deixado na pasta?
    public static func isWorthRecovering(name: String, bytes: Int) -> Bool {
        isClipFile(name) && bytes >= minRecoverableBytes
    }
}
