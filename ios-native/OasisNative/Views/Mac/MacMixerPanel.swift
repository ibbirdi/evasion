import SwiftUI

struct MacMixerPanel: View {
    @Environment(AppModel.self) private var model
    @State private var selectedSection: MacPanelSection = .mixer
    @State private var detailChannel: SoundChannel?
    @State private var didConfigureScreenshotScenario = false

    var body: some View {
        @Bindable var model = model

        ZStack {
            MacPanelBackground()

            VStack(spacing: 16) {
                MacMixerHeader()

                Picker("", selection: $selectedSection) {
                    ForEach(MacPanelSection.allCases) { section in
                        Label {
                            Text(section.title)
                        } icon: {
                            Image(systemName: section.systemImage)
                        }
                        .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .labelsHidden()
                .frame(maxWidth: 380)

                Group {
                    switch selectedSection {
                    case .mixer:
                        MacMixerSection { channel in
                            withAnimation(.smooth(duration: 0.18)) {
                                detailChannel = channel
                            }
                        }
                    case .presets:
                        MacPresetsSection()
                    case .binaural:
                        MacBinauralSection()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(20)

            if let detailChannel {
                MacSoundDetailOverlay(channel: detailChannel) {
                    withAnimation(.smooth(duration: 0.16)) {
                        self.detailChannel = nil
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.985)))
                .zIndex(10)
            }
        }
        .frame(minWidth: MacPanelLayout.idealSize.width, minHeight: MacPanelLayout.idealSize.height)
        .clipShape(RoundedRectangle(cornerRadius: MacPanelLayout.cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: MacPanelLayout.cornerRadius, style: .continuous))
        .tint(MacDesign.accent)
        .preferredColorScheme(.dark)
        .task {
            await configureMacScreenshotScenarioIfNeeded()
        }
        .sheet(item: $model.activePaywallContext) { context in
            MacPaywallSheet(context: context)
                .environment(model)
                .frame(width: 460)
        }
        .sheet(item: $model.activeInlineUpsell) { context in
            MacInlineUpsellSheet(context: context)
                .environment(model)
                .frame(width: 420)
        }
    }

    @MainActor
    private func configureMacScreenshotScenarioIfNeeded() async {
        guard !didConfigureScreenshotScenario else { return }
        guard AppConfiguration.isRunningMacScreenshotAutomation else { return }
        didConfigureScreenshotScenario = true

        model.setImmersiveAudioEnabled(true)
        model.randomizeMix()
        model.setChannelSpatialPosition(.oiseaux, value: SpatialPoint(x: -0.55, y: -0.18))
        model.setChannelAutoVariationRange(.vent, range: AutoVariationRange(lowerBound: 0.18, upperBound: 0.62))

        switch AppConfiguration.macScreenshotScenario {
        case "02_sound_detail":
            selectedSection = .mixer
            try? await Task.sleep(for: .milliseconds(180))
            detailChannel = .oiseaux
        case "03_auto_range":
            selectedSection = .mixer
        case "04_saved_ambiences":
            if let preset = model.presets.first(where: \.isSignature) {
                model.loadPreset(preset)
            }
            selectedSection = .presets
        case "05_binaural_timer":
            _ = model.selectBinauralTrack(.alpha)
            model.setBinauralEnabled(true)
            model.setBinauralVolume(0.64)
            model.setTimer(30)
            selectedSection = .binaural
        default:
            selectedSection = .mixer
        }
    }
}

private struct MacSoundDetailOverlay: View {
    let channel: SoundChannel
    let onClose: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .contentShape(Rectangle())
                .onTapGesture(perform: onClose)

            SoundDetailSheet(channel: channel, showsCloseButton: true, onClose: onClose)
                .frame(width: 430, height: 560)
                .background(.regularMaterial, in: shape)
                .clipShape(shape)
                .overlay {
                    shape
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.32), radius: 34, y: 18)
                .padding(.horizontal, 28)
        }
        .accessibilityAddTraits(.isModal)
    }
}

private struct MacMixerHeader: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 18) {
                MacBrandLockup()
                    .frame(width: 118, height: 60, alignment: .leading)

                Spacer(minLength: 0)

                MacPlaybackButton()
            }

            HStack(spacing: 10) {
                Toggle(isOn: Binding(
                    get: { model.immersiveAudioEnabled },
                    set: { model.setImmersiveAudioEnabled($0) }
                )) {
                    Label {
                        Text(L10n.Header.immersiveSound)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    } icon: {
                        Image(systemName: "airpodspro")
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)

                Spacer(minLength: 0)

                MacTimerMenu()

                MacIconButton(
                    systemImage: "shuffle",
                    accessibilityLabel: L10n.HomeControls.shuffle,
                    action: model.randomizeMix
                )

                #if os(macOS)
                Button {
                    MacApplicationCommands.quit()
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.58))
                .help(L10n.string(L10n.Mac.quit))
                #endif
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }
}

private struct MacBrandLockup: View {
    var body: some View {
        Text(verbatim: "OASIS")
            .oasisFont(size: 22, weight: .semibold, design: .default, relativeTo: .title3)
            .kerning(4)
            .foregroundStyle(.white.opacity(0.96))
            .padding(.bottom, 25)
            .background(alignment: .bottom) {
                MacWaveformSignatureLine()
                    .frame(maxWidth: .infinity, maxHeight: 24)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.App.title)
    }
}

private struct MacPlaybackButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.24)) {
                model.togglePlayback()
            }
        } label: {
            MacPlaybackButtonLabel()
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(Text(model.isPlaying ? L10n.HomeControls.pause : L10n.HomeControls.play))
    }
}

private struct MacPlaybackButtonLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let palette = model.activePlaybackPalette

        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            .oasisFont(size: 25, weight: .bold, design: .default, relativeTo: .title3)
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .shadow(
                color: .black.opacity(model.isPlaying ? 0.26 : 0.12),
                radius: model.isPlaying ? 4 : 2,
                y: model.isPlaying ? 1.5 : 1
            )
            .symbolEffect(.bounce, value: model.isPlaying)
            .offset(x: model.isPlaying ? 0 : 1)
            .frame(width: 66, height: 66)
            .background {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .macLiquidGlass(in: Circle(), interactive: true)
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(model.isPlaying ? 0.04 : 0.022))
                        }

                    if model.isPlaying {
                        MacAnimatedPlaybackMesh(
                            palette: palette,
                            animationKey: "mac-playback-\(model.isPlaying)-\(palette.count)"
                        )
                        .padding(1)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.96, green: 0.83, blue: 0.45),
                                        MacDesign.accent
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.72)
                            .padding(1)
                    }

                    Circle()
                        .fill(model.isPlaying ? Color.white.opacity(0.05) : Color.clear)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(borderStyle(for: palette), lineWidth: 1.3)
            }
            .animation(.smooth(duration: 0.22), value: model.isPlaying)
    }

    private func borderStyle(for palette: [Color]) -> AnyShapeStyle {
        guard model.isPlaying else {
            return AnyShapeStyle(Color.white.opacity(0.08))
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: palette.map { $0.opacity(0.42) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct MacAnimatedPlaybackMesh: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let palette: [Color]
    let animationKey: String

    @State private var seed = Double.random(in: 0...100)

    var body: some View {
        let shouldPause = scenePhase != .active || reduceMotion || AppConfiguration.isRunningScreenshotAutomation
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: shouldPause)) { context in
            let time = AppConfiguration.isRunningScreenshotAutomation
                ? 2.4 + seed
                : context.date.timeIntervalSinceReferenceDate + seed

            Circle()
                .fill(animatedMesh(at: time))
                .overlay {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.28),
                                    Color.white.opacity(0.04),
                                    Color.clear
                                ],
                                center: .topLeading,
                                startRadius: 2,
                                endRadius: 70
                            )
                        )
                }
                .clipShape(Circle())
        }
        .onChange(of: animationKey) { _, _ in
            seed = Double.random(in: 0...100)
        }
    }

    private func animatedMesh(at time: TimeInterval) -> MeshGradient {
        let t = Float(time)
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2<Float>(0.00, 0.00),
                SIMD2<Float>(0.50 + 0.10 * sin(t * 0.55), 0.02),
                SIMD2<Float>(1.00, 0.00),
                SIMD2<Float>(0.04, 0.50 + 0.12 * cos(t * 0.42)),
                SIMD2<Float>(0.50 + 0.14 * sin(t * 0.36 + 1.7), 0.50 + 0.16 * cos(t * 0.48)),
                SIMD2<Float>(0.96, 0.50 + 0.12 * sin(t * 0.39 + 0.8)),
                SIMD2<Float>(0.00, 1.00),
                SIMD2<Float>(0.50 + 0.10 * cos(t * 0.44), 0.98),
                SIMD2<Float>(1.00, 1.00)
            ],
            colors: meshColors,
            background: meshColors.first ?? MacDesign.accent,
            smoothsColors: true
        )
    }

    private var meshColors: [Color] {
        let source = palette.isEmpty
            ? LiquidActivityPalette.playback(from: [MacDesign.accent, Color(red: 0.96, green: 0.83, blue: 0.45)])
            : palette
        let fallback = [
            MacDesign.accent,
            Color(red: 0.95, green: 0.88, blue: 0.52),
            Color(red: 0.66, green: 0.80, blue: 0.96)
        ]
        let colors = source.isEmpty ? fallback : source

        return [
            colors[safe: 0] ?? fallback[0],
            colors[safe: 1] ?? fallback[1],
            colors[safe: 2] ?? fallback[2],
            colors[safe: 2] ?? fallback[2],
            Color.white.opacity(0.88),
            colors[safe: 0] ?? fallback[0],
            colors[safe: 1] ?? fallback[1],
            colors[safe: 0] ?? fallback[0],
            colors[safe: 2] ?? fallback[2]
        ]
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct MacWaveformSignatureLine: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var transitionFrom: Double = 0
    @State private var transitionTo: Double = 0
    @State private var transitionStartTime: TimeInterval = 0
    @State private var hasInitialised = false
    @State private var phaseAccumulator = MacWavePhaseAccumulator()

    private static let transitionDuration: Double = 0.40

    var body: some View {
        let shouldPause = AppConfiguration.isRunningScreenshotAutomation || reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: shouldPause)) { context in
            let now = AppConfiguration.isRunningScreenshotAutomation
                ? 3.4
                : context.date.timeIntervalSinceReferenceDate
            let p = computePhaseProgress(at: now)
            let palette = model.activePlaybackPalette
            let speed = 0.40 + (0.95 - 0.40) * p
            let accumulatedPhase = phaseAccumulator.advance(to: now, speed: speed)

            Canvas { gc, size in
                drawWave(
                    gc: gc,
                    size: size,
                    time: now,
                    palette: palette,
                    paletteCount: palette.count,
                    p: p,
                    phaseTime: accumulatedPhase
                )
            }
        }
        .onAppear { initialiseIfNeeded() }
        .onChange(of: model.isPlaying) { _, newValue in
            startTransition(toPlaying: newValue)
        }
    }

    private func initialiseIfNeeded() {
        guard !hasInitialised else { return }
        let initial: Double = model.isPlaying ? 1 : 0
        transitionFrom = initial
        transitionTo = initial
        transitionStartTime = 0
        hasInitialised = true
    }

    private func startTransition(toPlaying: Bool) {
        let now = Date().timeIntervalSinceReferenceDate
        transitionFrom = computePhaseProgress(at: now)
        transitionTo = toPlaying ? 1 : 0
        transitionStartTime = now
    }

    private func computePhaseProgress(at now: TimeInterval) -> Double {
        guard transitionStartTime > 0 else { return transitionTo }
        let elapsed = now - transitionStartTime
        if elapsed >= Self.transitionDuration { return transitionTo }
        if elapsed <= 0 { return transitionFrom }
        let t = elapsed / Self.transitionDuration
        let eased = t * t * (3 - 2 * t)
        return transitionFrom + (transitionTo - transitionFrom) * eased
    }

    private func drawWave(
        gc: GraphicsContext,
        size: CGSize,
        time: TimeInterval,
        palette: [Color],
        paletteCount: Int,
        p: Double,
        phaseTime: Double
    ) {
        var path = Path()
        let midY = size.height / 2
        let width = size.width
        let step: Double = 1.4
        let pClamped = max(0, min(1, p))
        let driftMix = 0.30 * pClamped
        let idleAmp = 0.22
        let playAmp = min(1.20, 0.85 + Double(paletteCount) * 0.08)
        let amplitude = idleAmp + (playAmp - idleAmp) * pClamped
        let envelopeNoise = 1.0 + (0.7 + 0.3 * sin(time * 0.42) - 1.0) * pClamped

        path.move(to: CGPoint(x: 0, y: midY))

        var x: Double = 0
        while x <= Double(width) {
            let nx = x / Double(width)
            let primary = sin(nx * 4.5 * .pi + phaseTime)
            let drift = sin(nx * 1.7 * .pi + time * 0.6)
            let wave = primary + drift * driftMix
            let envelope = sin(nx * .pi)
            let yRaw = midY + amplitude * envelopeNoise * Double(size.height) * 0.20 * wave * envelope
            let y = min(max(yRaw, 1.5), Double(size.height) - 1.5)

            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        let colors = palette.isEmpty
            ? [Color.white.opacity(0.55)]
            : palette.map { $0.opacity(0.82) }
        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(colors: colors),
            startPoint: .zero,
            endPoint: CGPoint(x: width, y: 0)
        )

        gc.stroke(path, with: shading, lineWidth: 2.0)
    }
}

private final class MacWavePhaseAccumulator {
    private var phase: Double = 0
    private var lastTime: TimeInterval = -1

    func advance(to now: TimeInterval, speed: Double) -> Double {
        defer { lastTime = now }
        guard lastTime > 0, now > lastTime else { return phase }
        let dt = min(now - lastTime, 0.5)
        phase += dt * speed
        if phase > 10_000 * .pi * 2 {
            phase = phase.truncatingRemainder(dividingBy: 2 * .pi)
        }
        return phase
    }
}

private struct MacTimerMenu: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Menu {
            Button {
                model.setTimer(nil)
            } label: {
                Text(L10n.Header.off)
            }

            Divider()

            ForEach([15, 30, 60, 120], id: \.self) { minutes in
                Button {
                    model.setTimer(minutes)
                } label: {
                    HStack {
                        Text(verbatim: L10n.timerOptionLabel(minutes: minutes))
                        if !model.canUseTimer(minutes: minutes) {
                            Image(systemName: "lock.fill")
                        }
                    }
                }
            }
        } label: {
            Label {
                Text(verbatim: model.timerToolbarTitle)
            } icon: {
                Image(systemName: "timer")
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .menuStyle(.button)
        .controlSize(.regular)
    }
}
