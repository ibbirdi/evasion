import Foundation
import SwiftUI

enum OasisGlyph: String, Sendable {
    case airplaneTilt = "oasis_glyph_airplane_tilt"
    case bell = "oasis_glyph_bell"
    case bird = "oasis_glyph_bird"
    case bookOpenText = "oasis_glyph_book_open_text"
    case bug = "oasis_glyph_bug"
    case checkFat = "oasis_glyph_check_fat"
    case cloudFog = "oasis_glyph_cloud_fog"
    case cloudRain = "oasis_glyph_cloud_rain"
    case coffee = "oasis_glyph_coffee"
    case drop = "oasis_glyph_drop"
    case fan = "oasis_glyph_fan"
    case flame = "oasis_glyph_flame"
    case house = "oasis_glyph_house"
    case leaf = "oasis_glyph_leaf"
    case lightning = "oasis_glyph_lightning"
    case moonStars = "oasis_glyph_moon_stars"
    case musicNote = "oasis_glyph_music_note"
    case sailboat = "oasis_glyph_sailboat"
    case shieldCheck = "oasis_glyph_shield_check"
    case snowflake = "oasis_glyph_snowflake"
    case sparkle = "oasis_glyph_sparkle"
    case sunHorizon = "oasis_glyph_sun_horizon"
    case target = "oasis_glyph_target"
    case tent = "oasis_glyph_tent"
    case tree = "oasis_glyph_tree"
    case waveform = "oasis_glyph_waveform"
    case waves = "oasis_glyph_waves"
    case wind = "oasis_glyph_wind"
}

enum AmbienceIntent: String, CaseIterable, Codable, Identifiable, Sendable {
    case sleep
    case focus
    case travel
    case reading
    case reset

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .sleep: return "moon.stars.fill"
        case .focus: return "scope"
        case .travel: return "airplane"
        case .reading: return "book.closed.fill"
        case .reset: return "sparkles"
        }
    }

    var oasisGlyph: OasisGlyph {
        switch self {
        case .sleep: return .moonStars
        case .focus: return .target
        case .travel: return .airplaneTilt
        case .reading: return .bookOpenText
        case .reset: return .sparkle
        }
    }

    var tint: Color {
        switch self {
        case .sleep: return Color(red: 0.46, green: 0.62, blue: 0.96)
        case .focus: return Color(red: 0.94, green: 0.72, blue: 0.42)
        case .travel: return Color(red: 0.56, green: 0.82, blue: 0.88)
        case .reading: return Color(red: 0.74, green: 0.82, blue: 0.58)
        case .reset: return Color(red: 0.88, green: 0.76, blue: 0.94)
        }
    }
}

enum ProceduralNoise: String, CaseIterable, Codable, Identifiable, Sendable {
    case white
    case brown
    case pink
    case green
    case fan
    case aircraft

    var id: String { rawValue }

    var isPremium: Bool {
        switch self {
        case .white, .brown:
            return false
        case .pink, .green, .fan, .aircraft:
            return true
        }
    }

    var systemImage: String {
        switch self {
        case .white: return "sparkle"
        case .brown: return "circle.lefthalf.filled"
        case .pink: return "waveform.path.ecg"
        case .green: return "leaf.fill"
        case .fan: return "fan.fill"
        case .aircraft: return "airplane"
        }
    }

    var tint: Color {
        switch self {
        case .white: return Color(red: 0.80, green: 0.86, blue: 0.92)
        case .brown: return Color(red: 0.72, green: 0.58, blue: 0.42)
        case .pink: return Color(red: 0.96, green: 0.62, blue: 0.74)
        case .green: return Color(red: 0.50, green: 0.82, blue: 0.58)
        case .fan: return Color(red: 0.62, green: 0.78, blue: 0.92)
        case .aircraft: return Color(red: 0.56, green: 0.70, blue: 0.90)
        }
    }
}

struct ProceduralNoiseState: Codable, Equatable, Sendable {
    var volume: Double
    var isMuted: Bool

    init(volume: Double = 0.42, isMuted: Bool = true) {
        self.volume = AutoVariationRange.unitValue(volume, fallback: 0.42)
        self.isMuted = isMuted
    }
}

struct AmbienceRecipe: Identifiable, Equatable, Sendable {
    let id = UUID()
    var title: String
    var subtitle: String
    var intent: AmbienceIntent
    var channels: [SoundChannel: ChannelState]
    var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]
    var isBinauralActive: Bool
    var binauralTrack: BinauralTrack
    var binauralVolume: Double
    var timerMinutes: Int?
    var immersiveAudioEnabled: Bool

    var activeChannels: [SoundChannel] {
        SoundChannel.allCases.filter { channel in
            channels[channel]?.isMuted == false
        }
    }

    var activeNoises: [ProceduralNoise] {
        ProceduralNoise.allCases.filter { noise in
            proceduralNoises[noise]?.isMuted == false
        }
    }

    var requiresPremium: Bool {
        activeChannels.contains { !SoundChannel.freeChannels.contains($0) }
            || activeNoises.contains(where: \.isPremium)
            || (isBinauralActive && binauralTrack.isPremium)
            || (timerMinutes ?? 0) > 30
    }
}

struct RitualPhase: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var subtitle: String
    var durationSeconds: TimeInterval
    var recipe: AmbienceRecipe
}

struct RitualPreset: Identifiable, Equatable, Sendable {
    let id: String
    var title: String
    var subtitle: String
    var systemImage: String
    var tint: Color
    var phases: [RitualPhase]

    var totalDurationSeconds: TimeInterval {
        phases.reduce(0) { $0 + $1.durationSeconds }
    }

    var totalMinutes: Int {
        max(Int((totalDurationSeconds / 60).rounded()), 1)
    }

    var requiresPremium: Bool {
        phases.contains { $0.recipe.requiresPremium }
    }
}

struct ActiveRitualSession: Codable, Equatable {
    var ritualID: String
    var ritualTitle: String
    var intent: AmbienceIntent
    var phaseIndex: Int
    var phaseCount: Int
    var phaseTitle: String
    var phaseStartDate: Date
    var phaseEndDate: Date
    var phaseDurationSeconds: TimeInterval
    var totalEndDate: Date
    var phaseRemainingWhenPaused: TimeInterval?
    var totalRemainingWhenPaused: TimeInterval?

    var phaseNumberText: String {
        "\(phaseIndex + 1)/\(max(phaseCount, 1))"
    }

    func phaseProgress(at date: Date) -> Double {
        let phaseDuration = max(phaseDurationSeconds, 1)
        let elapsed: TimeInterval

        if let phaseRemainingWhenPaused {
            elapsed = phaseDuration - phaseRemainingWhenPaused
        } else {
            elapsed = date.timeIntervalSince(phaseStartDate)
        }

        return min(max(elapsed / phaseDuration, 0), 1)
    }

    func totalRemainingMinutes(at date: Date) -> Int {
        let remaining = totalRemainingWhenPaused ?? totalEndDate.timeIntervalSince(date)
        return max(Int(ceil(remaining / 60)), 0)
    }
}

extension Dictionary where Key == ProceduralNoise, Value == ProceduralNoiseState {
    static var initialNoises: [ProceduralNoise: ProceduralNoiseState] {
        ProceduralNoise.allCases.reduce(into: [:]) { partialResult, noise in
            partialResult[noise] = ProceduralNoiseState()
        }
    }
}

extension RitualPreset {
    static var builtIns: [RitualPreset] {
        [
            sleepDescent,
            deepWork,
            travelShield,
            readingRoom
        ]
    }

    private static var sleepDescent: RitualPreset {
        RitualPreset(
            id: "ritual_sleep_descent",
            title: L10n.string(L10n.Compose.ritualSleepTitle),
            subtitle: L10n.string(L10n.Compose.ritualSleepSubtitle),
            systemImage: "moon.stars.fill",
            tint: AmbienceIntent.sleep.tint,
            phases: [
                RitualPhase(
                    id: "settle",
                    title: L10n.string(L10n.Compose.ritualSleepPhaseSettleTitle),
                    subtitle: L10n.string(L10n.Compose.ritualSleepPhaseSettleSubtitle),
                    durationSeconds: 8 * 60,
                    recipe: AmbienceComposer.template(intent: .sleep, premium: false, variant: .opening)
                ),
                RitualPhase(
                    id: "drift",
                    title: L10n.string(L10n.Compose.ritualSleepPhaseDriftTitle),
                    subtitle: L10n.string(L10n.Compose.ritualSleepPhaseDriftSubtitle),
                    durationSeconds: 14 * 60,
                    recipe: AmbienceComposer.template(intent: .sleep, premium: false, variant: .middle)
                ),
                RitualPhase(
                    id: "fade",
                    title: L10n.string(L10n.Compose.ritualSleepPhaseFadeTitle),
                    subtitle: L10n.string(L10n.Compose.ritualSleepPhaseFadeSubtitle),
                    durationSeconds: 8 * 60,
                    recipe: AmbienceComposer.template(intent: .sleep, premium: false, variant: .ending)
                )
            ]
        )
    }

    private static var deepWork: RitualPreset {
        RitualPreset(
            id: "ritual_deep_work",
            title: L10n.string(L10n.Compose.ritualFocusTitle),
            subtitle: L10n.string(L10n.Compose.ritualFocusSubtitle),
            systemImage: "scope",
            tint: AmbienceIntent.focus.tint,
            phases: [
                RitualPhase(
                    id: "enter",
                    title: L10n.string(L10n.Compose.ritualFocusPhaseEnterTitle),
                    subtitle: L10n.string(L10n.Compose.ritualFocusPhaseEnterSubtitle),
                    durationSeconds: 10 * 60,
                    recipe: AmbienceComposer.template(intent: .focus, premium: true, variant: .opening)
                ),
                RitualPhase(
                    id: "flow",
                    title: L10n.string(L10n.Compose.ritualFocusPhaseFlowTitle),
                    subtitle: L10n.string(L10n.Compose.ritualFocusPhaseFlowSubtitle),
                    durationSeconds: 32 * 60,
                    recipe: AmbienceComposer.template(intent: .focus, premium: true, variant: .middle)
                ),
                RitualPhase(
                    id: "return",
                    title: L10n.string(L10n.Compose.ritualFocusPhaseReturnTitle),
                    subtitle: L10n.string(L10n.Compose.ritualFocusPhaseReturnSubtitle),
                    durationSeconds: 8 * 60,
                    recipe: AmbienceComposer.template(intent: .focus, premium: true, variant: .ending)
                )
            ]
        )
    }

    private static var travelShield: RitualPreset {
        RitualPreset(
            id: "ritual_travel_shield",
            title: L10n.string(L10n.Compose.ritualTravelTitle),
            subtitle: L10n.string(L10n.Compose.ritualTravelSubtitle),
            systemImage: "airplane",
            tint: AmbienceIntent.travel.tint,
            phases: [
                RitualPhase(
                    id: "cover",
                    title: L10n.string(L10n.Compose.ritualTravelPhaseCoverTitle),
                    subtitle: L10n.string(L10n.Compose.ritualTravelPhaseCoverSubtitle),
                    durationSeconds: 15 * 60,
                    recipe: AmbienceComposer.template(intent: .travel, premium: true, variant: .opening)
                ),
                RitualPhase(
                    id: "hold",
                    title: L10n.string(L10n.Compose.ritualTravelPhaseHoldTitle),
                    subtitle: L10n.string(L10n.Compose.ritualTravelPhaseHoldSubtitle),
                    durationSeconds: 22 * 60,
                    recipe: AmbienceComposer.template(intent: .travel, premium: true, variant: .middle)
                ),
                RitualPhase(
                    id: "soften",
                    title: L10n.string(L10n.Compose.ritualTravelPhaseSoftenTitle),
                    subtitle: L10n.string(L10n.Compose.ritualTravelPhaseSoftenSubtitle),
                    durationSeconds: 8 * 60,
                    recipe: AmbienceComposer.template(intent: .travel, premium: true, variant: .ending)
                )
            ]
        )
    }

    private static var readingRoom: RitualPreset {
        RitualPreset(
            id: "ritual_reading_room",
            title: L10n.string(L10n.Compose.ritualReadingTitle),
            subtitle: L10n.string(L10n.Compose.ritualReadingSubtitle),
            systemImage: "book.closed.fill",
            tint: AmbienceIntent.reading.tint,
            phases: [
                RitualPhase(
                    id: "open",
                    title: L10n.string(L10n.Compose.ritualReadingPhaseOpenTitle),
                    subtitle: L10n.string(L10n.Compose.ritualReadingPhaseOpenSubtitle),
                    durationSeconds: 10 * 60,
                    recipe: AmbienceComposer.template(intent: .reading, premium: true, variant: .opening)
                ),
                RitualPhase(
                    id: "read",
                    title: L10n.string(L10n.Compose.ritualReadingPhaseReadTitle),
                    subtitle: L10n.string(L10n.Compose.ritualReadingPhaseReadSubtitle),
                    durationSeconds: 18 * 60,
                    recipe: AmbienceComposer.template(intent: .reading, premium: true, variant: .middle)
                ),
                RitualPhase(
                    id: "close",
                    title: L10n.string(L10n.Compose.ritualReadingPhaseCloseTitle),
                    subtitle: L10n.string(L10n.Compose.ritualReadingPhaseCloseSubtitle),
                    durationSeconds: 7 * 60,
                    recipe: AmbienceComposer.template(intent: .reading, premium: true, variant: .ending)
                )
            ]
        )
    }
}
