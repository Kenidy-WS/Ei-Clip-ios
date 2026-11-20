import SwiftUI

/// Chip de acesso da tela de Início (C2, etapa 4). Cinza = informação (4 ou mais clipes gratuitos); amarelo com "›" = atenção,
/// toca e abre a escolha de acesso. Sem chip com acesso pago. É uma vista própria para só ela observar o StoreManager.
struct AccessChipView: View {
    @ObservedObject private var store = StoreManager.shared

    var body: some View {
        if let chip = HomeChipRules.chip(for: store.access?.state) {
            let color = chip.isAttention ? SheetStyle.yellow : SheetStyle.muted
            let content = HStack(spacing: 6) {
                Text(text(chip.kind))
                    .font(.system(size: 14, weight: .semibold))
                if chip.opensPlans {
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                }
            }
            .foregroundColor(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(chip.isAttention ? SheetStyle.yellow.opacity(0.14) : Color.white.opacity(0.07), in: Capsule())
            if chip.opensPlans {
                Button {
                    PlansPresenter.shared.present(PlansRequest(reason: chip.plansReason, pending: chip.kind == .pending), source: "chip")
                } label: { content.frame(minHeight: 44) }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private func text(_ kind: HomeChip.Kind) -> String {
        switch kind {
        case .remaining(let n): return Textos.chipRestam(n)
        case .used: return Textos.chipUsados
        case .ended: return Textos.chipEncerrada
        case .billing: return Textos.chipPagamento
        case .notConfirmed: return Textos.chipNaoConfirmada
        case .revoked: return Textos.chipRevogado
        case .pending: return Textos.emAnaliseTitulo
        }
    }
}
