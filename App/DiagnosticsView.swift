import SwiftUI

/// Diagnóstico: o texto daqui (botão "Compartilhar", arquivo .txt) é o único log do aparelho. Envie no chat quando algo falhar.
struct DiagnosticsView: View {
    @EnvironmentObject var engine: CaptureEngine
    @ObservedObject private var diag = Diagnostics.shared
    @Environment(\.dismiss) private var dismiss
    @State private var shareFailed = false

    /// v0.8.4: tela enxuta. Saíram o teste de 20 aberturas (da etapa 1) e os controles de voz (a voz tem página própria em
    /// Ajustes > Voz e sons). v0.9.11: o "Copiar" virou "Compartilhar" (arquivo .txt pela folha do iOS: o texto colado
    /// travava o aparelho com registros grandes). Ficam: compartilhar, compartilhar a rodada anterior, limpar e o painel.
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Textos.tituloDiagnostico(Diagnostics.appVersion)).font(.headline)
                Spacer()
                Button(Textos.fechar) { dismiss() }
            }

            VStack(spacing: 8) {
                Button {
                    // v0.3.10: o texto leva o painel (seções) e o registro.
                    share(diag.fullText(panel: DiagPanel.text(DiagPanel.sections(engine.diagnosticsSnapshot()))), kind: "atual")
                } label: {
                    Text(Textos.compartilhar).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                // v0.1.5: o Diagnóstico é salvo em arquivo; a rodada que terminou fica aqui, mesmo depois de fechar o app.
                HStack(spacing: 8) {
                    Button {
                        share(diag.previousText, kind: "anterior")
                    } label: {
                        Text(Textos.compartilharRodadaAnterior).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(diag.previousText.isEmpty)

                    Button(role: .destructive) { diag.clear() } label: {
                        Text(Textos.limpar).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Text(diag.previousText.isEmpty ? Textos.semRodadaAnterior : Textos.linhasDaRodadaAnterior(diag.previousText.split(separator: "\n").count))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if shareFailed {
                    Text(Textos.diagnosticoNaoCompartilhado)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // v0.3.10: painel com as seções do Diagnóstico, atualizado a cada 1 s enquanto a tela está aberta.
                    TimelineView(.periodic(from: .now, by: 1)) { _ in
                        let sections = DiagPanel.sections(engine.diagnosticsSnapshot())
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(sections) { section in
                                DiagSectionView(section: section)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Textos.registro).font(.system(size: 13, weight: .semibold))
                        Text(diag.lines.joined(separator: "\n"))
                            .font(.system(size: 11, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(Color(white: 0.1))
            .cornerRadius(8)
        }
        .padding()
        .edgeGestures(back: { dismiss() })
    }

    /// v0.9.11: grava o texto num .txt temporário e abre a folha de compartilhar do iOS (a mesma dos clipes).
    private func share(_ text: String, kind: String) {
        guard let url = Diagnostics.exportFile(text, kind: kind) else {
            shareFailed = true
            return
        }
        shareFailed = false
        ClipShare.present([url]) { Diagnostics.cleanUpExport() }
    }
}

/// Uma seção do painel: título, linhas "rótulo e valor" e linhas soltas. A de "Atenção" fica em vermelho.
private struct DiagSectionView: View {
    let section: DiagSection
    private let alertRed = Color(red: 1.0, green: 0.27, blue: 0.23)

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(section.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(section.alert ? alertRed : .primary)
            ForEach(section.rows) { row in
                HStack(alignment: .top, spacing: 8) {
                    Text(row.label)
                        .foregroundColor(.secondary)
                        .frame(width: 130, alignment: .leading)
                    Text(row.value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 12))
            }
            ForEach(Array(section.lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(section.alert ? alertRed : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(section.alert ? alertRed.opacity(0.15) : Color(white: 0.14), in: RoundedRectangle(cornerRadius: 10))
    }
}
