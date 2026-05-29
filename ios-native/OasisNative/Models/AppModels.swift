import Foundation
import SwiftUI

// Legacy persisted language values kept for backward compatibility with previously saved state.
enum AppLanguage: String, Codable, Sendable {
    case en
    case fr
    case es
    case de
    case it
    case pt
}

enum SoundChannel: String, CaseIterable, Codable, Identifiable, Sendable {
    case oiseaux
    case vent
    case plage
    case goelands
    case foret
    case pluie
    case tonnerre
    case cigales
    case grillons
    case tente
    case riviere
    case village
    case mer
    case orageMontagne
    case campfire
    case cafe
    case lac
    case savane
    case jungleAmerique
    case jungleAsie
    case pluieFenetre
    case pluieForet
    case fortePluie
    case ventNuit
    case foretNuit
    case crueMontagne
    case cascade
    case neigeVille
    case pluieCabane
    case foretChiloe
    case aubeJungle
    case port
    case chevres
    case carillons
    case cloches

    var id: String { rawValue }

    static let freeChannels: Set<SoundChannel> = [.oiseaux, .vent, .plage]

    // Per-channel audio file, visual identity, location and freesound credits live in
    // `SoundChannelMetadata.swift` so that adding a channel is a single-entry change.
}

enum BinauralTrack: String, CaseIterable, Codable, Identifiable, Sendable {
    case delta
    case theta
    case alpha
    case beta

    var id: String { rawValue }

    var filename: String {
        switch self {
        case .delta: return "1_binaural_sleep_delta.m4a"
        case .theta: return "2_binaural_meditation_theta.m4a"
        case .alpha: return "3_binaural_relax_alpha.m4a"
        case .beta: return "4_binaural_focus_beta.m4a"
        }
    }

    var isPremium: Bool {
        self != .delta
    }

    var tint: Color {
        switch self {
        case .delta: return Color(red: 0.38, green: 0.78, blue: 0.94)
        case .theta: return Color(red: 0.54, green: 0.65, blue: 0.98)
        case .alpha: return Color(red: 0.91, green: 0.57, blue: 0.91)
        case .beta: return Color(red: 0.99, green: 0.75, blue: 0.40)
        }
    }

    var beatFrequencyHz: Double {
        switch self {
        case .delta: return 2.5
        case .theta: return 6
        case .alpha: return 10
        case .beta: return 16
        }
    }
}

struct ChannelState: Codable, Equatable {
    var volume: Double = 0.5
    var isMuted = true
    var autoVariationEnabled = false
    var autoVariationRange = AutoVariationRange.defaultRange(around: 0.5)
    var spatialPosition = SpatialPoint.center

    private enum CodingKeys: String, CodingKey {
        case volume
        case isMuted
        case autoVariationEnabled
        case autoVariationRange
        case spatialPosition
    }

    init(
        volume: Double = 0.5,
        isMuted: Bool = true,
        autoVariationEnabled: Bool = false,
        autoVariationRange: AutoVariationRange? = nil,
        spatialPosition: SpatialPoint = .center
    ) {
        self.volume = AutoVariationRange.unitValue(volume, fallback: 0.5)
        self.isMuted = isMuted
        self.autoVariationEnabled = autoVariationEnabled
        self.autoVariationRange = (autoVariationRange ?? AutoVariationRange.defaultRange(around: self.volume)).clamped()
        self.spatialPosition = spatialPosition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        volume = AutoVariationRange.unitValue(
            try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0.5,
            fallback: 0.5
        )
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? true
        autoVariationEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoVariationEnabled) ?? false
        autoVariationRange = (try container.decodeIfPresent(AutoVariationRange.self, forKey: .autoVariationRange) ?? AutoVariationRange.defaultRange(around: volume)).clamped()
        spatialPosition = try container.decodeIfPresent(SpatialPoint.self, forKey: .spatialPosition) ?? .center
    }
}

struct AutoVariationRange: Codable, Equatable, Sendable {
    static let minimumWidth = 0.08
    private static let defaultWidth = 0.44

    var lowerBound: Double
    var upperBound: Double

    static func defaultRange(around volume: Double) -> AutoVariationRange {
        let center = unitValue(volume, fallback: 0.5)
        let halfWidth = defaultWidth / 2
        var lower = center - halfWidth
        var upper = center + halfWidth

        if lower < 0 {
            upper -= lower
            lower = 0
        }
        if upper > 1 {
            lower -= upper - 1
            upper = 1
        }

        return AutoVariationRange(lowerBound: lower, upperBound: upper).clamped()
    }

    func clamped() -> AutoVariationRange {
        let lower = Self.unitValue(lowerBound, fallback: 0)
        let upper = Self.unitValue(upperBound, fallback: 1)

        if upper - lower >= Self.minimumWidth {
            return AutoVariationRange(lowerBound: lower, upperBound: upper)
        }

        let midpoint = (lower + upper) / 2
        let halfWidth = Self.minimumWidth / 2
        var adjustedLower = midpoint - halfWidth
        var adjustedUpper = midpoint + halfWidth

        if adjustedLower < 0 {
            adjustedUpper -= adjustedLower
            adjustedLower = 0
        }
        if adjustedUpper > 1 {
            adjustedLower -= adjustedUpper - 1
            adjustedUpper = 1
        }

        return AutoVariationRange(
            lowerBound: min(max(adjustedLower, 0), 1),
            upperBound: min(max(adjustedUpper, 0), 1)
        )
    }

    func clampedValue(_ value: Double) -> Double {
        let normalized = clamped()
        let fallback = (normalized.lowerBound + normalized.upperBound) / 2
        let finiteValue = value.isFinite ? value : fallback
        return min(max(finiteValue, normalized.lowerBound), normalized.upperBound)
    }

    static func unitValue(_ value: Double, fallback: Double) -> Double {
        guard value.isFinite else { return min(max(fallback, 0), 1) }
        return min(max(value, 0), 1)
    }
}

struct SpatialPoint: Codable, Equatable {
    var x: Double
    var y: Double

    static let center = SpatialPoint(x: 0, y: 0)

    var isCentered: Bool {
        abs(x) < 0.001 && abs(y) < 0.001
    }

    func clamped() -> SpatialPoint {
        SpatialPoint(
            x: min(max(x, -1), 1),
            y: min(max(y, -1), 1)
        )
    }
}

struct Preset: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var channels: [SoundChannel: ChannelState]
    var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]?
    var isBinauralActive: Bool?
    var activeBinauralTrack: BinauralTrack?
    var binauralVolume: Double?
    var timerDurationMinutes: Int?
    var immersiveAudioEnabled: Bool?
    var backdropAssetName: String? = nil

    var isDefault: Bool {
        id.hasPrefix("preset_default_") || isSignature
    }

    var isSignature: Bool {
        id == "preset_signature_oasis"
    }

    var isUser: Bool {
        id.hasPrefix("preset_user_")
    }

    static let legacyBundledPresetIDs: Set<String> = [
        "preset_default_nap",
        "preset_default_reset",
        "preset_default_starter",
        "preset_default_deep_sleep",
        "preset_default_deep_work",
        "preset_default_travel",
        "preset_default_reading",
        "preset_default_rain_cabin",
        "preset_default_morning",
        "preset_default_calm",
        "preset_default_storm",
        "preset_signature_oasis"
    ]

    var requiresPremium: Bool {
        channels.contains { channel, state in
            !state.isMuted && !SoundChannel.freeChannels.contains(channel)
        }
            || (proceduralNoises ?? [:]).contains { noise, state in
                !state.isMuted && noise.isPremium
            }
            || ((isBinauralActive ?? false) && (activeBinauralTrack?.isPremium ?? false))
            || (timerDurationMinutes ?? 0) > 30
    }
}

struct PresetExportArchive: Codable {
    var schemaVersion: Int = 1
    var exportedAt: Date
    var appVersion: String
    var buildNumber: String
    var presets: [Preset]
}

struct PersistedMixerState: Codable {
    var channels: [SoundChannel: ChannelState]
    var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]?
    var presets: [Preset]
    var currentPresetID: String?
    var activeComposerRecipeTitle: String?
    var activeNoiseBlendTitle: String?
    var activeRitualSession: ActiveRitualSession?
    var isBinauralActive: Bool
    var activeBinauralTrack: BinauralTrack
    var binauralVolume: Double
    // Legacy field kept to decode older persisted states after the app moved to Apple-managed localization.
    var selectedLanguage: AppLanguage?
    var premiumBannerLastDismissedAt: Date?
    var signaturePreviewLastPlayedAt: Date?
    var deletedDefaultPresetIDs: Set<String>?
    /// Global immersive rendering toggle. Optional so older persisted states keep the classic
    /// rendering unless users explicitly enable the new mode.
    var immersiveAudioEnabled: Bool?
}

struct MixerSnapshot {
    var isPlaying: Bool
    var isPremium: Bool
    var channels: [SoundChannel: ChannelState]
    var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]
    var isBinauralActive: Bool
    var activeBinauralTrack: BinauralTrack
    var binauralVolume: Double
    var previewUnlockedChannels: Set<SoundChannel>
    var previewUnlockedTracks: Set<BinauralTrack>
    var immersiveAudioEnabled: Bool = false

    func hasAmbientAccess(to channel: SoundChannel) -> Bool {
        isPremium || SoundChannel.freeChannels.contains(channel) || previewUnlockedChannels.contains(channel)
    }

    func hasBinauralAccess(to track: BinauralTrack) -> Bool {
        isPremium || !track.isPremium || previewUnlockedTracks.contains(track)
    }

    func hasProceduralNoiseAccess(to noise: ProceduralNoise) -> Bool {
        isPremium || !noise.isPremium
    }
}

extension Dictionary where Key == SoundChannel, Value == ChannelState {
    static var initialChannels: [SoundChannel: ChannelState] {
        SoundChannel.allCases.reduce(into: [:]) { partialResult, channel in
            partialResult[channel] = ChannelState()
        }
    }

    static var starterChannels: [SoundChannel: ChannelState] {
        var channels = [SoundChannel: ChannelState].initialChannels
        channels[.oiseaux] = ChannelState(volume: 0.45, isMuted: false, autoVariationEnabled: true)
        channels[.vent] = ChannelState(volume: 0.35, isMuted: false, autoVariationEnabled: true)
        channels[.plage] = ChannelState(volume: 0.40, isMuted: false, autoVariationEnabled: false)
        return channels
    }
}

extension Array where Element == Preset {
    static func defaultPresets() -> [Preset] {
        [
            defaultPreset(
                id: "preset_default_repos_sur_la_plage",
                name: "Repos Sur La Plage",
                channels: [
                    .plage: activeChannel(
                        volume: 0.6352,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.4152, upperBound: 0.8552)
                    ),
                    .vent: activeChannel(
                        volume: 0.5,
                        autoVariationEnabled: true,
                        range: AutoVariationRange(lowerBound: 0.28, upperBound: 0.7037)
                    )
                ],
                proceduralNoises: [
                    .brown: ProceduralNoiseState(volume: 0.0854, isMuted: false)
                ],
                backdropAssetName: "sound_plage_background"
            ),
            defaultPreset(
                id: "preset_default_orage_distant",
                name: "Orage Distant",
                channels: [
                    .pluieForet: activeChannel(
                        volume: 0.1648,
                        autoVariationEnabled: true,
                        range: AutoVariationRange(lowerBound: 0.0, upperBound: 0.4889)
                    ),
                    .tonnerre: activeChannel(
                        volume: 0.5926,
                        autoVariationEnabled: true,
                        range: AutoVariationRange(lowerBound: 0.0685, upperBound: 1.0)
                    ),
                    .ventNuit: activeChannel(
                        volume: 0.5,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.28, upperBound: 0.72)
                    )
                ],
                backdropAssetName: "sound_tonnerre_background"
            ),
            defaultPreset(
                id: "preset_default_petite_ondee",
                name: "Petite Ondée",
                channels: [
                    .oiseaux: activeChannel(
                        volume: 0.5,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.28, upperBound: 0.72),
                        position: SpatialPoint(x: -0.0319, y: 0.4498)
                    )
                ],
                proceduralNoises: [
                    .brown: ProceduralNoiseState(volume: 0.068, isMuted: false),
                    .white: ProceduralNoiseState(volume: 0.4941, isMuted: false)
                ],
                backdropAssetName: "sound_forte_pluie_background"
            ),
            defaultPreset(
                id: "preset_default_carillons_relaxants",
                name: "Carillons Relaxants",
                channels: [
                    .carillons: activeChannel(
                        volume: 0.5,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.28, upperBound: 0.72)
                    ),
                    .foret: activeChannel(
                        volume: 0.4497,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.2297, upperBound: 0.6697)
                    ),
                    .foretChiloe: activeChannel(
                        volume: 0.6192,
                        autoVariationEnabled: true,
                        range: AutoVariationRange(lowerBound: 0.3992, upperBound: 0.8392)
                    ),
                    .grillons: activeChannel(
                        volume: 0.1082,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.0, upperBound: 0.44)
                    ),
                    .lac: activeChannel(
                        volume: 0.4456,
                        autoVariationEnabled: true,
                        range: AutoVariationRange(lowerBound: 0.2256, upperBound: 0.6656)
                    ),
                    .mer: activeChannel(
                        volume: 0.369,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.149, upperBound: 0.589)
                    )
                ],
                proceduralNoises: [
                    .brown: ProceduralNoiseState(volume: 0.068, isMuted: false)
                ],
                backdropAssetName: "sound_carillons_background"
            ),
            defaultPreset(
                id: "preset_default_sous_la_tente",
                name: "Sous La Tente",
                channels: [
                    .neigeVille: activeChannel(
                        volume: 0.5,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.28, upperBound: 0.72)
                    ),
                    .tente: activeChannel(
                        volume: 0.5,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.28, upperBound: 0.72)
                    )
                ],
                proceduralNoises: [
                    .green: ProceduralNoiseState(volume: 0.1165, isMuted: false),
                    .pink: ProceduralNoiseState(volume: 0.841, isMuted: false)
                ],
                backdropAssetName: "routine_night_cabin"
            ),
            defaultPreset(
                id: "preset_default_cigales_au_rythme_des_cloches",
                name: "Cigales Au Rythme Des Cloches",
                channels: [
                    .aubeJungle: activeChannel(
                        volume: 0.4611,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.2411, upperBound: 0.6811)
                    ),
                    .cigales: activeChannel(
                        volume: 0.5537,
                        autoVariationEnabled: true,
                        range: AutoVariationRange(lowerBound: 0.3337, upperBound: 0.7737)
                    ),
                    .cloches: activeChannel(
                        volume: 0.3185,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.0985, upperBound: 0.5385)
                    ),
                    .oiseaux: activeChannel(
                        volume: 0.289,
                        autoVariationEnabled: false,
                        range: AutoVariationRange(lowerBound: 0.069, upperBound: 0.509)
                    )
                ],
                proceduralNoises: [
                    .pink: ProceduralNoiseState(volume: 0.841, isMuted: false)
                ],
                backdropAssetName: "sound_cigales_background"
            )
        ]
    }

    private static func defaultPreset(
        id: String,
        name: String,
        channels activeChannels: [SoundChannel: ChannelState],
        proceduralNoises activeNoises: [ProceduralNoise: ProceduralNoiseState] = [:],
        isBinauralActive: Bool = false,
        activeBinauralTrack: BinauralTrack = .delta,
        binauralVolume: Double = 0.14,
        timerDurationMinutes: Int? = nil,
        immersiveAudioEnabled: Bool = false,
        backdropAssetName: String
    ) -> Preset {
        var channels = [SoundChannel: ChannelState].initialChannels
        activeChannels.forEach { channels[$0.key] = $0.value }

        var proceduralNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        activeNoises.forEach { proceduralNoises[$0.key] = $0.value }

        return Preset(
            id: id,
            name: name,
            channels: channels,
            proceduralNoises: proceduralNoises,
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume,
            timerDurationMinutes: timerDurationMinutes,
            immersiveAudioEnabled: immersiveAudioEnabled,
            backdropAssetName: backdropAssetName
        )
    }

    private static func activeChannel(
        volume: Double,
        autoVariationEnabled: Bool,
        range: AutoVariationRange,
        position: SpatialPoint = .center
    ) -> ChannelState {
        ChannelState(
            volume: volume,
            isMuted: false,
            autoVariationEnabled: autoVariationEnabled,
            autoVariationRange: range,
            spatialPosition: position
        )
    }
}

extension Color {
    init(hslHue: Double, saturation: Double, lightness: Double, opacity: Double = 1.0) {
        let q = lightness < 0.5
            ? lightness * (1 + saturation)
            : lightness + saturation - lightness * saturation
        let p = 2 * lightness - q

        func convert(_ component: Double) -> Double {
            var value = component
            if value < 0 { value += 1 }
            if value > 1 { value -= 1 }

            switch value {
            case 0..<1.0 / 6.0:
                return p + (q - p) * 6 * value
            case 1.0 / 6.0..<0.5:
                return q
            case 0.5..<2.0 / 3.0:
                return p + (q - p) * (2.0 / 3.0 - value) * 6
            default:
                return p
            }
        }

        let red = convert(hslHue + 1.0 / 3.0)
        let green = convert(hslHue)
        let blue = convert(hslHue - 1.0 / 3.0)

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
