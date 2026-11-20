import SwiftUI

/// Pedido para abrir a escolha de acesso (C2, etapa 4).
struct PlansRequest: Identifiable, Equatable {
    let id = UUID()
    /// Por que abriu; nil = por vontade própria (chip com clipes gratuitos sobrando).
    let reason: PlansReason?
    /// Abre o painel "Compra em análise" no lugar dos cartões.
    let pending: Bool
}

/// Quem abre e fecha a tela "Escolha seu acesso". Só a raiz do app observa este objeto (não é estado da câmera).
/// Abre UMA vez: enquanto a tela está aberta, novos pedidos (outro gatilho de gravação) são ignorados.
/// Nunca abre com o app fora de primeiro plano (tela bloqueada, segundo plano) nem por cima de outra tela (Ajustes, player, aviso).
@MainActor
final class PlansPresenter: ObservableObject {
    static let shared = PlansPresenter()

    @Published var request: PlansRequest?

    /// Chamado pela Engine, de qualquer fila.
    nonisolated static func requestFromEngine(_ request: PlansRequest, source: String) {
        Task { @MainActor in shared.present(request, source: source) }
    }

    func present(_ new: PlansRequest, source: String) {
        let what = new.pending ? "compra em análise" : (new.reason.map { "\($0)" } ?? "voluntária")
        guard request == nil else {
            Diagnostics.shared.log("acesso", "escolha de acesso já está aberta; pedido ignorado (\(source))")
            return
        }
        guard UIApplication.shared.applicationState == .active else {
            Diagnostics.shared.log("acesso", "escolha de acesso NÃO aberta (\(source)): o app não está em primeiro plano")
            return
        }
        guard !ScreenOverlay.isPresented() else {
            Diagnostics.shared.log("acesso", "escolha de acesso NÃO aberta (\(source)): há outra tela por cima")
            return
        }
        Diagnostics.shared.log("acesso", "escolha de acesso aberta (\(source)): \(what)")
        request = new
    }

    func dismiss() {
        if request != nil { Diagnostics.shared.log("acesso", "escolha de acesso fechada") }
        request = nil
    }
}
