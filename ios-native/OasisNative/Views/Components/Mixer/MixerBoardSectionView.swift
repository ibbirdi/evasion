import SwiftUI
import UIKit

struct MixerBoardSectionView: View {
    @Environment(AppModel.self) private var model
    let onOpenSpatial: (SoundChannel) -> Void
    let onOpenDetail: (SoundChannel) -> Void
    @State private var showsLockedLibrary = false
    private let guidedRoutineVisibleChannelLimit = 5

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

    private var shouldShowLibraryTeaser: Bool {
        !model.isPremium
            && model.activeRitualSession == nil
            && !hasGuidedScene
    }

    private var hasGuidedScene: Bool {
        guard model.activeRitualSession == nil else { return false }
        return model.activeComposerRecipeTitle != nil || model.activeProceduralNoiseCount > 0
    }

    private var hasGuidedRoutine: Bool {
        guard model.activeRitualSession == nil else { return false }
        return model.activeComposerRecipeTitle != nil
    }

    private var channelsBeforeActiveScene: [SoundChannel] {
        guard hasGuidedScene else { return displayedChannels }
        if hasGuidedRoutine {
            return Array(guidedRoutineActiveChannels.prefix(guidedRoutineVisibleChannelLimit))
        }
        return displayedChannels.filter(model.isAmbientChannelActive(_:))
    }

    private var channelsAfterActiveScene: [SoundChannel] {
        guard hasGuidedScene else { return [] }
        guard !hasGuidedRoutine else { return [] }
        let promotedChannels = Set(channelsBeforeActiveScene)
        return displayedChannels.filter { !promotedChannels.contains($0) }
    }

    private var guidedRoutineSupportingChannels: [SoundChannel] {
        guard hasGuidedRoutine else { return [] }
        return Array(guidedRoutineActiveChannels.dropFirst(guidedRoutineVisibleChannelLimit))
    }

    private var guidedRoutineActiveChannels: [SoundChannel] {
        SoundChannel.allCases.filter(model.isAmbientChannelActive(_:))
    }

    private var shouldShowRoutineRestCue: Bool {
        hasGuidedRoutine
            && guidedRoutineSupportingChannels.isEmpty
            && channelsBeforeActiveScene.count <= 4
    }

    private var displayedNoises: [ProceduralNoise] {
        if hasGuidedRoutine || model.activeRitualSession != nil {
            return ProceduralNoise.allCases.filter(model.isProceduralNoiseActive(_:))
        }

        if model.isPremium {
            if model.showsOnlyActiveChannels {
                return ProceduralNoise.allCases.filter(model.isProceduralNoiseActive(_:))
            }
            return ProceduralNoise.allCases
        }

        let freeNoises = ProceduralNoise.allCases.filter { !$0.isPremium }

        if model.showsOnlyActiveChannels {
            return freeNoises.filter(model.isProceduralNoiseActive(_:))
        }

        let lockedNoises = ProceduralNoise.allCases.filter(\.isPremium)
        return showsLockedLibrary ? freeNoises + lockedNoises : freeNoises
    }

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(channelsBeforeActiveScene) { channel in
                SoundRowView(
                    channel: channel,
                    onOpenSpatial: onOpenSpatial,
                    onOpenDetail: onOpenDetail
                )
            }

            if !guidedRoutineSupportingChannels.isEmpty {
                GuidedRoutineSupportingLayersView(channels: guidedRoutineSupportingChannels)
                    .padding(.top, 4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }

            ForEach(channelsAfterActiveScene) { channel in
                SoundRowView(
                    channel: channel,
                    onOpenSpatial: onOpenSpatial,
                    onOpenDetail: onOpenDetail
                )
            }

            if !displayedNoises.isEmpty {
                ProceduralNoiseSectionHeader()
                    .padding(.top, 12)
                    .padding(.horizontal, 14)

                ForEach(displayedNoises) { noise in
                    ProceduralNoiseRowView(noise: noise)
                }
            }

            if shouldShowRoutineRestCue {
                GuidedRoutineRestCue()
                    .padding(.top, 18)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 104)
            }

            if shouldShowLibraryTeaser {
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

private struct ProceduralNoiseSectionHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)

            Label {
                Text(L10n.NoiseLab.title)
                    .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.54))
                    .lineLimit(1)
            } icon: {
                Image(systemName: "waveform")
                    .oasisFont(size: 10, weight: .semibold, design: .default, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.42))
                    .accessibilityHidden(true)
            }
            .labelStyle(.titleAndIcon)
            .fixedSize(horizontal: true, vertical: false)

            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("noise.section")
    }
}

private struct GuidedRoutineSupportingLayersView: View {
    let channels: [SoundChannel]

    private var title: String {
        channels.prefix(3).map(\.localizedName).joined(separator: ", ")
    }

    private var hiddenCount: Int {
        max(channels.count - 3, 0)
    }

    private var accent: Color {
        channels.first?.tint ?? AmbienceIntent.sleep.tint
    }

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: -5) {
                ForEach(Array(channels.prefix(3))) { channel in
                    OasisGlyphImage(glyph: channel.oasisGlyph)
                        .foregroundStyle(channel.tint)
                        .frame(width: 13, height: 13)
                        .frame(width: 24, height: 24)
                        .background {
                            Circle()
                                .fill(Color(red: 0.04, green: 0.055, blue: 0.085))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(channel.tint.opacity(0.28), lineWidth: 1)
                        }
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.HomeActive.routineSupportingLayers)
                    .oasisFont(size: 10, weight: .bold, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)

                Text(title)
                    .oasisFont(size: 12, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }

            Spacer(minLength: 0)

            if hiddenCount > 0 {
                Text("+\(hiddenCount)")
                    .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background {
                        Capsule(style: .continuous)
                            .fill(accent.opacity(0.12))
                    }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.045))
                .overlay {
                    LinearGradient(
                        colors: [
                            accent.opacity(0.10),
                            Color.white.opacity(0.010)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.075), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.routine.supporting-layers")
    }
}

private struct GuidedRoutineRestCue: View {
    @Environment(AppModel.self) private var model

    private var palette: [Color] {
        let playbackPalette = model.activePlaybackPalette
        if playbackPalette.isEmpty {
            return [AmbienceIntent.sleep.tint, AmbienceIntent.reset.tint]
        }
        return Array(playbackPalette.prefix(5))
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 7) {
                ForEach(Array(palette.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .fill(color.opacity(index == 0 ? 0.90 : 0.58))
                        .frame(width: index == 0 ? 7 : 5, height: index == 0 ? 7 : 5)
                        .shadow(color: color.opacity(0.22), radius: 8, y: 2)
                }
            }
            .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(L10n.HomeActive.routineRestTitle)
                    .oasisFont(size: 14, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.84)

                Text(L10n.HomeActive.routineRestSubtitle)
                    .oasisFont(size: 11, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.46))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .background(alignment: .top) {
            LinearGradient(
                colors: [
                    (palette.first ?? AmbienceIntent.sleep.tint).opacity(0.16),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 76)
            .blur(radius: 18)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("home.routine.rest-cue")
    }
}

private struct ProceduralNoiseRowView: View {
    @Environment(AppModel.self) private var model
    let noise: ProceduralNoise

    private var state: ProceduralNoiseState {
        model.proceduralNoiseState(for: noise)
    }

    private var isLocked: Bool {
        model.isProceduralNoiseLocked(noise)
    }

    private var isActive: Bool {
        !isLocked && !state.isMuted
    }

    private var title: String {
        noise.localizedName
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            identityRow
            controlsRow
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("noise.row.\(noise.id)")
        .background {
            ZStack {
                Rectangle()
                    .fill(isActive ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.thinMaterial))
                    .opacity(isActive ? 1 : 0.45)
                Rectangle()
                    .fill(backgroundGradient)
            }
        }
        .overlay {
            Rectangle()
                .strokeBorder(Color.white.opacity(isActive ? 0.07 : 0.05), lineWidth: 0.8)
        }
        .opacity(isLocked ? 0.84 : (isActive ? 1 : 0.82))
        .animation(.easeInOut(duration: 0.18), value: state.isMuted)
    }

    private var identityRow: some View {
        HStack(spacing: 8) {
            Image(systemName: noise.systemImage)
                .oasisFont(size: 12, weight: .semibold, design: .default, relativeTo: .caption)
                .foregroundStyle(isActive ? noise.tint : .white.opacity(isLocked ? 0.38 : 0.54))
                .frame(width: 18, height: 18)
                .accessibilityHidden(true)

            Text(title)
                .oasisFont(size: 13, weight: .semibold, relativeTo: .subheadline)
                .foregroundStyle(identityForeground)
                .lineLimit(1)

            Text("·")
                .oasisFont(size: 11, design: .default, relativeTo: .caption)
                .foregroundStyle(.white.opacity(0.30))

            Text(noise.localizedSubtitle)
                .oasisFont(size: 11, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.white.opacity(isLocked ? 0.32 : 0.44))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isLocked {
                Text(L10n.Mixer.statusPremium)
                    .oasisFont(size: 8, weight: .semibold, relativeTo: .caption2)
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    }
            }
        }
        .accessibilityIdentifier("noise.identity.\(noise.id)")
    }

    private var controlsRow: some View {
        HStack(spacing: 10) {
            toggleButton

            HapticSlider(
                value: Binding(
                    get: { state.volume },
                    set: { model.setProceduralNoiseVolume(noise, value: $0) }
                ),
                tint: noise.tint
            )
            .disabled(isLocked || state.isMuted)
            .opacity(sliderOpacity)
            .accessibilityIdentifier("noise.slider.\(noise.id)")
            .accessibilityLabel(Text(L10n.NoiseLab.volume))
        }
    }

    private var toggleButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .noise(noise))
            } else {
                withAnimation(.easeInOut(duration: 0.18)) {
                    model.toggleProceduralNoise(noise)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: Circle())
                    .overlay {
                        Circle()
                            .fill(isActive ? noise.tint.opacity(0.20) : Color.white.opacity(0.012))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isActive
                                    ? AnyShapeStyle(noise.tint.opacity(0.34))
                                    : AnyShapeStyle(Color.white.opacity(0.08)),
                                lineWidth: 1.1
                            )
                    }

                Image(systemName: isLocked ? "lock.fill" : noise.systemImage)
                    .oasisFont(size: 14, weight: .semibold, design: .default, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.54 : 1))
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
            .frame(width: 38, height: 38)
        }
        .oasisMinimumHitTarget()
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("noise.mute.\(noise.id)")
        .accessibilityLabel(Text(title))
        .accessibilityValue(toggleAccessibilityValue)
        .accessibilityHint(Text(L10n.Mixer.toggleSoundHint))
    }

    private var backgroundGradient: LinearGradient {
        if isActive {
            return LinearGradient(
                colors: [
                    noise.tint.opacity(0.14),
                    noise.tint.opacity(0.08),
                    Color.white.opacity(0.025)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(state.isMuted && !isLocked ? 0.026 : 0.036),
                Color.white.opacity(0.014)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var identityForeground: Color {
        if isLocked { return .white.opacity(0.65) }
        return isActive ? .white.opacity(0.98) : .white.opacity(0.80)
    }

    private var sliderOpacity: Double {
        if isLocked { return 0.28 }
        if state.isMuted { return 0.24 }
        return 1
    }

    private var toggleAccessibilityValue: Text {
        if isLocked {
            return Text(L10n.Mixer.locked)
        }
        return Text(state.isMuted ? L10n.Mixer.soundOff : L10n.Mixer.soundOn)
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

    private var usesGuidedListeningChrome: Bool {
        model.activeRitualSession == nil
            && model.activeComposerRecipeTitle != nil
            && isActive
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
            // Active rows keep a neutral translucent surface so the place photo remains
            // visible. Activity is carried by text weight and controls rather than a
            // channel-coloured wash.
            ZStack {
                Rectangle()
                    .fill(isActive ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(.thinMaterial))
                    .opacity(isActive ? 0.62 : 0.45)
                SoundBackdropImage(backdrop: channel.backdrop, opacity: backdropOpacity)
                Rectangle()
                    .fill(channelBackgroundGradient)
            }
        }
        .overlay {
            Rectangle()
                .strokeBorder(borderStyle, lineWidth: 0.8)
        }
        .opacity(isLocked ? 0.84 : (isActive ? 1 : 0.82))
        .animation(.easeInOut(duration: 0.18), value: state.isMuted)
        .animation(.easeInOut(duration: 0.18), value: state.autoVariationEnabled)
    }

    private var borderStyle: AnyShapeStyle {
        AnyShapeStyle(Color.white.opacity(isActive ? 0.07 : 0.05))
    }

    // MARK: - Identity row (tap to open detail sheet)

    private var identityRow: some View {
        Button {
            onOpenDetail(channel)
        } label: {
            HStack(alignment: .center, spacing: 6) {
                Text(channel.localizedName)
                    .oasisFont(size: 13, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(identityForeground)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                if isActive && !compactLocationLabel.isEmpty {
                    Text("·")
                        .oasisFont(size: 11, design: .default, relativeTo: .caption)
                        .foregroundStyle(.white.opacity(0.30))

                    Text(compactLocationLabel)
                        .oasisFont(size: 11, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(locationForeground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(0)
                }

                if let statusText {
                    Text(statusText)
                        .oasisFont(size: 8, weight: .semibold, relativeTo: .caption2)
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

            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("channel.identity.\(channel.id)")
        .accessibilityLabel(accessibilityIdentityLabel)
        .accessibilityHint(Text(L10n.Mixer.soundDetailsHint))
    }

    // MARK: - Controls row (mute, slider, spatial, auto)

    private var controlsRow: some View {
        HStack(spacing: 10) {
            muteButton

            Group {
                if isAutoAnimating {
                    AutoVariationRangeSlider(
                        range: Binding(
                            get: { state.autoVariationRange },
                            set: { model.setChannelAutoVariationRange(channel, range: $0) }
                        ),
                        liveValue: model.displayVolume(for: channel),
                        tint: channel.tint
                    )
                    .disabled(isLocked || state.isMuted)
                    .accessibilityIdentifier("channel.slider.\(channel.id)")
                    .accessibilityLabel(Text(L10n.Mixer.autoRange))
                    .accessibilityHint(Text(L10n.Mixer.autoRangeHint))
                } else {
                    HapticSlider(
                        value: Binding(
                            get: { model.displayVolume(for: channel) },
                            set: { model.setChannelVolume(channel, value: $0) }
                        ),
                        tint: channel.tint
                    )
                    .disabled(isLocked || state.isMuted || state.autoVariationEnabled)
                    .accessibilityIdentifier("channel.slider.\(channel.id)")
                    .accessibilityLabel(Text(L10n.Mixer.volume))
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(sliderOpacity)

            if !usesGuidedListeningChrome {
                spatialButton

                autoButton
            }
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

                OasisGlyphImage(glyph: channel.oasisGlyph)
                    .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.54 : 1))
                    .frame(width: 19, height: 19)
                    .accessibilityHidden(true)
            }
            .frame(width: 38, height: 38)
        }
        .oasisMinimumHitTarget()
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("channel.mute.\(channel.id)")
        .accessibilityLabel(Text(channel.localizedName))
        .accessibilityValue(muteAccessibilityValue)
        .accessibilityHint(Text(L10n.Mixer.toggleSoundHint))
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
                            .fill(isSpatialized ? channel.tint.opacity(0.18) : Color.white.opacity(0.008))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isSpatialized ? channel.tint.opacity(0.36) : Color.white.opacity(0.045),
                                lineWidth: 1.1
                            )
                    }

                OasisGlyphImage(glyph: .target)
                    .foregroundStyle(isSpatialized ? .white : .white.opacity(0.56))
                    .frame(width: 14, height: 14)
                    .accessibilityHidden(true)
            }
            .frame(width: 36, height: 36)
        }
        .oasisMinimumHitTarget()
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("channel.spatial.\(channel.id)")
        .accessibilityLabel(Text(L10n.Mixer.soundPlacement))
        .accessibilityHint(Text(L10n.Mixer.soundPlacementHint))
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
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: Circle())
                    .overlay {
                        Circle()
                            .fill(state.autoVariationEnabled ? channel.tint.opacity(0.18) : Color.white.opacity(0.008))
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                state.autoVariationEnabled ? channel.tint.opacity(0.36) : Color.white.opacity(0.045),
                                lineWidth: 1.1
                            )
                    }

                Image(systemName: isLocked ? "lock.fill" : "arrow.triangle.2.circlepath")
                    .oasisFont(size: 12, weight: .semibold, design: .default, relativeTo: .caption)
                    .foregroundStyle(buttonForeground)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
            .frame(width: 36, height: 36)
        }
        .oasisMinimumHitTarget()
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("channel.auto.\(channel.id)")
        .accessibilityLabel(Text(L10n.Mixer.autoVariation))
        .accessibilityValue(Text(state.autoVariationEnabled ? L10n.Mixer.enabled : L10n.Mixer.disabled))
    }

    // MARK: - Derived styling

    private var identityForeground: Color {
        if isLocked { return .white.opacity(0.65) }
        return isActive ? .white.opacity(0.98) : .white.opacity(0.80)
    }

    private var locationForeground: Color {
        if isLocked { return .white.opacity(0.32) }
        return .white.opacity(0.44)
    }

    private var compactLocationLabel: String {
        channel.location.rowLabel
    }

    private var statusBackground: Color {
        if isLocked { return Color.white.opacity(0.06) }
        if isActive { return Color.white.opacity(0.06) }
        return Color.white.opacity(0.04)
    }

    private var secondaryTint: Color {
        if isLocked { return .white.opacity(0.48) }
        return isActive ? .white.opacity(0.70) : .white.opacity(0.44)
    }

    private var sliderOpacity: Double {
        if isLocked { return 0.28 }
        if state.isMuted { return 0.24 }
        if isAutoAnimating { return 1 }
        if state.autoVariationEnabled { return 0.80 }
        return 1
    }

    private var backdropOpacity: Double {
        if isLocked { return 0.055 }
        if isActive { return state.autoVariationEnabled ? 0.32 : 0.30 }
        return 0.085
    }

    private var channelBackgroundGradient: LinearGradient {
        if isActive {
            return LinearGradient(
                colors: [
                    Color.black.opacity(0.030),
                    Color.white.opacity(0.018)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(state.isMuted && !isLocked ? 0.026 : 0.036),
                Color.white.opacity(0.014)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var buttonForeground: Color {
        if isLocked { return .white.opacity(0.72) }
        return state.autoVariationEnabled ? .white : .white.opacity(0.56)
    }

    private var muteAccessibilityValue: Text {
        if isLocked {
            return Text(L10n.Mixer.locked)
        }
        return Text(state.isMuted ? L10n.Mixer.soundOff : L10n.Mixer.soundOn)
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

private extension ProceduralNoise {
    var localizedName: String {
        switch self {
        case .white: return L10n.string(L10n.NoiseLab.white)
        case .brown: return L10n.string(L10n.NoiseLab.brown)
        case .pink: return L10n.string(L10n.NoiseLab.pink)
        case .green: return L10n.string(L10n.NoiseLab.green)
        case .fan: return L10n.string(L10n.NoiseLab.fan)
        case .aircraft: return L10n.string(L10n.NoiseLab.aircraft)
        }
    }

    var localizedSubtitle: String {
        switch self {
        case .white: return L10n.string(L10n.NoiseLab.whiteSubtitle)
        case .brown: return L10n.string(L10n.NoiseLab.brownSubtitle)
        case .pink: return L10n.string(L10n.NoiseLab.pinkSubtitle)
        case .green: return L10n.string(L10n.NoiseLab.greenSubtitle)
        case .fan: return L10n.string(L10n.NoiseLab.fanSubtitle)
        case .aircraft: return L10n.string(L10n.NoiseLab.aircraftSubtitle)
        }
    }
}
