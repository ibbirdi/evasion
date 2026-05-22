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

    private static let lockupSize: CGFloat = 158
    private static let visualCanvasSize: CGFloat = 208
    private static let ringSize: CGFloat = 118
    private static let expandedHeightCap: CGFloat = 165

    var body: some View {
        ZStack {
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

            OasisHeaderWordmark()
        }
        .frame(width: Self.visualCanvasSize, height: Self.visualCanvasSize)
        .offset(y: -30)
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
}

private struct OasisHeaderWordmark: View {
    private static let letters: [(id: Int, value: String)] = [
        (0, "O"),
        (1, "A"),
        (2, "S"),
        (3, "I"),
        (4, "S")
    ]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Self.letters, id: \.id) { letter in
                Text(verbatim: letter.value)
            }
        }
        .oasisFont(size: 18, weight: .semibold, design: .default, relativeTo: .title3)
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

                if model.immersiveAudioEnabled {
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
        .accessibilityLabel(Text(L10n.Header.activeFilter))
        .accessibilityValue(Text(isActivated ? L10n.Header.activeFilterOn : L10n.Header.activeFilterOff))
    }

    /// Pill-shaped numeric badge. Picks up the active-state mint accent when the filter
    /// is on; falls back to a neutral white wash when the filter is off but channels
    /// are still audible — so the count remains readable without implying the filter
    /// is engaged.
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

}
