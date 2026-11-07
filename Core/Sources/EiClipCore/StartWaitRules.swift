import Foundation

/// Início da gravação sem keyframe no buffer (v0.7.23).
///
/// Logo depois de abrir a câmera ou de parar um clipe, o buffer ainda não tem um keyframe (o vídeo só pode ser cortado
/// em um). Em vez de recusar o pedido ("Aguarde 1 segundo"), o app aceita e tenta de novo a cada 0,1 s; a gravação
/// começa no primeiro keyframe, que chega em até ~1 s (`MaxKeyFrameIntervalDuration` = 1 s). Passando de 2,5 s sem
/// keyframe, desiste e avisa como antes.
public enum StartWaitRules {
    public static let retryInterval = 0.1
    public static let maxWaitSeconds = 2.5

    /// Continua esperando enquanto o tempo já esperado não passou do limite.
    public static func shouldKeepWaiting(waited: Double) -> Bool {
        waited < maxWaitSeconds
    }

    /// Só vale registrar "começou depois do pedido" quando houve espera de verdade.
    public static func wasDelayed(waited: Double) -> Bool {
        waited >= 0.05
    }
}
