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
    case voiture
    case train
    case campfire
    case cafe
    case lac
    case savane
    case jungleAmerique
    case jungleAsie

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
}

struct ChannelState: Codable, Equatable {
    var volume: Double = 0.5
    var isMuted = true
    var autoVariationEnabled = false
    var spatialPosition = SpatialPoint.center

    private enum CodingKeys: String, CodingKey {
        case volume
        case isMuted
        case autoVariationEnabled
        case spatialPosition
    }

    init(
        volume: Double = 0.5,
        isMuted: Bool = true,
        autoVariationEnabled: Bool = false,
        spatialPosition: SpatialPoint = .center
    ) {
        self.volume = volume
        self.isMuted = isMuted
        self.autoVariationEnabled = autoVariationEnabled
        self.spatialPosition = spatialPosition
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0.5
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? true
        autoVariationEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoVariationEnabled) ?? false
        spatialPosition = try container.decodeIfPresent(SpatialPoint.self, forKey: .spatialPosition) ?? .center
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
    }
}

struct PersistedMixerState: Codable {
    var channels: [SoundChannel: ChannelState]
    var presets: [Preset]
    var currentPresetID: String?
    var isBinauralActive: Bool
    var activeBinauralTrack: BinauralTrack
    var binauralVolume: Double
    // Legacy field kept to decode older persisted states after the app moved to Apple-managed localization.
    var selectedLanguage: AppLanguage?
    var premiumBannerLastDismissedAt: Date?
    var signaturePreviewLastPlayedAt: Date?
}

struct MixerSnapshot {
    var isPlaying: Bool
    var isPremium: Bool
    var channels: [SoundChannel: ChannelState]
    var isBinauralActive: Bool
    var activeBinauralTrack: BinauralTrack
    var binauralVolume: Double
    var previewUnlockedChannels: Set<SoundChannel>
    var previewUnlockedTracks: Set<BinauralTrack>

    func hasAmbientAccess(to channel: SoundChannel) -> Bool {
        isPremium || SoundChannel.freeChannels.contains(channel) || previewUnlockedChannels.contains(channel)
    }

    func hasBinauralAccess(to track: BinauralTrack) -> Bool {
        isPremium || !track.isPremium || previewUnlockedTracks.contains(track)
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
        var starter = [SoundChannel: ChannelState].initialChannels
        starter[.oiseaux] = ChannelState(volume: 0.42, isMuted: false, autoVariationEnabled: false)
        starter[.vent] = ChannelState(volume: 0.28, isMuted: false, autoVariationEnabled: true)
        starter[.plage] = ChannelState(volume: 0.48, isMuted: false, autoVariationEnabled: false)

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
            Preset(id: "preset_default_starter", name: "Sea Breeze", channels: starter),
            Preset(id: "preset_default_calm", name: "Quiet Forest", channels: calm),
            Preset(id: "preset_default_storm", name: "Distant Storm", channels: storm),
            Preset(id: "preset_signature_oasis", name: "After the Rain", channels: signature)
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
