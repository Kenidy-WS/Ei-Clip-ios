import SwiftUI

@main
struct EiClipApp: App {
    @StateObject private var engine = CaptureEngine()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { phase in
                    // O iOS não mantém a câmera em segundo plano: salva a gravação e fecha.
                    // (Só em .background: o pedido de permissão do sistema passa por .inactive.)
                    if phase == .background {
                        Task { await engine.closeCamera(reason: "app foi para o segundo plano") }
                    }
                }
        }
    }
}
