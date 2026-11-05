import SwiftUI

/// Diagnóstico: o texto daqui (botão "Copiar") é o único log do aparelho. Cole no chat quando algo falhar.
struct DiagnosticsView: View {
    @EnvironmentObject var engine: CaptureEngine
    @ObservedObject private var diag = Diagnostics.shared
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var copiedPrevious = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(Textos.tituloDiagnostico(Diagnostics.appVersion)).font(.headline)
                Spacer()
                Button(Textos.fechar) { dismiss() }
            }

            HStack(spacing: 10) {
                Button(copied ? Textos.copiado : Textos.copiar) {
                    // v0.3.10: o texto copiado leva o painel (seções) e o registro.
                    UIPasteboard.general.string = diag.fullText(panel: DiagPanel.text(DiagPanel.sections(engine.diagnosticsSnapshot())))
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                }
                .buttonStyle(.borderedProminent)

                Button(Textos.limpar) { diag.clear() }
                    .buttonStyle(.bordered)

                Spacer()

                Button(engine.testRunning ? Textos.testando : Textos.testar20Aberturas) {
                    Task { await engine.runOpenTest(times: 20) }
                }
                .buttonStyle(.bordered)
                .disabled(engine.testRunning || engine.isRecording)
            }

            // v0.2.2: voz. "Só medir" não grava; "Comando" faz "Ei Clip" ligar e parar a gravação. Precisa da câmera aberta.
            VStack(alignment: .leading, spacing: 4) {
                Text(Textos.vozTeste).font(.footnote)
                Picker(
                    Textos.vozTeste,
                    selection: Binding(get: { engine.voiceMode }, set: { engine.setVoiceMode($0) })
                ) {
                    Text(Textos.vozDesligada).tag(VoiceMode.off)
                    Text(Textos.vozSoMedir).tag(VoiceMode.measure)
                    Text(Textos.vozComando).tag(VoiceMode.command)
                }
                .pickerStyle(.segmented)
                .disabled(!engine.isOpen || engine.testRunning)
                // v0.2.5: qual palavra age no modo Comando (as outras continuam só no log).
                Text(Textos.palavraDeAtivacao).font(.footnote)
                Picker(Textos.palavra, selection: $engine.voiceWord) {
                    ForEach(WakeWord.allCases, id: \.self) { word in
                        Text(word.label).tag(word)
                    }
                }
                .pickerStyle(.segmented)
                if !engine.isOpen {
                    Text(Textos.abraACameraParaVoz).font(.caption2).foregroundColor(.secondary)
                }
            }

            // v0.1.5: o Diagnóstico agora é salvo em arquivo; a rodada que terminou fica aqui, mesmo depois de fechar o app.
            HStack(spacing: 10) {
                Button(copiedPrevious ? Textos.copiado : Textos.copiarRodadaAnterior) {
                    UIPasteboard.general.string = diag.previousText
                    copiedPrevious = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedPrevious = false }
                }
                .buttonStyle(.bordered)
                .disabled(diag.previousText.isEmpty)

                Text(diag.previousText.isEmpty ? Textos.semRodadaAnterior : Textos.linhas(diag.previousText.split(separator: "\n").count))
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Spacer()
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
