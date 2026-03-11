import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case en
    case fr
    case es
    case de
    case it
    case pt

    var id: String { rawValue }

    static func resolved(from locale: Locale = .autoupdatingCurrent) -> AppLanguage {
        let languageCode = locale.language.languageCode?.identifier.lowercased() ?? "en"

        switch languageCode {
        case "fr":
            return .fr
        case "es":
            return .es
        case "de":
            return .de
        case "it":
            return .it
        case "pt":
            return .pt
        default:
            return .en
        }
    }
}

enum SoundChannel: String, CaseIterable, Codable, Identifiable {
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

    var id: String { rawValue }

    static let freeChannels: Set<SoundChannel> = [.oiseaux, .vent, .plage]

    var filename: String {
        switch self {
        case .oiseaux: return "oiseaux1.m4a"
        case .vent: return "vent1.m4a"
        case .plage: return "plage1.m4a"
        case .goelands: return "goelants1.m4a"
        case .foret: return "foret1.m4a"
        case .pluie: return "pluie1.m4a"
        case .tonnerre: return "orage1.m4a"
        case .cigales: return "cigales1.m4a"
        case .grillons: return "grillons1.m4a"
        case .tente: return "tente1.m4a"
        case .riviere: return "riviere1.m4a"
        case .village: return "ville1.m4a"
        case .voiture: return "voiture1.m4a"
        case .train: return "train1.m4a"
        }
    }

    var systemImage: String {
        switch self {
        case .oiseaux: return "bird.fill"
        case .vent: return "wind"
        case .plage: return "water.waves"
        case .goelands: return "bird"
        case .foret: return "tree.fill"
        case .pluie: return "cloud.rain.fill"
        case .tonnerre: return "cloud.bolt.fill"
        case .cigales: return "ladybug.fill"
        case .grillons: return "moon.stars"
        case .tente: return "tent.fill"
        case .riviere: return "drop.fill"
        case .village: return "house.fill"
        case .voiture: return "car.fill"
        case .train: return "tram.fill"
        }
    }

    var hueDegrees: Double {
        switch self {
        case .oiseaux: return 0
        case .vent: return 26
        case .plage: return 51
        case .goelands: return 77
        case .foret: return 103
        case .pluie: return 129
        case .tonnerre: return 154
        case .cigales: return 180
        case .grillons: return 206
        case .tente: return 231
        case .riviere: return 257
        case .village: return 283
        case .voiture: return 309
        case .train: return 334
        }
    }

    var tint: Color {
        Color(hslHue: hueDegrees / 360.0, saturation: 0.65, lightness: 0.80)
    }
}

enum BinauralTrack: String, CaseIterable, Codable, Identifiable {
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
}

struct Preset: Codable, Equatable, Identifiable {
    let id: String
    var name: String
    var channels: [SoundChannel: ChannelState]

    var isDefault: Bool {
        id == "preset_default_calm" || id == "preset_default_storm"
    }
}

struct PersistedMixerState: Codable {
    var channels: [SoundChannel: ChannelState]
    var presets: [Preset]
    var currentPresetID: String?
    var isPremium: Bool
    var isBinauralActive: Bool
    var activeBinauralTrack: BinauralTrack
    var binauralVolume: Double
    var selectedLanguage: AppLanguage?
}

struct MixerSnapshot {
    var isPlaying: Bool
    var isPremium: Bool
    var channels: [SoundChannel: ChannelState]
    var isBinauralActive: Bool
    var activeBinauralTrack: BinauralTrack
    var binauralVolume: Double
}

extension Dictionary where Key == SoundChannel, Value == ChannelState {
    static var initialChannels: [SoundChannel: ChannelState] {
        SoundChannel.allCases.reduce(into: [:]) { partialResult, channel in
            partialResult[channel] = ChannelState()
        }
    }
}

extension Array where Element == Preset {
    static func defaultPresets() -> [Preset] {
        var calm = [SoundChannel: ChannelState].initialChannels
        calm[.foret] = ChannelState(volume: 0.6, isMuted: false, autoVariationEnabled: false)
        calm[.oiseaux] = ChannelState(volume: 0.4, isMuted: false, autoVariationEnabled: false)
        calm[.vent] = ChannelState(volume: 0.3, isMuted: false, autoVariationEnabled: true)

        var storm = [SoundChannel: ChannelState].initialChannels
        storm[.pluie] = ChannelState(volume: 0.7, isMuted: false, autoVariationEnabled: false)
        storm[.tonnerre] = ChannelState(volume: 0.6, isMuted: false, autoVariationEnabled: true)
        storm[.vent] = ChannelState(volume: 0.4, isMuted: false, autoVariationEnabled: false)

        return [
            Preset(id: "preset_default_calm", name: "Calm Forest", channels: calm),
            Preset(id: "preset_default_storm", name: "Distant Storm", channels: storm)
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
