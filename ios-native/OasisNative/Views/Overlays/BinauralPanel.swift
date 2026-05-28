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
            heroCard
                .padding(.top, 24)

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
            .accessibilityIdentifier("binaural.track.grid")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.binaural.container")
    }

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            OrganicBackdropImage(
                backdrop: model.activeBinauralTrack.backdrop,
                opacity: model.isBinauralActive ? 0.78 : 0.56,
                bottomShadeOpacity: 0.56
            )

            LinearGradient(
                colors: [
                    model.activeBinauralTrack.tint.opacity(model.isBinauralActive ? 0.34 : 0.20),
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.62)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.Binaural.title)
                            .oasisFont(size: 24, weight: .semibold, relativeTo: .title2)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text("\(model.activeBinauralTrack.localizedTitle) - \(model.activeBinauralTrack.localizedFrequencyLabel)")
                            .oasisFont(size: 12, weight: .semibold, relativeTo: .caption)
                            .foregroundStyle(.white.opacity(0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        Text(L10n.Binaural.headphonesHint)
                            .oasisFont(size: 11, weight: .medium, relativeTo: .caption2)
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    Spacer(minLength: 0)

                    binauralToggle
                        .padding(.top, 2)
                }

                HapticSlider(
                    value: binauralVolumeBinding,
                    tint: model.activeBinauralTrack.tint
                )
                .opacity(model.isBinauralActive ? 1 : 0.56)
                .accessibilityLabel(Text(L10n.Binaural.volume))
            }
            .padding(18)
        }
        .frame(height: 154)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(model.activeBinauralTrack.tint.opacity(model.isBinauralActive ? 0.30 : 0.14), lineWidth: 1)
        }
    }

    private var binauralToggle: some View {
        Group {
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
        .accessibilityLabel(Text(L10n.Binaural.title))
        .accessibilityValue(Text(model.isBinauralActive ? L10n.Binaural.enabled : L10n.Binaural.disabled))
    }
}

private struct BinauralTrackCard: View {
    @Environment(AppModel.self) private var model
    let track: BinauralTrack
    private let cardShape = RoundedRectangle(cornerRadius: 20, style: .continuous)

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
            VStack(alignment: .leading, spacing: 10) {
                BinauralFrequencyWaveform(track: track, isActive: isActive, isLocked: isLocked)
                    .frame(width: 44, height: 12)
                    .accessibilityHidden(true)

                HStack(alignment: .top, spacing: 8) {
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

                    Spacer(minLength: 0)

                    statusIcon
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("binaural.track.\(track.id)")
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                cardShape
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: cardShape)
                    .overlay {
                        OrganicBackdropImage(backdrop: track.backdrop, opacity: backdropOpacity, bottomShadeOpacity: 0.42)
                    }
                    .overlay {
                        cardShape.fill(isActive ? track.tint.opacity(0.13) : Color.white.opacity(0.018))
                    }
                    .clipShape(cardShape)
            }
            .clipShape(cardShape)
            .overlay {
                cardShape.strokeBorder(isActive ? track.tint.opacity(0.28) : Color.white.opacity(0.06), lineWidth: 1)
            }
        }
        .accessibilityIdentifier("binaural.track.\(track.id)")
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .buttonStyle(BinauralButtonScaleStyle())
    }

    private var backdropOpacity: Double {
        if isLocked { return 0.16 }
        return isActive ? 0.34 : 0.22
    }

    @ViewBuilder
    private var statusIcon: some View {
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

private struct BinauralFrequencyWaveform: View {
    let track: BinauralTrack
    let isActive: Bool
    let isLocked: Bool

    var body: some View {
        BinauralFrequencyWaveShape(cycles: waveCycles)
            .stroke(
                track.tint.opacity(isLocked ? 0.34 : (isActive ? 0.94 : 0.58)),
                style: StrokeStyle(lineWidth: isActive ? 2.2 : 1.6, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: track.tint.opacity(isActive && !isLocked ? 0.34 : 0), radius: 5, y: 1)
            .animation(.smooth(duration: 0.20), value: isActive)
    }

    private var waveCycles: Double {
        switch track.beatFrequencyHz {
        case ..<4: return 1.20
        case ..<8: return 1.85
        case ..<13: return 2.55
        default: return 3.45
        }
    }
}

private struct BinauralFrequencyWaveShape: Shape {
    let cycles: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let amplitude = rect.height * 0.34
        let stepCount = max(Int(rect.width.rounded(.up)), 24)

        for step in 0...stepCount {
            let progress = CGFloat(step) / CGFloat(stepCount)
            let x = rect.minX + (rect.width * progress)
            let envelope = sin(.pi * progress)
            let phase = Double(progress) * cycles * 2 * .pi
            let y = midY + CGFloat(sin(phase)) * amplitude * envelope

            if step == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        return path
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
