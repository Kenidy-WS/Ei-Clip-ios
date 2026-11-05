import SwiftUI

/// Tela de Início (v0.3.0), igual à do web app: marca, texto, "Abrir câmera" e a versão.
/// Os "Recentes" entram na v0.3.1; os Ajustes finais, na v0.3.3 (por ora a engrenagem abre o Diagnóstico).
struct HomeView: View {
    let opening: Bool
    let message: String
    let onOpen: () -> Void
    let onSettings: () -> Void

    private let yellow = Color(red: 1.0, green: 0.84, blue: 0.04)  // #ffd60a, o amarelo do web app

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Ajustes")
            }

            Spacer()

            VStack(spacing: 10) {
                BrandMark(size: 96)
                Image("BrandLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .accessibilityLabel("Ei Clip")
                Text("Câmera de ação com comando de voz.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                Button(action: onOpen) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text(opening ? "Abrindo…" : "Abrir câmera")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(yellow, in: Capsule())
                }
                .disabled(opening)
                if !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Text("Ei Clip \(Diagnostics.appVersion)")
                .font(.caption2)
                .foregroundColor(Color.white.opacity(0.4))
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 12)
    }
}
