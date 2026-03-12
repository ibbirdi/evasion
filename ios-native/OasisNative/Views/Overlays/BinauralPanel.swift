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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("Sons binauraux")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(model.copy.binaural.headphonesHint)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

                activeTrackSummary

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(BinauralTrack.allCases) { track in
                        BinauralTrackCard(track: track)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .background(.clear)
    }

    private var activeTrackSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.copy.binaural[model.activeBinauralTrack])
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(model.copy.binaural.frequencyLabel(for: model.activeBinauralTrack))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(model.activeBinauralTrack.tint.opacity(0.90))
                }

                Spacer(minLength: 8)

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

            if model.isBinauralActive {
                VStack(alignment: .leading, spacing: 6) {
                    HapticSlider(
                        value: binauralVolumeBinding,
                        tint: model.activeBinauralTrack.tint
                    )

                    Text("Mix binaural actif")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.46))
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(model.activeBinauralTrack.tint.opacity(0.10))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .animation(.smooth(duration: 0.24), value: model.isBinauralActive)
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
                    Text(model.copy.binaural[track])
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(isLocked ? .white.opacity(0.46) : .white)
                        .lineLimit(1)

                    Text(model.copy.binaural.frequencyLabel(for: track))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(isActive ? track.tint.opacity(0.84) : .white.opacity(0.42))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(isActive ? track.tint.opacity(0.12) : Color.white.opacity(0.02))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isActive ? track.tint.opacity(0.34) : Color.white.opacity(0.06), lineWidth: 1)
            }
        }
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
