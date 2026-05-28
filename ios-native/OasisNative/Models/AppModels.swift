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
        func noise(_ kind: ProceduralNoise, volume: Double, in noises: inout [ProceduralNoise: ProceduralNoiseState]) {
            noises[kind] = ProceduralNoiseState(volume: volume, isMuted: false)
        }

        var nap = [SoundChannel: ChannelState].initialChannels
        nap[.plage] = ChannelState(volume: 0.46, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.05, y: -0.44))
        nap[.vent] = ChannelState(volume: 0.28, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.42, y: 0.16))
        nap[.oiseaux] = ChannelState(volume: 0.16, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.38, y: -0.20))
        var napNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.brown, volume: 0.34, in: &napNoises)

        var reset = [SoundChannel: ChannelState].initialChannels
        reset[.oiseaux] = ChannelState(volume: 0.38, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.34, y: -0.30))
        reset[.vent] = ChannelState(volume: 0.30, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.46, y: 0.12))
        reset[.plage] = ChannelState(volume: 0.42, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.04, y: -0.42))
        var resetNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.white, volume: 0.18, in: &resetNoises)

        var starter = [SoundChannel: ChannelState].initialChannels
        starter[.oiseaux] = ChannelState(volume: 0.42, isMuted: false, autoVariationEnabled: false)
        starter[.vent] = ChannelState(volume: 0.28, isMuted: false, autoVariationEnabled: true)
        starter[.plage] = ChannelState(volume: 0.48, isMuted: false, autoVariationEnabled: false)

        var deepSleep = [SoundChannel: ChannelState].initialChannels
        deepSleep[.pluieFenetre] = ChannelState(volume: 0.36, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: -0.18, y: 0.32))
        deepSleep[.foretNuit] = ChannelState(volume: 0.30, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.42, y: 0.20))
        deepSleep[.plage] = ChannelState(volume: 0.26, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.08, y: -0.46))
        deepSleep[.ventNuit] = ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.46, y: -0.10))
        deepSleep[.fortePluie] = ChannelState(volume: 0.13, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.56, y: 0.08))
        deepSleep[.pluieCabane] = ChannelState(volume: 0.10, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.54, y: -0.04))
        var deepSleepNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.brown, volume: 0.38, in: &deepSleepNoises)
        noise(.pink, volume: 0.16, in: &deepSleepNoises)

        var deepWork = [SoundChannel: ChannelState].initialChannels
        deepWork[.cafe] = ChannelState(volume: 0.32, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.18, y: 0.26))
        deepWork[.riviere] = ChannelState(volume: 0.24, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.30, y: -0.34))
        deepWork[.lac] = ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.50, y: 0.10))
        deepWork[.vent] = ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.46, y: 0.14))
        var deepWorkNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.green, volume: 0.34, in: &deepWorkNoises)

        var travel = [SoundChannel: ChannelState].initialChannels
        travel[.pluieFenetre] = ChannelState(volume: 0.30, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.18, y: 0.28))
        travel[.fortePluie] = ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.48, y: -0.08))
        travel[.ventNuit] = ChannelState(volume: 0.26, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.42, y: 0.18))
        travel[.plage] = ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.40, y: -0.30))
        var travelNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.aircraft, volume: 0.40, in: &travelNoises)
        noise(.fan, volume: 0.26, in: &travelNoises)
        noise(.brown, volume: 0.24, in: &travelNoises)

        var reading = [SoundChannel: ChannelState].initialChannels
        reading[.campfire] = ChannelState(volume: 0.34, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: -0.24, y: -0.24))
        reading[.lac] = ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.42, y: 0.26))
        reading[.foret] = ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.36, y: 0.16))
        reading[.oiseaux] = ChannelState(volume: 0.14, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.36, y: -0.20))
        reading[.carillons] = ChannelState(volume: 0.08, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.52, y: 0.34))
        var readingNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.pink, volume: 0.18, in: &readingNoises)

        var rainCabin = [SoundChannel: ChannelState].initialChannels
        rainCabin[.pluieCabane] = ChannelState(volume: 0.42, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.12, y: 0.30))
        rainCabin[.pluieForet] = ChannelState(volume: 0.32, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.34, y: 0.12))
        rainCabin[.tonnerre] = ChannelState(volume: 0.12, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.56, y: -0.10))
        rainCabin[.campfire] = ChannelState(volume: 0.16, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: 0.36, y: -0.24))
        rainCabin[.vent] = ChannelState(volume: 0.16, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.46, y: 0.30))
        var rainCabinNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.brown, volume: 0.26, in: &rainCabinNoises)

        var morning = [SoundChannel: ChannelState].initialChannels
        morning[.aubeJungle] = ChannelState(volume: 0.36, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.30, y: -0.26))
        morning[.oiseaux] = ChannelState(volume: 0.24, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.48, y: 0.04))
        morning[.lac] = ChannelState(volume: 0.24, isMuted: false, autoVariationEnabled: false, spatialPosition: SpatialPoint(x: -0.20, y: -0.38))
        morning[.vent] = ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: -0.48, y: 0.14))
        morning[.carillons] = ChannelState(volume: 0.10, isMuted: false, autoVariationEnabled: true, spatialPosition: SpatialPoint(x: 0.50, y: 0.34))
        var morningNoises = [ProceduralNoise: ProceduralNoiseState].initialNoises
        noise(.green, volume: 0.14, in: &morningNoises)

        var calm = [SoundChannel: ChannelState].initialChannels
        calm[.foret] = ChannelState(volume: 0.6, isMuted: false, autoVariationEnabled: false)
        calm[.oiseaux] = ChannelState(volume: 0.4, isMuted: false, autoVariationEnabled: false)
        calm[.vent] = ChannelState(volume: 0.3, isMuted: false, autoVariationEnabled: true)

        var storm = [SoundChannel: ChannelState].initialChannels
        storm[.pluie] = ChannelState(volume: 0.7, isMuted: false, autoVariationEnabled: true)
        storm[.tonnerre] = ChannelState(volume: 0.6, isMuted: false, autoVariationEnabled: true)
        storm[.vent] = ChannelState(volume: 0.4, isMuted: false, autoVariationEnabled: false)

        var signature = [SoundChannel: ChannelState].initialChannels
        signature[.foret] = ChannelState(volume: 0.46, isMuted: false, autoVariationEnabled: true)
        signature[.riviere] = ChannelState(volume: 0.38, isMuted: false, autoVariationEnabled: false)
        signature[.oiseaux] = ChannelState(volume: 0.28, isMuted: false, autoVariationEnabled: true)

        return [
            Preset(
                id: "preset_default_nap",
                name: "Short nap",
                channels: nap,
                proceduralNoises: napNoises,
                isBinauralActive: false,
                activeBinauralTrack: .delta,
                binauralVolume: 0.16,
                timerDurationMinutes: 15,
                backdropAssetName: "organic_dark_satin"
            ),
            Preset(
                id: "preset_default_reset",
                name: "Soft reset",
                channels: reset,
                proceduralNoises: resetNoises,
                isBinauralActive: false,
                activeBinauralTrack: .delta,
                binauralVolume: 0.5,
                timerDurationMinutes: 30,
                backdropAssetName: "ambience_soft_hues"
            ),
            Preset(
                id: "preset_default_starter",
                name: "Sea Breeze",
                channels: starter,
                backdropAssetName: "sound_plage_background"
            ),
            Preset(
                id: "preset_default_deep_sleep",
                name: "Deep sleep",
                channels: deepSleep,
                proceduralNoises: deepSleepNoises,
                isBinauralActive: true,
                activeBinauralTrack: .delta,
                binauralVolume: 0.18,
                timerDurationMinutes: 60,
                backdropAssetName: "ambience_colorful_shapes"
            ),
            Preset(
                id: "preset_default_deep_work",
                name: "Deep work",
                channels: deepWork,
                proceduralNoises: deepWorkNoises,
                isBinauralActive: true,
                activeBinauralTrack: .beta,
                binauralVolume: 0.16,
                timerDurationMinutes: 60,
                backdropAssetName: "organic_blue_flow"
            ),
            Preset(
                id: "preset_default_travel",
                name: "Travel cocoon",
                channels: travel,
                proceduralNoises: travelNoises,
                isBinauralActive: true,
                activeBinauralTrack: .delta,
                binauralVolume: 0.14,
                timerDurationMinutes: 60,
                backdropAssetName: "ambience_colorful_fabric"
            ),
            Preset(
                id: "preset_default_reading",
                name: "Evening reading",
                channels: reading,
                proceduralNoises: readingNoises,
                isBinauralActive: true,
                activeBinauralTrack: .alpha,
                binauralVolume: 0.14,
                timerDurationMinutes: 45,
                backdropAssetName: "ambience_warm_fluid"
            ),
            Preset(
                id: "preset_default_rain_cabin",
                name: "Rain cabin",
                channels: rainCabin,
                proceduralNoises: rainCabinNoises,
                isBinauralActive: true,
                activeBinauralTrack: .theta,
                binauralVolume: 0.14,
                timerDurationMinutes: 60,
                backdropAssetName: "ambience_forest_cabin"
            ),
            Preset(
                id: "preset_default_morning",
                name: "Gentle morning",
                channels: morning,
                proceduralNoises: morningNoises,
                isBinauralActive: true,
                activeBinauralTrack: .alpha,
                binauralVolume: 0.10,
                timerDurationMinutes: 30,
                backdropAssetName: "sound_aube_jungle_background"
            ),
            Preset(
                id: "preset_default_calm",
                name: "Quiet Forest",
                channels: calm,
                backdropAssetName: "sound_foret_background"
            ),
            Preset(
                id: "preset_default_storm",
                name: "Distant Storm",
                channels: storm,
                backdropAssetName: "sound_tonnerre_background"
            ),
            Preset(
                id: "preset_signature_oasis",
                name: "After the Rain",
                channels: signature,
                backdropAssetName: "sound_riviere_background"
            )
        ]
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
