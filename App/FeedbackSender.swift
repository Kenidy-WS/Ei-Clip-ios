import MessageUI
import UIKit

/// v0.9.40: envio do feedback. Caminho principal: e-mail pronto (Mail do iPhone) com o relato e o Diagnóstico anexado.
/// Reserva (iPhone sem Mail configurado): folha de compartilhar do iOS com o relato e o arquivo.
enum FeedbackSender {
    /// O iOS informa se há conta de e-mail no app Mail (decide pela capacidade do aparelho, não pelo modelo).
    static var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    private final class MailDelegate: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: (MFMailComposeResult) -> Void
        init(onFinish: @escaping (MFMailComposeResult) -> Void) { self.onFinish = onFinish }
        func mailComposeController(
            _ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?
        ) {
            controller.dismiss(animated: true)
            onFinish(result)
        }
    }

    /// O delegado precisa ficar vivo enquanto o e-mail está aberto (o controlador só guarda uma referência fraca).
    private static var activeDelegate: MailDelegate?

    /// Abre o e-mail pronto. `onFinish` recebe true só se a pessoa enviou (cancelar ou salvar rascunho não conta).
    static func presentMail(report: String, version: String, attachment: URL, onFinish: @escaping (Bool) -> Void) {
        guard let top = ClipShare.topController(), let data = try? Data(contentsOf: attachment) else {
            onFinish(false)
            return
        }
        let delegate = MailDelegate { result in
            activeDelegate = nil
            Diagnostics.shared.log("feedback", "e-mail fechado: \(describe(result))")
            onFinish(result == .sent)
        }
        activeDelegate = delegate
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = delegate
        controller.setToRecipients([Textos.feedbackEmail])
        controller.setSubject(Textos.feedbackAssunto(version))
        controller.setMessageBody(report, isHTML: false)
        controller.addAttachmentData(data, mimeType: "text/plain", fileName: attachment.lastPathComponent)
        top.present(controller, animated: true)
    }

    /// Reserva: folha de compartilhar com o relato e o arquivo. `onFinish` recebe true se a pessoa concluiu o envio.
    static func share(report: String, attachment: URL, onFinish: @escaping (Bool) -> Void) {
        guard let top = ClipShare.topController() else {
            onFinish(false)
            return
        }
        let controller = UIActivityViewController(activityItems: [report, attachment], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            Diagnostics.shared.log("feedback", "folha de compartilhar fechada: \(completed ? "concluída" : "cancelada")")
            onFinish(completed)
        }
        controller.popoverPresentationController?.sourceView = top.view
        top.present(controller, animated: true)
    }

    private static func describe(_ result: MFMailComposeResult) -> String {
        switch result {
        case .sent: return "enviado"
        case .cancelled: return "cancelado"
        case .saved: return "rascunho salvo"
        case .failed: return "falhou"
        @unknown default: return "desconhecido"
        }
    }
}
