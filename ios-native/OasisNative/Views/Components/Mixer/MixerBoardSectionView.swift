import SwiftUI
import UIKit

struct MixerBoardSectionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.locale) private var locale
    let onOpenSpatial: (SoundChannel) -> Void
    @State private var showsLockedLibrary = false
    @State private var labelColumnWidth: CGFloat = 0

    private var displayedChannels: [SoundChannel] {
        if model.isPremium {
            if model.showsOnlyActiveChannels {
                return SoundChannel.allCases.filter(model.isAmbientChannelActive(_:))
            }
            return SoundChannel.allCases
        }

        if model.showsOnlyActiveChannels {
            return SoundChannel.allCases
                .filter(SoundChannel.freeChannels.contains(_:))
                .filter(model.isAmbientChannelActive(_:))
        }

        let freeChannels = SoundChannel.allCases.filter(SoundChannel.freeChannels.contains(_:))
        let lockedChannels = SoundChannel.allCases.filter { !SoundChannel.freeChannels.contains($0) }
        return showsLockedLibrary ? freeChannels + lockedChannels : freeChannels
    }

    var body: some View {
        let channels = displayedChannels

        LazyVStack(spacing: 8) {
            ForEach(channels) { channel in
                SoundRowView(
                    channel: channel,
                    labelColumnWidth: labelColumnWidth,
                    onOpenSpatial: onOpenSpatial
                )
            }

            if !model.isPremium {
                PremiumLibraryTeaserCard(
                    presentation: model.libraryTeaserPresentation,
                    isExpanded: showsLockedLibrary,
                    onPrimaryAction: {
                        model.presentPaywall(from: .manual)
                    },
                    onToggleExpanded: {
                        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                            showsLockedLibrary.toggle()
                        }
                    }
                )
                .padding(.top, 4)
            }
        }
        .task(id: labelMeasurementKey) {
            updateLabelColumnWidth(for: channels)
        }
    }

    private var labelMeasurementKey: String {
        let channelIDs = displayedChannels.map(\.id).joined(separator: "|")
        let localeID = locale.identifier(.bcp47)
        return "\(localeID)#\(channelIDs)"
    }

    private func updateLabelColumnWidth(for channels: [SoundChannel]) {
        guard !channels.isEmpty else {
            labelColumnWidth = 0
            return
        }

        let roundedDescriptor = UIFont.systemFont(ofSize: 13, weight: .semibold).fontDescriptor.withDesign(.rounded)
            ?? UIFont.systemFont(ofSize: 13, weight: .semibold).fontDescriptor
        let font = UIFont(descriptor: roundedDescriptor, size: 13)

        let measuredWidth = channels.reduce(CGFloat.zero) { currentMax, channel in
            let title = channel.localizedName
            let width = ceil((title as NSString).size(withAttributes: [.font: font]).width) + 2
            return max(currentMax, width)
        }

        labelColumnWidth = measuredWidth
    }
}

struct SoundRowView: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel
    let labelColumnWidth: CGFloat
    let onOpenSpatial: (SoundChannel) -> Void

    private var state: ChannelState {
        model.channelState(for: channel)
    }

    private var isLocked: Bool {
        model.isChannelLocked(channel)
    }

    private var isAutoAnimating: Bool {
        !isLocked && state.autoVariationEnabled
    }

    private var isActive: Bool {
        !isLocked && !state.isMuted
    }

    private var isSpatialized: Bool {
        !state.spatialPosition.isCentered
    }

    private var statusText: String? {
        if isLocked {
            return L10n.string(L10n.Mixer.statusPremium)
        }
        if state.isMuted {
            return L10n.string(L10n.Mixer.statusMuted)
        }
        if state.autoVariationEnabled {
            return L10n.string(L10n.Mixer.statusAuto)
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if isLocked {
                    model.presentPaywall(from: .sound(channel))
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        model.toggleMute(channel)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(isActive ? channel.tint.opacity(0.20) : Color.white.opacity(0.012))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    isActive
                                        ? AnyShapeStyle(channel.tint.opacity(0.34))
                                        : AnyShapeStyle(Color.white.opacity(0.08)),
                                    lineWidth: 1.1
                                )
                        }

                    Image(systemName: channel.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.54 : 1))
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(PressScaleButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(model.channelName(channel))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.60 : 0.98))
                    .lineLimit(1)

                if let statusText {
                    Text(statusText)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(secondaryTint)
                        .lineLimit(1)
                }
            }
            .frame(width: labelColumnWidth == 0 ? nil : labelColumnWidth, alignment: .leading)
            .layoutPriority(1)

            Group {
                if isAutoAnimating {
                    AutoVariationLevelBar(
                        value: model.displayVolume(for: channel),
                        tint: channel.tint
                    )
                } else {
                    HapticSlider(
                        value: Binding(
                            get: { model.displayVolume(for: channel) },
                            set: { model.setChannelVolume(channel, value: $0) }
                        ),
                        tint: channel.tint
                    )
                    .disabled(isLocked || state.isMuted || state.autoVariationEnabled)
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(sliderOpacity)

            Button {
                if isLocked {
                    model.presentPaywall(from: .spatial(channel))
                } else {
                    onOpenSpatial(channel)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(isSpatialized ? channel.tint.opacity(0.18) : Color.white.opacity(0.02))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    isSpatialized ? channel.tint.opacity(0.36) : Color.white.opacity(0.08),
                                    lineWidth: 1.1
                                )
                        }

                    Image(systemName: isSpatialized ? "scope" : "scope")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityIdentifier("channel.spatial.\(channel.id)")

            Button {
                if isLocked {
                    model.presentPaywall(from: .sound(channel))
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        model.toggleAutoVariation(channel)
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                    } else {
                        Text(L10n.Mixer.statusAuto)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(buttonForeground)
                .padding(.horizontal, isLocked ? 12 : 14)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(state.autoVariationEnabled ? channel.tint.opacity(0.22) : Color.white.opacity(0.04))
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            state.autoVariationEnabled ? channel.tint.opacity(0.36) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityIdentifier("channel.row.\(channel.id)")
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(channelTint)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        }
        .opacity(isLocked ? 0.90 : 1)
        .animation(.easeInOut(duration: 0.16), value: state.isMuted)
        .animation(.easeInOut(duration: 0.16), value: state.autoVariationEnabled)
    }

    private var secondaryTint: Color {
        if isLocked {
            return .white.opacity(0.34)
        }
        return isActive ? channel.tint.opacity(0.90) : .white.opacity(0.34)
    }

    private var sliderOpacity: Double {
        if isLocked {
            return 0.28
        }
        if state.isMuted {
            return 0.24
        }
        if isAutoAnimating {
            return 1
        }
        if state.autoVariationEnabled {
            return 0.80
        }
        return 1
    }

    private var channelTint: Color {
        if isActive {
            return channel.tint.opacity(state.autoVariationEnabled ? 0.10 : 0.07)
        }
        return Color.white.opacity(state.isMuted && !isLocked ? 0.010 : 0.018)
    }

    private var buttonForeground: Color {
        if isLocked {
            return .white.opacity(0.72)
        }
        return state.autoVariationEnabled ? .white : .white.opacity(0.82)
    }
}

private struct AutoVariationLevelBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(value, 0), 1)
            let width = max(proxy.size.width * clamped, 12)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.96),
                                tint.opacity(0.58)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
            }
        }
        .frame(height: 12)
        .animation(.linear(duration: 0.14), value: value)
    }
}
