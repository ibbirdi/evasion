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
            .equatable()
            .frame(width: 154, height: 154)
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
            return HomeMixConstellationNode(
                id: "channel-\(channel.id)",
                tint: channel.tint,
                size: 8.4,
                phase: Double(index) * 0.73
            )
        }

        let noiseNodes = ProceduralNoise.allCases.enumerated().compactMap { index, noise -> HomeMixConstellationNode? in
            guard model.isProceduralNoiseActive(noise) else { return nil }
            return HomeMixConstellationNode(
                id: "noise-\(noise.id)",
                tint: noise.tint,
                size: 9.0,
                phase: 1.35 + Double(index) * 0.82
            )
        }

        let binauralNodes: [HomeMixConstellationNode]
        if model.isBinauralActive {
            binauralNodes = [
                HomeMixConstellationNode(
                    id: "binaural-\(model.activeBinauralTrack.id)",
                    tint: model.activeBinauralTrack.tint,
                    size: 9.4,
                    phase: 2.15
                )
            ]
        } else {
            binauralNodes = []
        }

        return Array((ambientNodes + noiseNodes + binauralNodes).prefix(9))
    }
}

private struct HomeMixConstellationNode: Identifiable, Equatable {
    let id: String
    let tint: Color
    let size: CGFloat
    let phase: Double

    static func == (lhs: HomeMixConstellationNode, rhs: HomeMixConstellationNode) -> Bool {
        lhs.id == rhs.id
            && lhs.size == rhs.size
            && lhs.phase == rhs.phase
    }
}

private struct HomeMixConstellationView: View, Equatable {
    let nodes: [HomeMixConstellationNode]
    let isPlaying: Bool
    let reduceMotion: Bool

    private static let haloSegments = 136
    private static let particleTrailSegments = 44
    private static let baseAngularSpeed = 0.42

    nonisolated static func == (lhs: HomeMixConstellationView, rhs: HomeMixConstellationView) -> Bool {
        lhs.nodes == rhs.nodes
            && lhs.isPlaying == rhs.isPlaying
            && lhs.reduceMotion == rhs.reduceMotion
    }

    var body: some View {
        if isPlaying || !nodes.isEmpty {
            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: pausesTimeline)) { context in
                let time = animatedTime(from: context.date)

                Canvas(opaque: false, colorMode: .linear, rendersAsynchronously: true) { context, size in
                    context.blendMode = .plusLighter
                    drawIconHalo(time: time, in: &context, canvasSize: size)

                    for (index, node) in nodes.enumerated() {
                        drawOrbitingGlint(
                            node: node,
                            index: index,
                            total: nodes.count,
                            time: time,
                            in: &context,
                            canvasSize: size
                        )
                    }
                }
                .opacity(isPlaying ? 0.96 : 0)
                .animation(.smooth(duration: isPlaying ? 0.32 : 0.72), value: isPlaying)
                .drawingGroup(opaque: false, colorMode: .linear)
            }
            .transition(.opacity)
        }
    }

    private var freezesMotion: Bool {
        reduceMotion || AppConfiguration.isRunningScreenshotAutomation
    }

    private var pausesTimeline: Bool {
        freezesMotion || !isPlaying
    }

    private func animatedTime(from date: Date) -> Double {
        freezesMotion ? 0 : date.timeIntervalSinceReferenceDate
    }

    private func drawIconHalo(
        time: Double,
        in context: inout GraphicsContext,
        canvasSize: CGSize
    ) {
        let baseRadius = min(canvasSize.width, canvasSize.height) * 0.37

        drawHaloRibbon(
            radius: baseRadius,
            waveAmplitude: 1.8,
            waveFrequency: 2.0,
            basePhase: 0.10,
            angularVelocity: 0.08,
            waveVelocity: 0.26,
            lineWidth: 18,
            opacity: 0.085,
            strandIndex: 0,
            time: time,
            in: &context,
            canvasSize: canvasSize
        )
        drawHaloRibbon(
            radius: baseRadius + 1.5,
            waveAmplitude: 2.6,
            waveFrequency: 3.0,
            basePhase: 0.80,
            angularVelocity: -0.07,
            waveVelocity: -0.32,
            lineWidth: 9.0,
            opacity: 0.17,
            strandIndex: 1,
            time: time,
            in: &context,
            canvasSize: canvasSize
        )

        for strand in 0..<8 {
            let lane = CGFloat(strand - 3) * 1.85
            let direction = strand.isMultiple(of: 2) ? 1.0 : -1.0
            drawHaloRibbon(
                radius: baseRadius + lane,
                waveAmplitude: 3.3 + CGFloat(strand % 3) * 0.85,
                waveFrequency: 3.0 + Double(strand % 4),
                basePhase: Double(strand) * 0.74,
                angularVelocity: direction * (0.16 + Double(strand % 3) * 0.026),
                waveVelocity: direction * (0.48 + Double(strand % 4) * 0.075),
                lineWidth: strand.isMultiple(of: 3) ? 1.55 : 0.88,
                opacity: strand.isMultiple(of: 3) ? 0.48 : 0.34,
                strandIndex: strand + 2,
                time: time,
                in: &context,
                canvasSize: canvasSize
            )
        }

        drawHaloRibbon(
            radius: baseRadius + 7.0,
            waveAmplitude: 0.8,
            waveFrequency: 2.0,
            basePhase: 1.45,
            angularVelocity: 0.11,
            waveVelocity: 0.34,
            lineWidth: 1.1,
            opacity: 0.52,
            strandIndex: 10,
            time: time,
            in: &context,
            canvasSize: canvasSize
        )
        drawHaloRibbon(
            radius: baseRadius - 8.0,
            waveAmplitude: 1.1,
            waveFrequency: 2.0,
            basePhase: 2.35,
            angularVelocity: -0.13,
            waveVelocity: -0.40,
            lineWidth: 1.0,
            opacity: 0.42,
            strandIndex: 11,
            time: time,
            in: &context,
            canvasSize: canvasSize
        )
    }

    private func drawHaloRibbon(
        radius: CGFloat,
        waveAmplitude: CGFloat,
        waveFrequency: Double,
        basePhase: Double,
        angularVelocity: Double,
        waveVelocity: Double,
        lineWidth: CGFloat,
        opacity: Double,
        strandIndex: Int,
        time: Double,
        in context: inout GraphicsContext,
        canvasSize: CGSize
    ) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let driver = activeNode(for: strandIndex)
        let activePhase = driver?.phase ?? basePhase
        let activeEnergy = min(max(((driver?.size ?? 8.0) - 5.8) / 5.6, 0), 1)
        let direction = strandIndex.isMultiple(of: 2) ? 1.0 : -1.0
        let angleOffset = time * (angularVelocity + direction * (0.020 + Double(activeEnergy) * 0.034)) + activePhase * 0.10
        let phase = basePhase + activePhase * 0.56 + time * (waveVelocity + direction * Double(activeEnergy) * 0.18)
        let pulseSpeed = 0.88 + Double(strandIndex % 5) * 0.075 + Double(activeEnergy) * 0.24
        let radiusPulse = CGFloat(sin(time * pulseSpeed + basePhase + activePhase)) * (lineWidth > 2 ? 0.65 : 1.28)
        let animatedWaveAmplitude = waveAmplitude * (1.0 + activeEnergy * 0.26)
        var path = Path()

        for sample in 0...Self.haloSegments {
            let progress = Double(sample) / Double(Self.haloSegments)
            let angle = progress * 2.0 * Double.pi + angleOffset
            let point = haloPoint(
                angle: angle,
                radius: radius + radiusPulse,
                waveAmplitude: animatedWaveAmplitude,
                waveFrequency: waveFrequency,
                phase: phase,
                center: center
            )

            if sample == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        context.stroke(
            path,
            with: .conicGradient(
                haloGradient(strandIndex: strandIndex, opacity: opacity),
                center: center,
                angle: .radians(time * (0.30 + abs(angularVelocity) * 0.42) + phase)
            ),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawOrbitingGlint(
        node: HomeMixConstellationNode,
        index: Int,
        total: Int,
        time: Double,
        in context: inout GraphicsContext,
        canvasSize: CGSize
    ) {
        let head = particlePoint(
            for: node,
            index: index,
            total: total,
            time: time,
            canvasSize: canvasSize
        )
        let pulse = pulse(for: node, time: time)
        let headWidth = 1.05 + node.size * 0.08
        let headDiameter = 1.5 + node.size * 0.14
        let trailDuration = 2.85 + Double(node.size) * 0.036
        let glintOpacity = 0.62 + pulse * 0.20
        var trailPath = Path()
        var tail = head

        for sample in stride(from: Self.particleTrailSegments, through: 0, by: -1) {
            let age = Double(sample) / Double(Self.particleTrailSegments) * trailDuration
            let point = particlePoint(
                for: node,
                index: index,
                total: total,
                time: time - age,
                canvasSize: canvasSize
            )

            if sample == Self.particleTrailSegments {
                tail = point
                trailPath.move(to: point)
            } else {
                trailPath.addLine(to: point)
            }
        }

        context.stroke(
            trailPath,
            with: .linearGradient(
                Gradient(stops: [
                    Gradient.Stop(color: node.tint.opacity(0.0), location: 0.0),
                    Gradient.Stop(color: node.tint.opacity(glintOpacity * 0.020), location: 0.24),
                    Gradient.Stop(color: node.tint.opacity(glintOpacity * 0.070), location: 0.62),
                    Gradient.Stop(color: node.tint.opacity(glintOpacity * 0.16), location: 1.0)
                ]),
                startPoint: tail,
                endPoint: head
            ),
            style: StrokeStyle(lineWidth: headWidth * 3.5, lineCap: .round, lineJoin: .round)
        )
        context.stroke(
            trailPath,
            with: .linearGradient(
                Gradient(stops: [
                    Gradient.Stop(color: node.tint.opacity(0.0), location: 0.0),
                    Gradient.Stop(color: node.tint.opacity(glintOpacity * 0.030), location: 0.18),
                    Gradient.Stop(color: node.tint.opacity(glintOpacity * 0.20), location: 0.58),
                    Gradient.Stop(color: .white.opacity(glintOpacity * 0.60), location: 1.0)
                ]),
                startPoint: tail,
                endPoint: head
            ),
            style: StrokeStyle(lineWidth: headWidth, lineCap: .round, lineJoin: .round)
        )

        let glowRadius = headDiameter * (3.2 + CGFloat(pulse) * 0.65)
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
                    Gradient.Stop(color: .white.opacity(0.34), location: 0.0),
                    Gradient.Stop(color: node.tint.opacity(0.20), location: 0.34),
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

    private func particlePoint(
        for node: HomeMixConstellationNode,
        index: Int,
        total: Int,
        time: Double,
        canvasSize: CGSize
    ) -> CGPoint {
        let angle = angle(for: index, total: total, node: node, time: time)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let orbit = haloOrbitPoint(
            angle: angle,
            index: index,
            node: node,
            time: time,
            canvasSize: canvasSize
        )
        return CGPoint(
            x: center.x + orbit.x,
            y: center.y + orbit.y
        )
    }

    private func angle(for index: Int, total: Int, node: HomeMixConstellationNode, time: Double) -> CGFloat {
        let base = (Double(index) / Double(max(total, 1))) * 2.0 * Double.pi - Double.pi / 2.0
        let speed = Self.baseAngularSpeed + Double(index % 4) * 0.032 + sin(node.phase) * 0.014
        return CGFloat(base + time * speed)
    }

    private func haloOrbitPoint(
        angle: CGFloat,
        index: Int,
        node: HomeMixConstellationNode,
        time: Double,
        canvasSize: CGSize
    ) -> CGPoint {
        let baseRadius = min(canvasSize.width, canvasSize.height) * 0.37
        let lane = CGFloat(index % 4) * 2.2 - 3.3
        let breath = CGFloat(sin(time * 1.18 + node.phase)) * (1.5 + node.size * 0.05)
        let radial = baseRadius + lane + breath

        return CGPoint(
            x: cos(angle) * radial,
            y: sin(angle) * radial
        )
    }

    private func haloPoint(
        angle: Double,
        radius: CGFloat,
        waveAmplitude: CGFloat,
        waveFrequency: Double,
        phase: Double,
        center: CGPoint
    ) -> CGPoint {
        let wovenWave = sin(angle * waveFrequency + phase) * Double(waveAmplitude)
        let fineWave = sin(angle * (waveFrequency + 3.0) - phase * 0.65) * Double(waveAmplitude) * 0.34
        let radial = radius + CGFloat(wovenWave + fineWave)

        return CGPoint(
            x: center.x + cos(angle) * radial,
            y: center.y + sin(angle) * radial
        )
    }

    private func pulse(for node: HomeMixConstellationNode, time: Double) -> Double {
        freezesMotion ? 0 : (sin(time * 2.0 + node.phase) + 1.0) / 2.0
    }

    private func activeNode(for strandIndex: Int) -> HomeMixConstellationNode? {
        guard !nodes.isEmpty else { return nil }
        return nodes[strandIndex % nodes.count]
    }

    private func haloGradient(strandIndex: Int, opacity: Double) -> Gradient {
        let cool = Color(red: 0.20, green: 0.82, blue: 1.0)
        let deepCool = Color(red: 0.24, green: 0.46, blue: 0.96)
        let warm = Color(red: 1.0, green: 0.50, blue: 0.16)
        let cream = Color(red: 1.0, green: 0.86, blue: 0.56)

        guard !nodes.isEmpty else {
            return Gradient(stops: [
                Gradient.Stop(color: cool.opacity(opacity * 0.90), location: 0.0),
                Gradient.Stop(color: deepCool.opacity(opacity * 0.58), location: 0.22),
                Gradient.Stop(color: cool.opacity(opacity * 0.72), location: 0.42),
                Gradient.Stop(color: warm.opacity(opacity * 1.10), location: 0.60),
                Gradient.Stop(color: cream.opacity(opacity * 0.92), location: 0.78),
                Gradient.Stop(color: cool.opacity(opacity * 0.90), location: 1.0)
            ])
        }

        let primaryTint = activeNode(for: strandIndex)?.tint ?? cool
        let secondaryTint = activeNode(for: strandIndex + 1)?.tint ?? primaryTint
        let tertiaryTint = activeNode(for: strandIndex + 2)?.tint ?? secondaryTint

        return Gradient(stops: [
            Gradient.Stop(color: primaryTint.opacity(opacity * 1.34), location: 0.0),
            Gradient.Stop(color: cool.opacity(opacity * 0.52), location: 0.14),
            Gradient.Stop(color: primaryTint.opacity(opacity * 1.62), location: 0.28),
            Gradient.Stop(color: secondaryTint.opacity(opacity * 1.22), location: 0.44),
            Gradient.Stop(color: warm.opacity(opacity * 0.84), location: 0.58),
            Gradient.Stop(color: tertiaryTint.opacity(opacity * 1.16), location: 0.72),
            Gradient.Stop(color: cream.opacity(opacity * 0.58), location: 0.86),
            Gradient.Stop(color: primaryTint.opacity(opacity * 1.34), location: 1.0)
        ])
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
/// set. Rendered outside `ToolbarItem` so the glass capsule stays passive instead of
/// becoming another navigation-bar button.
struct TimerCountdownIndicator: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.timerDurationMinutes != nil {
            Text(model.timerToolbarTitle)
                .oasisFont(size: 11, weight: .medium, relativeTo: .caption)
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.84))
                .contentTransition(.numericText(countsDown: true))
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 10)
                .frame(height: 28)
                .background {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.001))
                        .oasisGlassEffect(in: Capsule(style: .continuous))
                        .overlay {
                            Capsule(style: .continuous)
                                .fill(Color(red: 0.035, green: 0.050, blue: 0.090).opacity(0.36))
                        }
                }
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(HomeToolbarTimerMenu.activeAccent.opacity(0.24), lineWidth: 1)
                }
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
