import SwiftUI

/// Raiz do app. Câmera fechada: tela de Início. Câmera aberta: tela da Câmera (v0.3.4). Galeria: `GalleryView` (v0.4.0).
/// Ajustes: folha `SettingsSheet` (v0.3.6; o Diagnóstico fica dentro dela).
///
/// Câmera ↔ Galeria (v0.4.1): ao entrar na Galeria pela câmera, a câmera FECHA (microfone, voz e gravação desligam: a voz não
/// pode escutar dentro da Galeria). Ao voltar, a câmera reabre e o buffer recomeça vazio. Gravando, não sai da câmera.
///
/// Transições (v0.4.2): a direção vem de `screenTransition` (Core). O SwiftUI usa, na saída de uma tela, a transição que ela
/// tinha na última vez em que foi desenhada; por isso `navigate` troca a direção primeiro e só 50 ms depois muda a tela.
struct RootView: View {
    @EnvironmentObject var engine: CaptureEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSettings = false
    @State private var opening = false
    @State private var inGallery = false
    /// De onde o usuário entrou na Galeria: o botão de voltar volta para lá.
    @State private var galleryFromCamera = false
    /// Fechamento da câmera em andamento (a reabertura espera por ele, para nunca abrir no meio do fechamento).
    @State private var closingTask: Task<Void, Never>?
    /// Direção da próxima troca de tela.
    @State private var nav: ScreenTransitionKind = .fade

    private var currentScreen: AppScreen {
        inGallery ? .gallery : (engine.isOpen ? .camera : .home)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if inGallery {
                GalleryView(onBack: leaveGallery, onCamera: returnToCamera)
                    .transition(.screen(reduceMotion ? .none : nav))
            } else if engine.isOpen {
                CameraScreen(
                    onSettings: { showSettings = true },
                    onGallery: openGalleryFromCamera,
                    onBack: { closeCameraToHome(reason: "botão Voltar da câmera") }
                )
                .transition(.screen(reduceMotion ? .none : nav))
            } else {
                HomeView(
                    opening: opening,
                    message: engine.message,
                    onOpen: openCamera,
                    onSettings: { showSettings = true },
                    onSeeAll: openGalleryFromHome
                )
                .transition(.screen(reduceMotion ? .none : nav))
            }
        }
        .animation(reduceMotion ? nil : .screenChange, value: currentScreen)
        // v0.3.5: arrastar da borda esquerda volta (Câmera → Início). Gravando, o gesto é ignorado: um arrasto sem querer
        // com a mão molhada não pode encerrar o clipe (o botão de voltar continua valendo).
        .edgeBack {
            if engine.isOpen && !engine.isRecording {
                closeCameraToHome(reason: "gesto de voltar (borda)")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet().environmentObject(engine)
        }
    }

    /// Define a direção e, 50 ms depois (para a tela atual ser redesenhada com ela), faz a troca.
    private func navigate(from: AppScreen, to: AppScreen, _ change: @escaping () -> Void) {
        nav = screenTransition(from: from, to: to)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { change() }
    }

    private func openCamera() {
        guard !opening, !engine.testRunning else { return }
        opening = true
        nav = screenTransition(from: .home, to: .camera)  // a câmera leva mais de 50 ms para abrir
        Task {
            _ = await engine.openCamera()
            opening = false
        }
    }

    /// Câmera → Início (botão Voltar e gesto de borda).
    private func closeCameraToHome(reason: String) {
        navigate(from: .camera, to: .home) {
            Task { await engine.closeCamera(reason: reason) }
        }
    }

    private func openGalleryFromHome() {
        Diagnostics.shared.log("galeria", "aberta pelo Início")
        galleryFromCamera = false
        navigate(from: .home, to: .gallery) { inGallery = true }
    }

    /// Miniatura da câmera: fecha a câmera e abre a Galeria. Gravando, só avisa.
    private func openGalleryFromCamera() {
        guard !engine.isRecording else {
            engine.flash(Textos.terminePrimeiro)
            return
        }
        Diagnostics.shared.log("galeria", "aberta pela câmera (a câmera será fechada)")
        galleryFromCamera = true
        navigate(from: .camera, to: .gallery) {
            inGallery = true
            closingTask = Task { await engine.closeCamera(reason: "Galeria") }
        }
    }

    /// Voltar da Galeria: para a tela de onde veio (câmera ou Início).
    private func leaveGallery() {
        if galleryFromCamera {
            returnToCamera()
        } else {
            navigate(from: .gallery, to: .home) { inGallery = false }
        }
    }

    /// Reabre a câmera e só então sai da Galeria (assim o Início não pisca no meio do caminho). Se a câmera não abrir,
    /// o Início aparece com o aviso do motor.
    private func returnToCamera() {
        guard !opening, !engine.testRunning else { return }
        opening = true
        Diagnostics.shared.log("galeria", "voltando à câmera")
        nav = screenTransition(from: .gallery, to: .camera)  // reabrir leva mais de 50 ms
        Task {
            await closingTask?.value
            closingTask = nil
            _ = await engine.openCamera()
            opening = false
            inGallery = false
        }
    }
}
