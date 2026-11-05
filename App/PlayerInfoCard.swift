import Photos
import SwiftUI

/// Cartão de detalhes do player (v0.4.4, movido na v0.5.3): data, duração, tamanho, resolução, fluidez, taxa e áudio.
/// O que o arquivo ainda não informou aparece como "—".
struct PlayerInfoCard: View {
    let asset: PHAsset
    let info: ClipInfo?

    var body: some View {
        let rows: [(String, String)] = [
            (Textos.infoData, formatDetailDate(asset.creationDate ?? Date())),
            (Textos.infoDuracao, formatDuration(asset.duration)),
            (Textos.infoTamanho, info?.sizeBytes.map(formatMegabytes) ?? "—"),
            (Textos.infoResolucao, formatDimensions(width: asset.pixelWidth, height: asset.pixelHeight)),
            (Textos.infoFluidez, info?.fps.map(formatFps) ?? "—"),
            (Textos.infoTaxa, info?.bitsPerSecond.map(formatMbps) ?? "—"),
            (Textos.infoAudio, info?.hasAudio.map { $0 ? Textos.infoAudioSim : Textos.infoAudioNao } ?? "—"),
        ]
        return VStack(spacing: 10) {
            ForEach(rows.indices, id: \.self) { i in
                HStack {
                    Text(rows[i].0).foregroundColor(Color.white.opacity(0.7))
                    Spacer()
                    Text(rows[i].1).fontWeight(.semibold).foregroundColor(.white)
                }
                .font(.system(size: 14))
            }
        }
        .padding(16)
        .glassBackground(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 14)
        .padding(.top, 10)
    }
}
