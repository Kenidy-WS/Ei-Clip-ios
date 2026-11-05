import SwiftUI

/// Diagnóstico: o texto daqui (botão "Copiar") é o único log do aparelho. Cole no chat quando algo falhar.
struct DiagnosticsView: View {
    @EnvironmentObject var engine: CaptureEngine
    @ObservedObject private var diag = Diagnostics.shared
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Diagnóstico · \(Diagnostics.appVersion)").font(.headline)
                Spacer()
                Button("Fechar") { dismiss() }
            }

            HStack(spacing: 10) {
                Button(copied ? "Copiado ✓" : "Copiar") {
                    UIPasteboard.general.string = diag.text
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                }
                .buttonStyle(.borderedProminent)

                Button("Limpar") { diag.clear() }
                    .buttonStyle(.bordered)

                Spacer()

                Button(engine.testRunning ? "Testando…" : "Teste 20 aberturas") {
                    Task { await engine.runOpenTest(times: 20) }
                }
                .buttonStyle(.bordered)
                .disabled(engine.testRunning || engine.isRecording)
            }

            ScrollView {
                Text(diag.text)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(8)
            .background(Color(white: 0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}
