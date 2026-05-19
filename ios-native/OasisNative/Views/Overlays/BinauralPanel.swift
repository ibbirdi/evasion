import SwiftUI

struct BinauralPanel: View {
    @Environment(AppModel.self) private var model

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var binauralEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.isBinauralActive },
            set: { newValue in
                withAnimation(.smooth(duration: 0.24)) {
                    model.setBinauralEnabled(newValue)
                }
            }
        )
    }

    private var binauralVolumeBinding: Binding<Double> {
        Binding(
            get: { model.binauralVolume },
            set: { model.setBinauralVolume($0) }
        )
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Image(systemName: "waveform.path")
                    .oasisFont(size: 18, weight: .semibold, design: .default, relativeTo: .headline)
                    .foregroundStyle(model.activeBinauralTrack.tint.opacity(0.92))
                    .accessibilityHidden(true)

                Text(L10n.Binaural.title)
                    .oasisFont(size: 24, weight: .semibold, relativeTo: .title2)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L10n.Binaural.headphonesHint)
                    .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 30)

            controlsRow

            if let presentation = model.binauralUpsellPresentation {
                PremiumInlineUpsellCard(
                    presentation: presentation,
                    onPrimaryAction: {
                        if let entryPoint = model.activeInlineUpsell?.entryPoint {
                            model.presentPaywall(from: entryPoint)
                        }
                    },
                    onSecondaryAction: {
                        model.dismissInlineUpsell()
                    },
                    onDismiss: {
                        model.dismissInlineUpsell()
                    }
                )
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(BinauralTrack.allCases) { track in
                    BinauralTrackCard(track: track)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.binaural.container")
    }

    private var controlsRow: some View {
        HStack(spacing: 14) {
            HapticSlider(
                value: binauralVolumeBinding,
                tint: model.activeBinauralTrack.tint
            )
            .opacity(model.isBinauralActive ? 1 : 0.54)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(Text(L10n.Binaural.volume))

            if AppConfiguration.supportsSensoryFeedback {
                Toggle("", isOn: binauralEnabledBinding)
                    .labelsHidden()
                    .tint(model.activeBinauralTrack.tint)
                    .sensoryFeedback(.impact(weight: .heavy, intensity: 0.92), trigger: model.isBinauralActive)
                    .accessibilityLabel(Text(L10n.Binaural.title))
                    .accessibilityValue(Text(model.isBinauralActive ? L10n.Binaural.enabled : L10n.Binaural.disabled))
            } else {
                Toggle("", isOn: binauralEnabledBinding)
                    .labelsHidden()
                    .tint(model.activeBinauralTrack.tint)
                    .accessibilityLabel(Text(L10n.Binaural.title))
                    .accessibilityValue(Text(model.isBinauralActive ? L10n.Binaural.enabled : L10n.Binaural.disabled))
            }
        }
    }
}

private struct BinauralTrackCard: View {
    @Environment(AppModel.self) private var model
    let track: BinauralTrack

    private var isActive: Bool {
        model.activeBinauralTrack == track
    }

    private var isLocked: Bool {
        !model.isPremium && track.isPremium
    }

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.22)) {
                _ = model.selectBinauralTrack(track)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform.path")
                        .oasisFont(size: 13, weight: .semibold, design: .default, relativeTo: .caption)
                        .foregroundStyle(isActive ? track.tint : .white.opacity(0.82))
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityHidden(true)

                    Spacer(minLength: 0)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .oasisFont(size: 10, weight: .semibold, design: .default, relativeTo: .caption2)
                            .foregroundStyle(.white.opacity(0.44))
                            .accessibilityHidden(true)
                    } else if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .oasisFont(size: 14, weight: .semibold, design: .default, relativeTo: .caption)
                            .foregroundStyle(track.tint)
                            .accessibilityHidden(true)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.localizedTitle)
                        .oasisFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                        .foregroundStyle(isLocked ? .white.opacity(0.46) : .white)
                        .lineLimit(1)

                    Text(track.localizedFrequencyLabel)
                        .oasisFont(size: 10, weight: .medium, relativeTo: .caption2)
                        .foregroundStyle(isActive ? track.tint.opacity(0.84) : .white.opacity(0.42))
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("binaural.track.\(track.id)")
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(isActive ? track.tint.opacity(0.13) : Color.white.opacity(0.018))
                    }
            }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isActive ? track.tint.opacity(0.28) : Color.white.opacity(0.06), lineWidth: 1)
        }
        }
        .accessibilityIdentifier("binaural.track.\(track.id)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .buttonStyle(BinauralButtonScaleStyle())
    }

    private var accessibilityValue: Text {
        if isLocked {
            return Text(L10n.Mixer.locked)
        }
        if isActive {
            return Text(L10n.Presets.statusActive)
        }
        return Text("")
    }
}

private struct BinauralButtonScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if AppConfiguration.supportsSensoryFeedback {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
                .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: configuration.isPressed) { _, isPressed in
                    isPressed
                }
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}
