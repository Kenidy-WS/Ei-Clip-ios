import AppIntents

/// Ação "Abrir câmera" (v0.9.2): aparece sozinha no app Atalhos, na lista do Botão de Ação e na Siri.
/// Roda dentro do próprio app (sem extensão) e só deixa um recado em `LaunchRequests`; a `RootView` abre a câmera quando o app
/// estiver ativo. Não toca em câmera, áudio nem voz.
///
/// Os textos desta ação ficam aqui, como literais, porque o iOS lê o título e as frases na hora de compilar (não aceita
/// `Textos.swift`). Exceção à regra de textos novos em `Engine/Textos.swift`.
struct OpenCameraIntent: AppIntent {
    static let title: LocalizedStringResource = "Abrir câmera"
    static let description = IntentDescription("Abre o Ei Clip direto na câmera.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        Diagnostics.shared.log("atalho", "ação \"Abrir câmera\" recebida (Atalhos, Botão de Ação ou Siri)")
        LaunchRequests.post()
        return .result()
    }
}

struct EiClipShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenCameraIntent(),
            phrases: [
                "Abrir a câmera do \(.applicationName)",
                "Abrir câmera no \(.applicationName)",
            ],
            shortTitle: "Abrir câmera",
            systemImageName: "camera"
        )
    }
}
