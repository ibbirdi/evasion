import CoreLocation
import Foundation
import SwiftUI

/// All immutable per-channel metadata in a single source of truth:
/// audio file name, visual identity, i18n keys, recording location, and freesound credit.
struct ChannelMetadata: Sendable {
    let filename: String
    let systemImage: String
    let tintRGB: TintRGB
    let shortName: LocalizedStringResource
    let longName: LocalizedStringResource
    let location: ChannelLocation
    let credit: ChannelCredit

    struct TintRGB: Sendable {
        let red: Double
        let green: Double
        let blue: Double
    }

    var tint: Color {
        Color(red: tintRGB.red, green: tintRGB.green, blue: tintRGB.blue)
    }
}

/// Recording location attached to a sound. The country is represented by its ISO 3166-1 alpha-2
/// code so the flag emoji and localized country name can be derived at render time from
/// `Locale.current`. The `region` key is localized separately because region names (neighborhoods,
/// mountain ranges, forests) are not part of any standard region database.
struct ChannelLocation: Sendable {
    /// ISO 3166-1 alpha-2 code, e.g. "FR", "TW". Empty string when the location is unknown
    /// (in which case the row shows the region key alone and no flag).
    let countryCode: String
    let region: LocalizedStringResource
    /// When true, the location has been inferred or imagined rather than documented by the
    /// original recording author. Shown discreetly in the detail sheet for transparency.
    let isApproximate: Bool
    /// Approximate coordinate for the recording site. Precise to the region, not the meter —
    /// most source recordings don't document exact GPS. Nil when no reasonable location
    /// could be inferred. Used by `SoundLocationMinimap` in the detail sheet.
    let coordinate: CLLocationCoordinate2D?

    init(
        countryCode: String,
        region: LocalizedStringResource,
        isApproximate: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.countryCode = countryCode
        self.region = region
        self.isApproximate = isApproximate
        if let latitude, let longitude {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            self.coordinate = nil
        }
    }

    var flagEmoji: String {
        guard countryCode.count == 2 else { return "" }
        let base: UInt32 = 127_397
        let scalars = countryCode.uppercased().unicodeScalars.compactMap { scalar -> Unicode.Scalar? in
            Unicode.Scalar(base + scalar.value)
        }
        return String(String.UnicodeScalarView(scalars))
    }

    /// Localized country name, e.g. "France" in FR, "Frankreich" in DE. Nil for unknown codes.
    var localizedCountryName: String? {
        guard !countryCode.isEmpty else { return nil }
        return Locale.current.localizedString(forRegionCode: countryCode)
    }

    /// Region name in the current locale, e.g. "Bretagne".
    var localizedRegion: String {
        String(localized: region)
    }

    /// Compact label for the row, e.g. "Bretagne". Just the region; the flag emoji is rendered
    /// separately so the row stays legible on small widths.
    var rowLabel: String {
        localizedRegion
    }

    /// Full label for the detail sheet, e.g. "Bretagne, France".
    var fullLabel: String {
        guard let country = localizedCountryName else { return localizedRegion }
        return "\(localizedRegion), \(country)"
    }
}

/// Attribution info for a freesound.org recording.
struct ChannelCredit: Sendable {
    let author: String
    let freesoundURL: URL
    let license: License

    enum License: String, Sendable {
        case cc0
        case ccBy4

        var shortLabel: String {
            switch self {
            case .cc0: return "CC0"
            case .ccBy4: return "CC BY 4.0"
            }
        }

        var requiresAttribution: Bool {
            switch self {
            case .cc0: return false
            case .ccBy4: return true
            }
        }
    }
}

extension SoundChannel {
    var metadata: ChannelMetadata {
        guard let value = Self.metadataTable[self] else {
            preconditionFailure("Missing metadata for channel \(rawValue). Add an entry in SoundChannel.metadataTable.")
        }
        return value
    }

    var filename: String { metadata.filename }
    var systemImage: String { metadata.systemImage }
    var tint: Color { metadata.tint }
    var location: ChannelLocation { metadata.location }
    var credit: ChannelCredit { metadata.credit }
    var shortNameResource: LocalizedStringResource { metadata.shortName }
    var longNameResource: LocalizedStringResource { metadata.longName }

    var localizedName: String { String(localized: shortNameResource) }
    var localizedLongName: String { String(localized: longNameResource) }

    // MARK: - Single source of truth

    private static let metadataTable: [SoundChannel: ChannelMetadata] = [
        .oiseaux: ChannelMetadata(
            filename: "oiseaux1.m4a",
            systemImage: "bird.fill",
            tintRGB: .init(red: 0.96, green: 0.74, blue: 0.53),
            shortName: LocalizedStringResource("channel.birds", defaultValue: "Birds", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.birds.long", defaultValue: "Birds in the Breton countryside", bundle: .main, comment: "Ambient sound channel long descriptive name shown in the detail sheet."),
            location: ChannelLocation(
                countryCode: "FR",
                region: LocalizedStringResource("channel.birds.location", defaultValue: "Nivillac, Morbihan", bundle: .main, comment: "Region where the birds sound was recorded."),
                latitude: 47.5839,
                longitude: -2.2611
            ),
            credit: ChannelCredit(
                author: "bruno.auzet",
                freesoundURL: URL(string: "https://freesound.org/people/bruno.auzet/sounds/838024/")!,
                license: .cc0
            )
        ),
        .vent: ChannelMetadata(
            filename: "vent1.m4a",
            systemImage: "wind",
            tintRGB: .init(red: 0.96, green: 0.97, blue: 0.92),
            shortName: LocalizedStringResource("channel.wind", defaultValue: "Wind", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.wind.long", defaultValue: "Outdoor wind at Perpignan", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "FR",
                region: LocalizedStringResource("channel.wind.location", defaultValue: "Perpignan, Occitanie", bundle: .main, comment: "Region where the wind sound was recorded."),
                latitude: 42.6886,
                longitude: 2.8949
            ),
            credit: ChannelCredit(
                author: "Sadiquecat",
                freesoundURL: URL(string: "https://freesound.org/people/Sadiquecat/sounds/773670/")!,
                license: .cc0
            )
        ),
        .plage: ChannelMetadata(
            filename: "plage1.m4a",
            systemImage: "water.waves",
            tintRGB: .init(red: 0.93, green: 0.86, blue: 0.57),
            shortName: LocalizedStringResource("channel.shore", defaultValue: "Shore", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.shore.long", defaultValue: "Waves on the Shetland Islands", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "GB",
                region: LocalizedStringResource("channel.shore.location", defaultValue: "Shetland Islands, Scotland", bundle: .main, comment: "Region where the shore sound was recorded."),
                latitude: 60.5292,
                longitude: -1.2659
            ),
            credit: ChannelCredit(
                author: "straget",
                freesoundURL: URL(string: "https://freesound.org/people/straget/sounds/434615/")!,
                license: .ccBy4
            )
        ),
        .goelands: ChannelMetadata(
            filename: "goelants1.m4a",
            systemImage: "bird",
            tintRGB: .init(red: 0.71, green: 0.86, blue: 0.66),
            shortName: LocalizedStringResource("channel.seagulls", defaultValue: "Seagulls", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.seagulls.long", defaultValue: "Seagulls over a Breton harbour", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "FR",
                region: LocalizedStringResource("channel.seagulls.location", defaultValue: "Brittany harbour", bundle: .main, comment: "Region where the seagulls sound was recorded."),
                latitude: 48.3904,
                longitude: -4.4861
            ),
            credit: ChannelCredit(
                author: "Further_Roman",
                freesoundURL: URL(string: "https://freesound.org/people/Further_Roman/sounds/208074/")!,
                license: .cc0
            )
        ),
        .foret: ChannelMetadata(
            filename: "foret1.m4a",
            systemImage: "tree.fill",
            tintRGB: .init(red: 0.63, green: 0.86, blue: 0.55),
            shortName: LocalizedStringResource("channel.forest", defaultValue: "Forest", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.forest.long", defaultValue: "Kampina woodland in early spring", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "NL",
                region: LocalizedStringResource("channel.forest.location", defaultValue: "Kampina, North Brabant", bundle: .main, comment: "Region where the forest sound was recorded."),
                latitude: 51.57181,
                longitude: 5.24226
            ),
            credit: ChannelCredit(
                author: "klankbeeld",
                freesoundURL: URL(string: "https://freesound.org/people/klankbeeld/sounds/468049/")!,
                license: .ccBy4
            )
        ),
        .pluie: ChannelMetadata(
            filename: "pluie1.m4a",
            systemImage: "cloud.rain.fill",
            tintRGB: .init(red: 0.45, green: 0.79, blue: 0.92),
            shortName: LocalizedStringResource("channel.rain", defaultValue: "Rain", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.rain.long", defaultValue: "Medium rain in the Po valley", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "IT",
                region: LocalizedStringResource("channel.rain.location", defaultValue: "Voghera, Pavia", bundle: .main, comment: "Region where the rain sound was recorded."),
                latitude: 44.9942,
                longitude: 9.0086
            ),
            credit: ChannelCredit(
                author: "Stagno",
                freesoundURL: URL(string: "https://freesound.org/people/Stagno/sounds/832262/")!,
                license: .ccBy4
            )
        ),
        .tonnerre: ChannelMetadata(
            filename: "orage1.m4a",
            systemImage: "cloud.bolt.fill",
            tintRGB: .init(red: 0.69, green: 0.57, blue: 0.92),
            shortName: LocalizedStringResource("channel.thunder", defaultValue: "Thunder", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.thunder.long", defaultValue: "Summer storm in Southern France", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "FR",
                region: LocalizedStringResource("channel.thunder.location", defaultValue: "Azillanet, Hérault", bundle: .main, comment: "Region where the thunder sound was recorded."),
                latitude: 43.3667,
                longitude: 2.7667
            ),
            credit: ChannelCredit(
                author: "felix.blume",
                freesoundURL: URL(string: "https://freesound.org/people/felix.blume/sounds/437133/")!,
                license: .cc0
            )
        ),
        .cigales: ChannelMetadata(
            filename: "cigales1.m4a",
            systemImage: "ladybug.fill",
            tintRGB: .init(red: 0.89, green: 0.86, blue: 0.51),
            shortName: LocalizedStringResource("channel.cicadas", defaultValue: "Cicadas", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.cicadas.long", defaultValue: "Sicilian summer cicadas", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "IT",
                region: LocalizedStringResource("channel.cicadas.location", defaultValue: "Lampedusa, Sicily", bundle: .main, comment: "Region where the cicadas sound was recorded."),
                isApproximate: true,
                latitude: 35.5049,
                longitude: 12.5964
            ),
            credit: ChannelCredit(
                author: "pablodavilla",
                freesoundURL: URL(string: "https://freesound.org/people/pablodavilla/sounds/592110/")!,
                license: .cc0
            )
        ),
        .grillons: ChannelMetadata(
            filename: "grillons1.m4a",
            systemImage: "moon.stars",
            tintRGB: .init(red: 0.65, green: 0.80, blue: 0.97),
            shortName: LocalizedStringResource("channel.crickets", defaultValue: "Crickets", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.crickets.long", defaultValue: "Countryside night crickets", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "FR",
                region: LocalizedStringResource("channel.crickets.location", defaultValue: "Theneuille, Allier", bundle: .main, comment: "Region where the crickets sound was recorded."),
                latitude: 46.5778,
                longitude: 2.8111
            ),
            credit: ChannelCredit(
                author: "keng-wai-chane-chick-te",
                freesoundURL: URL(string: "https://freesound.org/people/keng-wai-chane-chick-te/sounds/692908/")!,
                license: .cc0
            )
        ),
        .tente: ChannelMetadata(
            filename: "tente1.m4a",
            systemImage: "tent.fill",
            tintRGB: .init(red: 0.85, green: 0.73, blue: 0.60),
            shortName: LocalizedStringResource("channel.tent", defaultValue: "Tent", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.tent.long", defaultValue: "Heavy rain on the canvas", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "DK",
                region: LocalizedStringResource("channel.tent.location", defaultValue: "Bornholm island", bundle: .main, comment: "Region where the tent sound was recorded."),
                isApproximate: true,
                latitude: 55.1656,
                longitude: 14.9224
            ),
            credit: ChannelCredit(
                author: "Petrosilia",
                freesoundURL: URL(string: "https://freesound.org/people/Petrosilia/sounds/592997/")!,
                license: .cc0
            )
        ),
        .riviere: ChannelMetadata(
            filename: "riviere1.m4a",
            systemImage: "drop.fill",
            tintRGB: .init(red: 0.50, green: 0.85, blue: 0.95),
            shortName: LocalizedStringResource("channel.river", defaultValue: "River", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.river.long", defaultValue: "Taiwan mountain stream", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "TW",
                region: LocalizedStringResource("channel.river.location", defaultValue: "Taoyuan Mountains", bundle: .main, comment: "Region where the river sound was recorded."),
                latitude: 24.9936,
                longitude: 121.3010
            ),
            credit: ChannelCredit(
                author: "calebjay",
                freesoundURL: URL(string: "https://freesound.org/people/calebjay/sounds/684901/")!,
                license: .ccBy4
            )
        ),
        .village: ChannelMetadata(
            filename: "ville1.m4a",
            systemImage: "house.fill",
            tintRGB: .init(red: 0.90, green: 0.72, blue: 0.60),
            shortName: LocalizedStringResource("channel.village", defaultValue: "Village", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.village.long", defaultValue: "Bustling Chinese pedestrian street", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "CN",
                region: LocalizedStringResource("channel.village.location", defaultValue: "Liuzhou, Guangxi", bundle: .main, comment: "Region where the village sound was recorded."),
                latitude: 24.3261,
                longitude: 109.4135
            ),
            credit: ChannelCredit(
                author: "lastraindrop",
                freesoundURL: URL(string: "https://freesound.org/people/lastraindrop/sounds/716384/")!,
                license: .cc0
            )
        ),
        .mer: ChannelMetadata(
            filename: "mer1.m4a",
            systemImage: "water.waves",
            tintRGB: .init(red: 0.32, green: 0.55, blue: 0.78),
            shortName: LocalizedStringResource("channel.sea", defaultValue: "Sea", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.sea.long", defaultValue: "Mediterranean shore at Epitalio", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "GR",
                region: LocalizedStringResource("channel.sea.location", defaultValue: "Epitalio, Western Greece", bundle: .main, comment: "Region where the sea sound was recorded."),
                latitude: 37.6483,
                longitude: 21.3877
            ),
            credit: ChannelCredit(
                author: "yiorgis",
                freesoundURL: URL(string: "https://freesound.org/people/yiorgis/sounds/705548/")!,
                license: .cc0
            )
        ),
        .orageMontagne: ChannelMetadata(
            filename: "orageMontagne1.m4a",
            systemImage: "cloud.bolt.fill",
            tintRGB: .init(red: 0.58, green: 0.62, blue: 0.78),
            shortName: LocalizedStringResource("channel.mountainStorm", defaultValue: "Mountain storm", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.mountainStorm.long", defaultValue: "Distant thunder over Lake Garda", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "IT",
                region: LocalizedStringResource("channel.mountainStorm.location", defaultValue: "Tremosine sul Garda, Brescia", bundle: .main, comment: "Region where the mountain storm sound was recorded."),
                latitude: 45.7456,
                longitude: 10.6700
            ),
            credit: ChannelCredit(
                author: "bruno.auzet",
                freesoundURL: URL(string: "https://freesound.org/people/bruno.auzet/sounds/647420/")!,
                license: .cc0
            )
        ),
        .campfire: ChannelMetadata(
            filename: "campfire1.m4a",
            systemImage: "flame.fill",
            tintRGB: .init(red: 0.95, green: 0.55, blue: 0.30),
            shortName: LocalizedStringResource("channel.campfire", defaultValue: "Campfire", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.campfire.long", defaultValue: "Riverside campfire at dusk", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "US",
                region: LocalizedStringResource("channel.campfire.location", defaultValue: "St. Marys River, Michigan", bundle: .main, comment: "Region where the campfire sound was recorded."),
                latitude: 46.4909,
                longitude: -84.3453
            ),
            credit: ChannelCredit(
                author: "Ambient-X",
                freesoundURL: URL(string: "https://freesound.org/people/Ambient-X/sounds/688992/")!,
                license: .ccBy4
            )
        ),
        .cafe: ChannelMetadata(
            filename: "cafe1.m4a",
            systemImage: "cup.and.saucer.fill",
            tintRGB: .init(red: 0.65, green: 0.48, blue: 0.38),
            shortName: LocalizedStringResource("channel.cafe", defaultValue: "Café", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.cafe.long", defaultValue: "Late-night São Paulo café", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "BR",
                region: LocalizedStringResource("channel.cafe.location", defaultValue: "São Paulo", bundle: .main, comment: "Region where the café sound was recorded."),
                latitude: -23.5505,
                longitude: -46.6333
            ),
            credit: ChannelCredit(
                author: "felix.blume",
                freesoundURL: URL(string: "https://freesound.org/people/felix.blume/sounds/422097/")!,
                license: .cc0
            )
        ),
        .lac: ChannelMetadata(
            filename: "lac1.m4a",
            systemImage: "sailboat.fill",
            tintRGB: .init(red: 0.42, green: 0.68, blue: 0.85),
            shortName: LocalizedStringResource("channel.lake", defaultValue: "Lake", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.lake.long", defaultValue: "Twilight at Fritton Lake", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "GB",
                region: LocalizedStringResource("channel.lake.location", defaultValue: "Fritton Lake, Norfolk", bundle: .main, comment: "Region where the lake sound was recorded."),
                latitude: 52.5575,
                longitude: 1.6425
            ),
            credit: ChannelCredit(
                author: "Yarmonics",
                freesoundURL: URL(string: "https://freesound.org/people/Yarmonics/sounds/445956/")!,
                license: .cc0
            )
        ),
        .savane: ChannelMetadata(
            filename: "savane1.m4a",
            systemImage: "sun.max.fill",
            tintRGB: .init(red: 0.92, green: 0.78, blue: 0.45),
            shortName: LocalizedStringResource("channel.savanna", defaultValue: "Savanna", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.savanna.long", defaultValue: "Mkuze River at sundown", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "ZA",
                region: LocalizedStringResource("channel.savanna.location", defaultValue: "KwaZulu-Natal", bundle: .main, comment: "Region where the savanna sound was recorded."),
                latitude: -27.6284,
                longitude: 32.2169
            ),
            credit: ChannelCredit(
                author: "eardeer",
                freesoundURL: URL(string: "https://freesound.org/people/eardeer/sounds/512090/")!,
                license: .cc0
            )
        ),
        .jungleAmerique: ChannelMetadata(
            filename: "jungleamerique1.m4a",
            systemImage: "leaf.fill",
            tintRGB: .init(red: 0.35, green: 0.72, blue: 0.45),
            shortName: LocalizedStringResource("channel.jungleAmericas", defaultValue: "Tropical jungle", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.jungleAmericas.long", defaultValue: "Veracruz jungle at night", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "MX",
                region: LocalizedStringResource("channel.jungleAmericas.location", defaultValue: "Los Tuxtlas, Veracruz", bundle: .main, comment: "Region where the tropical jungle sound was recorded."),
                latitude: 18.4592,
                longitude: -95.0600
            ),
            credit: ChannelCredit(
                author: "Globofonia",
                freesoundURL: URL(string: "https://freesound.org/people/Globofonia/sounds/587720/")!,
                license: .ccBy4
            )
        ),
        .jungleAsie: ChannelMetadata(
            filename: "jungleasie1.m4a",
            systemImage: "cloud.fog.fill",
            tintRGB: .init(red: 0.40, green: 0.80, blue: 0.60),
            shortName: LocalizedStringResource("channel.jungleAsia", defaultValue: "Asian jungle", bundle: .main, comment: "Ambient sound channel short name."),
            longName: LocalizedStringResource("channel.jungleAsia.long", defaultValue: "Chiang Mai jungle at night", bundle: .main, comment: "Ambient sound channel long descriptive name."),
            location: ChannelLocation(
                countryCode: "TH",
                region: LocalizedStringResource("channel.jungleAsia.location", defaultValue: "Chiang Mai", bundle: .main, comment: "Region where the Asian jungle sound was recorded."),
                latitude: 18.7883,
                longitude: 98.9853
            ),
            credit: ChannelCredit(
                author: "Anantich",
                freesoundURL: URL(string: "https://freesound.org/people/Anantich/sounds/250273/")!,
                license: .ccBy4
            )
        )
    ]
}
