import SwiftUI

/// Raiz do app. Câmera fechada: tela de Início. Câmera aberta: tela da Câmera (v0.3.4). Ajustes: por ora o Diagnóstico (v0.3.5).
struct RootView: View {
    @EnvironmentObject var engine: CaptureEngine
    @State private var showDiagnostics = false
    @State private var opening = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if engine.isOpen {
                CameraScreen(onSettings: { showDiagnostics = true })
            } else {
                HomeView(
                    opening: opening,
                    message: engine.message,
                    onOpen: openCamera,
                    onSettings: { showDiagnostics = true })
            }
        }
        .sheet(isPresented: $showDiagnostics) {
            DiagnosticsView().environmentObject(engine)
        }
    }

    private func openCamera() {
        guard !opening, !engine.testRunning else { return }
        opening = true
        Task {
            _ = await engine.openCamera()
            opening = false
        }
    }
}
