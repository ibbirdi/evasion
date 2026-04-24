import Foundation
import SwiftUI

/// Category of ambient particle rendered above the backdrop. Each style has its own spawn
/// pattern, velocity, and color behavior in `ParticleField`.
enum ParticleStyle: Equatable {
    /// Downward drops — thin streaks, quick fall. Rain, storm, rain-on-tent.
    case rain

    /// Rising glowing specks — slight flicker, warm. Fire, campfire.
    case embers

    /// Slow floating luminous points — occasional twinkle. Insects at night, fireflies.
    case fireflies

    /// Very slow, near-horizontal drifting specks. Forest air, savanna dust, pollen, wind.
    case motes

    /// Horizontal diffuse wisps — long, low opacity. Mist near water, spray on shore.
    case mist

    /// No particle layer — the backdrop alone carries the scene.
    case none
}

extension SoundChannel {
    /// Particle style tied to this channel's character. Every outdoor/nature channel returns
    /// a non-`.none` style so at least some atmosphere surfaces on any active mix. Urban /
    /// transport channels stay quiet since their character is rhythmic, not weather-like.
    var particleStyle: ParticleStyle {
        switch self {
        case .pluie, .tonnerre, .tente: return .rain
        case .campfire: return .embers
        case .grillons: return .fireflies
        case .riviere, .lac: return .mist
        case .plage, .goelands: return .mist
        case .foret, .savane, .jungleAmerique, .jungleAsie, .oiseaux, .cigales, .vent:
            return .motes
        case .village, .voiture, .train, .cafe:
            return .none
        }
    }
}
