import Foundation

/// v0.9.11: etiqueta gravada nos metadados do arquivo do clipe, para os detalhes da galeria mostrarem a lente usada.
/// Formato: "EiClip;lente=0,5×". Fica no próprio arquivo (vai junto para o Fotos; não depende de nada guardado no app).
/// Clipes antigos, ou arquivos em que o iOS não guardou a etiqueta, simplesmente não têm a linha "Lente".
public enum ClipTag {
    static let prefix = "EiClip;"

    /// Texto da lente no começo da gravação: "Frontal" ou o rótulo da lente traseira ("0,5×", "1×", "2×").
    public static func lensText(position: CameraPosition, lens: Lens) -> String {
        position == .front ? "Frontal" : lens.label
    }

    public static func encode(lens: String) -> String {
        "\(prefix)lente=\(lens)"
    }

    /// A lente guardada numa etiqueta; nulo se o texto não é uma etiqueta do Ei Clip ou não traz a lente.
    public static func lens(from text: String) -> String? {
        guard text.hasPrefix(prefix) else { return nil }
        for part in text.dropFirst(prefix.count).split(separator: ";") {
            let pair = part.split(separator: "=", maxSplits: 1)
            if pair.count == 2, pair[0] == "lente", !pair[1].isEmpty { return String(pair[1]) }
        }
        return nil
    }
}
