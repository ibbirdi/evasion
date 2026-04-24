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

/// Toggles "show only audible channels". Native nav-bar button; SF Symbol swaps between
/// outline and filled to signal state, tint turns mint green when on.
struct HomeToolbarActiveFilter: View {
    @Environment(AppModel.self) private var model

    private var isActivated: Bool {
        model.showsOnlyActiveChannels
    }

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.26, extraBounce: 0.02)) {
                model.showsOnlyActiveChannels.toggle()
            }
        } label: {
            Image(systemName: isActivated
                ? "line.3.horizontal.decrease.circle.fill"
                : "line.3.horizontal.decrease.circle")
                .foregroundStyle(isActivated
                    ? Color(red: 0.54, green: 0.88, blue: 0.70)
                    : .white.opacity(0.86))
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityIdentifier("home.header.active-filter")
        .accessibilityLabel("Show only active channels")
    }
}
