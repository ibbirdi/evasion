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
        // `.contain` is critical: without it SwiftUI flattens the VStack into one
        // accessibility element and overrides every child's identifier with
        // `channel.row.<id>`, which breaks UI tests that target `channel.identity.<id>`,
        // `channel.mute.<id>`, `channel.spatial.<id>`, etc.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("channel.row.\(channel.id)")
        .background {
            // Active rows read as alive: opaque frosted material + coloured tint wash +
            // saturated channel-tint border + a soft glow shadow. Inactive rows read as
            // receding: lighter material, almost no tint, thin neutral border, no glow.
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isActive ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.thinMaterial))
                    .opacity(isActive ? 1 : 0.45)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(channelTint)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderStyle, lineWidth: isActive ? 1.4 : 0.8)
        }
        .shadow(
            color: isActive ? channel.tint.opacity(0.28) : .clear,
            radius: isActive ? 10 : 0,
            y: isActive ? 3 : 0
        )
        .opacity(isLocked ? 0.84 : (isActive ? 1 : 0.82))
        .scaleEffect(isActive ? 1 : 0.985, anchor: .center)
        .animation(.easeInOut(duration: 0.18), value: state.isMuted)
        .animation(.easeInOut(duration: 0.18), value: state.autoVariationEnabled)
    }

    private var borderStyle: AnyShapeStyle {
        if isActive {
            return AnyShapeStyle(channel.tint.opacity(0.70))
        }
        return AnyShapeStyle(Color.white.opacity(0.05))
    }

    // MARK: - Identity row (tap to open detail sheet)

    private var identityRow: some View {
        Button {
            onOpenDetail(channel)
        } label: {
            HStack(alignment: .center, spacing: 6) {
                Text(channel.localizedName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(identityForeground)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if !channel.location.fullLabel.isEmpty {
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.30))

                    // Location reads "Region, Country". Falls back to a smooth horizontal
                    // marquee when the full label does not fit in the remaining width.
                    MarqueeText(
                        text: channel.location.fullLabel,
                        font: .system(size: 11, weight: .regular, design: .rounded),
                        foregroundStyle: locationForeground
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(0)
                }

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
                        .fixedSize(horizontal: true, vertical: false)
                }

                Image(systemName: "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.30))
                    .fixedSize(horizontal: true, vertical: false)
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
            // Coloured wash that clearly signals "this track is part of the mix".
            return channel.tint.opacity(state.autoVariationEnabled ? 0.26 : 0.20)
        }
        // Inactive rows stay almost colorless — the faint white wash is enough since the
        // material itself is already lighter.
        return Color.white.opacity(state.isMuted && !isLocked ? 0.02 : 0.03)
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

/// Single-line Text that fades from left to right and, if the content overflows the
/// available width, auto-scrolls back and forth with a short pause at each end so the
/// user can read the whole label without tapping. Position is driven by `TimelineView`
/// so the animation is deterministic and pauses when the view is off-screen.
private struct MarqueeText: View {
    let text: String
    let font: Font
    let foregroundStyle: Color

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private var overflow: CGFloat {
        max(0, textWidth - containerWidth + 6)
    }

    private var needsScroll: Bool {
        overflow > 1
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !needsScroll)) { context in
                Text(text)
                    .font(font)
                    .foregroundStyle(foregroundStyle)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .preference(key: MarqueeWidthKey.self, value: textGeo.size.width)
                        }
                    )
                    .offset(x: offset(atTime: context.date.timeIntervalSinceReferenceDate))
            }
            // GeometryReader positions its content at the top-leading corner by default,
            // which left the location text anchored at the top of the row while the
            // title (at HStack centre) was vertically centred. Explicitly centre the
            // inner content vertically so the two labels share the same baseline.
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            .onAppear { containerWidth = proxy.size.width }
            .onChange(of: proxy.size.width) { _, new in containerWidth = new }
            .onPreferenceChange(MarqueeWidthKey.self) { textWidth = $0 }
        }
        .clipped()
        // Only apply the edge-fade mask while the marquee is actually scrolling; when
        // the text fits, the mask would otherwise fade the leading characters (text
        // left-aligned at x=0 sits directly under the left stop of the gradient).
        .mask {
            if needsScroll {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black, location: 0.03),
                        .init(color: .black, location: 0.97),
                        .init(color: .black.opacity(0), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                Rectangle()
            }
        }
    }

    /// Piecewise constant/linear offset computed from a monotonic time source.
    /// - Phase 1: dwell at origin (reader sees the beginning).
    /// - Phase 2: slide left until the end of the text is exposed.
    /// - Phase 3: dwell at the end.
    /// - Phase 4: slide back to the origin.
    private func offset(atTime time: TimeInterval) -> CGFloat {
        guard needsScroll else { return 0 }

        let scrollSpeed: Double = 26 // pt / second
        let scrollDuration = max(1.0, Double(overflow) / scrollSpeed)
        let dwell: Double = 1.6
        let cycle = 2 * dwell + 2 * scrollDuration
        let phase = time.truncatingRemainder(dividingBy: cycle)

        if phase < dwell {
            return 0
        }
        if phase < dwell + scrollDuration {
            let progress = (phase - dwell) / scrollDuration
            return -CGFloat(progress) * overflow
        }
        if phase < 2 * dwell + scrollDuration {
            return -overflow
        }
        let progress = (phase - 2 * dwell - scrollDuration) / scrollDuration
        return -overflow * (1 - CGFloat(progress))
    }
}

private struct MarqueeWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
