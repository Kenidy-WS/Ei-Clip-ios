import Foundation

/// Lente da câmera traseira (v0.6.10): ultra-angular (0,5×), principal (1×) e 2× (a lente principal com aproximação).
public enum Lens: String, CaseIterable, Equatable {
    case ultraWide
    case wide
    case twoX

    /// Texto do botão.
    public var label: String {
        switch self {
        case .ultraWide: return "0,5×"
        case .wide: return "1×"
        case .twoX: return "2×"
        }
    }

    /// Aproximação aplicada sobre o aparelho da lente.
    public var zoomFactor: Double { self == .twoX ? 2.0 : 1.0 }

    /// Qual aparelho (lente física) a lente usa: o 1× e o 2× usam a principal.
    public var usesUltraWideDevice: Bool { self == .ultraWide }
}

public enum LensRules {
    /// Lentes oferecidas: a frontal só tem a principal; a traseira soma a ultra-angular se o aparelho tiver.
    public static func available(position: CameraPosition, hasUltraWide: Bool) -> [Lens] {
        guard position == .back else { return [.wide] }
        return hasUltraWide ? [.ultraWide, .wide, .twoX] : [.wide, .twoX]
    }

    /// Trocar de lente exige reabrir a câmera quando muda o aparelho (ultra-angular ↔ principal).
    public static func needsReopen(from: Lens, to: Lens) -> Bool {
        from.usesUltraWideDevice != to.usesUltraWideDevice
    }

    /// Gravando, só dá para trocar entre 1× e 2× (muda a aproximação, não o aparelho).
    public static func canSwitch(from: Lens, to: Lens, recording: Bool) -> Bool {
        if from == to { return false }
        return !recording || !needsReopen(from: from, to: to)
    }

    /// A lente que vale: se não estiver entre as oferecidas, volta para a principal.
    public static func resolved(_ lens: Lens, position: CameraPosition, hasUltraWide: Bool) -> Lens {
        available(position: position, hasUltraWide: hasUltraWide).contains(lens) ? lens : .wide
    }
}
