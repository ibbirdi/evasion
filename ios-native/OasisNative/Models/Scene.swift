import Foundation
import SwiftUI

/// Snapshot of the place the user is hearing right now. Derived by `SceneCoordinator` from
/// the active preset and the dominant channel, plus the current time of day. Only populated
/// once there is at least one audible channel — a silent mixer has no scene.
struct CurrentScene: Equatable {
    /// Stable identity that changes only when the derived place changes. The SceneCard uses
    /// this to decide when to re-emerge from the dimmed state.
    let id: String

    /// Short place label. Sourced from the preset narrative when available, otherwise from
    /// the dominant channel's documented location.
    let placeLine: String

    /// One concrete sensory detail. Deliberately short — nil when no curated line is available
    /// for this scene (shown as a minimal card in that case).
    let detailLine: String?

    /// System clock snapshot at derivation. Formatted by the UI; held here so the card does
    /// not update every second during playback.
    let capturedAt: Date

    let timeOfDay: TimeOfDay

    /// Dominant channel tint used to accent the card and the entry ritual text.
    let tint: Color

    /// Visual particle atmosphere attached to the scene. Rendered by `ParticleField` above
    /// the LiquidAura backdrop. Derived from the dominant audible channel.
    let particleStyle: ParticleStyle
}

/// Category of ambient particle rendered above the backdrop. Each style has its own spawn
/// pattern, velocity, and color behavior in `ParticleField`.
enum ParticleStyle: Equatable {
    /// Downward drops — thin streaks, quick fall. Rain, storm.
    case rain

    /// Rising glowing specks — slight flicker, warm. Fire, campfire.
    case embers

    /// Slow floating luminous points — occasional twinkle. Insects at night, fireflies.
    case fireflies

    /// Very slow, near-horizontal drifting specks. Forest air, savanna dust, pollen.
    case motes

    /// Horizontal diffuse wisps — long, low opacity. Mist near water.
    case mist

    /// No particle layer — the shader + tint alone carry the scene.
    case none
}

extension SoundChannel {
    /// Particle style tied to this channel's character. Kept in sync with the rendering code
    /// in `ParticleField`; a style here without a rendering there (or vice versa) silently
    /// falls back to `.none` so the system fails quiet rather than loud.
    var particleStyle: ParticleStyle {
        switch self {
        case .pluie, .tonnerre: return .rain
        case .campfire: return .embers
        case .grillons: return .fireflies
        case .riviere, .lac: return .mist
        case .foret, .savane, .jungleAmerique, .jungleAsie: return .motes
        case .oiseaux, .vent, .plage, .goelands, .cigales,
             .tente, .village, .voiture, .train, .cafe:
            return .none
        }
    }
}

/// Coarse buckets for the time-of-day palette and narrative tone. Transitions are handled at
/// the palette layer, not here — this enum is purely categorical.
enum TimeOfDay: Equatable {
    case dawn
    case morning
    case noon
    case afternoon
    case dusk
    case evening
    case night

    static func current(at date: Date = Date(), calendar: Calendar = .current) -> TimeOfDay {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<7: return .dawn
        case 7..<11: return .morning
        case 11..<14: return .noon
        case 14..<17: return .afternoon
        case 17..<19: return .dusk
        case 19..<22: return .evening
        default: return .night
        }
    }
}
