import Foundation

enum AmbienceComposer {
    enum TemplateVariant {
        case opening
        case middle
        case ending
    }

    static func compose(intent: AmbienceIntent, prompt: String, premium: Bool) -> AmbienceRecipe {
        let normalized = prompt.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        var recipe = template(intent: intent, premium: premium, variant: .middle)

        if containsAny(normalized, PromptKeywords.travel) {
            recipe = template(intent: .travel, premium: premium, variant: .middle)
            recipe.title = L10n.string(L10n.Compose.travelShieldTitle)
            recipe.subtitle = L10n.string(L10n.Compose.travelSubtitle)
        } else if containsAny(normalized, PromptKeywords.reading) {
            recipe = template(intent: .reading, premium: premium, variant: .middle)
            recipe.title = L10n.string(L10n.Compose.readingRoomTitle)
            recipe.subtitle = L10n.string(L10n.Compose.readingSubtitle)
        } else if containsAny(normalized, PromptKeywords.focus) {
            recipe = template(intent: .focus, premium: premium, variant: .middle)
            recipe.title = L10n.string(L10n.Compose.focusCocoonTitle)
            recipe.subtitle = L10n.string(L10n.Compose.focusSubtitle)
        } else if containsAny(normalized, PromptKeywords.sleep) {
            recipe = template(intent: .sleep, premium: premium, variant: .middle)
            recipe.title = L10n.string(L10n.Compose.sleepCocoonTitle)
            recipe.subtitle = L10n.string(L10n.Compose.sleepSubtitle)
        }

        if containsAny(normalized, PromptKeywords.rain) {
            addChannel(.pluie, volume: premium ? 0.48 : 0, auto: true, position: SpatialPoint(x: -0.15, y: -0.28), to: &recipe, premium: premium)
            addChannel(.pluieFenetre, volume: 0.36, auto: false, position: SpatialPoint(x: 0.32, y: 0.08), to: &recipe, premium: premium)
        }

        if containsAny(normalized, PromptKeywords.ocean) {
            addChannel(.plage, volume: 0.50, auto: false, position: SpatialPoint(x: 0.05, y: -0.42), to: &recipe, premium: premium)
            addChannel(.mer, volume: 0.34, auto: true, position: SpatialPoint(x: -0.48, y: 0.10), to: &recipe, premium: premium)
        }

        if containsAny(normalized, PromptKeywords.forest) {
            addChannel(.foret, volume: 0.46, auto: true, position: SpatialPoint(x: -0.28, y: -0.16), to: &recipe, premium: premium)
            addChannel(.oiseaux, volume: 0.26, auto: true, position: SpatialPoint(x: 0.38, y: -0.22), to: &recipe, premium: premium)
        }

        if containsAny(normalized, PromptKeywords.brownNoise) {
            addNoise(.brown, volume: 0.36, to: &recipe, premium: premium)
        } else if containsAny(normalized, PromptKeywords.pinkNoise) {
            addNoise(.pink, volume: 0.34, to: &recipe, premium: premium)
        } else if containsAny(normalized, PromptKeywords.whiteNoise) {
            addNoise(.white, volume: 0.30, to: &recipe, premium: premium)
        } else if containsAny(normalized, PromptKeywords.greenNoise) {
            addNoise(.green, volume: 0.34, to: &recipe, premium: premium)
        }

        if containsAny(normalized, PromptKeywords.shortNap) {
            recipe.timerMinutes = premium ? 22 : 15
        }

        return recipe
    }

    static func template(intent: AmbienceIntent, premium: Bool, variant: TemplateVariant) -> AmbienceRecipe {
        var recipe = AmbienceRecipe(
            title: title(for: intent, variant: variant),
            subtitle: subtitle(for: intent, premium: premium, variant: variant),
            intent: intent,
            channels: .initialChannels,
            proceduralNoises: .initialNoises,
            isBinauralActive: true,
            binauralTrack: .delta,
            binauralVolume: 0.22,
            timerMinutes: timerMinutes(for: intent, premium: premium),
            immersiveAudioEnabled: true
        )

        switch intent {
        case .sleep:
            addChannel(.plage, volume: variant == .ending ? 0.32 : 0.48, auto: false, position: SpatialPoint(x: 0.06, y: -0.42), to: &recipe, premium: premium)
            addChannel(.vent, volume: variant == .opening ? 0.34 : 0.24, auto: true, position: SpatialPoint(x: -0.42, y: 0.18), to: &recipe, premium: premium)
            addChannel(.oiseaux, volume: variant == .ending ? 0.10 : 0.20, auto: true, position: SpatialPoint(x: 0.36, y: -0.18), to: &recipe, premium: premium)
            if premium {
                addChannel(.pluieFenetre, volume: variant == .opening ? 0.20 : 0.16, auto: false, position: SpatialPoint(x: -0.18, y: 0.36), to: &recipe, premium: premium)
                addChannel(.foretNuit, volume: variant == .ending ? 0.22 : 0.14, auto: true, position: SpatialPoint(x: 0.46, y: 0.20), to: &recipe, premium: premium)
                addChannel(.fortePluie, volume: variant == .middle ? 0.12 : 0.08, auto: true, position: SpatialPoint(x: -0.54, y: -0.04), to: &recipe, premium: premium)
            }
            addNoise(.brown, volume: variant == .middle ? 0.40 : 0.30, to: &recipe, premium: premium)
            recipe.binauralTrack = .delta
            recipe.binauralVolume = 0.20

        case .focus:
            addChannel(.vent, volume: 0.28, auto: true, position: SpatialPoint(x: -0.38, y: 0.08), to: &recipe, premium: premium)
            addChannel(.plage, volume: 0.26, auto: false, position: SpatialPoint(x: 0.38, y: -0.30), to: &recipe, premium: premium)
            addChannel(.cafe, volume: 0.30, auto: true, position: SpatialPoint(x: 0.15, y: 0.25), to: &recipe, premium: premium)
            if premium {
                addChannel(.riviere, volume: 0.16, auto: true, position: SpatialPoint(x: -0.18, y: -0.36), to: &recipe, premium: premium)
                addChannel(.lac, volume: 0.14, auto: false, position: SpatialPoint(x: 0.48, y: 0.12), to: &recipe, premium: premium)
            }
            addNoise(premium ? .green : .white, volume: variant == .middle ? 0.34 : 0.26, to: &recipe, premium: premium)
            recipe.binauralTrack = premium ? .beta : .delta
            recipe.binauralVolume = premium ? 0.18 : 0.12

        case .travel:
            addChannel(.vent, volume: 0.34, auto: true, position: SpatialPoint(x: -0.50, y: 0.10), to: &recipe, premium: premium)
            addChannel(.plage, volume: 0.30, auto: false, position: SpatialPoint(x: 0.35, y: -0.28), to: &recipe, premium: premium)
            addChannel(.pluieFenetre, volume: 0.28, auto: false, position: SpatialPoint(x: 0.10, y: 0.24), to: &recipe, premium: premium)
            if premium {
                addChannel(.ventNuit, volume: 0.24, auto: true, position: SpatialPoint(x: -0.36, y: -0.24), to: &recipe, premium: premium)
                addChannel(.fortePluie, volume: 0.14, auto: true, position: SpatialPoint(x: 0.52, y: 0.04), to: &recipe, premium: premium)
                addNoise(.fan, volume: 0.22, to: &recipe, premium: premium)
            }
            addNoise(premium ? .aircraft : .brown, volume: variant == .middle ? 0.42 : 0.34, to: &recipe, premium: premium)
            recipe.binauralTrack = .delta
            recipe.binauralVolume = 0.16

        case .reading:
            addChannel(.oiseaux, volume: 0.24, auto: true, position: SpatialPoint(x: 0.42, y: -0.24), to: &recipe, premium: premium)
            addChannel(.vent, volume: 0.24, auto: true, position: SpatialPoint(x: -0.44, y: 0.10), to: &recipe, premium: premium)
            addChannel(.campfire, volume: 0.32, auto: false, position: SpatialPoint(x: -0.20, y: -0.20), to: &recipe, premium: premium)
            if premium {
                addChannel(.lac, volume: 0.18, auto: false, position: SpatialPoint(x: 0.34, y: 0.28), to: &recipe, premium: premium)
                addChannel(.carillons, volume: 0.08, auto: true, position: SpatialPoint(x: -0.48, y: 0.32), to: &recipe, premium: premium)
            }
            addNoise(premium ? .pink : .brown, volume: variant == .middle ? 0.24 : 0.18, to: &recipe, premium: premium)
            recipe.binauralTrack = premium ? .alpha : .delta
            recipe.binauralVolume = premium ? 0.16 : 0.10

        case .reset:
            addChannel(.oiseaux, volume: 0.42, auto: true, position: SpatialPoint(x: 0.28, y: -0.28), to: &recipe, premium: premium)
            addChannel(.vent, volume: 0.32, auto: true, position: SpatialPoint(x: -0.34, y: 0.10), to: &recipe, premium: premium)
            addChannel(.plage, volume: 0.40, auto: false, position: SpatialPoint(x: 0.08, y: -0.36), to: &recipe, premium: premium)
            addNoise(.white, volume: 0.18, to: &recipe, premium: premium)
            recipe.isBinauralActive = false
            recipe.timerMinutes = nil
        }

        return recipe
    }

    private static func baseRecipe(
        title: String,
        subtitle: String,
        intent: AmbienceIntent,
        timerMinutes: Int?,
        isBinauralActive: Bool = true,
        binauralTrack: BinauralTrack = .delta,
        binauralVolume: Double = 0.18,
        immersiveAudioEnabled: Bool = true
    ) -> AmbienceRecipe {
        AmbienceRecipe(
            title: title,
            subtitle: subtitle,
            intent: intent,
            channels: .initialChannels,
            proceduralNoises: .initialNoises,
            isBinauralActive: isBinauralActive,
            binauralTrack: binauralTrack,
            binauralVolume: binauralVolume,
            timerMinutes: timerMinutes,
            immersiveAudioEnabled: immersiveAudioEnabled
        )
    }

    private static func addChannel(
        _ channel: SoundChannel,
        volume: Double,
        auto: Bool,
        position: SpatialPoint,
        to recipe: inout AmbienceRecipe,
        premium: Bool
    ) {
        guard premium || SoundChannel.freeChannels.contains(channel) else { return }
        guard volume > 0 else { return }
        recipe.channels[channel] = ChannelState(
            volume: volume,
            isMuted: false,
            autoVariationEnabled: auto,
            spatialPosition: position
        )
    }

    private static func addNoise(
        _ noise: ProceduralNoise,
        volume: Double,
        to recipe: inout AmbienceRecipe,
        premium: Bool
    ) {
        guard premium || !noise.isPremium else { return }
        recipe.proceduralNoises[noise] = ProceduralNoiseState(volume: volume, isMuted: false)
    }

    private static func containsAny(_ normalizedPrompt: String, _ keywords: [String]) -> Bool {
        keywords.contains { normalizedPrompt.contains($0) }
    }

    private enum PromptKeywords {
        static let travel = [
            "hotel", "plane", "avion", "flugzeug", "tren", "train", "zug", "treno", "trem",
            "street", "rue", "strasse", "calle", "strada", "rua",
            "travel", "voyage", "reise", "viaje", "viaggio", "viagem"
        ]

        static let reading = [
            "read", "reading", "book", "journal", "lire", "lecture", "livre", "lesen", "buch",
            "leer", "libro", "lectura", "lettura", "leggere", "ler", "leitura", "livro"
        ]

        static let focus = [
            "focus", "work", "study", "code", "concentration", "travail", "etude", "fokus",
            "arbeit", "lernen", "trabajo", "estudio", "lavoro", "studio", "foco"
        ]

        static let sleep = [
            "sleep", "night", "insomnia", "wind down", "sommeil", "nuit", "dormir", "insomnie",
            "schlaf", "nacht", "einschlafen", "sueno", "insomnio", "sonno", "notte",
            "insonnia", "sono", "noite", "insonia"
        ]

        static let rain = ["rain", "pluie", "regen", "lluvia", "pioggia", "chuva"]
        static let ocean = [
            "ocean", "sea", "shore", "wave", "mer", "vague", "meer", "welle", "mar",
            "ola", "mare", "onda", "onde", "ondas"
        ]
        static let forest = ["forest", "woods", "foret", "bois", "wald", "bosque", "floresta"]
        static let brownNoise = ["brown", "brun", "marron", "braun", "marrom"]
        static let pinkNoise = ["pink", "rose", "rosa"]
        static let whiteNoise = ["white", "blanc", "weiss", "blanco", "bianco", "branco"]
        static let greenNoise = ["green", "vert", "grun", "verde"]
        static let shortNap = [
            "short", "nap", "sieste", "court", "courte", "kurz", "siesta", "pisolino",
            "soneca", "curto", "curta"
        ]
    }

    private static func timerMinutes(for intent: AmbienceIntent, premium: Bool) -> Int? {
        switch intent {
        case .sleep:
            return premium ? 45 : 30
        case .focus:
            return premium ? 50 : 30
        case .travel:
            return premium ? 45 : 30
        case .reading:
            return premium ? 35 : 30
        case .reset:
            return nil
        }
    }

    private static func title(for intent: AmbienceIntent, variant: TemplateVariant) -> String {
        switch intent {
        case .sleep:
            return L10n.string(L10n.Compose.sleepCocoonTitle)
        case .focus:
            return L10n.string(L10n.Compose.focusCocoonTitle)
        case .travel:
            return L10n.string(L10n.Compose.travelShieldTitle)
        case .reading:
            return L10n.string(L10n.Compose.readingRoomTitle)
        case .reset:
            return L10n.string(L10n.Compose.resetTitle)
        }
    }

    private static func subtitle(for intent: AmbienceIntent, premium: Bool, variant: TemplateVariant) -> String {
        switch intent {
        case .sleep:
            return L10n.string(L10n.Compose.sleepSubtitle)
        case .focus:
            return L10n.string(L10n.Compose.focusSubtitle)
        case .travel:
            return L10n.string(L10n.Compose.travelSubtitle)
        case .reading:
            return L10n.string(L10n.Compose.readingSubtitle)
        case .reset:
            return L10n.string(L10n.Compose.resetSubtitle)
        }
    }
}
