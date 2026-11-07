import Foundation

/// Por que a lanterna apagou sozinha (v0.7.13).
public enum TorchOffReason: Equatable {
    case batteryCritical
    case tooHot
}

/// Regras da lanterna (flash), puras e testáveis.
public enum TorchRules {
    /// A lanterna só existe na câmera traseira e se o aparelho informa que tem (`hasTorch`).
    public static func isAvailable(position: CameraPosition, hasTorch: Bool) -> Bool {
        position == .back && hasTorch
    }

    /// Bateria muito baixa ou aparelho muito quente: a lanterna gasta e esquenta, então apaga sozinha.
    public static func autoOffReason(batteryCritical: Bool, tooHot: Bool) -> TorchOffReason? {
        if tooHot { return .tooHot }
        if batteryCritical { return .batteryCritical }
        return nil
    }
}
