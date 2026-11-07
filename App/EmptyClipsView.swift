import SwiftUI

/// v0.7.6: o que aparece quando não há clipes para mostrar. Se a causa é a falta de acesso às Fotos (negado, limitado ou sem
/// resposta do iPhone), diz isso e oferece os Ajustes, em vez de "Nenhum clipe ainda.".
struct EmptyClipsView: View {
    let accessProblem: PermissionProblem?

    private let gray = Color(red: 0.56, green: 0.56, blue: 0.58)  // #8e8e93

    var body: some View {
        if accessProblem != nil {
            VStack(spacing: 8) {
                Text(Textos.fotosSemAcessoInicio)
                    .font(.system(size: 14))
                    .foregroundColor(gray)
                    .multilineTextAlignment(.center)
                Button(Textos.abrirAjustes) { SystemSettings.open() }
                    .font(.system(size: 15))
                    .foregroundColor(Color.white.opacity(0.7))
            }
        } else {
            Text(Textos.semClipes)
                .font(.system(size: 14))
                .foregroundColor(gray)
        }
    }
}
