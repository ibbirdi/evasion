import Foundation
import SwiftUI

enum L10n {
    static func string(_ resource: LocalizedStringResource) -> String {
        String(localized: resource)
    }

    static func timerOptionLabel(minutes: Int?) -> String {
        switch minutes {
        case nil:
            return string(Header.off)
        case 15:
            return string(Timer.option15)
        case 30:
            return string(Timer.option30)
        case 60:
            return string(Timer.option60)
        case 120:
            return string(Timer.option120)
        case let value?:
            return "\(value) min"
        }
    }

    enum App {
        static let title = LocalizedStringResource(
            "app.title",
            defaultValue: "Oasis",
            bundle: .main,
            comment: "App title and fallback brand label when the logo image is unavailable."
        )

        static let nowPlayingArtist = LocalizedStringResource(
            "audio.nowPlaying.artist",
            defaultValue: "Nature soundscapes",
            bundle: .main,
            comment: "Artist line shown in iOS Now Playing for the app audio session."
        )
    }

    enum Header {
        static let timer = LocalizedStringResource(
            "header.timer",
            defaultValue: "Timer",
            bundle: .main,
            comment: "Short label for the timer control in the home header."
        )

        static let off = LocalizedStringResource(
            "header.off",
            defaultValue: "Off",
            bundle: .main,
            comment: "Menu action that disables the timer."
        )
    }

    enum Presets {
        static let defaultStarter = LocalizedStringResource(
            "presets.default.starter",
            defaultValue: "Sea Breeze",
            bundle: .main,
            comment: "Name of the first default ambience."
        )

        static let defaultCalm = LocalizedStringResource(
            "presets.default.calm",
            defaultValue: "Quiet Forest",
            bundle: .main,
            comment: "Name of the second default ambience."
        )

        static let defaultStorm = LocalizedStringResource(
            "presets.default.storm",
            defaultValue: "Distant Storm",
            bundle: .main,
            comment: "Name of the third default ambience."
        )

        static let afterTheRain = LocalizedStringResource(
            "presets.default.afterRain",
            defaultValue: "After the Rain",
            bundle: .main,
            comment: "Public name of the featured preview ambience that keeps the preset_signature_oasis internal identifier."
        )

        static let panelTitle = LocalizedStringResource(
            "presets.panel.title",
            defaultValue: "Mixes",
            bundle: .main,
            comment: "Short title of the presets panel and inactive presets chip."
        )

        static let panelSubtitle = LocalizedStringResource(
            "presets.panel.subtitle",
            defaultValue: "Open a saved mix or save the one you're shaping now.",
            bundle: .main,
            comment: "Subtitle in the presets panel explaining that the user can reopen or save mixes."
        )

        static let namePrompt = LocalizedStringResource(
            "presets.name.prompt",
            defaultValue: "Name this mix",
            bundle: .main,
            comment: "Placeholder in the text field used to save a new mix."
        )
    }

    enum Paywall {
        static let titleGeneric = LocalizedStringResource(
            "paywall.title.generic",
            defaultValue: "Full access",
            bundle: .main,
            comment: "Generic paywall title when no specific premium entry point needs to be highlighted."
        )

        static let titleSounds = LocalizedStringResource(
            "paywall.title.sounds",
            defaultValue: "More sounds",
            bundle: .main,
            comment: "Paywall title when triggered from a locked sound or spatial control."
        )

        static let titleTimer = LocalizedStringResource(
            "paywall.title.timer",
            defaultValue: "Timer",
            bundle: .main,
            comment: "Paywall title when the user wants the premium timer."
        )

        static let titlePresets = LocalizedStringResource(
            "paywall.title.presets",
            defaultValue: "Saved mixes",
            bundle: .main,
            comment: "Paywall title when the user wants premium preset features."
        )

        static let titleBinaural = LocalizedStringResource(
            "paywall.title.binaural",
            defaultValue: "All binaural modes",
            bundle: .main,
            comment: "Paywall title when the user taps a locked binaural mode."
        )

        static let titlePreview = LocalizedStringResource(
            "paywall.title.preview",
            defaultValue: "Listen again",
            bundle: .main,
            comment: "Paywall title shown after the featured ambience preview has ended."
        )

        static let subtitleGeneric = LocalizedStringResource(
            "paywall.subtitle.generic",
            defaultValue: "More sounds, saved mixes and all binaural modes.",
            bundle: .main,
            comment: "Generic paywall subtitle summarizing the full premium offer."
        )

        static let subtitleSounds = LocalizedStringResource(
            "paywall.subtitle.sounds",
            defaultValue: "Rain, forest, thunder, river and 7 other sounds.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants more ambient sounds."
        )

        static let subtitleTimer = LocalizedStringResource(
            "paywall.subtitle.timer",
            defaultValue: "Automatic stop from 15 min to 2 hr.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants to use the timer."
        )

        static let subtitlePresets = LocalizedStringResource(
            "paywall.subtitle.presets",
            defaultValue: "Find your favorite mixes again in one tap.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants to save or reload mixes."
        )

        static let subtitleBinaural = LocalizedStringResource(
            "paywall.subtitle.binaural",
            defaultValue: "Theta, Alpha and Beta for meditation, relaxation and focus.",
            bundle: .main,
            comment: "Paywall subtitle when the user wants locked binaural modes."
        )

        static let subtitlePreview = LocalizedStringResource(
            "paywall.subtitle.preview",
            defaultValue: "Come back to this ambience anytime with full access.",
            bundle: .main,
            comment: "Paywall subtitle shown after the featured ambience preview has finished."
        )

        static let benefitSounds = LocalizedStringResource(
            "paywall.benefit.sounds",
            defaultValue: "11 extra real HD recordings: rain, forest, thunder, river...",
            bundle: .main,
            comment: "First premium benefit row about the extra ambient library."
        )

        static let benefitPresets = LocalizedStringResource(
            "paywall.benefit.presets",
            defaultValue: "Save your mixes",
            bundle: .main,
            comment: "Premium benefit row about saved mixes."
        )

        static let benefitTimer = LocalizedStringResource(
            "paywall.benefit.timer",
            defaultValue: "Timer from 15 min to 2 hr",
            bundle: .main,
            comment: "Premium benefit row about the timer."
        )

        static let benefitBinaural = LocalizedStringResource(
            "paywall.benefit.binaural",
            defaultValue: "Delta, Theta, Alpha and Beta",
            bundle: .main,
            comment: "Premium benefit row about the binaural modes."
        )

        static let benefitUpdates = LocalizedStringResource(
            "paywall.benefit.updates",
            defaultValue: "Future updates at no extra cost",
            bundle: .main,
            comment: "Premium benefit row clarifying that future app updates are included without extra charge."
        )

        static let noSubscription = LocalizedStringResource(
            "paywall.trust.noSubscription",
            defaultValue: "One purchase. Lifetime access. No subscription.",
            bundle: .main,
            comment: "Trust line below the paywall benefits clarifying that premium is a one-time purchase."
        )

        static let primaryTitle = LocalizedStringResource(
            "paywall.cta.title",
            defaultValue: "Get lifetime access",
            bundle: .main,
            comment: "Main paywall call to action above the localized price."
        )

        static let loading = LocalizedStringResource(
            "paywall.state.loading",
            defaultValue: "Loading price...",
            bundle: .main,
            comment: "Paywall loading state while RevenueCat offerings are fetched."
        )

        static let retry = LocalizedStringResource(
            "paywall.state.retry",
            defaultValue: "Try again",
            bundle: .main,
            comment: "Retry button shown when the paywall fails to load."
        )

        static let unavailable = LocalizedStringResource(
            "paywall.state.unavailable",
            defaultValue: "Purchase is temporarily unavailable.",
            bundle: .main,
            comment: "Error message shown when the paywall has no available product."
        )

        static let restore = LocalizedStringResource(
            "paywall.footer.restore",
            defaultValue: "Restore",
            bundle: .main,
            comment: "Paywall footer button that restores previous purchases."
        )

        static let restoring = LocalizedStringResource(
            "paywall.footer.restoring",
            defaultValue: "Restoring...",
            bundle: .main,
            comment: "Temporary paywall footer label shown while purchases are being restored."
        )

        static let support = LocalizedStringResource(
            "paywall.footer.support",
            defaultValue: "Support",
            bundle: .main,
            comment: "Paywall footer button that opens the support URL."
        )
    }

    enum Premium {
        static let bannerTitle = LocalizedStringResource(
            "premium.banner.title",
            defaultValue: "More to discover",
            bundle: .main,
            comment: "Title of the subtle premium banner shown on the home screen."
        )

        static let bannerSubtitle = LocalizedStringResource(
            "premium.banner.subtitle",
            defaultValue: "More sounds, saved mixes and more binaural modes.",
            bundle: .main,
            comment: "Short explanatory line in the premium home banner."
        )

        static let bannerCTA = LocalizedStringResource(
            "premium.banner.cta",
            defaultValue: "Learn more",
            bundle: .main,
            comment: "Call to action in the premium home banner."
        )

        static let libraryTitle = LocalizedStringResource(
            "premium.library.title",
            defaultValue: "More sounds",
            bundle: .main,
            comment: "Title of the home teaser card for the locked sound library."
        )

        static let libraryBadgeSuffix = LocalizedStringResource(
            "premium.library.badgeSuffix",
            defaultValue: "available",
            bundle: .main,
            comment: "Suffix used after the locked sound count in the home teaser badge, for example '11 more sounds'."
        )

        static let librarySubtitle = LocalizedStringResource(
            "premium.library.subtitle",
            defaultValue: "Rain, forest, thunder, river and 7 other sounds.",
            bundle: .main,
            comment: "Body copy in the locked sound library teaser."
        )

        static let libraryCTA = LocalizedStringResource(
            "premium.library.cta",
            defaultValue: "Learn more",
            bundle: .main,
            comment: "Primary action of the locked sound library teaser."
        )

        static let libraryExpand = LocalizedStringResource(
            "premium.library.expand",
            defaultValue: "Show list",
            bundle: .main,
            comment: "Secondary action that expands the locked sound list in the home teaser."
        )

        static let libraryCollapse = LocalizedStringResource(
            "premium.library.collapse",
            defaultValue: "Hide list",
            bundle: .main,
            comment: "Secondary action that collapses the locked sound list in the home teaser."
        )

        static let inlinePresetTitle = LocalizedStringResource(
            "premium.inline.preset.title",
            defaultValue: "Save this mix",
            bundle: .main,
            comment: "Inline upsell title shown in the presets panel."
        )

        static let inlinePresetSubtitle = LocalizedStringResource(
            "premium.inline.preset.subtitle",
            defaultValue: "Save it now and find it again in one tap.",
            bundle: .main,
            comment: "Inline upsell message shown when the user wants premium preset features."
        )

        static let inlineBinauralTitle = LocalizedStringResource(
            "premium.inline.binaural.title",
            defaultValue: "All binaural modes",
            bundle: .main,
            comment: "Inline upsell title shown in the binaural panel."
        )

        static let inlineBinauralSubtitle = LocalizedStringResource(
            "premium.inline.binaural.subtitle",
            defaultValue: "Theta, Alpha and Beta for meditation, relaxation and focus.",
            bundle: .main,
            comment: "Inline upsell message shown when the user taps a locked binaural mode."
        )

        static let inlineUnlock = LocalizedStringResource(
            "premium.inline.unlock",
            defaultValue: "Learn more",
            bundle: .main,
            comment: "Primary call to action on inline premium cards."
        )

        static let inlineNotNow = LocalizedStringResource(
            "premium.inline.notNow",
            defaultValue: "Not now",
            bundle: .main,
            comment: "Dismissive secondary action on inline premium cards."
        )

        static let previewCTA = LocalizedStringResource(
            "premium.preview.cta",
            defaultValue: "Listen to a sample",
            bundle: .main,
            comment: "Secondary inline upsell action that launches the featured ambience preview."
        )

        static let previewPlaying = LocalizedStringResource(
            "premium.preview.playing",
            defaultValue: "Sample playing",
            bundle: .main,
            comment: "Small status line shown while the featured ambience preview is playing."
        )

        static let previewLimit = LocalizedStringResource(
            "premium.preview.limit",
            defaultValue: "Another sample will be available tomorrow.",
            bundle: .main,
            comment: "Footnote shown when the daily ambience preview has already been used."
        )

        static let timerTitle = LocalizedStringResource(
            "premium.timer.title",
            defaultValue: "Timer",
            bundle: .main,
            comment: "Title of the timer unlock panel shown to free users."
        )

        static let timerSubtitle = LocalizedStringResource(
            "premium.timer.subtitle",
            defaultValue: "Choose when playback should stop automatically.",
            bundle: .main,
            comment: "Subtitle of the timer unlock panel shown to free users."
        )

        static let timerIncluded = LocalizedStringResource(
            "premium.timer.included",
            defaultValue: "Included with full access",
            bundle: .main,
            comment: "Small caption under the locked timer durations."
        )
    }

    enum Binaural {
        static let title = LocalizedStringResource(
            "binaural.title",
            defaultValue: "Binaural modes",
            bundle: .main,
            comment: "Title of the binaural panel."
        )

        static let headphonesHint = LocalizedStringResource(
            "binaural.headphones",
            defaultValue: "Headphones are recommended for the best effect.",
            bundle: .main,
            comment: "Helper line in the binaural panel encouraging headphone use."
        )

        static let deltaTitle = LocalizedStringResource(
            "binaural.delta.title",
            defaultValue: "Delta",
            bundle: .main,
            comment: "Name of the free delta binaural mode."
        )

        static let deltaFrequency = LocalizedStringResource(
            "binaural.delta.frequency",
            defaultValue: "Deep sleep • 4 Hz",
            bundle: .main,
            comment: "Short descriptive label for the delta binaural mode."
        )

        static let thetaTitle = LocalizedStringResource(
            "binaural.theta.title",
            defaultValue: "Theta",
            bundle: .main,
            comment: "Name of the theta binaural mode."
        )

        static let thetaFrequency = LocalizedStringResource(
            "binaural.theta.frequency",
            defaultValue: "Meditation • 6 Hz",
            bundle: .main,
            comment: "Short descriptive label for the theta binaural mode."
        )

        static let alphaTitle = LocalizedStringResource(
            "binaural.alpha.title",
            defaultValue: "Alpha",
            bundle: .main,
            comment: "Name of the alpha binaural mode."
        )

        static let alphaFrequency = LocalizedStringResource(
            "binaural.alpha.frequency",
            defaultValue: "Relaxation • 10 Hz",
            bundle: .main,
            comment: "Short descriptive label for the alpha binaural mode."
        )

        static let betaTitle = LocalizedStringResource(
            "binaural.beta.title",
            defaultValue: "Beta",
            bundle: .main,
            comment: "Name of the beta binaural mode."
        )

        static let betaFrequency = LocalizedStringResource(
            "binaural.beta.frequency",
            defaultValue: "Focus • 18 Hz",
            bundle: .main,
            comment: "Short descriptive label for the beta binaural mode."
        )
    }

    enum Spatial {
        static let subtitle = LocalizedStringResource(
            "spatial.subtitle",
            defaultValue: "Place this sound around you.",
            bundle: .main,
            comment: "Subtitle in the spatial positioning panel."
        )

        static let reset = LocalizedStringResource(
            "spatial.reset",
            defaultValue: "Center sound",
            bundle: .main,
            comment: "Button title that recenters a sound in the spatial positioning panel."
        )

        static let front = LocalizedStringResource(
            "spatial.front",
            defaultValue: "Front",
            bundle: .main,
            comment: "Top label in the spatial positioning panel."
        )

        static let back = LocalizedStringResource(
            "spatial.back",
            defaultValue: "Back",
            bundle: .main,
            comment: "Bottom label in the spatial positioning panel."
        )

        static let left = LocalizedStringResource(
            "spatial.left",
            defaultValue: "Left",
            bundle: .main,
            comment: "Left label in the spatial positioning panel."
        )

        static let right = LocalizedStringResource(
            "spatial.right",
            defaultValue: "Right",
            bundle: .main,
            comment: "Right label in the spatial positioning panel."
        )
    }

    enum Mixer {
        static let statusPremium = LocalizedStringResource(
            "mixer.status.premium",
            defaultValue: "PREMIUM",
            bundle: .main,
            comment: "Small uppercase status label shown on locked premium rows."
        )

        static let statusMuted = LocalizedStringResource(
            "mixer.status.muted",
            defaultValue: "MUTED",
            bundle: .main,
            comment: "Small uppercase status label shown on muted sound rows."
        )

        static let statusAuto = LocalizedStringResource(
            "mixer.status.auto",
            defaultValue: "AUTO",
            bundle: .main,
            comment: "Small uppercase status label shown when automatic variation is enabled."
        )
    }

    enum Timer {
        static let option15 = LocalizedStringResource(
            "timer.option.15",
            defaultValue: "15 min",
            bundle: .main,
            comment: "15 minute duration label in timer controls."
        )

        static let option30 = LocalizedStringResource(
            "timer.option.30",
            defaultValue: "30 min",
            bundle: .main,
            comment: "30 minute duration label in timer controls."
        )

        static let option60 = LocalizedStringResource(
            "timer.option.60",
            defaultValue: "1 hr",
            bundle: .main,
            comment: "1 hour duration label in timer controls."
        )

        static let option120 = LocalizedStringResource(
            "timer.option.120",
            defaultValue: "2 hr",
            bundle: .main,
            comment: "2 hour duration label in timer controls."
        )
    }
}

extension SoundChannel {
    var localizedName: String {
        L10n.string(localizedNameResource)
    }

    private var localizedNameResource: LocalizedStringResource {
        switch self {
        case .oiseaux:
            return LocalizedStringResource("channel.birds", defaultValue: "Birds", bundle: .main, comment: "Ambient sound channel name.")
        case .vent:
            return LocalizedStringResource("channel.wind", defaultValue: "Wind", bundle: .main, comment: "Ambient sound channel name.")
        case .plage:
            return LocalizedStringResource("channel.shore", defaultValue: "Shore", bundle: .main, comment: "Ambient sound channel name.")
        case .goelands:
            return LocalizedStringResource("channel.seagulls", defaultValue: "Seagulls", bundle: .main, comment: "Ambient sound channel name.")
        case .foret:
            return LocalizedStringResource("channel.forest", defaultValue: "Forest", bundle: .main, comment: "Ambient sound channel name.")
        case .pluie:
            return LocalizedStringResource("channel.rain", defaultValue: "Rain", bundle: .main, comment: "Ambient sound channel name.")
        case .tonnerre:
            return LocalizedStringResource("channel.thunder", defaultValue: "Thunder", bundle: .main, comment: "Ambient sound channel name.")
        case .cigales:
            return LocalizedStringResource("channel.cicadas", defaultValue: "Cicadas", bundle: .main, comment: "Ambient sound channel name.")
        case .grillons:
            return LocalizedStringResource("channel.crickets", defaultValue: "Crickets", bundle: .main, comment: "Ambient sound channel name.")
        case .tente:
            return LocalizedStringResource("channel.tent", defaultValue: "Tent", bundle: .main, comment: "Ambient sound channel name.")
        case .riviere:
            return LocalizedStringResource("channel.river", defaultValue: "River", bundle: .main, comment: "Ambient sound channel name.")
        case .village:
            return LocalizedStringResource("channel.village", defaultValue: "Village", bundle: .main, comment: "Ambient sound channel name.")
        case .voiture:
            return LocalizedStringResource("channel.carRide", defaultValue: "Car ride", bundle: .main, comment: "Ambient sound channel name.")
        case .train:
            return LocalizedStringResource("channel.train", defaultValue: "Train", bundle: .main, comment: "Ambient sound channel name.")
        }
    }
}

extension BinauralTrack {
    var localizedTitle: String {
        switch self {
        case .delta:
            return L10n.string(L10n.Binaural.deltaTitle)
        case .theta:
            return L10n.string(L10n.Binaural.thetaTitle)
        case .alpha:
            return L10n.string(L10n.Binaural.alphaTitle)
        case .beta:
            return L10n.string(L10n.Binaural.betaTitle)
        }
    }

    var localizedFrequencyLabel: String {
        switch self {
        case .delta:
            return L10n.string(L10n.Binaural.deltaFrequency)
        case .theta:
            return L10n.string(L10n.Binaural.thetaFrequency)
        case .alpha:
            return L10n.string(L10n.Binaural.alphaFrequency)
        case .beta:
            return L10n.string(L10n.Binaural.betaFrequency)
        }
    }
}
