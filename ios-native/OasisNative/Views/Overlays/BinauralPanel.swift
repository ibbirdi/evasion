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

            // Ambient pad anchored at the bottom of the panel: the binaural tracks
            // are the headline choice (user picks one), so they sit immediately
            // under the volume + toggle. The pad is an *additive* texture that
            // sits underneath whatever you've picked, so it reads better as a
            // closing footer than as something interrupting the track grid.
            AmbientPadCard(
                isEnabled: model.isTonalBedEnabled,
                onToggle: { model.setTonalBedEnabled($0) }
            )
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

/// Atmospheric pad control surface. Anchored at the bottom of the binaural panel —
/// the tracks above are the headline choice, the pad is an additive texture that
/// sits underneath whichever track you pick. When active it gains an accent tint, a
/// glowing border, and a subtle breathing wave so the user can see at a glance that
/// something is sitting under their mix.
private struct AmbientPadCard: View {
    let isEnabled: Bool
    let onToggle: (Bool) -> Void

    private var accentColor: Color {
        Color(red: 0.62, green: 0.74, blue: 0.98)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            iconWell

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.TonalBed.rowTitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(L10n.TonalBed.rowSubtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Toggle("", isOn: Binding(get: { isEnabled }, set: onToggle))
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isEnabled ? accentColor.opacity(0.14) : Color.white.opacity(0.018))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isEnabled ? accentColor.opacity(0.34) : Color.white.opacity(0.08),
                    lineWidth: 1.15
                )
        }
        .shadow(color: isEnabled ? accentColor.opacity(0.14) : .clear, radius: 14, y: 2)
        .animation(.smooth(duration: 0.26), value: isEnabled)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("binaural.tonalBed.toggle")
    }

    /// Circular icon well on the left. The breathing wave inside makes the card feel like
    /// an audio surface even when the pad is off — hints at what the toggle activates.
    private var iconWell: some View {
        ZStack {
            Circle()
                .fill(isEnabled ? accentColor.opacity(0.22) : Color.white.opacity(0.06))

            Circle()
                .strokeBorder(
                    isEnabled ? accentColor.opacity(0.45) : Color.white.opacity(0.10),
                    lineWidth: 1
                )

            AmbientPadWaveGlyph(accentColor: accentColor, isEnabled: isEnabled)
                .padding(8)
        }
        .frame(width: 44, height: 44)
    }
}

/// Minimal three-line wave rendered inside the pad card's icon well. Breathes when the pad
/// is on (animated via `TimelineView`), holds a flat low-amplitude silhouette when off so
/// the icon still reads as a frequency graph.
private struct AmbientPadWaveGlyph: View {
    let accentColor: Color
    let isEnabled: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: !isEnabled)) { context in
            Canvas { gc, size in
                let t = isEnabled ? context.date.timeIntervalSinceReferenceDate : 0
                drawWaves(gc: gc, size: size, time: t)
            }
        }
    }

    private func drawWaves(gc: GraphicsContext, size: CGSize, time: TimeInterval) {
        let midY = size.height / 2
        let amp = isEnabled ? size.height * 0.24 : size.height * 0.08
        // Three detuned sines at different phase speeds so the motion reads as a slow drone,
        // never as a metronome.
        let frequencies: [Double] = [2.6, 3.8, 5.2]
        let speeds: [Double] = [0.9, 1.3, 1.7]
        let weights: [Double] = [0.55, 0.30, 0.15]
        let color = isEnabled ? accentColor : Color.white.opacity(0.52)

        var path = Path()
        path.move(to: CGPoint(x: 0, y: midY))

        var x: Double = 0
        let step: Double = 1.2
        while x <= Double(size.width) {
            let nx = x / Double(size.width)
            var wave: Double = 0
            for i in 0..<frequencies.count {
                wave += sin(nx * frequencies[i] * .pi + time * speeds[i]) * weights[i]
            }
            let envelope = sin(nx * .pi)
            let y = midY + amp * wave * envelope
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        gc.stroke(path, with: .color(color.opacity(0.88)), lineWidth: 1.2)
    }
}
