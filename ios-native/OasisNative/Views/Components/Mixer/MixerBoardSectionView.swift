import SwiftUI
import UIKit

struct MixerBoardSectionView: View {
    @Environment(AppModel.self) private var model
    let onOpenSpatial: (SoundChannel) -> Void
    let onOpenDetail: (SoundChannel) -> Void
    @State private var showsLockedLibrary = false

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
        LazyVStack(spacing: 8) {
            ForEach(displayedChannels) { channel in
                SoundRowView(
                    channel: channel,
                    onOpenSpatial: onOpenSpatial,
                    onOpenDetail: onOpenDetail
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
    }
}

struct SoundRowView: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel
    let onOpenSpatial: (SoundChannel) -> Void
    let onOpenDetail: (SoundChannel) -> Void

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
        // Only PREMIUM is surfaced as a label. Mute and auto-variation states are already
        // communicated by the icon opacity and the AUTO pill/slider appearance — an extra
        // uppercase badge on every row was more noise than signal.
        isLocked ? L10n.string(L10n.Mixer.statusPremium) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            identityRow
            controlsRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
                .strokeBorder(borderStyle, lineWidth: isActive ? 1.2 : 1)
        }
        .opacity(isLocked ? 0.90 : 1)
        .animation(.easeInOut(duration: 0.16), value: state.isMuted)
        .animation(.easeInOut(duration: 0.16), value: state.autoVariationEnabled)
    }

    private var borderStyle: AnyShapeStyle {
        if isActive {
            return AnyShapeStyle(channel.tint.opacity(0.45))
        }
        return AnyShapeStyle(Color.white.opacity(0.05))
    }

    // MARK: - Identity row (tap to open detail sheet)

    private var identityRow: some View {
        Button {
            onOpenDetail(channel)
        } label: {
            HStack(alignment: .center, spacing: 6) {
                if !channel.location.flagEmoji.isEmpty {
                    Text(channel.location.flagEmoji)
                        .font(.system(size: 14))
                }

                Text(channel.localizedName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(identityForeground)

                if !channel.location.rowLabel.isEmpty {
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.30))

                    Text(channel.location.rowLabel)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(locationForeground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 6)

                if let statusText {
                    Text(statusText)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(secondaryTint)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(statusBackground)
                        }
                }

                Image(systemName: "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("channel.identity.\(channel.id)")
        .accessibilityLabel(accessibilityIdentityLabel)
        .accessibilityHint(Text("Opens sound details"))
    }

    // MARK: - Controls row (mute, slider, spatial, auto)

    private var controlsRow: some View {
        HStack(spacing: 10) {
            muteButton

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

            spatialButton

            autoButton
        }
    }

    private var muteButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .sound(channel))
            } else {
                withAnimation(.easeInOut(duration: 0.18)) {
                    model.toggleMute(channel)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: Circle())
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
        .accessibilityIdentifier("channel.mute.\(channel.id)")
    }

    private var spatialButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .spatial(channel))
            } else {
                onOpenSpatial(channel)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: Circle())
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

                Image(systemName: "scope")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("channel.spatial.\(channel.id)")
    }

    private var autoButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .sound(channel))
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
        .accessibilityIdentifier("channel.auto.\(channel.id)")
    }

    // MARK: - Derived styling

    private var identityForeground: Color {
        if isLocked { return .white.opacity(0.65) }
        return isActive ? .white.opacity(0.98) : .white.opacity(0.80)
    }

    private var locationForeground: Color {
        if isLocked { return .white.opacity(0.32) }
        return .white.opacity(0.52)
    }

    private var statusBackground: Color {
        if isLocked { return Color.white.opacity(0.06) }
        if isActive { return channel.tint.opacity(0.16) }
        return Color.white.opacity(0.04)
    }

    private var secondaryTint: Color {
        if isLocked { return .white.opacity(0.48) }
        return isActive ? channel.tint.opacity(0.95) : .white.opacity(0.44)
    }

    private var sliderOpacity: Double {
        if isLocked { return 0.28 }
        if state.isMuted { return 0.24 }
        if isAutoAnimating { return 1 }
        if state.autoVariationEnabled { return 0.80 }
        return 1
    }

    private var channelTint: Color {
        if isActive {
            return channel.tint.opacity(state.autoVariationEnabled ? 0.10 : 0.07)
        }
        return Color.white.opacity(state.isMuted && !isLocked ? 0.010 : 0.018)
    }

    private var buttonForeground: Color {
        if isLocked { return .white.opacity(0.72) }
        return state.autoVariationEnabled ? .white : .white.opacity(0.82)
    }

    private var accessibilityIdentityLabel: Text {
        let name = channel.localizedName
        let location = channel.location.fullLabel
        if location.isEmpty {
            return Text(name)
        }
        return Text("\(name), \(location)")
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
