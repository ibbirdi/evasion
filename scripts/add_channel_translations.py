#!/usr/bin/env python3
"""
Adds long-name and location i18n keys for the 14 existing ambient channels and
full (short + long + location) keys for the 6 new channels.

Keeps the Xcode Strings Catalog format intact: sorted keys, per-language
`stringUnit.state = "translated"` entries, 6 languages (en, fr, es, de, it, pt).
"""

import json
import sys
from collections import OrderedDict
from pathlib import Path

XCSTRINGS = Path(__file__).resolve().parents[1] / "ios-native/OasisNative/Resources/Localizable.xcstrings"

LANGS = ["de", "en", "es", "fr", "it", "pt"]

# Structured translations. Each channel has three optional kinds: short, long, location.
# Existing channels only need long + location (short is already translated).
# New channels need all three.

NEW_CHANNELS_SHORT = {
    "channel.campfire": {
        "comment": "Ambient sound channel short name.",
        "en": "Campfire", "fr": "Feu de camp", "es": "Hoguera",
        "de": "Lagerfeuer", "it": "Falò", "pt": "Fogueira",
    },
    "channel.cafe": {
        "comment": "Ambient sound channel short name.",
        "en": "Café", "fr": "Café", "es": "Café",
        "de": "Café", "it": "Caffè", "pt": "Café",
    },
    "channel.lake": {
        "comment": "Ambient sound channel short name.",
        "en": "Lake", "fr": "Lac", "es": "Lago",
        "de": "See", "it": "Lago", "pt": "Lago",
    },
    "channel.savanna": {
        "comment": "Ambient sound channel short name.",
        "en": "Savanna", "fr": "Savane", "es": "Sabana",
        "de": "Savanne", "it": "Savana", "pt": "Savana",
    },
    "channel.jungleAmericas": {
        "comment": "Ambient sound channel short name.",
        "en": "Tropical jungle", "fr": "Jungle tropicale", "es": "Selva tropical",
        "de": "Tropischer Dschungel", "it": "Giungla tropicale", "pt": "Selva tropical",
    },
    "channel.jungleAsia": {
        "comment": "Ambient sound channel short name.",
        "en": "Asian jungle", "fr": "Jungle d’Asie", "es": "Selva asiática",
        "de": "Asiatischer Dschungel", "it": "Giungla asiatica", "pt": "Selva asiática",
    },
}

LONG_NAMES = {
    "channel.birds.long": {
        "en": "Mountain birds of Taoyuan", "fr": "Oiseaux des montagnes de Taoyuan",
        "es": "Aves de las montañas de Taoyuan", "de": "Vögel der Taoyuan-Berge",
        "it": "Uccelli delle montagne di Taoyuan", "pt": "Aves das montanhas de Taoyuan",
    },
    "channel.wind.long": {
        "en": "Cliffside winds of Gavdos", "fr": "Vents de la falaise de Gavdos",
        "es": "Vientos del acantilado de Gavdos", "de": "Klippenwinde von Gavdos",
        "it": "Venti sulla scogliera di Gavdos", "pt": "Ventos do penhasco de Gavdos",
    },
    "channel.shore.long": {
        "en": "Breezy coastline", "fr": "Côte venteuse",
        "es": "Costa con brisa", "de": "Windige Küste",
        "it": "Costa ventosa", "pt": "Costa com brisa",
    },
    "channel.seagulls.long": {
        "en": "Seagulls over a Breton harbour", "fr": "Goélands sur un port breton",
        "es": "Gaviotas sobre un puerto bretón", "de": "Möwen über einem bretonischen Hafen",
        "it": "Gabbiani su un porto bretone", "pt": "Gaivotas sobre um porto bretão",
    },
    "channel.forest.long": {
        "en": "Burgundy woodland at dawn", "fr": "Forêt bourguignonne à l’aube",
        "es": "Bosque de Borgoña al amanecer", "de": "Burgundischer Wald bei Tagesanbruch",
        "it": "Bosco borgognone all’alba", "pt": "Floresta da Borgonha ao amanhecer",
    },
    "channel.rain.long": {
        "en": "Rain on a camping tent", "fr": "Pluie sur une tente de camping",
        "es": "Lluvia sobre una tienda de campaña", "de": "Regen auf einem Zelt",
        "it": "Pioggia su una tenda da campeggio", "pt": "Chuva sobre uma tenda",
    },
    "channel.thunder.long": {
        "en": "Summer storm in Southern France", "fr": "Orage d’été dans le sud de la France",
        "es": "Tormenta de verano en el sur de Francia", "de": "Sommergewitter in Südfrankreich",
        "it": "Temporale estivo nel sud della Francia", "pt": "Tempestade de verão no sul da França",
    },
    "channel.cicadas.long": {
        "en": "Sicilian summer cicadas", "fr": "Cigales d’été en Sicile",
        "es": "Cigarras de verano en Sicilia", "de": "Sizilianische Sommer-Zikaden",
        "it": "Cicale estive siciliane", "pt": "Cigarras de verão na Sicília",
    },
    "channel.crickets.long": {
        "en": "Countryside night crickets", "fr": "Grillons de campagne la nuit",
        "es": "Grillos campestres nocturnos", "de": "Nachtgrillen auf dem Land",
        "it": "Grilli di campagna notturni", "pt": "Grilos noturnos do campo",
    },
    "channel.tent.long": {
        "en": "Heavy rain on the canvas", "fr": "Forte pluie sur la toile",
        "es": "Lluvia fuerte sobre la lona", "de": "Starker Regen auf der Zeltplane",
        "it": "Pioggia battente sulla tela", "pt": "Chuva forte sobre a lona",
    },
    "channel.river.long": {
        "en": "Taiwan mountain stream", "fr": "Ruisseau de montagne taïwanais",
        "es": "Arroyo de montaña en Taiwán", "de": "Bergbach in Taiwan",
        "it": "Ruscello di montagna a Taiwan", "pt": "Ribeiro de montanha em Taiwan",
    },
    "channel.village.long": {
        "en": "Bustling Chinese pedestrian street", "fr": "Rue piétonne animée en Chine",
        "es": "Calle peatonal china animada", "de": "Belebte chinesische Fußgängerstraße",
        "it": "Via pedonale cinese animata", "pt": "Rua pedonal chinesa movimentada",
    },
    "channel.carRide.long": {
        "en": "Highway cabin rumble", "fr": "Intérieur de voiture sur l’autoroute",
        "es": "Interior de coche en autopista", "de": "Fahrzeuginnenraum auf der Autobahn",
        "it": "Interno auto in autostrada", "pt": "Interior de carro na autoestrada",
    },
    "channel.train.long": {
        "en": "Intercity rail to Lisbon", "fr": "Intercidades jusqu’à Lisbonne",
        "es": "Intercidades hasta Lisboa", "de": "Intercidades nach Lissabon",
        "it": "Intercidades fino a Lisbona", "pt": "Intercidades até Lisboa",
    },
    "channel.campfire.long": {
        "en": "Riverside campfire at dusk", "fr": "Feu de camp au crépuscule, au bord de la rivière",
        "es": "Hoguera junto al río al atardecer", "de": "Lagerfeuer am Fluss in der Abenddämmerung",
        "it": "Falò sul fiume al tramonto", "pt": "Fogueira à beira-rio ao entardecer",
    },
    "channel.cafe.long": {
        "en": "Late-night São Paulo café", "fr": "Café nocturne à São Paulo",
        "es": "Café nocturno en São Paulo", "de": "Café bei Nacht in São Paulo",
        "it": "Caffè notturno a San Paolo", "pt": "Café noturno em São Paulo",
    },
    "channel.lake.long": {
        "en": "Twilight at Fritton Lake", "fr": "Crépuscule au lac de Fritton",
        "es": "Atardecer en el lago Fritton", "de": "Dämmerung am Fritton Lake",
        "it": "Crepuscolo al lago Fritton", "pt": "Crepúsculo no lago Fritton",
    },
    "channel.savanna.long": {
        "en": "Mkuze River at sundown", "fr": "Rivière Mkuze au coucher du soleil",
        "es": "Río Mkuze al atardecer", "de": "Mkuze-Fluss bei Sonnenuntergang",
        "it": "Fiume Mkuze al tramonto", "pt": "Rio Mkuze ao pôr do sol",
    },
    "channel.jungleAmericas.long": {
        "en": "Veracruz jungle at night", "fr": "Jungle de Veracruz la nuit",
        "es": "Selva de Veracruz de noche", "de": "Veracruz-Dschungel bei Nacht",
        "it": "Giungla di Veracruz di notte", "pt": "Selva de Veracruz à noite",
    },
    "channel.jungleAsia.long": {
        "en": "Chiang Mai jungle at night", "fr": "Jungle de Chiang Mai la nuit",
        "es": "Selva de Chiang Mai de noche", "de": "Chiang-Mai-Dschungel bei Nacht",
        "it": "Giungla di Chiang Mai di notte", "pt": "Selva de Chiang Mai à noite",
    },
}

LOCATIONS = {
    "channel.birds.location": {
        "en": "Taoyuan Mountains", "fr": "Montagnes de Taoyuan",
        "es": "Montañas de Taoyuan", "de": "Taoyuan-Berge",
        "it": "Montagne di Taoyuan", "pt": "Montanhas de Taoyuan",
    },
    "channel.wind.location": {
        "en": "Gavdos island, Crete", "fr": "Île de Gavdos, Crète",
        "es": "Isla de Gavdos, Creta", "de": "Insel Gavdos, Kreta",
        "it": "Isola di Gavdos, Creta", "pt": "Ilha de Gavdos, Creta",
    },
    "channel.shore.location": {
        "en": "Cornish coast", "fr": "Côte des Cornouailles",
        "es": "Costa de Cornualles", "de": "Kornische Küste",
        "it": "Costa della Cornovaglia", "pt": "Costa da Cornualha",
    },
    "channel.seagulls.location": {
        "en": "Brittany harbour", "fr": "Port en Bretagne",
        "es": "Puerto en Bretaña", "de": "Bretonischer Hafen",
        "it": "Porto in Bretagna", "pt": "Porto na Bretanha",
    },
    "channel.forest.location": {
        "en": "Détain-Gergueil, Burgundy", "fr": "Détain-Gergueil, Bourgogne",
        "es": "Détain-Gergueil, Borgoña", "de": "Détain-Gergueil, Burgund",
        "it": "Détain-Gergueil, Borgogna", "pt": "Détain-Gergueil, Borgonha",
    },
    "channel.rain.location": {
        "en": "Bornholm island", "fr": "Île de Bornholm",
        "es": "Isla de Bornholm", "de": "Insel Bornholm",
        "it": "Isola di Bornholm", "pt": "Ilha de Bornholm",
    },
    "channel.thunder.location": {
        "en": "Azillanet, Hérault", "fr": "Azillanet, Hérault",
        "es": "Azillanet, Hérault", "de": "Azillanet, Hérault",
        "it": "Azillanet, Hérault", "pt": "Azillanet, Hérault",
    },
    "channel.cicadas.location": {
        "en": "Lampedusa, Sicily", "fr": "Lampedusa, Sicile",
        "es": "Lampedusa, Sicilia", "de": "Lampedusa, Sizilien",
        "it": "Lampedusa, Sicilia", "pt": "Lampedusa, Sicília",
    },
    "channel.crickets.location": {
        "en": "Theneuille, Allier", "fr": "Theneuille, Allier",
        "es": "Theneuille, Allier", "de": "Theneuille, Allier",
        "it": "Theneuille, Allier", "pt": "Theneuille, Allier",
    },
    "channel.tent.location": {
        "en": "Bornholm island", "fr": "Île de Bornholm",
        "es": "Isla de Bornholm", "de": "Insel Bornholm",
        "it": "Isola di Bornholm", "pt": "Ilha de Bornholm",
    },
    "channel.river.location": {
        "en": "Taoyuan Mountains", "fr": "Montagnes de Taoyuan",
        "es": "Montañas de Taoyuan", "de": "Taoyuan-Berge",
        "it": "Montagne di Taoyuan", "pt": "Montanhas de Taoyuan",
    },
    "channel.village.location": {
        "en": "Liuzhou, Guangxi", "fr": "Liuzhou, Guangxi",
        "es": "Liuzhou, Guangxi", "de": "Liuzhou, Guangxi",
        "it": "Liuzhou, Guangxi", "pt": "Liuzhou, Guangxi",
    },
    "channel.carRide.location": {
        "en": "Quebec highway", "fr": "Autoroute québécoise",
        "es": "Autopista de Quebec", "de": "Autobahn in Québec",
        "it": "Autostrada del Québec", "pt": "Autoestrada do Quebeque",
    },
    "channel.train.location": {
        "en": "Porto–Lisbon line", "fr": "Ligne Porto–Lisbonne",
        "es": "Línea Oporto–Lisboa", "de": "Strecke Porto–Lissabon",
        "it": "Linea Porto–Lisbona", "pt": "Linha Porto–Lisboa",
    },
    "channel.campfire.location": {
        "en": "St. Marys River, Michigan", "fr": "Rivière St. Marys, Michigan",
        "es": "Río St. Marys, Michigan", "de": "St. Marys River, Michigan",
        "it": "Fiume St. Marys, Michigan", "pt": "Rio St. Marys, Michigan",
    },
    "channel.cafe.location": {
        "en": "São Paulo", "fr": "São Paulo",
        "es": "São Paulo", "de": "São Paulo",
        "it": "San Paolo", "pt": "São Paulo",
    },
    "channel.lake.location": {
        "en": "Fritton Lake, Norfolk", "fr": "Lac Fritton, Norfolk",
        "es": "Lago Fritton, Norfolk", "de": "Fritton Lake, Norfolk",
        "it": "Lago Fritton, Norfolk", "pt": "Lago Fritton, Norfolk",
    },
    "channel.savanna.location": {
        "en": "KwaZulu-Natal", "fr": "KwaZulu-Natal",
        "es": "KwaZulu-Natal", "de": "KwaZulu-Natal",
        "it": "KwaZulu-Natal", "pt": "KwaZulu-Natal",
    },
    "channel.jungleAmericas.location": {
        "en": "Los Tuxtlas, Veracruz", "fr": "Los Tuxtlas, Veracruz",
        "es": "Los Tuxtlas, Veracruz", "de": "Los Tuxtlas, Veracruz",
        "it": "Los Tuxtlas, Veracruz", "pt": "Los Tuxtlas, Veracruz",
    },
    "channel.jungleAsia.location": {
        "en": "Chiang Mai", "fr": "Chiang Mai",
        "es": "Chiang Mai", "de": "Chiang Mai",
        "it": "Chiang Mai", "pt": "Chiang Mai",
    },
}

LONG_COMMENT = "Ambient sound channel long descriptive name shown in the detail sheet."
LOCATION_COMMENT = "Region where the sound was recorded."

SHEET_STRINGS = {
    "sound.detail.recordedBy": {
        "comment": "Small label above the author name in the sound detail sheet.",
        "en": "Recorded by", "fr": "Enregistré par", "es": "Grabado por",
        "de": "Aufgenommen von", "it": "Registrato da", "pt": "Gravado por",
    },
    "sound.detail.licensedUnder": {
        "comment": "Prefix before the license name, followed by the license label and the source site name.",
        "en": "Licensed", "fr": "Sous licence", "es": "Con licencia",
        "de": "Lizenz", "it": "Con licenza", "pt": "Sob licença",
    },
    "sound.detail.viewSource": {
        "comment": "Primary action in the sound detail sheet that opens the original freesound.org page.",
        "en": "View on freesound.org", "fr": "Voir sur freesound.org", "es": "Ver en freesound.org",
        "de": "Auf freesound.org ansehen", "it": "Apri su freesound.org", "pt": "Ver em freesound.org",
    },
    "sound.detail.approximateLocation": {
        "comment": "Small note shown below a location when it was inferred rather than documented by the author.",
        "en": "Approximate location", "fr": "Localisation approximative", "es": "Ubicación aproximada",
        "de": "Ungefährer Ort", "it": "Posizione approssimativa", "pt": "Localização aproximada",
    },
}


def build_entry(translations: dict, comment: str) -> dict:
    localizations = {}
    for lang in LANGS:
        value = translations[lang]
        localizations[lang] = {
            "stringUnit": {"state": "translated", "value": value}
        }
    return {"comment": comment, "localizations": localizations}


def main() -> int:
    raw = XCSTRINGS.read_text(encoding="utf-8")
    data = json.loads(raw, object_pairs_hook=OrderedDict)
    strings = data["strings"]

    added = 0
    updated = 0

    # Short names for new channels.
    for key, translations in NEW_CHANNELS_SHORT.items():
        comment = translations.pop("comment")
        entry = build_entry(translations, comment)
        if key in strings:
            updated += 1
        else:
            added += 1
        strings[key] = entry

    # Long names (all 20 channels).
    for key, translations in LONG_NAMES.items():
        entry = build_entry(translations, LONG_COMMENT)
        if key in strings:
            updated += 1
        else:
            added += 1
        strings[key] = entry

    # Locations (all 20 channels).
    for key, translations in LOCATIONS.items():
        entry = build_entry(translations, LOCATION_COMMENT)
        if key in strings:
            updated += 1
        else:
            added += 1
        strings[key] = entry

    # Detail sheet copy.
    for key, translations in SHEET_STRINGS.items():
        comment = translations.pop("comment")
        entry = build_entry(translations, comment)
        if key in strings:
            updated += 1
        else:
            added += 1
        strings[key] = entry

    # Xcode Strings Catalog sorts keys alphabetically.
    sorted_strings = OrderedDict(sorted(strings.items(), key=lambda kv: kv[0]))
    data["strings"] = sorted_strings

    XCSTRINGS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Added {added} new keys, updated {updated} existing keys.")
    print(f"Total keys in catalog: {len(sorted_strings)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
