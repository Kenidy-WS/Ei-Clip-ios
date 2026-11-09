import AVKit
import SwiftUI

/// Botões de volume como obturador (v0.9.5): na tela da câmera, apertar + ou − liga e para a gravação.
/// Usa `AVCaptureEventInteraction` (iOS 17.2 ou mais novo; sem permissão especial nem extensão). Enquanto a interação está
/// ligada, o iOS não muda o volume nem mostra a barra de volume. Age quando o botão é SOLTO (fase `.ended`).
/// Fica sempre na tela da câmera (também com a tela escura). Em iOS mais antigo não faz nada e o motivo vai para o
/// Diagnóstico; o botão da tela segue como reserva.
struct VolumeShutterView: UIViewRepresentable {
    let enabled: Bool
    let onPress: () -> Void
    /// Registra no Diagnóstico o estado (ativo, desligado em Ajustes ou indisponível), uma vez por abertura da tela.
    let onReady: (_ supported: Bool) -> Void

    final class Coordinator {
        var interaction: AnyObject?
        var onPress: () -> Void = {}
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        context.coordinator.onPress = onPress
        var supported = false
        if #available(iOS 17.2, *) {
            let coordinator = context.coordinator
            let interaction = AVCaptureEventInteraction { event in
                if event.phase == .ended { coordinator.onPress() }
            }
            interaction.isEnabled = enabled
            view.addInteraction(interaction)
            coordinator.interaction = interaction
            supported = true
        }
        let ready = onReady
        DispatchQueue.main.async { ready(supported) }  // fora da montagem da tela
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onPress = onPress
        if #available(iOS 17.2, *), let interaction = context.coordinator.interaction as? AVCaptureEventInteraction {
            interaction.isEnabled = enabled
        }
    }
}
