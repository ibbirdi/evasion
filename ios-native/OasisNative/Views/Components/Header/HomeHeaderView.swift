import SwiftUI

/// Floating header, rendered above the home backdrop inside the ZStack. Reduced to the
/// animated brand lockup after the per-surface chips moved to the navigation bar's
/// native toolbar.
struct HomeHeaderView: View {
    let compactProgress: CGFloat

    private var logoVisibility: CGFloat {
        max(0, 1 - (compactProgress * 3.4))
    }

    var body: some View {
        BrandLockupView(visibility: logoVisibility)
            .padding(.vertical, max(2, 6 - compactProgress * 4))
            .frame(maxWidth: .infinity)
            .animation(.smooth(duration: 0.22), value: compactProgress)
    }
}

private struct BrandLockupView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let visibility: CGFloat

    private static let logoScale: CGFloat = 0.84
    private static let lockupSize: CGFloat = 158 * logoScale
    private static let visualCanvasSize: CGFloat = 208 * logoScale
    private static let ringSize: CGFloat = 118 * logoScale
    private static let verticalOffset: CGFloat = -30 * logoScale
    private static let expandedHeightCap: CGFloat = 165 * logoScale
    private static let showsLogoRings = false

    var body: some View {
        ZStack {
            if Self.showsLogoRings {
                ZStack {
                    RotatingOasisLogoRing(
                        isPlaying: model.isPlaying,
                        reduceMotion: reduceMotion,
                        rotationDirection: -1,
                        initialRotationDegrees: 118
                    )
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .saturation(1.14)
                    .contrast(1.02)
                    .opacity(0.56)
                    .blendMode(.plusLighter)
                    .accessibilityHidden(true)

                    RotatingOasisLogoRing(
                        isPlaying: model.isPlaying,
                        reduceMotion: reduceMotion,
                        rotationDirection: 1,
                        initialRotationDegrees: 0
                    )
                    .frame(width: Self.ringSize, height: Self.ringSize)
                    .saturation(1.14)
                    .contrast(1.02)
                    .opacity(0.56)
                    .blendMode(.plusLighter)
                    .accessibilityHidden(true)
                }
                .compositingGroup()
                .brightness(-0.14)
            }

            HomeMixConstellationView(
                nodes: mixConstellationNodes,
                isPlaying: model.isPlaying,
                reduceMotion: reduceMotion
            )
            .frame(width: 150, height: 150)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            OasisHeaderWordmark()
        }
        .frame(width: Self.visualCanvasSize, height: Self.visualCanvasSize)
        .offset(y: Self.verticalOffset)
        .frame(width: Self.lockupSize, height: Self.lockupSize, alignment: .top)
        // `maxHeight` (not a fixed `height`) lets the full lockup render at
        // rest while the cap still collapses to 0 when the user scrolls.
        .frame(maxHeight: Self.expandedHeightCap * visibility, alignment: .top)
        .opacity(visibility)
        .scaleEffect(0.92 + (visibility * 0.08), anchor: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.App.title)
        .animation(.smooth(duration: 0.18), value: visibility)
    }

    private var mixConstellationNodes: [HomeMixConstellationNode] {
        let ambientNodes = SoundChannel.allCases.enumerated().compactMap { index, channel -> HomeMixConstellationNode? in
            guard model.isAmbientChannelActive(channel) else { return nil }
            let volume = model.channelState(for: channel).volume
            return HomeMixConstellationNode(
                id: "channel-\(channel.id)",
                tint: channel.tint,
                size: 5.8 + CGFloat(volume) * 4.2,
                phase: Double(index) * 0.73
            )
        }

        let noiseNodes = ProceduralNoise.allCases.enumerated().compactMap { index, noise -> HomeMixConstellationNode? in
            guard model.isProceduralNoiseActive(noise) else { return nil }
            let volume = model.proceduralNoises[noise]?.volume ?? 0.42
            return HomeMixConstellationNode(
                id: "noise-\(noise.id)",
                tint: noise.tint,
                size: 6.6 + CGFloat(volume) * 4.4,
                phase: 1.35 + Double(index) * 0.82
            )
        }

        let binauralNodes: [HomeMixConstellationNode]
        if model.isBinauralActive {
            binauralNodes = [
                HomeMixConstellationNode(
                    id: "binaural-\(model.activeBinauralTrack.id)",
                    tint: model.activeBinauralTrack.tint,
                    size: 7.0 + CGFloat(model.binauralVolume) * 4.0,
                    phase: 2.15
                )
            ]
        } else {
            binauralNodes = []
        }

        return Array((ambientNodes + noiseNodes + binauralNodes).prefix(9))
    }
}

private struct HomeMixConstellationNode: Identifiable {
    let id: String
    let tint: Color
    let size: CGFloat
    let phase: Double
}

private struct HomeMixConstellationView: View {
    let nodes: [HomeMixConstellationNode]
    let isPlaying: Bool
    let reduceMotion: Bool

    private static let trailSegments = 44
    private static let baseAngularSpeed = 0.48

    var body: some View {
        if !nodes.isEmpty {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: freezesMotion)) { context in
                let time = animatedTime(from: context.date)

                Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: true) { context, size in
                    context.blendMode = .plusLighter
                    for (index, node) in nodes.enumerated() {
                        drawMeteor(
                            node: node,
                            index: index,
                            total: nodes.count,
                            time: time,
                            in: &context,
                            canvasSize: size
                        )
                    }
                }
                .opacity(isPlaying ? 0.92 : 0)
                .animation(.smooth(duration: isPlaying ? 0.32 : 0.72), value: isPlaying)
                .drawingGroup(opaque: false, colorMode: .linear)
            }
            .transition(.opacity)
        }
    }

    private var freezesMotion: Bool {
        reduceMotion || AppConfiguration.isRunningScreenshotAutomation
    }

    private func animatedTime(from date: Date) -> Double {
        freezesMotion ? 0 : date.timeIntervalSinceReferenceDate
    }

    private func drawMeteor(
        node: HomeMixConstellationNode,
        index: Int,
        total: Int,
        time: Double,
        in context: inout GraphicsContext,
        canvasSize: CGSize
    ) {
        let head = trajectoryPoint(
            for: node,
            index: index,
            total: total,
            time: time,
            canvasSize: canvasSize
        )
        let pulse = pulse(for: node, time: time)
        let headWidth = 1.25 + node.size * 0.10
        let headDiameter = 1.8 + node.size * 0.16
        let trailDuration = (0.86 + Double(node.size) * 0.022) * 2.45
        let meteorOpacity = 0.78 + pulse * 0.18

        for segment in stride(from: Self.trailSegments - 1, through: 0, by: -1) {
            let newerAge = Double(segment) / Double(Self.trailSegments) * trailDuration
            let olderAge = Double(segment + 1) / Double(Self.trailSegments) * trailDuration
            let youngerPoint = trajectoryPoint(
                for: node,
                index: index,
                total: total,
                time: time - newerAge,
                canvasSize: canvasSize
            )
            let olderPoint = trajectoryPoint(
                for: node,
                index: index,
                total: total,
                time: time - olderAge,
                canvasSize: canvasSize
            )

            let age = (newerAge + olderAge) / 2
            let life = max(0, 1 - age / trailDuration)
            let opacity = pow(life, 1.7) * meteorOpacity
            let width = max(0.42, headWidth * (0.28 + CGFloat(pow(life, 1.08)) * 0.96))
            let isHeadSegment = segment == 0

            strokeTrailSegment(
                from: olderPoint,
                to: youngerPoint,
                tint: node.tint,
                opacity: opacity,
                lineWidth: width,
                roundsHead: isHeadSegment,
                in: &context
            )
        }

        let glowRadius = headDiameter * (2.8 + CGFloat(pulse) * 0.45)
        let glowRect = CGRect(
            x: head.x - glowRadius,
            y: head.y - glowRadius,
            width: glowRadius * 2,
            height: glowRadius * 2
        )
        context.fill(
            Path(ellipseIn: glowRect),
            with: .radialGradient(
                Gradient(stops: [
                    Gradient.Stop(color: node.tint.opacity(0.36), location: 0.0),
                    Gradient.Stop(color: node.tint.opacity(0.16), location: 0.36),
                    Gradient.Stop(color: node.tint.opacity(0.0), location: 1.0)
                ]),
                center: head,
                startRadius: 0,
                endRadius: glowRadius
            )
        )

        context.fill(
            Path(ellipseIn: CGRect(
                x: head.x - headDiameter / 2,
                y: head.y - headDiameter / 2,
                width: headDiameter,
                height: headDiameter
            )),
            with: .color(node.tint.opacity(0.90))
        )

        let coreSize = max(1.0, headDiameter * 0.36)
        context.fill(
            Path(ellipseIn: CGRect(
                x: head.x - coreSize / 2,
                y: head.y - coreSize / 2,
                width: coreSize,
                height: coreSize
            )),
            with: .color(.white.opacity(0.70))
        )
    }

    private func strokeTrailSegment(
        from olderPoint: CGPoint,
        to youngerPoint: CGPoint,
        tint: Color,
        opacity: Double,
        lineWidth: CGFloat,
        roundsHead: Bool,
        in context: inout GraphicsContext
    ) {
        var segmentPath = Path()
        segmentPath.move(to: olderPoint)
        segmentPath.addLine(to: youngerPoint)
        let cap: CGLineCap = roundsHead ? .round : .butt

        context.stroke(
            segmentPath,
            with: .color(tint.opacity(opacity * 0.16)),
            style: StrokeStyle(lineWidth: lineWidth * 3.4, lineCap: cap, lineJoin: .round)
        )
        context.stroke(
            segmentPath,
            with: .color(tint.opacity(opacity * 0.72)),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: cap, lineJoin: .round)
        )
        context.stroke(
            segmentPath,
            with: .color(.white.opacity(opacity * 0.08)),
            style: StrokeStyle(lineWidth: max(lineWidth * 0.32, 0.40), lineCap: cap)
        )
    }

    private func trajectoryPoint(
        for node: HomeMixConstellationNode,
        index: Int,
        total: Int,
        time: Double,
        canvasSize: CGSize
    ) -> CGPoint {
        let angle = angle(for: index, total: total, node: node, time: time)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let orbit = roundedWordmarkOrbitPoint(
            angle: angle,
            index: index,
            node: node,
            time: time
        )
        return CGPoint(
            x: center.x + orbit.x,
            y: center.y + orbit.y
        )
    }

    private func angle(for index: Int, total: Int, node: HomeMixConstellationNode, time: Double) -> CGFloat {
        let base = (Double(index) / Double(max(total, 1))) * 2.0 * Double.pi - Double.pi / 2.0
        let speed = Self.baseAngularSpeed + Double(index % 4) * 0.026 + sin(node.phase) * 0.012
        return CGFloat(base + time * speed)
    }

    private func roundedWordmarkOrbitPoint(
        angle: CGFloat,
        index: Int,
        node: HomeMixConstellationNode,
        time: Double
    ) -> CGPoint {
        let lane = CGFloat(index % 3) * 4.2
        let breath = CGFloat(sin(time * 1.42 + node.phase)) * (2.0 + node.size * 0.05)
        let drift = CGFloat(sin(time * 0.54 + node.phase * 0.7)) * 1.1
        let horizontalRadius = 55 + lane + breath
        let verticalRadius = 31 + lane * 0.50 + drift

        return CGPoint(
            x: cos(angle) * horizontalRadius,
            y: sin(angle) * verticalRadius
        )
    }

    private func pulse(for node: HomeMixConstellationNode, time: Double) -> Double {
        freezesMotion ? 0 : (sin(time * 2.0 + node.phase) + 1.0) / 2.0
    }
}

private struct OasisHeaderWordmark: View {
    private static let letters: [(id: Int, value: String)] = [
        (0, "O"),
        (1, "A"),
        (2, "S"),
        (3, "I"),
        (4, "S")
    ]
    private static let logoScale: CGFloat = 0.82

    var body: some View {
        HStack(spacing: 3 * Self.logoScale) {
            ForEach(Self.letters, id: \.id) { letter in
                Text(verbatim: letter.value)
            }
        }
        .oasisFont(size: 18 * Self.logoScale, weight: .semibold, design: .default, relativeTo: .title3)
        .foregroundStyle(.white.opacity(0.98))
        .shadow(color: .black.opacity(0.45), radius: 7, x: 0, y: 2)
    }
}

private struct RotatingOasisLogoRing: View {
    let isPlaying: Bool
    let reduceMotion: Bool
    let rotationDirection: Double
    let initialRotationDegrees: Double

    @State private var rotationAccumulator = RingRotationAccumulator()

    private static let idleDegreesPerSecond: Double = 4.2
    private static let playbackDegreesPerSecond: Double = 13.0

    var body: some View {
        let shouldPause = AppConfiguration.isRunningScreenshotAutomation || reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: shouldPause)) { context in
            let now = context.date.timeIntervalSinceReferenceDate
            let speed = isPlaying ? Self.playbackDegreesPerSecond : Self.idleDegreesPerSecond
            let rotation = rotationAccumulator.advance(
                to: now,
                degreesPerSecond: speed * rotationDirection,
                paused: shouldPause
            )

            OasisLogoRingArtwork()
                .rotationEffect(.degrees(rotation + initialRotationDegrees))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct OasisLogoRingArtwork: View {
    var body: some View {
        Image("OasisRingLogo")
            .resizable()
            .scaledToFit()
            .saturation(1.08)
            .contrast(1.04)
            .shadow(color: Color(red: 0.32, green: 0.92, blue: 1.0).opacity(0.28), radius: 8)
            .shadow(color: Color(red: 1.0, green: 0.61, blue: 0.20).opacity(0.22), radius: 8)
            .opacity(0.96)
    }
}

/// Reference-typed integrator owned by `RotatingOasisLogoRing`. It keeps the ring's
/// angle continuous when playback changes speed and when animations pause for tests or
/// Reduce Motion.
private final class RingRotationAccumulator {
    private var angle: Double = 0
    private var lastTime: TimeInterval = -1

    func advance(to now: TimeInterval, degreesPerSecond: Double, paused: Bool) -> Double {
        guard !paused else {
            lastTime = now
            return angle
        }

        guard lastTime > 0, now > lastTime else {
            lastTime = now
            return angle
        }

        let dt = min(now - lastTime, 0.5)
        angle += dt * degreesPerSecond
        if angle > 360 {
            angle = angle.truncatingRemainder(dividingBy: 360)
        } else if angle < -360 {
            angle = angle.truncatingRemainder(dividingBy: 360)
        }
        lastTime = now
        return angle
    }
}

// MARK: - Native toolbar items

struct HomeToolbarImmersiveAudioToggle: View {
    @Environment(AppModel.self) private var model

    private static let activeAccent = Color(red: 0.58, green: 0.78, blue: 1.0)

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                model.toggleImmersiveAudio()
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .symbolRenderingMode(.hierarchical)

                if model.immersiveAudioEnabled && model.activeComposerRecipeTitle == nil && model.activeRitualSession == nil {
                    Text(L10n.Header.immersiveSound)
                        .oasisFont(size: 11, weight: .semibold, relativeTo: .caption)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .transition(.opacity)
                }
            }
            .foregroundStyle(model.immersiveAudioEnabled ? Self.activeAccent : .white.opacity(0.86))
        }
        .accessibilityIdentifier("home.header.immersive")
        .accessibilityLabel(Text(L10n.Header.immersive))
        .accessibilityValue(Text(model.immersiveAudioEnabled ? L10n.Header.immersiveEnabled : L10n.Header.immersiveDisabled))
        .accessibilityAddTraits(model.immersiveAudioEnabled ? .isSelected : [])
    }
}

/// Sleep-timer picker, rendered as a native nav-bar Menu. Icon-only label; the live
/// countdown is shown separately on the leading side of the nav bar
/// (`HomeToolbarTimerCountdown`) because SwiftUI strips the title from `Menu` labels
/// inside a toolbar.
struct HomeToolbarTimerMenu: View {
    @Environment(AppModel.self) private var model
    let onRequestPremiumTimer: () -> Void

    /// Warm yellow used to signal an active timer — picked to read clearly against the
    /// dark playback backdrop while staying tonally close to the mint accent used by
    /// `HomeToolbarActiveFilter`.
    static let activeAccent = Color(red: 0.99, green: 0.84, blue: 0.41)

    var body: some View {
        Menu {
            timerAction(L10n.timerOptionLabel(minutes: nil), minutes: nil)
            timerAction(L10n.timerOptionLabel(minutes: 15), minutes: 15)
            timerAction(L10n.timerOptionLabel(minutes: 30), minutes: 30)
            timerAction(L10n.timerOptionLabel(minutes: 60), minutes: 60)
            timerAction(L10n.timerOptionLabel(minutes: 120), minutes: 120)
        } label: {
            Image(systemName: "timer")
                .foregroundStyle(model.timerDurationMinutes != nil
                    ? Self.activeAccent
                    : .white.opacity(0.86))
        }
        .menuIndicator(.hidden)
        .accessibilityIdentifier("home.header.timer")
        .accessibilityLabel(Text(L10n.Header.timer))
    }

    private func timerAction(_ title: String, minutes: Int?) -> some View {
        Button(title) {
            withAnimation(.smooth(duration: 0.22)) {
                if model.canUseTimer(minutes: minutes) {
                    model.setTimer(minutes)
                } else {
                    onRequestPremiumTimer()
                }
            }
        }
    }
}

/// Live countdown shown at the leading edge of the home header while a sleep timer is
/// set. Rendered as plain overlay text (not a `ToolbarItem`) so iOS 26's Liquid Glass
/// doesn't wrap it in a button-shaped capsule.
struct TimerCountdownIndicator: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.timerDurationMinutes != nil {
            Text(model.timerToolbarTitle)
                .oasisFont(size: 11, weight: .medium, relativeTo: .caption)
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.78))
                .contentTransition(.numericText(countsDown: true))
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("home.header.timer.countdown")
        }
    }
}

/// Compact passive feedback for active ambiences. It keeps the current ambience name and
/// timer visible without inserting another control into the mixer itself.
struct HomeAmbienceStatusIndicator: View {
    @Environment(AppModel.self) private var model
    var action: (() -> Void)?

    private var accent: Color {
        model.activePlaybackPalette.first ?? AmbienceIntent.reset.tint
    }

    var body: some View {
        if let title = model.activeComposerRecipeTitle {
            HStack(spacing: 7) {
                if let action {
                    Button(action: action) {
                        statusContent(title: title, showsDisclosure: true)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityAddTraits(.isButton)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(accessibilityLabel(title: title)))
                    .accessibilityIdentifier("home.ambience.status")
                } else {
                    statusContent(title: title, showsDisclosure: false)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(accessibilityLabel(title: title)))
                        .accessibilityIdentifier("home.ambience.status")
                }

                Button {
                    withAnimation(.smooth(duration: 0.24)) {
                        model.stopActiveAmbience()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .oasisFont(size: 10, weight: .bold, design: .default, relativeTo: .caption)
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(width: 30, height: 30)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.001))
                                .oasisGlassEffect(in: Circle())
                                .overlay {
                                    Circle()
                                        .fill(Color(red: 0.035, green: 0.050, blue: 0.090).opacity(0.46))
                                }
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(accent.opacity(0.22), lineWidth: 1)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(Text(L10n.HomeActive.stopAmbience))
                .accessibilityIdentifier("home.ambience.stop")
            }
        } else {
            TimerCountdownIndicator()
        }
    }

    private func statusContent(title: String, showsDisclosure: Bool) -> some View {
        HStack(spacing: 9) {
            OasisGlyphImage(glyph: .sparkle)
                .foregroundStyle(accent)
                .frame(width: 13, height: 13)
                .frame(width: 25, height: 25)
                .background {
                    Circle()
                        .fill(accent.opacity(0.14))
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(L10n.HomeActive.activeAmbience)
                    .oasisFont(size: 9, weight: .bold, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(1)

                Text(verbatim: title)
                    .oasisFont(size: 12, weight: .semibold, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.90))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }

            if model.timerDurationMinutes != nil {
                Text(model.timerToolbarTitle)
                    .oasisFont(size: 12, weight: .semibold, relativeTo: .caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.78))
                    .contentTransition(.numericText(countsDown: true))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.leading, 2)
            }

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .oasisFont(size: 9, weight: .bold, design: .default, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(0.38))
                    .accessibilityHidden(true)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, showsDisclosure ? 10 : 12)
        .frame(height: 38)
        .frame(maxWidth: 244)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .fill(Color(red: 0.035, green: 0.050, blue: 0.090).opacity(0.42))
                }
        }
    }

    private func accessibilityLabel(title: String) -> String {
        let base = "\(L10n.string(L10n.HomeActive.activeAmbience)), \(title)"
        if model.timerDurationMinutes != nil {
            return "\(base), \(model.timerToolbarTitle)"
        }
        return base
    }
}

/// Toggles "show only audible channels". Native nav-bar button; tint turns mint green
/// when the filter is on. Carries a small numeric badge in the top-trailing corner of
/// the icon showing how many channels are currently audible — same pattern Apple uses
/// for selection counts in Photos and filter indicators in Mail.
///
/// We use a manual overlay rather than SwiftUI's `.badge(_:)` modifier because the latter
/// only attaches badges to `ToolbarItem` from iOS 26 (Liquid Glass) onwards. The overlay
/// renders identically across the iOS 18 baseline and iOS 26+, and avoids a version
/// branch.
struct HomeToolbarActiveFilter: View {
    @Environment(AppModel.self) private var model

    private static let activeAccent = Color(red: 0.54, green: 0.88, blue: 0.70)

    private var isActivated: Bool {
        model.showsOnlyActiveChannels
    }

    private var count: Int {
        model.activeAmbientChannelsCount
    }

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.26, extraBounce: 0.02)) {
                model.showsOnlyActiveChannels.toggle()
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(isActivated ? Self.activeAccent : .white.opacity(0.86))
                .overlay(alignment: .topTrailing) {
                    if isActivated, count > 0 {
                        badge
                    }
                }
                // Reserve space so the badge doesn't get clipped against the toolbar's
                // tight frame around the SF Symbol's intrinsic bounds.
                .padding(.trailing, 4)
                .padding(.top, 2)
        }
        .accessibilityIdentifier("home.header.active-filter")
        .accessibilityLabel(Text(L10n.Header.activeFilter))
        .accessibilityValue(Text(isActivated ? L10n.Header.activeFilterOn : L10n.Header.activeFilterOff))
    }

    /// Pill-shaped numeric badge. It only appears while the active filter is engaged,
    /// so visible chrome always maps to an explicit filtering state.
    private var badge: some View {
        Text("\(count)")
            .oasisFont(size: 10, weight: .bold, relativeTo: .caption2)
            .foregroundStyle(.black.opacity(0.86))
            .monospacedDigit()
            .padding(.horizontal, 4)
            .padding(.vertical, 0.5)
            .frame(minWidth: 15, minHeight: 15)
            .background {
                Capsule()
                    .fill(Self.activeAccent)
            }
            .overlay {
                Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
            }
            // Sits in the top-trailing corner of the SF Symbol, partially overhanging
            // its bounding box the way iOS notification badges do.
            .offset(x: 9, y: -8)
            .accessibilityHidden(true)
    }

}
