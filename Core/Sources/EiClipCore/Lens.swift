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

    /// Texto do botão quando a lente NÃO está em uso (como no app Câmera: "0,5", "1", "2"; a lente em uso mostra o `label`).
    public var shortLabel: String {
        switch self {
        case .ultraWide: return "0,5"
        case .wide: return "1"
        case .twoX: return "2"
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
    /// v0.7.9: com a câmera combinada em uso (`combined`), as três lentes são pontos de zoom do mesmo aparelho e nada reabre.
    public static func needsReopen(from: Lens, to: Lens, combined: Bool = false) -> Bool {
        if combined { return false }
        return from.usesUltraWideDevice != to.usesUltraWideDevice
    }

    /// Gravando, no aparelho simples só dá para trocar entre 1× e 2× (muda a aproximação, não o aparelho).
    /// v0.7.12: com a câmera combinada em uso (`combined`) nenhuma troca reabre a câmera, então todas valem gravando também.
    public static func canSwitch(from: Lens, to: Lens, recording: Bool, combined: Bool = false) -> Bool {
        if from == to { return false }
        return !recording || !needsReopen(from: from, to: to, combined: combined)
    }

    /// A lente que vale: se não estiver entre as oferecidas, volta para a principal.
    public static func resolved(_ lens: Lens, position: CameraPosition, hasUltraWide: Bool) -> Lens {
        available(position: position, hasUltraWide: hasUltraWide).contains(lens) ? lens : .wide
    }
}

/// Fatores de aproximação das lentes (v0.7.9). No aparelho simples valem os de `Lens.zoomFactor`. Na câmera combinada
/// (ultra-angular + principal, às vezes + tele) a ultra-angular é o zoom 1,0 e a principal começa no primeiro ponto de
/// troca que o aparelho informa (`virtualDeviceSwitchOverVideoZoomFactors`, em geral 2,0); o 2× é o dobro da principal.
public enum LensZoom {
    /// Fator da lente principal na câmera combinada: o primeiro ponto de troca, se for maior que 1. Nulo se o aparelho não informar.
    public static func mainFactor(switchOvers: [Double]) -> Double? {
        guard let first = switchOvers.first, first > 1.0 else { return nil }
        return first
    }

    /// Aproximação da lente. `mainFactor` nulo = aparelho simples.
    public static func factor(for lens: Lens, mainFactor: Double?) -> Double {
        guard let main = mainFactor else { return lens.zoomFactor }
        switch lens {
        case .ultraWide: return 1.0
        case .wide: return main
        case .twoX: return main * 2
        }
    }

    /// O formato aceita chegar ao 2× (o dobro da principal)?
    public static func fits(main: Double, maxZoom: Double) -> Bool {
        maxZoom >= main * 2 - 0.01
    }
}
