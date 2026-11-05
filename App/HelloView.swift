import SwiftUI

/// Tela mínima só para validar o ciclo: compilar -> baixar IPA -> instalar -> abrir.
struct HelloView: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }

    private var bundleId: String {
        Bundle.main.bundleIdentifier ?? "?"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Ei Clip")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(Color(red: 1.0, green: 0.82, blue: 0.0))
                Text("Olá! O ciclo funcionou.")
                    .font(.title3)
                    .foregroundColor(.white)
                Text(version)
                    .font(.footnote)
                    .foregroundColor(.gray)
                Text(bundleId)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
    }
}
