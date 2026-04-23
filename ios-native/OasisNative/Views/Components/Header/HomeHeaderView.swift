import SwiftUI
import UIKit

struct HomeHeaderView: View {
    @Environment(AppModel.self) private var model
    let compactProgress: CGFloat
    let onOpenPresets: (PanelTransitionSource) -> Void
    let onOpenBinaural: (PanelTransitionSource) -> Void
    let onRequestPremiumTimer: () -> Void

    private var logoVisibility: CGFloat {
        max(0, 1 - (compactProgress * 3.4))
    }

    var body: some View {
        VStack(spacing: max(2, 9 - (compactProgress * 7))) {
            BrandLockupView(visibility: logoVisibility)

            if let scene = model.currentScene {
                SceneCard(scene: scene, compactProgress: compactProgress)
                    .padding(.horizontal, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            QuickControlsStrip(
                onOpenPresets: onOpenPresets,
                onOpenBinaural: onOpenBinaural,
                onRequestPremiumTimer: onRequestPremiumTimer
            )
        }
        .padding(.horizontal, 0)
        .padding(.vertical, max(2, 6 - compactProgress * 4))
        .frame(maxWidth: .infinity)
        .animation(.smooth(duration: 0.28), value: model.currentScene?.id)
        .animation(.smooth(duration: 0.22), value: compactProgress)
    }
}

private struct BrandLockupView: View {
    @Environment(AppModel.self) private var model
    let visibility: CGFloat

    var body: some View {
        // Anchoring the waveform to the Text's own bounds via `.background` guarantees the
        // two share the exact same horizontal frame. Any side-bearing or trailing-kerning
        // quirk from the font shifts both elements together instead of drifting the line
        // away from the wordmark — fixing the visual-axis misalignment reported from the
        // previous VStack layout.
        Text(verbatim: "OASIS")
            .font(.system(size: 22, weight: .semibold))
            .kerning(4)
            .foregroundStyle(.white.opacity(0.96))
            .padding(.bottom, 12)
            .background(alignment: .bottom) {
                WaveformSignatureLine()
                    .frame(maxWidth: .infinity, maxHeight: 8)
            }
            .frame(maxWidth: .infinity)
            // Height matched to natural content (22pt wordmark + 12pt padding + 8pt wave ≈
            // 42pt) instead of the legacy 74pt box. Drops the excess empty space below the
            // logo so the lockup reads as vertically centred against the quick-controls row.
            .frame(height: 42 * visibility, alignment: .top)
            .opacity(visibility)
            .scaleEffect(0.92 + (visibility * 0.08), anchor: .top)
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.App.title)
            .animation(.smooth(duration: 0.18), value: visibility)
    }
}

/// Thin signature line rendered beneath the OASIS wordmark. Stays flat at rest and
/// undulates when the app is playing. Amplitude grows with the number of active ambient
/// channels, colour reflects the tints of the currently mixed palette.
private struct WaveformSignatureLine: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        // Under UI-test automation, pause the animation. The moving waveform otherwise
        // keeps SwiftUI invalidating the view tree non-stop, which prevents the app from
        // ever reaching quiescence — XCUITest then waits up to 60s per interaction,
        // making the screenshot run ~5× slower and flaky.
        //
        // Paused = true still renders exactly one frame, so the marketing shots keep a
        // nice frozen wave shape at `context.date`'s initial value.
        let shouldPause = !model.isPlaying || AppConfiguration.isRunningScreenshotAutomation
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: shouldPause)) { context in
            let palette = model.activePlaybackPalette
            let amplitude: Double = model.isPlaying
                ? min(1.0, 0.35 + Double(palette.count) * 0.11)
                : 0

            Canvas { gc, size in
                drawWave(
                    gc: gc,
                    size: size,
                    // In screenshot mode, pin `time` to a deterministic value that produces
                    // a visually-interesting peak (not a flat line frozen at t=0).
                    time: AppConfiguration.isRunningScreenshotAutomation
                        ? 3.4
                        : context.date.timeIntervalSinceReferenceDate,
                    amplitude: amplitude,
                    palette: palette
                )
            }
        }
    }

    private func drawWave(
        gc: GraphicsContext,
        size: CGSize,
        time: TimeInterval,
        amplitude: Double,
        palette: [Color]
    ) {
        var path = Path()
        let midY = size.height / 2
        let width = size.width
        let step: Double = 1.4
        let phase = time * 0.9

        path.move(to: CGPoint(x: 0, y: midY))

        var x: Double = 0
        while x <= Double(width) {
            let nx = x / Double(width)           // 0 ... 1

            // Three detuned sines produce an organic breathing motion; the hard-coded
            // frequencies (4.5π, 7π, 10π) were picked so the peaks never align for long.
            let wave =
                sin(nx * 4.5 * .pi + phase) * 0.55 +
                sin(nx * 7.0 * .pi + phase * 1.4) * 0.30 +
                sin(nx * 10.0 * .pi + phase * 1.8) * 0.15

            // Raised-sine envelope tapers both ends to zero so the line fades in/out
            // instead of stopping abruptly at the edges of the frame.
            let envelope = sin(nx * .pi)
            let y = midY + amplitude * Double(size.height) * 0.38 * wave * envelope

            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }

        let colors: [Color] = palette.isEmpty
            ? [Color.white.opacity(0.55)]
            : palette.map { $0.opacity(0.82) }

        let shading = GraphicsContext.Shading.linearGradient(
            Gradient(colors: colors),
            startPoint: .zero,
            endPoint: CGPoint(x: width, y: 0)
        )

        gc.stroke(path, with: shading, lineWidth: 1.1)
    }
}

private struct QuickControlsStrip: View {
    @Environment(AppModel.self) private var model
    let onOpenPresets: (PanelTransitionSource) -> Void
    let onOpenBinaural: (PanelTransitionSource) -> Void
    let onRequestPremiumTimer: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            presetChip
                .frame(maxWidth: .infinity)

            binauralChip
                .frame(maxWidth: .infinity)

            TimerChip(onRequestPremiumTimer: onRequestPremiumTimer)

            ActiveChannelsChip()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var presetChip: some View {
        let isPresetActive = model.activePreset != nil

        return Button {
            onOpenPresets(.headerPresets)
        } label: {
            PanelTriggerChip(
                symbol: model.activePreset == nil ? "bookmark" : "bookmark.fill",
                title: model.activePreset.map(model.presetDisplayName) ?? L10n.string(L10n.Presets.panelTitle),
                tint: isPresetActive ? LiquidActivityPalette.preset[0] : .white,
                isActivated: isPresetActive,
                palette: LiquidActivityPalette.preset
            )
        }
        .accessibilityIdentifier("home.header.presets")
        .buttonStyle(PressScaleButtonStyle())
    }

    private var binauralChip: some View {
        let isBinauralActive = model.isBinauralActive

        return Button {
            onOpenBinaural(.headerBinaural)
        } label: {
            PanelTriggerChip(
                symbol: model.isBinauralActive ? "waveform.path.ecg" : "waveform.path",
                title: model.activeBinauralTrack.localizedTitle,
                tint: isBinauralActive ? model.activeBinauralTrack.tint : .white.opacity(0.84),
                isActivated: isBinauralActive,
                palette: LiquidActivityPalette.binaural(for: model.activeBinauralTrack.tint)
            )
        }
        .accessibilityIdentifier("home.header.binaural")
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct TimerChip: View {
    @Environment(AppModel.self) private var model
    let onRequestPremiumTimer: () -> Void

    var body: some View {
        Menu {
            timerAction(L10n.timerOptionLabel(minutes: nil), minutes: nil)
            timerAction(L10n.timerOptionLabel(minutes: 15), minutes: 15)
            timerAction(L10n.timerOptionLabel(minutes: 30), minutes: 30)
            timerAction(L10n.timerOptionLabel(minutes: 60), minutes: 60)
            timerAction(L10n.timerOptionLabel(minutes: 120), minutes: 120)
        } label: {
            HeaderChipLabel(
                symbol: "timer",
                title: model.timerToolbarTitle,
                tint: model.timerDurationMinutes == nil
                    ? .white.opacity(0.82)
                    : Color(red: 0.52, green: 0.91, blue: 0.64),
                expands: false
            )
        }
        .menuIndicator(.hidden)
        .accessibilityIdentifier("home.header.timer")
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

private struct ActiveChannelsChip: View {
    @Environment(AppModel.self) private var model

    private var isActivated: Bool {
        model.showsOnlyActiveChannels
    }

    private var tint: Color {
        if isActivated {
            return Color(red: 0.54, green: 0.88, blue: 0.70)
        }

        return Color.white.opacity(0.82)
    }

    private var symbol: String {
        if isActivated {
            return "line.3.horizontal.decrease.circle.fill"
        }

        return "line.3.horizontal.circle"
    }

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.26, extraBounce: 0.02)) {
                model.showsOnlyActiveChannels.toggle()
            }
        } label: {
            HeaderChipLabel(
                symbol: symbol,
                title: "\(model.activeAmbientChannelsCount)",
                tint: tint,
                isActivated: isActivated,
                expands: false
            )
        }
        .accessibilityIdentifier("home.header.active-filter")
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct HeaderChipLabel: View {
    let symbol: String
    let title: String
    let tint: Color
    var isActivated = false
    var expands = true

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: expands ? .infinity : nil)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: Capsule())
            if isActivated {
                Capsule().fill(tint.opacity(0.18))
            }
        }
        .contentShape(Capsule())
        .shadow(color: isActivated ? tint.opacity(0.06) : .clear, radius: 8, y: 2)
        .fixedSize(horizontal: !expands, vertical: false)
        .animation(.smooth(duration: 0.22), value: isActivated)
    }
}

private struct PanelTriggerChip: View {
    let symbol: String
    let title: String
    let tint: Color
    let isActivated: Bool
    let palette: [Color]

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: Capsule())
            if isActivated {
                Capsule().fill(tint.opacity(0.18))
            }
        }
        .contentShape(Capsule())
        .shadow(color: isActivated ? tint.opacity(0.04) : .clear, radius: 8, y: 2)
        .animation(.smooth(duration: 0.22), value: isActivated)
    }
}
