import SwiftUI

struct MacBinauralSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 12) {
            MacPanelSurface {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 10) {
                        MacSectionTitle(L10n.Binaural.title, subtitle: L10n.Binaural.headphonesHint)

                        Toggle("", isOn: Binding(
                            get: { model.isBinauralActive },
                            set: { model.setBinauralEnabled($0) }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }

                    Slider(value: Binding(
                        get: { model.binauralVolume },
                        set: { model.setBinauralVolume($0) }
                    ), in: 0...1)
                    .tint(model.activeBinauralTrack.tint)
                    .disabled(!model.isBinauralActive)
                    .accessibilityLabel(Text(L10n.Binaural.volume))
                }
            }

            VStack(spacing: 7) {
                ForEach(BinauralTrack.allCases) { track in
                    MacBinauralTrackRow(track: track)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

private struct MacBinauralTrackRow: View {
    @Environment(AppModel.self) private var model
    let track: BinauralTrack

    private var selected: Bool {
        model.activeBinauralTrack == track
    }

    private var locked: Bool {
        track.isPremium && !model.isPremium
    }

    var body: some View {
        Button {
            if model.selectBinauralTrack(track) {
                model.setBinauralEnabled(true)
            }
        } label: {
            MacPanelSurface(padding: EdgeInsets(top: 11, leading: 11, bottom: 11, trailing: 11)) {
                HStack(spacing: 11) {
                    Image(systemName: locked ? "lock.fill" : (selected ? "waveform.path.badge.plus" : "waveform.path"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(track.tint)
                        .frame(width: 32, height: 32)
                        .background(track.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(verbatim: track.localizedTitle)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.94))

                        Text(verbatim: track.localizedFrequencyLabel)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.48))
                    }

                    Spacer(minLength: 0)

                    if selected {
                        Image(systemName: model.isBinauralActive ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(track.tint)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
