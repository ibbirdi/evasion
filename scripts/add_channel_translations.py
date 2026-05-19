#!/usr/bin/env python3
"""
Adds and refreshes long-name, short-name and location i18n keys for the current
35 ambient channels.

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
    "channel.sea": {
        "comment": "Ambient sound channel short name.",
        "en": "Sea", "fr": "Mer", "es": "Mar",
        "de": "Meer", "it": "Mare", "pt": "Mar",
    },
    "channel.mountainStorm": {
        "comment": "Ambient sound channel short name.",
        "en": "Mountain storm", "fr": "Orage en montagne", "es": "Tormenta de montaña",
        "de": "Berggewitter", "it": "Temporale di montagna", "pt": "Trovoada de montanha",
    },
    "channel.rainWindow": {
        "comment": "Ambient sound channel short name.",
        "en": "Rain against the window", "fr": "Pluie contre la fenêtre", "es": "Lluvia contra la ventana",
        "de": "Regen am Fenster", "it": "Pioggia contro la finestra", "pt": "Chuva contra a janela",
    },
    "channel.rainForest": {
        "comment": "Ambient sound channel short name.",
        "en": "Forest rain", "fr": "Pluie en forêt", "es": "Lluvia en el bosque",
        "de": "Waldregen", "it": "Pioggia nel bosco", "pt": "Chuva na floresta",
    },
    "channel.heavyRain": {
        "comment": "Ambient sound channel short name.",
        "en": "Heavy rain", "fr": "Forte pluie", "es": "Lluvia intensa",
        "de": "Starkregen", "it": "Pioggia intensa", "pt": "Chuva forte",
    },
    "channel.nightWind": {
        "comment": "Ambient sound channel short name.",
        "en": "Night wind", "fr": "Vent nocturne", "es": "Viento nocturno",
        "de": "Nachtwind", "it": "Vento notturno", "pt": "Vento noturno",
    },
    "channel.nightForest": {
        "comment": "Ambient sound channel short name.",
        "en": "Night forest", "fr": "Forêt nocturne", "es": "Bosque nocturno",
        "de": "Nachtwald", "it": "Foresta notturna", "pt": "Floresta noturna",
    },
    "channel.mountainFlood": {
        "comment": "Ambient sound channel short name.",
        "en": "Mountain river", "fr": "Rivière de montagne", "es": "Río de montaña",
        "de": "Bergfluss", "it": "Fiume di montagna", "pt": "Rio de montanha",
    },
    "channel.waterfall": {
        "comment": "Ambient sound channel short name.",
        "en": "Waterfall", "fr": "Cascade", "es": "Cascada",
        "de": "Wasserfall", "it": "Cascata", "pt": "Cachoeira",
    },
    "channel.citySnow": {
        "comment": "Ambient sound channel short name.",
        "en": "Snowflakes", "fr": "Flocons de neige", "es": "Copos de nieve",
        "de": "Schneeflocken", "it": "Fiocchi di neve", "pt": "Flocos de neve",
    },
    "channel.cabinRain": {
        "comment": "Ambient sound channel short name.",
        "en": "Rain under the cabin roof", "fr": "Pluie sous la cabane", "es": "Lluvia bajo el techo de la cabaña",
        "de": "Regen unter dem Hüttendach", "it": "Pioggia sotto il tetto della baita", "pt": "Chuva sob o telhado da cabana",
    },
    "channel.chiloeForest": {
        "comment": "Ambient sound channel short name.",
        "en": "Chiloé forest", "fr": "Forêt de Chiloé", "es": "Bosque de Chiloé",
        "de": "Chiloé-Wald", "it": "Foresta di Chiloé", "pt": "Floresta de Chiloé",
    },
    "channel.jungleDawn": {
        "comment": "Ambient sound channel short name.",
        "en": "Jungle dawn", "fr": "Aube tropicale", "es": "Amanecer selvático",
        "de": "Dschungeldämmerung", "it": "Alba nella giungla", "pt": "Amanhecer na selva",
    },
    "channel.harbor": {
        "comment": "Ambient sound channel short name.",
        "en": "Harbor", "fr": "Port", "es": "Puerto",
        "de": "Hafen", "it": "Porto", "pt": "Porto",
    },
    "channel.goats": {
        "comment": "Ambient sound channel short name.",
        "en": "Goats with bells", "fr": "Chèvres et leurs clochettes", "es": "Cabras con cencerros",
        "de": "Ziegen mit Glocken", "it": "Capre con campanelli", "pt": "Cabras com sinos",
    },
    "channel.windChimes": {
        "comment": "Ambient sound channel short name.",
        "en": "Wind chimes", "fr": "Carillons", "es": "Campanas de viento",
        "de": "Windspiele", "it": "Campanelli al vento", "pt": "Sinos de vento",
    },
    "channel.churchBells": {
        "comment": "Ambient sound channel short name.",
        "en": "Church bells", "fr": "Cloches", "es": "Campanas de iglesia",
        "de": "Kirchenglocken", "it": "Campane", "pt": "Sinos de igreja",
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
        "en": "Plain storm near Azillanet", "fr": "Orage dans la plaine près d’Azillanet",
        "es": "Tormenta en la llanura cerca de Azillanet", "de": "Gewitter über der Ebene bei Azillanet",
        "it": "Temporale sulla pianura vicino ad Azillanet", "pt": "Tempestade na planície perto de Azillanet",
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
        "en": "Heavy rain under the tent canvas", "fr": "Forte pluie sous la toile de tente",
        "es": "Lluvia intensa bajo la lona", "de": "Starker Regen unter der Zeltplane",
        "it": "Pioggia battente sotto il telo", "pt": "Chuva forte dentro da barraca",
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
    "channel.sea.long": {
        "en": "Mediterranean shore at Epitalio", "fr": "Côte méditerranéenne d’Epitalio",
        "es": "Costa mediterránea de Epitalio", "de": "Mittelmeerküste bei Epitalio",
        "it": "Costa mediterranea a Epitalio", "pt": "Costa mediterrânea de Epitalio",
    },
    "channel.mountainStorm.long": {
        "en": "Distant thunder over Lake Garda", "fr": "Tonnerre lointain sur le lac de Garde",
        "es": "Truenos lejanos sobre el lago de Garda", "de": "Fernes Donnergrollen über dem Gardasee",
        "it": "Tuoni lontani sul lago di Garda", "pt": "Trovões distantes sobre o lago de Garda",
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
    "channel.rainWindow.long": {
        "en": "Rain against a Chiswick window", "fr": "Pluie contre une vitre à Chiswick",
        "es": "Lluvia contra una ventana en Chiswick", "de": "Regen an einem Fenster in Chiswick",
        "it": "Pioggia su una finestra a Chiswick", "pt": "Chuva contra uma janela em Chiswick",
    },
    "channel.rainForest.long": {
        "en": "Rain under the forest canopy", "fr": "Pluie sous la canopée",
        "es": "Lluvia bajo el dosel del bosque", "de": "Regen unter dem Blätterdach",
        "it": "Pioggia sotto la volta del bosco", "pt": "Chuva sob a copa da floresta",
    },
    "channel.heavyRain.long": {
        "en": "Heavy rain on rural land", "fr": "Forte pluie en pleine campagne",
        "es": "Lluvia intensa en zona rural", "de": "Starkregen auf dem Land",
        "it": "Pioggia intensa in campagna", "pt": "Chuva forte no campo",
    },
    "channel.nightWind.long": {
        "en": "Night wind through dry branches", "fr": "Vent nocturne dans les branches sèches",
        "es": "Viento nocturno entre ramas secas", "de": "Nachtwind in trockenen Ästen",
        "it": "Vento notturno tra rami secchi", "pt": "Vento noturno entre galhos secos",
    },
    "channel.nightForest.long": {
        "en": "Tallgrass prairie forest edge", "fr": "Lisière nocturne dans la prairie tallgrass",
        "es": "Borde de bosque en la pradera tallgrass", "de": "Waldrand in der Tallgrass-Prärie",
        "it": "Margine del bosco nella prateria tallgrass", "pt": "Borda da floresta na pradaria tallgrass",
    },
    "channel.mountainFlood.long": {
        "en": "Mountain river after heavy rain", "fr": "Rivière de montagne après la pluie",
        "es": "Río de montaña después de la lluvia", "de": "Bergfluss nach starkem Regen",
        "it": "Fiume di montagna dopo la pioggia", "pt": "Rio de montanha depois da chuva",
    },
    "channel.waterfall.long": {
        "en": "Small waterfall near Graz", "fr": "Petite cascade près de Graz",
        "es": "Pequeña cascada cerca de Graz", "de": "Kleiner Wasserfall bei Graz",
        "it": "Piccola cascata vicino a Graz", "pt": "Pequena cachoeira perto de Graz",
    },
    "channel.citySnow.long": {
        "en": "Snowflakes in Warren", "fr": "Flocons de neige à Warren",
        "es": "Copos de nieve en Warren", "de": "Schneeflocken in Warren",
        "it": "Fiocchi di neve a Warren", "pt": "Flocos de neve em Warren",
    },
    "channel.cabinRain.long": {
        "en": "Autumn rain under a log cabin roof", "fr": "Pluie d’automne sous le toit d’une cabane",
        "es": "Lluvia otoñal bajo el techo de una cabaña", "de": "Herbstregen unter dem Blockhüttendach",
        "it": "Pioggia d’autunno sotto il tetto di una baita", "pt": "Chuva de outono sob o telhado de uma cabana",
    },
    "channel.chiloeForest.long": {
        "en": "Cucao park overlook", "fr": "Belvédère du parc de Cucao",
        "es": "Mirador del parque de Cucao", "de": "Aussichtspunkt im Cucao-Park",
        "it": "Belvedere del parco di Cucao", "pt": "Mirante do parque de Cucao",
    },
    "channel.jungleDawn.long": {
        "en": "Dawn in Sian Ka'an", "fr": "Aube dans la réserve de Sian Ka'an",
        "es": "Amanecer en Sian Ka'an", "de": "Morgendämmerung in Sian Ka'an",
        "it": "Alba a Sian Ka'an", "pt": "Amanhecer em Sian Ka'an",
    },
    "channel.harbor.long": {
        "en": "Small harbor with gulls and boats", "fr": "Petit port avec goélands et bateaux",
        "es": "Pequeño puerto con gaviotas y barcos", "de": "Kleiner Hafen mit Möwen und Booten",
        "it": "Piccolo porto con gabbiani e barche", "pt": "Pequeno porto com gaivotas e barcos",
    },
    "channel.goats.long": {
        "en": "Goats with bells in Montargil", "fr": "Chèvres à clochettes à Montargil",
        "es": "Cabras con cencerros en Montargil", "de": "Ziegen mit Glocken in Montargil",
        "it": "Capre con campanelli a Montargil", "pt": "Cabras com sinos em Montargil",
    },
    "channel.windChimes.long": {
        "en": "Wind chimes in a Santa Fe breeze", "fr": "Carillons dans une brise de Santa Fe",
        "es": "Campanas de viento con la brisa de Santa Fe", "de": "Windspiele in einer Brise aus Santa Fe",
        "it": "Campanelli al vento nella brezza di Santa Fe", "pt": "Sinos de vento na brisa de Santa Fe",
    },
    "channel.churchBells.long": {
        "en": "Sunday church bells in Hanover", "fr": "Cloches du dimanche à Hanovre",
        "es": "Campanas dominicales en Hannover", "de": "Sonntagsglocken in Hannover",
        "it": "Campane della domenica ad Hannover", "pt": "Sinos de domingo em Hanover",
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
    "channel.sea.location": {
        "en": "Epitalio, Western Greece", "fr": "Epitalio, Grèce-Occidentale",
        "es": "Epitalio, Grecia Occidental", "de": "Epitalio, Westgriechenland",
        "it": "Epitalio, Grecia Occidentale", "pt": "Epitalio, Grécia Ocidental",
    },
    "channel.mountainStorm.location": {
        "en": "Tremosine sul Garda, Brescia", "fr": "Tremosine sul Garda, Brescia",
        "es": "Tremosine sul Garda, Brescia", "de": "Tremosine sul Garda, Brescia",
        "it": "Tremosine sul Garda, Brescia", "pt": "Tremosine sul Garda, Brescia",
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
    "channel.rainWindow.location": {
        "en": "Chiswick, London", "fr": "Chiswick, Londres",
        "es": "Chiswick, Londres", "de": "Chiswick, London",
        "it": "Chiswick, Londra", "pt": "Chiswick, Londres",
    },
    "channel.rainForest.location": {
        "en": "Leipzig area, Saxony", "fr": "Région de Leipzig, Saxe",
        "es": "Zona de Leipzig, Sajonia", "de": "Raum Leipzig, Sachsen",
        "it": "Area di Lipsia, Sassonia", "pt": "Região de Leipzig, Saxônia",
    },
    "channel.heavyRain.location": {
        "en": "Rural Brazil", "fr": "Campagne brésilienne",
        "es": "Brasil rural", "de": "Ländliches Brasilien",
        "it": "Brasile rurale", "pt": "Brasil rural",
    },
    "channel.nightWind.location": {
        "en": "Cabo Raso", "fr": "Cabo Raso",
        "es": "Cabo Raso", "de": "Cabo Raso",
        "it": "Cabo Raso", "pt": "Cabo Raso",
    },
    "channel.nightForest.location": {
        "en": "Tallgrass Prairie, Oklahoma", "fr": "Prairie tallgrass, Oklahoma",
        "es": "Pradera tallgrass, Oklahoma", "de": "Tallgrass-Prärie, Oklahoma",
        "it": "Prateria tallgrass, Oklahoma", "pt": "Pradaria tallgrass, Oklahoma",
    },
    "channel.mountainFlood.location": {
        "en": "Guilin, Guangxi", "fr": "Guilin, Guangxi",
        "es": "Guilin, Guangxi", "de": "Guilin, Guangxi",
        "it": "Guilin, Guangxi", "pt": "Guilin, Guangxi",
    },
    "channel.waterfall.location": {
        "en": "Graz, Styria", "fr": "Graz, Styrie",
        "es": "Graz, Estiria", "de": "Graz, Steiermark",
        "it": "Graz, Stiria", "pt": "Graz, Estíria",
    },
    "channel.citySnow.location": {
        "en": "Warren, Michigan", "fr": "Warren, Michigan",
        "es": "Warren, Michigan", "de": "Warren, Michigan",
        "it": "Warren, Michigan", "pt": "Warren, Michigan",
    },
    "channel.cabinRain.location": {
        "en": "Axelfors forest", "fr": "Forêt d’Axelfors",
        "es": "Bosque de Axelfors", "de": "Axelfors-Wald",
        "it": "Foresta di Axelfors", "pt": "Floresta de Axelfors",
    },
    "channel.chiloeForest.location": {
        "en": "Cucao, Chiloé", "fr": "Cucao, Chiloé",
        "es": "Cucao, Chiloé", "de": "Cucao, Chiloé",
        "it": "Cucao, Chiloé", "pt": "Cucao, Chiloé",
    },
    "channel.jungleDawn.location": {
        "en": "Sian Ka'an Biosphere Reserve", "fr": "Réserve de biosphère de Sian Ka'an",
        "es": "Reserva de la Biosfera Sian Ka'an", "de": "Biosphärenreservat Sian Ka'an",
        "it": "Riserva della biosfera di Sian Ka'an", "pt": "Reserva da Biosfera Sian Ka'an",
    },
    "channel.harbor.location": {
        "en": "Pazar, Rize", "fr": "Pazar, Rize",
        "es": "Pazar, Rize", "de": "Pazar, Rize",
        "it": "Pazar, Rize", "pt": "Pazar, Rize",
    },
    "channel.goats.location": {
        "en": "Montargil", "fr": "Montargil",
        "es": "Montargil", "de": "Montargil",
        "it": "Montargil", "pt": "Montargil",
    },
    "channel.windChimes.location": {
        "en": "Santa Fe, New Mexico", "fr": "Santa Fe, Nouveau-Mexique",
        "es": "Santa Fe, Nuevo México", "de": "Santa Fe, New Mexico",
        "it": "Santa Fe, Nuovo Messico", "pt": "Santa Fe, Novo México",
    },
    "channel.churchBells.location": {
        "en": "Hanover", "fr": "Hanovre",
        "es": "Hannover", "de": "Hannover",
        "it": "Hannover", "pt": "Hanover",
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

    # Long names (all channels).
    for key, translations in LONG_NAMES.items():
        entry = build_entry(translations, LONG_COMMENT)
        if key in strings:
            updated += 1
        else:
            added += 1
        strings[key] = entry

    # Locations (all channels).
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
