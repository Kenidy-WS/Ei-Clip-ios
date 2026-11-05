import Foundation

/// Um formato de vídeo que a câmera oferece (v0.6.11): tamanho e taxas de quadros suportadas.
public struct FormatInfo: Equatable {
    public let width: Int
    public let height: Int
    public let minFps: Double
    public let maxFps: Double

    public init(width: Int, height: Int, minFps: Double, maxFps: Double) {
        self.width = width
        self.height = height
        self.minFps = minFps
        self.maxFps = maxFps
    }

    func supports(fps: Int) -> Bool {
        Double(fps) >= minFps - 0.01 && Double(fps) <= maxFps + 0.01
    }
}

/// Escolhe o formato da câmera para a resolução e os quadros por segundo pedidos. Pedir uma taxa que o formato não aceita
/// derruba o app (exceção do AVFoundation), então a conferência vem antes.
public enum FormatPicker {
    /// Índice do melhor formato: o tamanho exato e a taxa pedida; entre os que servem, o de MENOR taxa máxima (evita os
    /// formatos de câmera lenta de 120/240 fps). Nulo se nenhum serve.
    public static func pick(_ formats: [FormatInfo], width: Int, height: Int, fps: Int) -> Int? {
        let fits = formats.enumerated().filter {
            $0.element.width == width && $0.element.height == height && $0.element.supports(fps: fps)
        }
        return fits.min { $0.element.maxFps < $1.element.maxFps }?.offset
    }

    /// Os quadros por segundo que valem de fato: o pedido, se algum formato do tamanho o aceita; senão 30.
    public static func effectiveFps(_ formats: [FormatInfo], width: Int, height: Int, requested: Int) -> Int {
        pick(formats, width: width, height: height, fps: requested) != nil ? requested : 30
    }
}
