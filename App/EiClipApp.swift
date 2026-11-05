import SwiftUI

@main
struct EiClipApp: App {
    @StateObject private var engine = CaptureEngine()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Primeiro uso do Diagnóstico: gira os arquivos (a rodada anterior vira "anterior") logo ao abrir o app.
        Diagnostics.shared.log("app", "iniciado")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(engine)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { phase in
                    // v0.1.5: todo estado do app vai para o Diagnóstico (casar interrupções e gravações com o que o app estava fazendo).
                    Diagnostics.shared.log("app", "estado: \(phase == .active ? "ativo" : (phase == .inactive ? "inativo" : "segundo plano"))")
                    // O iOS não mantém a câmera em segundo plano: salva a gravação e fecha.
                    // (Só em .background: o pedido de permissão do sistema passa por .inactive.)
                    if phase == .background {
                        Task { await engine.closeCamera(reason: "app foi para o segundo plano", reopenOnReturn: true) }
                    }
                    // v0.1.8: ao voltar, reabre a câmera sozinha (só se foi o segundo plano que a fechou).
                    if phase == .active {
                        Task { await engine.reopenAfterReturn() }
                    }
                }
        }
    }
}
