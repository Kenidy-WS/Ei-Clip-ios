import SwiftUI

/// Tutorial de primeiro acesso (v0.9.35): três telas, só na primeira abertura, por cima do Início. Segue o protótipo aprovado
/// em 22/11 (artefato "Ei Clip — Tutorial de primeiro acesso"). Os textos estão em `Textos`; a regra de quando mostrar, no Core
/// (`OnboardingRules`). Cabeçalho e cartão têm a mesma altura nas três telas (a maior delas), para nada pular de lugar.
struct OnboardingView: View {
    /// Chamado ao tocar em "Entendi" na última tela.
    let onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page {
        let title: String
        let description: String
        let items: [(titulo: String, texto: String)]
        /// Ícones do sistema, um por item; `nil` = itens numerados.
        let icons: [String]?
    }

    private let pages: [Page] = [
        Page(
            title: Textos.tutorialFuncionaTitulo, description: Textos.tutorialFuncionaDescricao,
            items: Textos.tutorialFuncionaPontos, icons: nil),
        Page(
            title: Textos.tutorialPermissoesTitulo, description: Textos.tutorialPermissoesDescricao,
            items: Textos.tutorialPermissoesPontos, icons: ["camera", "mic", "waveform", "photo"]),
        Page(
            title: Textos.tutorialCalorTitulo, description: Textos.tutorialCalorDescricao,
            items: Textos.tutorialCalorPontos, icons: nil),
    ]

    private static let background = Color(red: 0.11, green: 0.11, blue: 0.118)  // #1c1c1e
    private static let softText = Color(red: 0.68, green: 0.68, blue: 0.70)  // #aeaeb2
    private static let divider = Color.white.opacity(0.12)

    private var isLast: Bool { OnboardingRules.isLast(page) }

    var body: some View {
        ZStack {
            Self.background.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        brand
                            .padding(.bottom, 8)
                        sameHeight { index in header(pages[index]) }
                            .padding(.bottom, 18)
                        card
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                }
                footer
            }
        }
        .accessibilityAddTraits(.isModal)
        .onAppear { Diagnostics.shared.log("tutorial", "mostrado") }
    }

    // MARK: - Partes

    private var brand: some View {
        HStack(spacing: 8) {
            ZStack {
                Image("MarkRing").resizable()
                Image("MarkTriangle").resizable()
                Image("MarkDot").resizable()
            }
            .frame(width: 32, height: 32)
            .frame(width: 22, height: 22)
            .accessibilityHidden(true)
            Text(Textos.tutorialMarca)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(SheetStyle.yellow)
        }
        .padding(.horizontal, 6)
    }

    private func header(_ p: Page) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(p.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .accessibilityAddTraits(.isHeader)
            Text(p.description)
                .font(.system(size: 16))
                .foregroundColor(Self.softText)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 6)
    }

    private var card: some View {
        sameHeight { index in rows(pages[index]) }
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.07)))
    }

    private func rows(_ p: Page) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<p.items.count, id: \.self) { i in
                if i > 0 { Self.divider.frame(height: 1) }
                row(index: i, page: p)
            }
        }
    }

    private func row(index: Int, page p: Page) -> some View {
        HStack(alignment: .top, spacing: 14) {
            marker(index: index, icons: p.icons)
            VStack(alignment: .leading, spacing: 3) {
                Text(p.items[index].titulo)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Text(p.items[index].texto)
                    .font(.system(size: 15))
                    .foregroundColor(Self.softText)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func marker(index: Int, icons: [String]?) -> some View {
        if let icons = icons, index < icons.count {
            Image(systemName: icons[index])
                .font(.system(size: 22))
                .foregroundColor(SheetStyle.yellow)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
        } else {
            Text("\(index + 1)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Circle().fill(SheetStyle.yellow))
                .accessibilityHidden(true)
        }
    }

    private var footer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0..<OnboardingRules.pageCount, id: \.self) { i in
                    Circle()
                        .fill(i == page ? SheetStyle.yellow : Color.white.opacity(0.25))
                        .frame(width: 8, height: 8)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Textos.tutorialPasso(page + 1, de: OnboardingRules.pageCount))
            Button(action: advance) {
                Text(isLast ? Textos.entendi : Textos.continuar)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(SheetStyle.yellow))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Ações

    private func advance() {
        if isLast {
            onFinish()
            return
        }
        let target = OnboardingRules.next(after: page)
        if reduceMotion {
            page = target
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { page = target }
        }
    }

    /// Empilha o conteúdo das três telas no mesmo lugar e deixa visível só o da tela atual: a altura é a da maior, nas três.
    private func sameHeight<Content: View>(@ViewBuilder _ content: @escaping (Int) -> Content) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<pages.count, id: \.self) { i in
                content(i)
                    .opacity(i == page ? 1 : 0)
                    .accessibilityHidden(i != page)
            }
        }
    }
}
