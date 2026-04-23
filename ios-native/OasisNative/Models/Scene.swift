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
