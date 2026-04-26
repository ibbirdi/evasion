import SwiftUI
import UIKit

/// Floating header, rendered above the home backdrop inside the ZStack. Reduced to the
/// brand lockup (wordmark + waveform) after the per-surface chips moved to the navigation
/// bar's native toolbar — kept custom because the animated waveform isn't a standard
/// control surface.
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

/// Signature line rendered beneath the OASIS wordmark. Has two character states that the
/// view smoothly interpolates between:
///
/// - **Paused** (`playingPhase` = 0): a single regular sinusoid, slow phase, moderate
///   amplitude. Reads as a quiet pulse — the wordmark is alive but at rest.
/// - **Playing** (`playingPhase` = 1): three detuned sines plus a long-period drift term,
///   faster phase, larger amplitude. The shape never repeats exactly.
///
/// `playingPhase` is animated by `withAnimation(.easeInOut)` whenever `model.isPlaying`
/// flips. Each TimelineView tick during the transition reads the current interpolated
/// value, so the wave morphs continuously between the two characters.
private struct WaveformSignatureLine: View {
    @Environment(AppModel.self) private var model
    @State private var playingPhase: Double = 0

    var body: some View {
        // Under UI-test automation, freeze the timeline so XCUITest can reach quiescence
        // for screenshot capture.
        let shouldPause = AppConfiguration.isRunningScreenshotAutomation
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: shouldPause)) { context in
            let palette = model.activePlaybackPalette
            Canvas { gc, size in
                drawWave(
                    gc: gc,
                    size: size,
                    time: AppConfiguration.isRunningScreenshotAutomation
                        ? 3.4
                        : context.date.timeIntervalSinceReferenceDate,
                    palette: palette,
                    paletteCount: palette.count,
                    phase: playingPhase
                )
            }
        }
        .onAppear {
            playingPhase = model.isPlaying ? 1 : 0
        }
        .onChange(of: model.isPlaying) { _, newValue in
            withAnimation(.easeInOut(duration: 0.7)) {
                playingPhase = newValue ? 1 : 0
            }
        }
    }

    private func drawWave(
        gc: GraphicsContext,
        size: CGSize,
        time: TimeInterval,
        palette: [Color],
        paletteCount: Int,
        phase: Double
    ) {
        var path = Path()
        let midY = size.height / 2
        let width = size.width
        let step: Double = 1.4

        // Phase clamps. SwiftUI's animator can briefly overshoot a State Double, so guard
        // against negative weights or amplitude.
        let p = max(0, min(1, phase))

        // Speed: 0.40 at rest → 1.05 at full playback. Slightly faster than the previous
        // 0.9 so the playing motion reads as more energetic.
        let speed = 0.40 + (1.05 - 0.40) * p
        let phaseTime = time * speed

        // Harmonic weights interpolate from "single regular sinusoid" (paused) to "three
        // detuned sines + drift" (playing).
        let primaryWeight = 1.00 + (0.55 - 1.00) * p
        let secondaryWeight = 0.0 + (0.30 - 0.0) * p
        let tertiaryWeight = 0.0 + (0.15 - 0.0) * p
        let driftWeight = 0.0 + (0.18 - 0.0) * p

        // Amplitude grows with the active-channel count during playback. Idle amplitude
        // bumped from the previous 0.18 to 0.30 so the resting motion feels intentional.
        let idleAmp = 0.30
        let playAmp = min(1.0, 0.55 + Double(paletteCount) * 0.13)
        let amplitude = idleAmp + (playAmp - idleAmp) * p

        // Slow envelope modulator, scaled in proportion to the playing phase. At rest it's
        // a constant 1.0; during playback it varies between 0.7 and 1.0 over time so peaks
        // breathe instead of sitting at the same height.
        let envelopeNoise = 1.0 + (0.7 + 0.3 * sin(time * 0.42) - 1.0) * p

        path.move(to: CGPoint(x: 0, y: midY))

        var x: Double = 0
        while x <= Double(width) {
            let nx = x / Double(width)           // 0 ... 1

            let wave =
                sin(nx * 4.5 * .pi + phaseTime) * primaryWeight +
                sin(nx * 7.0 * .pi + phaseTime * 1.4) * secondaryWeight +
                sin(nx * 10.0 * .pi + phaseTime * 1.8) * tertiaryWeight +
                sin(nx * 1.7 * .pi + time * 0.6) * driftWeight

            // Raised-sine envelope tapers both ends to zero so the line fades in/out
            // instead of stopping abruptly at the edges of the frame.
            let envelope = sin(nx * .pi)
            let y = midY + amplitude * envelopeNoise * Double(size.height) * 0.46 * wave * envelope

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

        gc.stroke(path, with: shading, lineWidth: 1.6)
    }
}

// MARK: - Native toolbar items

/// Sleep-timer picker, rendered as a native nav-bar Menu. The label adapts: just an icon
/// when no timer is set, icon + remaining time while counting down.
struct HomeToolbarTimerMenu: View {
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
            if model.timerDurationMinutes != nil {
                Label(model.timerToolbarTitle, systemImage: "timer")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(Color(red: 0.52, green: 0.91, blue: 0.64))
                    .contentTransition(.numericText(countsDown: true))
            } else {
                Image(systemName: "timer")
                    .foregroundStyle(.white.opacity(0.86))
            }
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
                    if count > 0 {
                        badge
                    }
                }
                // Reserve space so the badge doesn't get clipped against the toolbar's
                // tight frame around the SF Symbol's intrinsic bounds.
                .padding(.trailing, 4)
                .padding(.top, 2)
        }
        .accessibilityIdentifier("home.header.active-filter")
        .accessibilityLabel(accessibilityLabel)
    }

    /// Pill-shaped numeric badge. Picks up the active-state mint accent when the filter
    /// is on; falls back to a neutral white wash when the filter is off but channels
    /// are still audible — so the count remains readable without implying the filter
    /// is engaged.
    private var badge: some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.black.opacity(0.86))
            .monospacedDigit()
            .padding(.horizontal, 4)
            .padding(.vertical, 0.5)
            .frame(minWidth: 15, minHeight: 15)
            .background {
                Capsule()
                    .fill(isActivated ? Self.activeAccent : Color.white.opacity(0.86))
            }
            .overlay {
                Capsule().strokeBorder(Color.black.opacity(0.08), lineWidth: 0.5)
            }
            // Sits in the top-trailing corner of the SF Symbol, partially overhanging
            // its bounding box the way iOS notification badges do.
            .offset(x: 9, y: -8)
            .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        if count > 0 {
            return "Show only active channels. \(count) active."
        }
        return "Show only active channels"
    }
}
