import SwiftUI

/// Aviso curto sobre a tela (v0.5.3), usado pela Galeria e pelo player (antes cada um tinha a sua cópia).
struct NoticeToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .glassBackground(RoundedRectangle(cornerRadius: 14))
    }
}

extension Binding where Value == String? {
    /// Mostra o texto e o apaga sozinho depois de 2,5 s (se não tiver sido trocado por outro nesse meio tempo).
    func flash(_ text: String) {
        wrappedValue = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if self.wrappedValue == text { self.wrappedValue = nil }
        }
    }
}
