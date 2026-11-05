import SwiftUI

/// Tela provisória da etapa 1 (a interface final, igual à do web app, é a etapa 3).
struct RootView: View {
    @EnvironmentObject var engine: CaptureEngine
    @State private var showDiagnostics = false
    @State private var opening = false

    private let yellow = Color(red: 1.0, green: 0.82, blue: 0.0)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if engine.isOpen {
                CameraPreview(session: engine.session).ignoresSafeArea()
            }
            VStack {
                topBar
                Spacer()
                if !engine.isOpen {
                    openButton
                    Spacer()
                }
                if !engine.message.isEmpty {
                    Text(engine.message)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 8)
                }
                bottomBar
            }
            .padding()
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView().environmentObject(engine)
        }
    }

    private var topBar: some View {
        HStack {
            Text("Ei Clip").font(.headline).foregroundColor(yellow)
            Spacer()
            if engine.isOpen {
                Text(engine.isRecording ? "● \(timeText(engine.recordSec))" : "buffer \(Int(engine.bufferSec))/\(engine.windowSec) s")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(engine.isRecording ? .red : .white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            Spacer()
            Button("Diagnóstico") { showDiagnostics = true }
                .font(.footnote)
                .foregroundColor(.white)
        }
    }

    private var openButton: some View {
        Button {
            opening = true
            Task {
                _ = await engine.openCamera()
                opening = false
            }
        } label: {
            Text(opening ? "Abrindo…" : "Abrir câmera")
                .font(.title3.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(yellow, in: Capsule())
        }
        .disabled(opening || engine.testRunning)
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            if engine.isOpen {
                Picker("Buffer", selection: $engine.windowSec) {
                    Text("15 s").tag(15)
                    Text("30 s").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                .disabled(engine.isRecording)

                VStack(spacing: 4) {
                    Toggle("Sons de gravação", isOn: $engine.beepEnabled)
                    Toggle("Sons no vídeo", isOn: $engine.beepInClip)
                        .disabled(!engine.beepEnabled)
                }
                .font(.footnote)
                .tint(yellow)
                .foregroundColor(.white)
                .frame(width: 220)
                .disabled(engine.isRecording)

                HStack(spacing: 40) {
                    Button("Fechar") { Task { await engine.closeCamera(reason: "botão Fechar") } }
                        .font(.footnote)
                        .foregroundColor(.white)
                        .frame(width: 70)
                    recordButton
                    Color.clear.frame(width: 70, height: 1)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var recordButton: some View {
        Button {
            if engine.isRecording {
                Task { await engine.stopRecording() }
            } else {
                engine.startRecording()
            }
        } label: {
            ZStack {
                Circle().stroke(Color.white, lineWidth: 4).frame(width: 76, height: 76)
                if engine.isRecording {
                    RoundedRectangle(cornerRadius: 6).fill(Color.red).frame(width: 30, height: 30)
                } else {
                    Circle().fill(Color.red).frame(width: 62, height: 62)
                }
            }
        }
    }

    private func timeText(_ s: Double) -> String {
        formatDuration(s)
    }
}
