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
            // Padding grown from 12 → 20 to give the wave a 16pt drawing zone; the
            // .background overlay anchors to the bottom of this padded text frame so the
            // wave sits in the bottom 16pt of the 20pt padding.
            .padding(.bottom, 20)
            .background(alignment: .bottom) {
                WaveformSignatureLine()
                    .frame(maxWidth: .infinity, maxHeight: 16)
            }
            .frame(maxWidth: .infinity)
            // Total content is 22pt wordmark + 20pt padding (with 16pt wave inside) = 42pt.
            // Frame matched exactly so the lockup collapses cleanly with `visibility`.
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
/// view smoothly morphs between via an explicit time-based phase:
///
/// - **Paused** (`phase` = 0): a single regular sinusoid, slow speed, moderate amplitude.
/// - **Playing** (`phase` = 1): three detuned sines plus a drift term, faster speed, much
///   larger amplitude. The shape never repeats exactly.
///
/// Transition: when `model.isPlaying` flips, we capture the current interpolated phase as
/// `phaseFrom`, set `phaseTo` to the new target, and stamp `transitionStartTime`. Every
/// TimelineView tick computes the current phase from `(now - start) / duration` clamped
/// and eased — so the wave morphs frame-by-frame for the full 0.7 s, even though the
/// drawing happens inside a `Canvas` (where SwiftUI's `withAnimation` does NOT interpolate
/// raw `@State Double` values, since the canvas isn't an animatable view).
private struct WaveformSignatureLine: View {
    @Environment(AppModel.self) private var model

    @State private var phaseFrom: Double = 0
    @State private var phaseTo: Double = 0
    @State private var transitionStartTime: TimeInterval = 0
    @State private var hasInitialised = false

    private static let transitionDuration: Double = 0.40

    var body: some View {
        // Under UI-test automation, freeze the timeline so XCUITest can reach quiescence
        // for screenshot capture.
        let shouldPause = AppConfiguration.isRunningScreenshotAutomation
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: shouldPause)) { context in
            let now = AppConfiguration.isRunningScreenshotAutomation
                ? 3.4
                : context.date.timeIntervalSinceReferenceDate
            let phase = computePhase(at: now)
            let palette = model.activePlaybackPalette

            Canvas { gc, size in
                drawWave(
                    gc: gc,
                    size: size,
                    time: now,
                    palette: palette,
                    paletteCount: palette.count,
                    phase: phase
                )
            }
        }
        .onAppear {
            initialiseIfNeeded()
        }
        .onChange(of: model.isPlaying) { _, newValue in
            startTransition(toPlaying: newValue)
        }
    }

    private func initialiseIfNeeded() {
        guard !hasInitialised else { return }
        let initial: Double = model.isPlaying ? 1 : 0
        phaseFrom = initial
        phaseTo = initial
        // A start time far in the past means the transition is already complete — phase
        // returns `phaseTo` immediately.
        transitionStartTime = 0
        hasInitialised = true
    }

    private func startTransition(toPlaying: Bool) {
        let now = Date().timeIntervalSinceReferenceDate
        // Capture wherever the wave currently is, so rapid play/pause toggles animate
        // smoothly from the in-flight value rather than snapping back to phaseFrom.
        phaseFrom = computePhase(at: now)
        phaseTo = toPlaying ? 1 : 0
        transitionStartTime = now
    }

    private func computePhase(at now: TimeInterval) -> Double {
        // Default: target value (no transition in progress, or we're past the duration).
        guard transitionStartTime > 0 else { return phaseTo }
        let elapsed = now - transitionStartTime
        if elapsed >= Self.transitionDuration { return phaseTo }
        if elapsed <= 0 { return phaseFrom }
        let t = elapsed / Self.transitionDuration
        // Smoothstep — ease in and ease out.
        let eased = t * t * (3 - 2 * t)
        return phaseFrom + (phaseTo - phaseFrom) * eased
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

        let p = max(0, min(1, phase))

        // Speed: 0.40 at rest → 0.65 at playback. Modest bump ("un peu plus rapide");
        // larger jumps caused the lateral motion to read as accelerating rubbery during
        // the transition.
        let speed = 0.40 + (0.65 - 0.40) * p
        let phaseTime = time * speed

        // Single sine baseline at all times — a slow drift overlay fades in only during
        // playback. Previously three different harmonics faded in concurrently, which
        // made the line gain new bumps at different frequencies during the transition
        // and read as "spring-like" / chaotic. One harmonic + drift keeps the lateral
        // shape continuous.
        let driftMix = 0.30 * p

        // Idle amplitude pulled back to 0.22 (was 0.40) — visible but subtle. Playback
        // amplitude bumped, capped at 1.20 (was 1.40) so peaks no longer graze the
        // bottom edge of the canvas.
        let idleAmp = 0.22
        let playAmp = min(1.20, 0.85 + Double(paletteCount) * 0.08)
        let amplitude = idleAmp + (playAmp - idleAmp) * p

        // Slow envelope modulator. Constant 1.0 at rest; 0.7…1.0 during playback so peaks
        // breathe rather than cycling at the same height.
        let envelopeNoise = 1.0 + (0.7 + 0.3 * sin(time * 0.42) - 1.0) * p

        path.move(to: CGPoint(x: 0, y: midY))

        var x: Double = 0
        while x <= Double(width) {
            let nx = x / Double(width)

            // Primary sine + slow drift overlay. driftMix → 0 at idle, 0.30 at play.
            let primary = sin(nx * 4.5 * .pi + phaseTime)
            let drift = sin(nx * 1.7 * .pi + time * 0.6)
            let wave = primary + drift * driftMix

            // Raised-sine envelope tapers both ends to zero so the line fades in/out
            // instead of stopping abruptly at the edges of the frame.
            let envelope = sin(nx * .pi)
            let yRaw = midY + amplitude * envelopeNoise * Double(size.height) * 0.27 * wave * envelope
            // Safety clamp: keep the stroke inside the canvas with a 1pt margin even on
            // edge cases where primary + drift align at high amplitude.
            let y = min(max(yRaw, 1), Double(size.height) - 1)

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
