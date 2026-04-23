import SwiftUI

/// Full-screen immersive backdrop for the home surface. Replaces the static `AnimatedBackdrop`
/// when the device can afford the live shader; falls back to the static version under
/// Reduce Motion or Low Power Mode so battery and accessibility preferences are honored.
///
/// Composition, back to front:
///   1. A deep dark gradient so the scene has a stable base even if the shader is masked.
///   2. `LiquidAuraBackdrop` — the Metal shader breathing slowly with the channel palette.
///   3. `TimeOfDayTint` — a subtle color-temperature wash tied to the system clock.
///   4. Vertical dim + radial vignette — preserves UI legibility against the moving backdrop.
struct ImmersionBackdrop: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    private var useStaticFallback: Bool {
        reduceMotion || isLowPowerMode
    }

    var body: some View {
        Group {
            if useStaticFallback {
                AnimatedBackdrop()
            } else {
                liveBackdrop
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            isLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }

    private var liveBackdrop: some View {
        ZStack {
            baseGradient

            LiquidAuraBackdrop(palette: backdropPalette)

            TimeOfDayTint(timeOfDay: timeOfDay)

            // Vertical dim keeps the toolbar readable against the brightest shader frames.
            LinearGradient(
                colors: [
                    Color.black.opacity(0.04),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.38)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            // Radial vignette: quiet center, darker edges. Helps the eye settle on the
            // mixer column even when the backdrop has high-contrast moments.
            GeometryReader { proxy in
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.10),
                                Color.black.opacity(0.32)
                            ],
                            center: .center,
                            startRadius: 24,
                            endRadius: max(proxy.size.width, proxy.size.height) * 0.88
                        )
                    )
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }

    private var backdropPalette: [Color] {
        // Reuse AppModel's curated playback palette so the shader room matches the mixer
        // state. When no channel is audible the palette is empty — LiquidAuraBackdrop
        // substitutes a quiet neutral internally.
        let palette = model.activePlaybackPalette
        if palette.isEmpty {
            // Silent mixer: surface the three starter tints so the app never renders pure
            // black while the user is deciding what to listen to.
            return [
                SoundChannel.oiseaux.tint,
                SoundChannel.vent.tint,
                SoundChannel.plage.tint
            ]
        }
        return palette
    }

    private var timeOfDay: TimeOfDay {
        model.currentScene?.timeOfDay ?? TimeOfDay.current()
    }

    private var baseGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.03, blue: 0.06),
                Color(red: 0.03, green: 0.03, blue: 0.07),
                Color(red: 0.02, green: 0.03, blue: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
