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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(model.activeBinauralTrack.tint.opacity(0.92))

                Text(L10n.Binaural.title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L10n.Binaural.headphonesHint)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
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

            tonalBedRow
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.binaural.container")
    }

    /// Compact toggle for the atmospheric pad. Kept inside this panel since it's the only
    /// other "non-ambient audio texture" control — deliberately understated.
    private var tonalBedRow: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.TonalBed.rowTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Text(L10n.TonalBed.rowSubtitle)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { model.isTonalBedEnabled },
                set: { model.setTonalBedEnabled($0) }
            ))
            .labelsHidden()
            .tint(Color(red: 0.64, green: 0.76, blue: 0.98))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
        .accessibilityIdentifier("binaural.tonalBed.toggle")
    }

    private var controlsRow: some View {
        HStack(spacing: 14) {
            HapticSlider(
                value: binauralVolumeBinding,
                tint: model.activeBinauralTrack.tint
            )
            .opacity(model.isBinauralActive ? 1 : 0.54)
            .frame(maxWidth: .infinity)

            if AppConfiguration.supportsSensoryFeedback {
                Toggle("", isOn: binauralEnabledBinding)
                    .labelsHidden()
                    .tint(model.activeBinauralTrack.tint)
                    .sensoryFeedback(.impact(weight: .heavy, intensity: 0.92), trigger: model.isBinauralActive)
            } else {
                Toggle("", isOn: binauralEnabledBinding)
                    .labelsHidden()
                    .tint(model.activeBinauralTrack.tint)
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
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isActive ? track.tint : .white.opacity(0.82))
                        .symbolRenderingMode(.hierarchical)

                    Spacer(minLength: 0)

                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.44))
                    } else if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(track.tint)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.localizedTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(isLocked ? .white.opacity(0.46) : .white)
                        .lineLimit(1)

                    Text(track.localizedFrequencyLabel)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
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
        .buttonStyle(BinauralButtonScaleStyle())
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
