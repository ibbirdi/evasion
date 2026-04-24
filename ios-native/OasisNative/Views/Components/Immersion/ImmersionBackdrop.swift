import SwiftUI

/// Full-screen backdrop for the home surface. Composes the production `AnimatedBackdrop`
/// (static three-ellipse palette + vignette, reverted here after the LiquidAura shader
/// experiment introduced contrast regressions) with a particle overlay tied to whichever
/// channel is dominant in the mix. The particle layer is the only moving element — the
/// base gradient is intentionally quiet so the particles read.
struct ImmersionBackdrop: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AnimatedBackdrop()

            if !reduceMotion {
                ParticleField(
                    style: dominantParticleStyle,
                    tint: dominantTint ?? .white
                )
            }
        }
        .ignoresSafeArea()
    }

    /// Dominant unmuted, audible channel by volume. Iterates `allCases` so ties break on
    /// declaration order, preventing flicker when two channels share volume. Locked
    /// channels are skipped — a non-premium user's mix only pulls particles from channels
    /// they can actually hear.
    private var dominantChannel: SoundChannel? {
        var best: SoundChannel?
        var bestVolume: Double = 0
        for channel in SoundChannel.allCases {
            guard let state = model.channels[channel], !state.isMuted else { continue }
            guard !model.isChannelLocked(channel) else { continue }
            if state.volume > bestVolume {
                bestVolume = state.volume
                best = channel
            }
        }
        return best
    }

    private var dominantParticleStyle: ParticleStyle {
        dominantChannel?.particleStyle ?? .none
    }

    private var dominantTint: Color? {
        dominantChannel?.tint
    }
}
