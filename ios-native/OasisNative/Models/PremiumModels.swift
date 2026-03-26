import Foundation

enum PremiumAccentToken: String, Sendable {
    case ambient
    case preset
    case binaural
    case timer
    case preview
    case neutral
}

enum PremiumEntryPoint: Hashable, Sendable {
    case manual
    case sound(SoundChannel)
    case timer
    case presetLoad
    case presetSave
    case binaural(BinauralTrack)
    case spatial(SoundChannel)
    case previewEnd

    enum Category: Hashable, Sendable {
        case manual
        case sound
        case timer
        case preset
        case binaural
        case spatial
        case preview
    }

    var category: Category {
        switch self {
        case .manual:
            return .manual
        case .sound:
            return .sound
        case .timer:
            return .timer
        case .presetLoad, .presetSave:
            return .preset
        case .binaural:
            return .binaural
        case .spatial:
            return .spatial
        case .previewEnd:
            return .preview
        }
    }

    var analyticsSource: String {
        switch self {
        case .manual:
            return "manual"
        case let .sound(channel):
            return "sound_\(channel.id)"
        case .timer:
            return "timer"
        case .presetLoad:
            return "preset_load"
        case .presetSave:
            return "preset_save"
        case let .binaural(track):
            return "binaural_\(track.id)"
        case let .spatial(channel):
            return "spatial_\(channel.id)"
        case .previewEnd:
            return "preview_end"
        }
    }

    var accentToken: PremiumAccentToken {
        switch category {
        case .manual:
            return .neutral
        case .sound, .spatial:
            return .ambient
        case .timer:
            return .timer
        case .preset:
            return .preset
        case .binaural:
            return .binaural
        case .preview:
            return .preview
        }
    }

    var symbolName: String {
        switch category {
        case .manual:
            return "sparkles"
        case .sound, .spatial:
            return "water.waves"
        case .timer:
            return "timer"
        case .preset:
            return "bookmark.fill"
        case .binaural:
            return "waveform.path"
        case .preview:
            return "play.circle.fill"
        }
    }
}

struct PremiumPaywallContext: Identifiable {
    let id = UUID()
    let entryPoint: PremiumEntryPoint
}

struct PremiumInlineUpsellContext: Identifiable, Equatable {
    let id = UUID()
    let entryPoint: PremiumEntryPoint
}

struct PremiumPaywallPresentation {
    let title: String
    let subtitle: String
    let benefitRows: [String]
    let symbolName: String
    let accentToken: PremiumAccentToken
}

struct PremiumInlineUpsellPresentation {
    let title: String
    let message: String
    let primaryActionTitle: String
    let secondaryActionTitle: String?
    let footnote: String?
    let symbolName: String
    let accentToken: PremiumAccentToken
}

struct PremiumHomeBannerPresentation {
    let title: String
    let message: String
    let ctaTitle: String
}

struct PremiumLibraryTeaserPresentation {
    let title: String
    let badgeTitle: String
    let message: String
    let ctaTitle: String
    let expandTitle: String
    let collapseTitle: String
    let lockedCount: Int
}

struct PremiumTimerSheetPresentation {
    let title: String
    let message: String
    let lockedLabel: String
}
