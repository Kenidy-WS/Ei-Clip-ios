import SwiftUI

/// Página "Ajuda" dos Ajustes (v0.9.36): como usar o app, em seções curtas. Os textos estão em `Textos.ajudaSecoes`.
/// A rolagem é da própria folha de Ajustes (que também avisa quando há mais conteúdo abaixo).
struct HelpPage: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<Textos.ajudaSecoes.count, id: \.self) { i in
                let section = Textos.ajudaSecoes[i]
                Text(section.titulo.uppercased())
                    .font(.system(size: 13))
                    .foregroundColor(SheetStyle.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                    .accessibilityAddTraits(.isHeader)
                SheetGroup {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<section.textos.count, id: \.self) { j in
                            Text(section.textos[j])
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                }
            }
        }
    }
}
