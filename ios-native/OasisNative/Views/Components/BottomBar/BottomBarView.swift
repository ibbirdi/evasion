import SwiftUI

private enum BottomToolbarStyle {
    static let sideButtonSize: CGFloat = 44
    static let playbackButtonSize: CGFloat = 58
    static let borderWidth: CGFloat = 1
    static let inactiveBorderOpacity: Double = 0.08
    static let activeBorderOpacity: Double = 0.34
}

struct BottomToolbarItemLabel: View {
    let glyph: OasisGlyph?
    let systemImage: String?
    let tint: Color
    let isActivated: Bool
    let palette: [Color]

    init(systemImage: String, tint: Color, isActivated: Bool, palette: [Color]) {
        self.glyph = nil
        self.systemImage = systemImage
        self.tint = tint
        self.isActivated = isActivated
        self.palette = palette
    }

    init(glyph: OasisGlyph, tint: Color, isActivated: Bool, palette: [Color]) {
        self.glyph = glyph
        self.systemImage = nil
        self.tint = tint
        self.isActivated = isActivated
        self.palette = palette
    }

    var body: some View {
        icon
            .foregroundStyle(isActivated ? .white : .white.opacity(0.66))
            .frame(width: BottomToolbarStyle.sideButtonSize, height: BottomToolbarStyle.sideButtonSize)
            .background {
                Circle()
                    .fill(isActivated ? tint.opacity(0.18) : Color.white.opacity(0.001))
                    .oasisGlassEffect(in: Circle())
            }
            .overlay {
                Circle()
                    .strokeBorder(activeBorderStyle, lineWidth: BottomToolbarStyle.borderWidth)
            }
            .contentShape(Circle())
            .animation(.smooth(duration: 0.22), value: isActivated)
    }

    @ViewBuilder
    private var icon: some View {
        if let glyph {
            OasisGlyphImage(glyph: glyph)
                .frame(width: 20, height: 20)
        } else {
            Image(systemName: systemImage ?? "circle")
                .oasisFont(size: 18, weight: .semibold, design: .default, relativeTo: .body)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var activeBorderStyle: AnyShapeStyle {
        if isActivated {
            AnyShapeStyle(tint.opacity(BottomToolbarStyle.activeBorderOpacity))
        } else {
            AnyShapeStyle(Color.white.opacity(BottomToolbarStyle.inactiveBorderOpacity))
        }
    }
}

private struct BottomToolbarGlassRail: View {
    var body: some View {
        Capsule(style: .continuous)
            .fill(Color.white.opacity(0.001))
            .oasisGlassEffect(in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.050),
                                Color.white.opacity(0.018)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(Color.white.opacity(0.115), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.26), radius: 22, y: 12)
    }
}

struct PlaybackToolbarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        // Compute the palette once per body pass instead of three times
        // (aura input, animationKey, border gradient) — each pass iterates all channels.
        let palette = model.activePlaybackPalette

        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            .oasisFont(size: 24, weight: .bold, design: .default, relativeTo: .title3)
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .shadow(
                color: .black.opacity(model.isPlaying ? 0.26 : 0.12),
                radius: model.isPlaying ? 4 : 2,
                y: model.isPlaying ? 1.5 : 1
            )
            .symbolEffect(.bounce, value: model.isPlaying)
            .frame(width: BottomToolbarStyle.playbackButtonSize, height: BottomToolbarStyle.playbackButtonSize)
            .background {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .oasisGlassEffect(in: Circle())
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(model.isPlaying ? 0.04 : 0.022))
                        }

                    if model.isPlaying {
                        AnimatedLiquidAura(
                            palette: palette,
                            shape: Circle(),
                            intensity: 0.78,
                            blurRadius: 5,
                            baseBlendOpacity: 0.04,
                            speedMultiplier: 2.65,
                            frameRate: 24,
                            isAnimated: true,
                            animationKey: "playback-\(model.isPlaying)-\(palette.count)",
                            coverage: 1.05,
                            accentMixAmount: 0.0,
                            colorSeparation: 4.2
                        )
                        .padding(1)
                    }

                    Circle()
                        .fill(model.isPlaying ? Color.white.opacity(0.05) : Color.clear)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(borderStyle(for: palette), lineWidth: BottomToolbarStyle.borderWidth)
            }
            .shadow(
                color: (palette.first ?? .white).opacity(model.isPlaying ? 0.18 : 0.0),
                radius: model.isPlaying ? 14 : 0,
                y: model.isPlaying ? 6 : 0
            )
            .animation(.smooth(duration: 0.22), value: model.isPlaying)
    }

    private func borderStyle(for palette: [Color]) -> AnyShapeStyle {
        guard model.isPlaying else {
            return AnyShapeStyle(Color.white.opacity(BottomToolbarStyle.inactiveBorderOpacity))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: palette.map { $0.opacity(BottomToolbarStyle.activeBorderOpacity) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct BottomBarView: View {
    @Environment(AppModel.self) private var model
    let transitionNamespace: Namespace.ID
    let onOpenCompose: (PanelTransitionSource) -> Void
    let onOpenBinaural: (PanelTransitionSource) -> Void

    private var isSavedAmbienceActive: Bool {
        model.activeRitualSession == nil && model.activeComposerRecipeTitle != nil
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            barContent
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background { BottomToolbarGlassRail() }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var barContent: some View {
        if isSavedAmbienceActive {
            HStack(spacing: 12) {
                playbackButton

                routePickerButton
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            HStack(spacing: 8) {
                composeButton

                shuffleButton

                playbackButton

                binauralButton

                routePickerButton
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        }
    }

    private var playbackButton: some View {
        Button {
            model.togglePlayback()
        } label: {
            PlaybackToolbarLabel()
        }
        .accessibilityIdentifier("home.bottom.playback")
        .accessibilityLabel(Text(model.isPlaying ? L10n.HomeControls.pause : L10n.HomeControls.play))
        .buttonStyle(PressScaleButtonStyle())
    }

    private var routePickerButton: some View {
        RoutePickerView()
            .frame(width: 20, height: 20)
            .foregroundStyle(.white.opacity(0.66))
            .padding(12)
            .accessibilityIdentifier("home.bottom.routepicker")
            .accessibilityLabel(Text(L10n.HomeControls.routePicker))
            .background {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: Circle())
                    .overlay {
                        Circle()
                            .fill(Color.white.opacity(0.012))
                    }
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        Color.white.opacity(BottomToolbarStyle.inactiveBorderOpacity),
                        lineWidth: BottomToolbarStyle.borderWidth
                    )
            }
            .contentShape(Circle())
    }

    @ViewBuilder
    private var composeButton: some View {
        let button = Button {
            onOpenCompose(.bottomCompose)
        } label: {
            BottomToolbarItemLabel(
                glyph: composeButtonGlyph,
                tint: composeButtonTint,
                isActivated: composeButtonIsActivated,
                palette: composeButtonPalette
            )
        }
        .accessibilityIdentifier("home.bottom.compose")
        .accessibilityLabel(Text(composeButtonAccessibilityLabel))
        .accessibilityValue(Text(composeStatusLabel ?? ""))
        .buttonStyle(PressScaleButtonStyle())
        .animation(.smooth(duration: 0.22), value: composeStatusLabel)
        .animation(.smooth(duration: 0.22), value: model.activeRitualSession?.ritualID)

        if #available(iOS 26.0, *) {
            button.matchedTransitionSource(id: PanelTransitionSource.bottomCompose.transitionID, in: transitionNamespace) { source in
                source
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        } else {
            button
        }
    }

    private var composeStatusLabel: String? {
        guard model.activeRitualSession == nil else { return nil }

        if let activeComposerRecipeTitle = model.activeComposerRecipeTitle {
            return activeComposerRecipeTitle
        }

        return model.activeNoiseBlendTitle
    }

    private var composeButtonGlyph: OasisGlyph {
        if let activeRitualSession = model.activeRitualSession {
            return activeRitualSession.intent.oasisGlyph
        }

        if model.activeComposerRecipeTitle != nil {
            return .sparkle
        }

        if model.activeNoiseBlendTitle != nil {
            return .waveform
        }

        return .sparkle
    }

    private var composeButtonTint: Color {
        if let activeRitualSession = model.activeRitualSession {
            return activeRitualSession.intent.tint
        }

        if model.activeComposerRecipeTitle != nil {
            return model.activePlaybackPalette.first ?? AmbienceIntent.sleep.tint
        }

        return activeNoiseTints.first ?? AmbienceIntent.reset.tint
    }

    private var composeButtonPalette: [Color] {
        if let activeRitualSession = model.activeRitualSession {
            return [activeRitualSession.intent.tint, .white.opacity(0.72)]
        }

        if model.activeComposerRecipeTitle != nil {
            return model.activePlaybackPalette
        }

        if model.activeNoiseBlendTitle != nil, !activeNoiseTints.isEmpty {
            return Array(activeNoiseTints.prefix(2)) + [.white.opacity(0.72)]
        }

        return [AmbienceIntent.sleep.tint, AmbienceIntent.focus.tint, AmbienceIntent.reset.tint]
    }

    private var activeNoiseTints: [Color] {
        ProceduralNoise.allCases.compactMap { noise in
            model.isProceduralNoiseActive(noise) ? noise.tint : nil
        }
    }

    private var composeButtonIsActivated: Bool {
        model.showsComposePanel
            || model.activeRitualSession != nil
            || model.activeComposerRecipeTitle != nil
            || model.activeNoiseBlendTitle != nil
    }

    private var composeButtonAccessibilityLabel: LocalizedStringResource {
        model.activeRitualSession == nil ? L10n.HomeControls.compose : L10n.HomeControls.activeRitual
    }

    private var shuffleButton: some View {
        Button {
            model.randomizeMix()
        } label: {
            BottomToolbarItemLabel(
                systemImage: "shuffle",
                tint: AmbienceIntent.reset.tint,
                isActivated: false,
                palette: [AmbienceIntent.sleep.tint, AmbienceIntent.focus.tint, AmbienceIntent.reset.tint]
            )
        }
        .accessibilityIdentifier("home.bottom.shuffle")
        .accessibilityLabel(Text(L10n.HomeControls.shuffle))
        .buttonStyle(PressScaleButtonStyle())
    }

    @ViewBuilder
    private var binauralButton: some View {
        let button = Button {
            onOpenBinaural(.bottomBinaural)
        } label: {
            BottomToolbarItemLabel(
                glyph: .waveform,
                tint: model.activeBinauralTrack.tint,
                isActivated: model.isBinauralActive,
                palette: LiquidActivityPalette.binaural(for: model.activeBinauralTrack.tint)
            )
        }
        .accessibilityIdentifier("home.bottom.binaural")
        .accessibilityLabel(Text(L10n.HomeControls.binaural))
        .buttonStyle(PressScaleButtonStyle())

        if #available(iOS 26.0, *) {
            button.matchedTransitionSource(id: PanelTransitionSource.bottomBinaural.transitionID, in: transitionNamespace) { source in
                // 48pt button with cornerRadius == half = perfect circle. The previous
                // value of 26 overshot the half-size, leaving a slightly bulged outline
                // after the sheet transition finished.
                source
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        } else {
            button
        }
    }
}
