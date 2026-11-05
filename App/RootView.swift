import SwiftUI

/// Raiz do app. Câmera fechada: tela de Início. Câmera aberta: tela da Câmera (v0.3.4). Ajustes: folha `SettingsSheet` (v0.3.6; o Diagnóstico fica dentro dela).
struct RootView: View {
    @EnvironmentObject var engine: CaptureEngine
    @State private var showSettings = false
    @State private var opening = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if engine.isOpen {
                CameraScreen(onSettings: { showSettings = true })
            } else {
                HomeView(
                    opening: opening,
                    message: engine.message,
                    onOpen: openCamera,
                    onSettings: { showSettings = true })
            }
        }
        // v0.3.5: arrastar da borda esquerda volta (Câmera → Início). Gravando, o gesto é ignorado: um arrasto sem querer
        // com a mão molhada não pode encerrar o clipe (o botão de voltar continua valendo).
        .edgeBack {
            if engine.isOpen && !engine.isRecording {
                Task { await engine.closeCamera(reason: "gesto de voltar (borda)") }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet().environmentObject(engine)
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
