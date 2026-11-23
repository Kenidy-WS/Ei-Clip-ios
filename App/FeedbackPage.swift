import SwiftUI
import UIKit

/// Página "Enviar feedback" dos Ajustes (v0.9.40): a pessoa escreve o relato e o app anexa o Diagnóstico sozinho.
/// Com Mail configurado, abre o e-mail pronto; sem Mail, mostra um aviso e usa a folha de compartilhar (reserva).
/// O texto do relato nunca vai para o Diagnóstico.
struct FeedbackPage: View {
    @EnvironmentObject var engine: CaptureEngine
    @State private var text = ""
    @State private var step: Step = .writing
    @State private var failed = false
    @State private var copied = false
    @State private var prepared: (report: String, file: URL)?

    private enum Step { case writing, noMail, thanks }

    var body: some View {
        VStack(spacing: 0) {
            switch step {
            case .writing: writing
            case .noMail: noMail
            case .thanks: thanks
            }
        }
    }

    // MARK: - Escrever

    private var writing: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Textos.feedbackTitulo)
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 20)
                .accessibilityAddTraits(.isHeader)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(minHeight: 150)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .onChange(of: text) { value in
                        let limited = FeedbackRules.limited(value)
                        if limited != value { text = limited }
                    }
                if text.isEmpty {
                    Text(Textos.feedbackMarcador)
                        .font(.system(size: 16))
                        .foregroundColor(SheetStyle.muted)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 14)
                        .allowsHitTesting(false)
                }
            }
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            Text(Textos.feedbackAviso)
                .font(.system(size: 12.5))
                .foregroundColor(SheetStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 2)
            if failed {
                Text(Textos.feedbackNaoPreparado)
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 1.0, green: 0.27, blue: 0.23))
            }
            let enabled = FeedbackRules.canSend(text)
            Button(action: send) {
                Text(Textos.enviarFeedback)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundColor(enabled ? .black : Color(white: 0.6))
                    .background(enabled ? SheetStyle.yellow : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .disabled(!enabled)
            .padding(.top, 20)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Sem e-mail configurado (reserva)

    private var noMail: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text(Textos.feedbackSemEmailTitulo)
                    .font(.system(size: 18, weight: .semibold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(Textos.feedbackSemEmailTexto)
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            Button(action: continueToShare) {
                Text(Textos.feedbackContinuar)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundColor(.black)
                    .background(SheetStyle.yellow, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            Button(action: copyEmail) {
                Text(copied ? Textos.feedbackEmailCopiado : Textos.feedbackCopiarEmail)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 6)
    }

    // MARK: - Obrigado

    private var thanks: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(SheetStyle.yellow)
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            Text(Textos.feedbackObrigado)
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
            Text(Textos.feedbackObrigadoTexto)
                .font(.system(size: 15))
                .foregroundColor(SheetStyle.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 48)
    }

    // MARK: - Ações

    private func send() {
        guard FeedbackRules.canSend(text) else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let report = FeedbackRules.clean(text)
        // O Diagnóstico completo (painel + registro), o mesmo do botão "Compartilhar" do Diagnóstico.
        let panel = DiagPanel.text(DiagPanel.sections(engine.diagnosticsSnapshot()))
        let full = Diagnostics.shared.fullText(panel: panel)
        guard let file = Diagnostics.exportFile(full, kind: "feedback") else {
            failed = true
            Diagnostics.shared.log("feedback", "não foi possível gravar o arquivo do Diagnóstico")
            return
        }
        failed = false
        if FeedbackSender.canSendMail {
            // O texto do relato não vai para o Diagnóstico; só o tamanho.
            Diagnostics.shared.log("feedback", "abrindo o e-mail (relato de \(report.count) caracteres, Diagnóstico anexado)")
            FeedbackSender.presentMail(report: report, version: Diagnostics.appVersion, attachment: file) { sent in
                Diagnostics.cleanUpExport()
                if sent { finish() }
            }
        } else {
            Diagnostics.shared.log("feedback", "sem Mail configurado: aviso e folha de compartilhar (reserva)")
            prepared = (report, file)
            step = .noMail
        }
    }

    private func continueToShare() {
        guard let prepared else { return }
        FeedbackSender.share(report: prepared.report, attachment: prepared.file) { completed in
            Diagnostics.cleanUpExport()
            if completed { finish() }
        }
    }

    private func copyEmail() {
        UIPasteboard.general.string = Textos.feedbackEmail
        copied = true
    }

    private func finish() {
        text = ""
        prepared = nil
        step = .thanks
        Diagnostics.shared.log("feedback", "envio concluído")
    }
}
