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
            // 25pt padding-bottom gives the wave a 24pt drawing zone with 1pt of gap
            // between the wordmark and the top of the wave — tight visual coupling
            // so the wave reads as the wordmark's underline, not a separate element.
            // Wave anchors to the bottom of this padded text frame.
            .padding(.bottom, 25)
            .background(alignment: .bottom) {
                WaveformSignatureLine()
                    .frame(maxWidth: .infinity, maxHeight: 24)
            }
            .frame(maxWidth: .infinity)
            // Total content is 22pt wordmark + 25pt padding (with 24pt wave inside) = 47pt.
            .frame(height: 47 * visibility, alignment: .top)
            .opacity(visibility)
            .scaleEffect(0.92 + (visibility * 0.08), anchor: .top)
            .clipped()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(L10n.App.title)
            .animation(.smooth(duration: 0.18), value: visibility)
    }
}

/// Signature line rendered beneath the OASIS wordmark. Two character states the view
/// morphs between via an explicit time-based crossfade:
///
/// - **Paused** (`p` = 0): a single regular sinusoid, slow accumulated phase, subtle
///   amplitude.
/// - **Playing** (`p` = 1): same primary sinusoid + a slow drift overlay, faster phase,
///   noticeably larger amplitude.
///
/// Why an integrated phase accumulator. The naive formula `phaseTime = time × speed`
/// is unusable here because `time` (`timeIntervalSinceReferenceDate`) is on the order
/// of 7 × 10⁸ at runtime. Interpolating `speed` during the transition makes
/// `phaseTime` jump by ~10⁸ units per frame even though the change in `speed` is
/// fractional, producing the "spring going in all directions" effect users reported.
/// Instead, `PhaseAccumulator` integrates `dt × speed` each tick, so changes in
/// `speed` only change the *derivative* of phase, never its instantaneous value.
private struct WaveformSignatureLine: View {
    @Environment(AppModel.self) private var model

    @State private var transitionFrom: Double = 0
    @State private var transitionTo: Double = 0
    @State private var transitionStartTime: TimeInterval = 0
    @State private var hasInitialised = false
    @State private var phaseAccumulator = PhaseAccumulator()

    private static let transitionDuration: Double = 0.40

    var body: some View {
        let shouldPause = AppConfiguration.isRunningScreenshotAutomation
        TimelineView(.animation(minimumInterval: 1.0 / 24.0, paused: shouldPause)) { context in
            let now = AppConfiguration.isRunningScreenshotAutomation
                ? 3.4
                : context.date.timeIntervalSinceReferenceDate
            let p = computePhaseProgress(at: now)
            let palette = model.activePlaybackPalette

            // Speed varies between idle (0.40) and playback (0.95). The accumulator
            // integrates this over time so transitions don't lurch.
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
        // Capture wherever the wave currently is so rapid toggles re-aim from the in-
        // flight value rather than snapping back to the previous start.
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

        // Drift overlay only fades in during playback; idle stays a clean single sinusoid.
        let driftMix = 0.30 * pClamped

        // Idle 0.22 (subtle); play capped at 1.20.
        let idleAmp = 0.22
        let playAmp = min(1.20, 0.85 + Double(paletteCount) * 0.08)
        let amplitude = idleAmp + (playAmp - idleAmp) * pClamped

        // Slow envelope breathing during playback only. At rest = constant 1.0.
        let envelopeNoise = 1.0 + (0.7 + 0.3 * sin(time * 0.42) - 1.0) * pClamped

        // Multiplier 0.20 chosen so peak excursion stays well clear of the canvas
        // edges, accounting for the larger 2.0pt stroke. With 24pt canvas:
        // peak ≤ 1.20 × 1.30 × 1.0 × 24 × 0.20 = 7.49pt vs. 10.5pt available from
        // midY (after 1.5pt half-stroke + cushion margin) → ~28% headroom.
        let multiplier: Double = 0.20

        path.move(to: CGPoint(x: 0, y: midY))

        var x: Double = 0
        while x <= Double(width) {
            let nx = x / Double(width)

            let primary = sin(nx * 4.5 * .pi + phaseTime)
            let drift = sin(nx * 1.7 * .pi + time * 0.6)
            let wave = primary + drift * driftMix

            let envelope = sin(nx * .pi)
            let yRaw = midY + amplitude * envelopeNoise * Double(size.height) * multiplier * wave * envelope

            // Stroke half-width margin: stroke = 2.0 pt, so each side needs 1.0 pt clear.
            // Extra 0.5 pt cushion absorbs sub-pixel rounding from SwiftUI layout and
            // prevents the bottom-edge "overflow hidden" clipping users were seeing.
            let strokeMargin: Double = 1.5
            let y = min(max(yRaw, strokeMargin), Double(size.height) - strokeMargin)

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

        gc.stroke(path, with: shading, lineWidth: 2.0)
    }
}

/// Reference-typed phase integrator owned by `WaveformSignatureLine`. Stores accumulated
/// phase + the timestamp of the last advance so the next call can integrate `dt × speed`.
/// Class semantics on purpose: SwiftUI's `@State` keeps a stable reference for the view's
/// lifetime, and mutating the object's properties from inside the Canvas closure does
/// *not* trigger a body invalidation (which is exactly what we want — the closure is the
/// only writer, the next frame just reads the new accumulated value).
private final class PhaseAccumulator {
    private var phase: Double = 0
    private var lastTime: TimeInterval = -1

    func advance(to now: TimeInterval, speed: Double) -> Double {
        defer { lastTime = now }
        guard lastTime > 0, now > lastTime else { return phase }
        // Clamp the per-tick delta. When the app is backgrounded then resumed, `now`
        // jumps by seconds or minutes — without the clamp the wave would suddenly
        // catapult through hundreds of cycles in one frame.
        let dt = min(now - lastTime, 0.5)
        phase += dt * speed
        // Periodically wrap to prevent floating-point precision loss over a long
        // session. 2π ≈ 6.28 wave cycles, so wrapping at 10 000 cycles keeps phase
        // values modest without introducing visible discontinuity (sin is 2π-periodic).
        if phase > 10_000 * .pi * 2 {
            phase = phase.truncatingRemainder(dividingBy: 2 * .pi)
        }
        return phase
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
