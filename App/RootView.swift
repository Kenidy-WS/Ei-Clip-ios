import SwiftUI

/// Raiz do app. Câmera fechada: tela de Início. Câmera aberta: tela da Câmera (v0.3.4). Galeria: `GalleryView` (v0.4.0).
/// Ajustes: folha `SettingsSheet` (v0.3.6; o Diagnóstico fica dentro dela).
///
/// Miniatura da câmera (v0.4.8): abre o player direto no último clipe; fechar o player volta direto à câmera (que fecha enquanto
/// o player está aberto, igual à Galeria).
/// Câmera ↔ Galeria (v0.4.1): a Galeria abre pelo Início; ao ir da Galeria à câmera, a câmera reabre. Ao entrar na Galeria a câmera FECHA (microfone, voz e gravação desligam: a voz não
/// pode escutar dentro da Galeria). Ao voltar, a câmera reabre e o buffer recomeça vazio. Gravando, não sai da câmera.
///
/// Transições (v0.4.2): a direção vem de `screenTransition` (Core). O SwiftUI usa, na saída de uma tela, a transição que ela
/// tinha na última vez em que foi desenhada; por isso `navigate` troca a direção primeiro e só 50 ms depois muda a tela.
struct RootView: View {
    @EnvironmentObject var engine: CaptureEngine
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showSettings = false
    @State private var opening = false
    /// v0.5.1: onde o usuário está além do motor (Galeria, tela preta do player, origem da Galeria): regra pura no Core.
    @State private var route = AppRoute()
    /// Modo de seleção da Galeria (v0.4.12); o gesto de voltar primeiro sai dele (v0.4.14).
    @State private var gallerySelecting = false
    /// v0.4.8: clipe aberto pela miniatura da câmera. Enquanto o player está aberto, a câmera fica FECHADA (a voz não escuta o
    /// som do vídeo) e `route.parked` mantém uma tela preta no lugar dela (sem piscar o Início).
    @State private var cameraPlayer: RecentClips.Item?
    /// Fechamento da câmera em andamento (a reabertura espera por ele, para nunca abrir no meio do fechamento).
    @State private var closingTask: Task<Void, Never>?
    /// Direção da próxima troca de tela.
    @State private var nav: ScreenTransitionKind = .fade

    private var currentScreen: AppScreen { route.screen(cameraOpen: engine.isOpen) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if route.inGallery {
                GalleryView(onBack: leaveGallery, onCamera: returnToCamera, selecting: $gallerySelecting)
                    .transition(.screen(reduceMotion ? .none : nav))
            } else if route.parked {
                Color.black.ignoresSafeArea()
                    .transition(.screen(reduceMotion ? .none : nav))
            } else if engine.isOpen {
                CameraScreen(
                    onSettings: { showSettings = true },
                    onLastClip: openPlayerFromCamera,
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
        // v0.3.5: arrastar da borda esquerda volta (Câmera → Início; na Galeria, sai da seleção e depois da Galeria). Gravando,
        // o gesto é ignorado. v0.4.14: da borda direita abre a Galeria. As regras estão no Core (`edgeBackAction`).
        .edgeBack { handleEdgeBack() }
        .edgeForward(enabled: !route.inGallery && !route.parked && cameraPlayer == nil) { handleEdgeForward() }
        .sheet(isPresented: $showSettings) {
            SettingsSheet().environmentObject(engine)
        }
        .fullScreenCover(item: $cameraPlayer) { item in
            ClipPlayerView(asset: item.asset, onClose: closePlayerToCamera)
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
        route.markGalleryOrigin(fromCamera: false)
        navigate(from: .home, to: .gallery) { route.showGallery() }
    }

    /// Miniatura da câmera: fecha a câmera e abre o player no último clipe (dá para passar pelos outros arrastando para os
    /// lados). Gravando, só avisa.
    private func openPlayerFromCamera(_ item: RecentClips.Item) {
        guard !engine.isRecording, !opening else {
            if engine.isRecording { engine.flash(Textos.terminePrimeiro) }
            return
        }
        Diagnostics.shared.log("player", "aberto pela câmera (a câmera será fechada)")
        navigate(from: .camera, to: .gallery) {
            route.park()
            let closing = Task { await engine.closeCamera(reason: "Player") }
            closingTask = closing
            // v0.4.17: o player troca a sessão de áudio para reprodução; isso só pode acontecer com a captura já FECHADA.
            Task { @MainActor in
                await closing.value
                cameraPlayer = item
            }
        }
    }

    /// Fechar o player aberto pela câmera (botão, arrastar para baixo ou gesto de borda): volta DIRETO à câmera, sem passar
    /// pela Galeria. A tela preta fica até a câmera reabrir.
    private func closePlayerToCamera() {
        guard cameraPlayer != nil else { return }
        cameraPlayer = nil
        guard !opening else { return }
        opening = true
        Diagnostics.shared.log("player", "voltando direto à câmera")
        nav = screenTransition(from: .gallery, to: .camera)
        Task {
            await closingTask?.value
            closingTask = nil
            _ = await engine.openCamera()
            opening = false
            route.unpark()
        }
    }

    /// Gesto de voltar (borda esquerda): a regra é do Core.
    private func handleEdgeBack() {
        switch edgeBackAction(
            inGallery: route.inGallery, selecting: gallerySelecting, cameraOpen: engine.isOpen, recording: engine.isRecording)
        {
        case .exitSelection: gallerySelecting = false
        case .leaveGallery: leaveGallery()
        case .closeCamera: closeCameraToHome(reason: "gesto de voltar (borda)")
        case .none: break
        }
    }

    /// Gesto de avançar (borda direita): abre a Galeria. Na câmera fecha a câmera (e gravando não faz nada).
    private func handleEdgeForward() {
        switch edgeForwardAction(
            route: route, playerOpen: cameraPlayer != nil, opening: opening, testRunning: engine.testRunning,
            cameraOpen: engine.isOpen, recording: engine.isRecording)
        {
        case .galleryFromCamera:
            Diagnostics.shared.log("galeria", "aberta pelo gesto de avançar (borda direita), vindo da câmera")
            openGalleryFromCamera()
        case .galleryFromHome:
            Diagnostics.shared.log("galeria", "aberta pelo gesto de avançar (borda direita), vindo do Início")
            openGalleryFromHome()
        case .none:
            break
        }
    }

    /// Fecha a câmera e abre a Galeria. Voltar da Galeria reabre a câmera.
    private func openGalleryFromCamera() {
        route.markGalleryOrigin(fromCamera: true)
        navigate(from: .camera, to: .gallery) {
            route.showGallery()
            closingTask = Task { await engine.closeCamera(reason: "Galeria") }
        }
    }

    /// Voltar da Galeria: para a tela de onde veio (câmera ou Início).
    private func leaveGallery() {
        if route.galleryFromCamera {
            returnToCamera()
        } else {
            navigate(from: .gallery, to: .home) { route.hideGallery() }
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
            route.hideGallery()
        }
    }
}
