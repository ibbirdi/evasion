# Oasis App — Sound Sources & Audio Processing

Documentation complète des **20 pistes nature** intégrées dans l'application Oasis : sources, traitement, encodage et implémentation iOS.

Sources téléchargées depuis [freesound.org](https://freesound.org). Toutes les durées et localisations ont été vérifiées le 2026-04-29 directement depuis chaque page (geotag, og:audio:title, page de licence).

---

## 1. Pipeline d'encodage

Toutes les pistes sont reconverties depuis les sources HQ avec le pipeline ffmpeg suivant :

### 1.1 Étapes

```
source.{wav,flac,mp3,ogg}  →  [troncature si >45 min]
                           →  [loudnorm pass 1 — measurement]
                           →  [loudnorm pass 2 — linear gain + EBU R128]
                           →  [alimiter brick-wall]
                           →  [AAC-LC encode]
                           →  pisteN.m4a
```

### 1.2 Paramètres détaillés

**Truncation :** sources >45 min coupées à 45:00, offset `+30s` au début pour éviter le bruit d'amorce. Sons concernés : *Forêt, Mer*.

```
ffmpeg -ss 30 -t 2700 -i <source>  …
```

**Loudness normalization (2-pass EBU R128 / ITU-R BS.1770) :**

- Cible : `I = -20 LUFS, TP = -1.5 dBTP, LRA = 11 LU`
- Mode `linear=true` : gain global pur (préserve toute la dynamique du son original ; pas de compression dynamique)
- Pass 1 mesure `input_i / input_tp / input_lra / input_thresh / target_offset`, Pass 2 applique avec ces valeurs

```
# Pass 1 (analysis only)
ffmpeg -i <source> -af "loudnorm=I=-20:TP=-1.5:LRA=11:print_format=json" -f null -

# Pass 2 (apply with measured values)
ffmpeg -i <source> -af \
  "loudnorm=I=-20:TP=-1.5:LRA=11:measured_I=…:measured_TP=…:measured_LRA=…:\
   measured_thresh=…:offset=…:linear=true:print_format=summary,\
   alimiter=limit=0.71:level=false" \
  -c:a aac -b:a 96k -ar 44100 -ac 2 -movflags +faststart  pisteN.m4a
```

**Brick-wall limiter (alimiter) :**

- `limit=0.71` ≈ -3 dBFS sample peak
- `level=false` désactive le makeup gain (sinon le limiteur restaure le pic après limitation, ce qui annule l'effet)
- Marge de 1.5 dB sous TP=-1.5 pour absorber les overshoots inter-sample générés par l'encodeur AAC

**Codec audio :**

- AAC-LC (PAS HE-AAC — pas de SBR, pas d'artefact métallique sur les sons large bande)
- 96 kbps stéréo : seuil de transparence pour ambient nature, équilibre qualité/taille
- 44.1 kHz, downmix stéréo si la source est multicanal
- Container m4a avec `+faststart` (atom moov en début de fichier, démarrage instantané)

### 1.3 Pourquoi ces choix

| Choix | Raison |
|---|---|
| AAC-LC vs HE-AAC | HE-AAC à 40 kbps utilise la SBR (Spectral Band Replication) qui *fabrique* les hautes fréquences à la décompression. Sur du contenu naturel apériodique (gouttes, oiseaux, vent), ça produit un grain métallique. AAC-LC encode toute la bande sans artifice. |
| 96 kbps | À ce débit AAC-LC est perçu comme transparent sur du naturel. 64 kbps audible sur les transitoires (cigales), 128 kbps n'apporte rien à l'oreille pour ce type de contenu. |
| 44.1 kHz | Fréquence d'échantillonnage standard CD. La plupart des sources sont à 44.1 ou 48 kHz ; on resample en 44.1 pour cohérence. |
| -20 LUFS | Cible de mix bus pour ambient/sleep app. Plus chaud (-14/-16 LUFS comme Spotify) écrase la dynamique naturelle. Plus bas (-23 LUFS broadcast) demande à l'utilisateur de monter le volume système. |
| -1.5 dBTP / alimiter -3 dBFS | Headroom pour superposition de plusieurs canaux sans clipping inter-sample lors du décodage. |
| 2-pass linear | Mode dynamique (1-pass) compresse pour atteindre la cible — perte de naturel. Linear 2-pass calcule un gain global précis et préserve toute la dynamique. |
| Tronqué à 45 min | Limite la taille du bundle (3 sons à 45 min ≈ 100 MB) sans amputer significativement la durée d'écoute (l'audio loop dans l'app). |

### 1.4 Mesures post-encodage

Toutes les pistes mesurées avec `ffmpeg ebur128 peak=true` après encodage :

| Fichier | I (LUFS) | TP (dBTP) | LRA (LU) | Taille |
|---|---:|---:|---:|---:|
| oiseaux1.m4a | -20.1 | -2.1 | 9.4 | 8.8 MB |
| vent1.m4a | -20.0 | -2.4 | 8.1 | 9.7 MB |
| plage1.m4a | -19.6 | -0.3 | 10.1 | 17.0 MB |
| goelants1.m4a | -20.0 | -4.0 | 5.4 | 1.5 MB |
| foret1.m4a | -20.1 | -1.5 | 9.7 | 31.9 MB |
| pluie1.m4a | -19.5 | -2.7 | 5.7 | 14.1 MB |
| orage1.m4a | -20.1 | -2.1 | 10.5 | 17.4 MB |
| cigales1.m4a | -20.1 | -10.2 | 2.2 | 1.9 MB |
| grillons1.m4a | -20.5 | -2.6 | 8.3 | 11.9 MB |
| tente1.m4a | -19.8 | -1.7 | 5.8 | 12.2 MB |
| riviere1.m4a | -19.7 | -2.9 | 0.3 | 14.9 MB |
| ville1.m4a | -20.0 | -2.2 | 5.2 | 12.5 MB |
| mer1.m4a | -19.7 | -1.3 | 5.3 | 31.4 MB |
| orageMontagne1.m4a | -20.4 | -2.2 | 11.2 | 12.8 MB |
| campfire1.m4a | -20.6 | -1.0 | 4.6 | 6.3 MB |
| cafe1.m4a | -20.0 | -1.8 | 4.2 | 7.0 MB |
| lac1.m4a | -20.5 | +0.3 | 4.7 | 14.4 MB |
| savane1.m4a | -20.0 | -3.2 | 10.2 | 11.4 MB |
| jungleamerique1.m4a | -20.1 | -1.9 | 11.0 | 17.2 MB |
| jungleasie1.m4a | -20.1 | -10.3 | 1.5 | 10.7 MB |

Toutes les pistes sont à **-20 LUFS ±0.6 LU** (tolérance perceptuelle ≈1 LU) : volume harmonieux entre canaux pour mixage.

`lac1.m4a` reste à +0.3 dBTP par overshoot inter-sample non bloqué par l'alimiter (la source hydrophone à -52 LUFS demande +32 dB de gain) ; pas de clipping audible en lecture mais pas de marge supplémentaire.

Total bundle audio (20 nature + 4 binaurals) : **~310 MB**.

---

## 2. Référence d'implémentation iOS

| # | Channel ID (Swift) | Fichier | Icône SF Symbol | Tint RGB | Groupe tonal |
|--:|---|---|---|---|---|
| 1 | `oiseaux` | oiseaux1.m4a | `bird.fill` | (0.96, 0.74, 0.53) | D3 open (146.83 Hz) |
| 2 | `vent` | vent1.m4a | `wind` | (0.96, 0.97, 0.92) | D3 open (146.83 Hz) |
| 3 | `plage` | plage1.m4a | `water.waves` | (0.93, 0.86, 0.57) | B2 open (123.47 Hz) |
| 4 | `goelands` | goelants1.m4a | `bird` | (0.71, 0.86, 0.66) | B2 open (123.47 Hz) |
| 5 | `foret` | foret1.m4a | `tree.fill` | (0.63, 0.86, 0.55) | D3 open (146.83 Hz) |
| 6 | `pluie` | pluie1.m4a | `cloud.rain.fill` | (0.45, 0.79, 0.92) | C3 minor drone (130.81 Hz) |
| 7 | `tonnerre` | orage1.m4a | `cloud.bolt.fill` | (0.69, 0.57, 0.92) | C3 minor drone (130.81 Hz) |
| 8 | `cigales` | cigales1.m4a | `ladybug.fill` | (0.89, 0.86, 0.51) | G3 sus4 (196 Hz) |
| 9 | `grillons` | grillons1.m4a | `moon.stars` | (0.65, 0.80, 0.97) | G3 sus4 (196 Hz) |
| 10 | `tente` | tente1.m4a | `tent.fill` | (0.85, 0.73, 0.60) | A2 neutral (110 Hz) |
| 11 | `riviere` | riviere1.m4a | `drop.fill` | (0.50, 0.85, 0.95) | C3 open (130.81 Hz) |
| 12 | `village` | ville1.m4a | `house.fill` | (0.90, 0.72, 0.60) | A2 neutral (110 Hz) |
| 13 | `mer` | mer1.m4a | `water.waves` | (0.32, 0.55, 0.78) | B2 open (123.47 Hz) |
| 14 | `orageMontagne` | orageMontagne1.m4a | `cloud.bolt.fill` | (0.58, 0.62, 0.78) | C3 minor drone (130.81 Hz) |
| 15 | `campfire` | campfire1.m4a | `flame.fill` | (0.95, 0.55, 0.30) | A2 major (110 Hz) |
| 16 | `cafe` | cafe1.m4a | `cup.and.saucer.fill` | (0.65, 0.48, 0.38) | A2 neutral (110 Hz) |
| 17 | `lac` | lac1.m4a | `sailboat.fill` | (0.42, 0.68, 0.85) | C3 open (130.81 Hz) |
| 18 | `savane` | savane1.m4a | `sun.max.fill` | (0.92, 0.78, 0.45) | D3 open (146.83 Hz) |
| 19 | `jungleAmerique` | jungleamerique1.m4a | `leaf.fill` | (0.35, 0.72, 0.45) | D3 open (146.83 Hz) |
| 20 | `jungleAsie` | jungleasie1.m4a | `cloud.fog.fill` | (0.40, 0.80, 0.60) | D3 open (146.83 Hz) |

Le **groupe tonal** détermine la note fondamentale du *Souffle harmonique* (`TonalBedSynth.swift`) quand le canal est dominant dans le mix : un drone synthétisé qui sit sous la captation pour donner une cohérence harmonique à l'ensemble.

`channel.{id}` / `channel.{id}.location` / `channel.{id}.long` dans `Localizable.xcstrings` couvrent **6 locales** : en, fr, de, es, it, pt.

---

## 3. Sources individuelles

> **Format des champs**
> - **Durée (in-app)** : durée du `.m4a` embarqué dans l'app, mesurée par `ffprobe`.
> - **Durée (source)** : durée affichée sur la page freesound.
> - **Nom du fichier source** : titre exact retourné par la balise `og:audio:title` de la page freesound — utile pour retrouver le fichier dans `~/Downloads`.

### 3.1 Oiseaux (Birds)
**Piste app:** `oiseaux1.m4a`
**Durée (in-app):** 12:31.5 (751.5 sec) — match exact source
**Nom du fichier source:** `common birds in britany spring countryside 2`
**Auteur:** [bruno.auzet](https://freesound.org/people/bruno.auzet/)
**Lien direct:** https://freesound.org/people/bruno.auzet/sounds/838024/
**Localisation:** 🇫🇷 France — Nivillac, Morbihan, Bretagne (Geotag freesound)
**Licence:** Creative Commons 0

---

### 3.2 Vent (Wind)
**Piste app:** `vent1.m4a`
**Durée (in-app):** 14:00.3 (840.3 sec) — match exact source
**Nom du fichier source:** `Perpignan outdoor wind - 2024 12 08`
**Auteur:** [Sadiquecat](https://freesound.org/people/Sadiquecat/)
**Lien direct:** https://freesound.org/people/Sadiquecat/sounds/773670/
**Localisation:** 🇫🇷 France — Perpignan, Occitanie *(déduit du titre — pas de geotag explicite)*
**Licence:** Creative Commons 0

---

### 3.3 Plage (Beach)
**Piste app:** `plage1.m4a`
**Durée (in-app):** 24:24.1 (1464.1 sec) — match exact source
**Nom du fichier source:** `Waves at Shetland Islands 3.wav`
**Auteur:** [straget](https://freesound.org/people/straget/)
**Lien direct:** https://freesound.org/people/straget/sounds/434615/
**Localisation:** 🇬🇧 Royaume-Uni — Îles Shetland, Écosse (Geotag freesound: "Scotland, United Kingdom")
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `straget` requise

---

### 3.4 Goélands (Seagulls)
**Piste app:** `goelants1.m4a`
**Durée (in-app):** 2:14.7 (134.7 sec) — match exact source
**Nom du fichier source:** `harbour, seagulls-48k.wav`
**Auteur:** [Further_Roman](https://freesound.org/people/Further_Roman/)
**Lien direct:** https://freesound.org/people/Further_Roman/sounds/208074/
**Localisation:** 🇫🇷 France — Bretagne *(déduit — pas de geotag, mais auteur français et description "port", enregistré avec Olympus LS-11)*
**Licence:** Creative Commons 0

---

### 3.5 Forêt (Forest) — *tronqué à 45 min*
**Piste app:** `foret1.m4a`
**Durée (in-app):** 45:00 (2700 sec) — **tronqué** depuis 48:18.869 (offset +30s, fenêtre de 45 min)
**Nom du fichier source:** `Kampina forest spring LONG 190322_1321.ogg`
**Auteur:** [klankbeeld](https://freesound.org/people/klankbeeld/)
**Lien direct:** https://freesound.org/people/klankbeeld/sounds/468049/
**Localisation:** 🇳🇱 Pays-Bas — Réserve naturelle de Kampina (Oisterwijkse bossen en vennen, rivière Rosep), Brabant-Septentrional (Geotag freesound: 51.57181, 5.24226)
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `klankbeeld` + freesound.org requise

---

### 3.6 Pluie (Rain)
**Piste app:** `pluie1.m4a`
**Durée (in-app):** 20:12 (1212 sec) — match exact source
**Nom du fichier source:** `29_10_25_Medium_Rain`
**Auteur:** [Stagno](https://freesound.org/people/Stagno/)
**Lien direct:** https://freesound.org/people/Stagno/sounds/832262/
**Localisation:** 🇮🇹 Italie — Voghera, Pavia (Geotag freesound — plaine du Pô, 29 octobre 2025)
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `Stagno` requise

---

### 3.7 Orage / Tonnerre (Thunder/Storm)
**Piste app:** `orage1.m4a`
**Durée (in-app):** 25:00 (1500 sec) — match exact source
**Nom du fichier source:** `Thunder and rain in south of France during summer`
**Auteur:** [felix.blume](https://freesound.org/people/felix.blume/)
**Lien direct:** https://freesound.org/people/felix.blume/sounds/437133/
**Localisation:** 🇫🇷 France — Azillanet, Hérault, Occitanie (Geotag freesound — enregistré depuis le balcon, été 2018, micros B&K 4006)
**Licence:** Creative Commons 0

---

### 3.8 Cigales (Cicadas)
**Piste app:** `cigales1.m4a`
**Durée (in-app):** 2:45 (165 sec) — match exact source
**Nom du fichier source:** `CICADAS_1.wav`
**Auteur:** [pablodavilla](https://freesound.org/people/pablodavilla/)
**Lien direct:** https://freesound.org/people/pablodavilla/sounds/592110/
**Localisation:** 🇮🇹 Italie — Île de Lampedusa, Sicile *(déduit — pas de geotag freesound, l'auteur a explicitement enregistré d'autres sons de nature à Lampedusa)*
**Licence:** Creative Commons 0

---

### 3.9 Grillons (Crickets)
**Piste app:** `grillons1.m4a`
**Durée (in-app):** 16:59.5 (1019.5 sec) — match exact source
**Nom du fichier source:** `NATURE_COUNTRY_NIGHT_CRICKETS_03.wav`
**Auteur:** [keng-wai-chane-chick-te](https://freesound.org/people/keng-wai-chane-chick-te/)
**Lien direct:** https://freesound.org/people/keng-wai-chane-chick-te/sounds/692908/
**Localisation:** 🇫🇷 France — Theneuille, Allier, Auvergne-Rhône-Alpes (Geotag freesound — 29 juillet 2019, 23h50, Olympus LS100, grillons + chouette)
**Licence:** Creative Commons 0

---

### 3.10 Tente (Tent)
**Piste app:** `tente1.m4a`
**Durée (in-app):** 17:22.2 (1042.2 sec) — match exact source
**Nom du fichier source:** `heavy rain on a small tent`
**Auteur:** [Petrosilia](https://freesound.org/people/Petrosilia/)
**Lien direct:** https://freesound.org/people/Petrosilia/sounds/592997/
**Localisation:** 🇩🇰 Danemark — Île de Bornholm *(déduit — pas de geotag freesound, l'auteur a uploadé ce son le même jour que plusieurs enregistrements explicitement situés à Bornholm)*
**Licence:** Creative Commons 0

---

### 3.11 Rivière (Stream/River)
**Piste app:** `riviere1.m4a`
**Durée (in-app):** 21:21.4 (1281.4 sec) — match exact source
**Nom du fichier source:** `Small Waterfalls, Mountain Stream, and Birds in a Taiwan Mountain`
**Auteur:** [calebjay](https://freesound.org/people/calebjay/)
**Lien direct:** https://freesound.org/people/calebjay/sounds/684901/
**Localisation:** 🇹🇼 Taïwan — 復興區 (district de Fuxing), Taoyuan (Geotag freesound)
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `calebjay` requise

---

### 3.12 Village (City/Urban)
**Piste app:** `ville1.m4a`
**Durée (in-app):** 17:55.8 (1075.8 sec) — match exact source
**Nom du fichier source:** `Urban commercial pedestrian street ambience`
**Auteur:** [lastraindrop](https://freesound.org/people/lastraindrop/)
**Lien direct:** https://freesound.org/people/lastraindrop/sounds/716384/
**Localisation:** 🇨🇳 Chine — Liuzhou Shi (柳州市), Guangxi (Geotag freesound)
**Licence:** Creative Commons 0

---

### 3.13 Mer (Sea) — *tronqué à 45 min*
**Piste app:** `mer1.m4a`
**Durée (in-app):** 45:00 (2700 sec) — **tronqué** depuis 47:33.150 (offset +30s, fenêtre de 45 min)
**Nom du fichier source:** `Sea MS.wav`
**Auteur:** [yiorgis](https://freesound.org/people/yiorgis/)
**Lien direct:** https://freesound.org/people/yiorgis/sounds/705548/
**Localisation:** 🇬🇷 Grèce — Epitalio, Grèce-Occidentale, Péloponnèse (Geotag freesound — captation MS [Mid/Side])
**Licence:** Creative Commons 0

---

### 3.14 Orage en montagne (Mountain Storm)
**Piste app:** `orageMontagne1.m4a`
**Durée (in-app):** 18:24.3 (1104.3 sec) — match exact source
**Nom du fichier source:** `mountain thunder`
**Auteur:** [bruno.auzet](https://freesound.org/people/bruno.auzet/)
**Lien direct:** https://freesound.org/people/bruno.auzet/sounds/647420/
**Localisation:** 🇮🇹 Italie — Tremosine sul Garda, Brescia (Geotag freesound — Alpes italiennes au-dessus du lac de Garde)
**Licence:** Creative Commons 0

---

### 3.15 Feu de camp (Campfire)
**Piste app:** `campfire1.m4a`
**Durée (in-app):** 9:00 (540 sec) — match exact source
**Nom du fichier source:** `Campfire Just After Dusk On The St. Marys River 5-28-23 9 minutes .wav`
**Auteur:** [Ambient-X](https://freesound.org/people/Ambient-X/)
**Lien direct:** https://freesound.org/people/Ambient-X/sounds/688992/
**Localisation:** 🇺🇸 États-Unis — Barbeau, Michigan, rivière St. Marys (Geotag freesound — 30 min après coucher du soleil, mai 2023)
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `Ambient-X` requise
**Contenu :** Crépitement du feu + oiseaux nocturnes + grenouilles + insectes

---

### 3.16 Café (Café / Restaurant)
**Piste app:** `cafe1.m4a`
**Durée (in-app):** 10:00.7 (600.7 sec) — match exact source
**Nom du fichier source:** `Restaurant Atmosphere (crowded)`
**Auteur:** [felix.blume](https://freesound.org/people/felix.blume/)
**Lien direct:** https://freesound.org/people/felix.blume/sounds/422097/
**Localisation:** 🇧🇷 Brésil — São Paulo (Geotag freesound, brasserie Bella Paulista, minuit, micros MS Schoeps)
**Licence:** Creative Commons 0
**Contenu :** Brouhaha de restaurant animé, voix, fond de machines

---

### 3.17 Lac (Bord de lac)
**Piste app:** `lac1.m4a`
**Durée (in-app):** 20:40.8 (1240.8 sec) — match exact source
**Nom du fichier source:** `180905-Fritton Lake - Lakeside 2 - Stereo Hydrophone_01.mp3`
**Auteur:** [Yarmonics](https://freesound.org/people/Yarmonics/)
**Lien direct:** https://freesound.org/people/Yarmonics/sounds/445956/
**Localisation:** 🇬🇧 Royaume-Uni — Great Yarmouth, Norfolk, Angleterre (Geotag freesound — Fritton Lake, hydrophone stéréo, enregistré par Martin Scaiff)
**Licence:** Creative Commons 0
**Contenu :** Eau calme + nature ambiante. Source extrêmement quiet (-52 LUFS) — la normalisation à -20 LUFS exige +32 dB de gain, d'où le TP marginal (+0.3 dBTP) en sortie.

---

### 3.18 Savane (Savane africaine)
**Piste app:** `savane1.m4a`
**Durée (in-app):** 16:19 (979 sec) — match exact source
**Nom du fichier source:** `Mkuze River.wav`
**Auteur:** [eardeer](https://freesound.org/people/eardeer/)
**Lien direct:** https://freesound.org/people/eardeer/sounds/512090/
**Localisation:** 🇿🇦 Afrique du Sud — Jozini NU, KwaZulu-Natal (Geotag freesound — rivière Mkuze, Harloo Safaris Basecamp, micros RØDE NT1-A)
**Licence:** Creative Commons 0
**Contenu :** Ambiance fluviale africaine, oiseaux exotiques, insectes

---

### 3.19 Jungle tropicale (Jungle d'Amérique latine)
**Piste app:** `jungleamerique1.m4a`
**Durée (in-app):** 24:28.3 (1468.3 sec) — match exact source
**Nom du fichier source:** `Night Montepio Frogs crikets and night birds`
**Auteur:** [Globofonia](https://freesound.org/people/Globofonia/)
**Lien direct:** https://freesound.org/people/Globofonia/sounds/587720/
**Localisation:** 🇲🇽 Mexique — Veracruz (Geotag freesound — Los Tuxtlas, jungle tropicale nocturne)
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `Globofonia` requise
**Contenu :** Grenouilles, grillons, oiseaux nocturnes, jungle dense

---

### 3.20 Jungle d'Asie
**Piste app:** `jungleasie1.m4a`
**Durée (in-app):** 15:09 (909 sec) — match exact source
**Nom du fichier source:** `140930 night jungle nature ambience.Chiangmai_Thailand. Cicades. Dew drops (ORTF.SD664+CS3e).wav`
**Auteur:** [Anantich](https://freesound.org/people/Anantich/)
**Lien direct:** https://freesound.org/people/Anantich/sounds/250273/
**Localisation:** 🇹🇭 Thaïlande — Hang Dong, Chiang Mai (Geotag freesound — micros Sanken CS3e en ORTF, Sound Devices 664)
**Licence:** Creative Commons Attribution 4.0 (CC-BY-4.0) — attribution à `Anantich` requise
**Contenu :** Cigales, gouttes de rosée, jungle tropicale asiatique

---

## 4. Résumé des localisations

| Pays | Pistes | Source |
|------|--------|--------|
| 🇫🇷 France | Oiseaux (Morbihan), Vent (Perpignan), Goélands (Bretagne *déduit*), Tonnerre (Hérault), Grillons (Allier) | mix vérifié + déduit |
| 🇮🇹 Italie | Pluie (Voghera, Pavia), Orage en montagne (Tremosine sul Garda, Brescia), Cigales (Lampedusa *déduit*) | mix vérifié + déduit |
| 🇹🇼 Taïwan | Rivière (district de Fuxing, Taoyuan) | vérifié |
| 🇬🇷 Grèce | Mer (Epitalio, Péloponnèse) | vérifié |
| 🇨🇳 Chine | Village (Liuzhou, Guangxi) | vérifié |
| 🇺🇸 États-Unis | Feu de camp (Barbeau, Michigan) | vérifié |
| 🇧🇷 Brésil | Café (São Paulo) | vérifié |
| 🇬🇧 Royaume-Uni | Lac (Great Yarmouth, Norfolk), Plage (Îles Shetland, Écosse) | vérifié |
| 🇳🇱 Pays-Bas | Forêt (Kampina, Brabant-Septentrional) | vérifié |
| 🇿🇦 Afrique du Sud | Savane (KwaZulu-Natal, Jozini NU) | vérifié |
| 🇲🇽 Mexique | Jungle tropicale (Veracruz) | vérifié |
| 🇹🇭 Thaïlande | Jungle d'Asie (Hang Dong, Chiang Mai) | vérifié |
| 🇩🇰 Danemark | Tente (Bornholm *déduit*) | déduit |

---

## 5. Notes importantes

1. **URLs directes:** Chaque lien pointe vers la page exacte du son (sound_id inclus). Format: `https://freesound.org/people/{auteur}/sounds/{sound_id}/`.

2. **Durées vérifiées (2026-04-29):** Les durées listées correspondent exactement à celles affichées sur la page freesound, sauf pour les 2 sons tronqués (Forêt, Mer) coupés volontairement à 45 min pour limiter la taille du bundle.

3. **Localisations non renseignées par les auteurs:** 4 pistes n'ont pas de geotag explicite sur freesound. Localisation déduite avec différents niveaux de confiance:
   - depuis le titre du son: Vent (Sadiquecat — Perpignan)
   - depuis le profil de l'auteur ou ses autres sons: Goélands (Further_Roman — Bretagne), Tente (Petrosilia — Bornholm), Cigales (pablodavilla — Lampedusa)

4. **Licences:** Les pistes utilisent des licences Creative Commons libres (CC0 ou CC-BY-4.0). Les pistes sous Attribution 4.0 — **Plage, Forêt, Pluie, Rivière, Feu de camp, Jungle tropicale, Jungle d'Asie** — exigent que l'attribution à l'auteur figure dans les crédits de l'app. Les noms d'auteurs sont déjà exposés via `ChannelCredit` dans `SoundChannelMetadata.swift`.

5. **Re-téléchargement:** Pour reconstruire les sources HQ depuis freesound, le `Nom du fichier source` indiqué correspond exactement au titre affiché par la page (balise `og:audio:title`). Le téléchargement de freesound préfixe ce nom avec `{sound_id}__{auteur_lowercase}__`.

6. **Re-encodage:** Le pipeline ffmpeg complet (script `/tmp/convert_2pass.sh` durant le développement) attend les sources dans `~/Downloads`. Cible : AAC-LC 96 kbps 44.1 kHz stéréo, normalisé EBU R128 à -20 LUFS / -1.5 dBTP, brick-wall alimiter à -3 dBFS sample peak. Voir §1.2 pour les commandes exactes.
