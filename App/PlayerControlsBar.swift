import SwiftUI

/// Barra de controles do player (v0.4.x, movida na v0.5.3): reproduzir/pausar, tempo, posição, velocidade e som.
struct PlayerControlsBar: View {
    @ObservedObject var model: PlayerModel
    @Binding var seeking: Bool
    @Binding var seekValue: Double

    var body: some View {
        HStack(spacing: 8) {
            controlButton(
                systemName: model.isPlaying ? "pause.fill" : "play.fill",
                label: model.isPlaying ? Textos.pausar : Textos.reproduzir
            ) { model.togglePlay() }

            Text(formatDuration(seeking ? seekValue * model.duration : model.currentTime))
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundColor(.white)
                .frame(minWidth: 34)

            Slider(
                value: Binding(
                    get: { seeking ? seekValue : model.fraction },
                    set: { value in
                        seekValue = value
                        model.seek(toFraction: value)
                    }),
                in: 0...1,
                onEditingChanged: { editing in
                    if editing { seekValue = model.fraction }
                    seeking = editing
                }
            )
            .tint(.white)
            .accessibilityLabel(Textos.posicaoDoVideo)

            Button { model.setRate(PlaybackRate.next(after: model.rate)) } label: {
                Text(PlaybackRate.label(model.rate))
                    .font(.system(size: 14, weight: .semibold).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel(Textos.velocidade)

            controlButton(
                systemName: model.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: model.isMuted ? Textos.ligarOSom : Textos.desligarOSom
            ) { model.isMuted.toggle() }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 52)
        .glassBackground(RoundedRectangle(cornerRadius: 26))
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
    }

    private func controlButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(label)
    }
}
