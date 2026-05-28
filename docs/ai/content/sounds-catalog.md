---
title: Sounds Catalog
status: stable
last_updated: 2026-05-28
tracks:
  - "ios-native/OasisNative/Models/SoundChannelMetadata.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Resources/Audio/*.m4a"
  - "scripts/convert_new_sounds.sh"
  - "scripts/generateBinauralSounds.py"
related:
  - "../architecture/audio-engine.md"
  - "../architecture/binaural.md"
  - "sound-backgrounds.md"
  - "../operations/known-issues.md"
---

# Sounds Catalog

The 35 ambient channels and 4 binaural tracks. The single source of truth for runtime metadata is [`SoundChannelMetadata.swift`](../../../ios-native/OasisNative/Models/SoundChannelMetadata.swift); this file documents the *why* (encoding pipeline, sourcing, licence obligations) and provides a reading-friendly index. Procedural Noise Lab layers are generated locally and are documented in [architecture/audio-engine.md](../architecture/audio-engine.md), not counted as bundled sound channels.

## 35 ambient channels

| # | ID | Display | File | Category | Location | Author | Licence | SF Symbol |
|---|---|---|---|---|---|---|---|---|
| 1 | `oiseaux` | Birds | `oiseaux1.m4a` | wildlife | Nivillac, Morbihan, FR | bruno.auzet | CC0 | `bird.fill` |
| 2 | `vent` | Wind | `vent1.m4a` | weather | Perpignan, Occitanie, FR | Sadiquecat | CC0 | `wind` |
| 3 | `plage` | Shore | `plage1.m4a` | water | Shetland Islands, GB | straget | **CC-BY-4.0** | `water.waves` |
| 4 | `goelands` | Seagulls | `goelants1.m4a` *(file mismatch — see known-issues)* | wildlife | Brittany harbour, FR | Further_Roman | CC0 | `bird` |
| 5 | `foret` | Forest | `foret1.m4a` | forest | Kampina, North Brabant, NL | klankbeeld | **CC-BY-4.0** | `tree.fill` |
| 6 | `pluie` | Rain | `pluie1.m4a` | weather | Voghera, Pavia, IT | Stagno | **CC-BY-4.0** | `cloud.rain.fill` |
| 7 | `tonnerre` | Storm over the plain | `orage1.m4a` *(file mismatch)* | weather | Azillanet, Hérault, FR | felix.blume | CC0 | `cloud.bolt.fill` |
| 8 | `cigales` | Cicadas | `cigales1.m4a` | wildlife | Lampedusa, Sicily, IT | pablodavilla | CC0 | `ladybug.fill` |
| 9 | `grillons` | Crickets | `grillons1.m4a` | wildlife | Theneuille, Allier, FR | keng-wai-chane-chick-te | CC0 | `moon.stars` |
| 10 | `tente` | Rain under the tent | `tente1.m4a` | shelter | Bornholm island, DK | Petrosilia | CC0 | `tent.fill` |
| 11 | `riviere` | River | `riviere1.m4a` | water | Fuxing, Taoyuan, TW | calebjay | **CC-BY-4.0** | `drop.fill` |
| 12 | `village` | Village | `ville1.m4a` *(file mismatch)* | human | Liuzhou, Guangxi, CN | lastraindrop | CC0 | `house.fill` |
| 13 | `mer` | Sea | `mer1.m4a` | water | Epitalio, Western Greece, GR | yiorgis | CC0 | `water.waves` |
| 14 | `orageMontagne` | Mountain storm | `orageMontagne1.m4a` | weather | Tremosine sul Garda, Brescia, IT | bruno.auzet | CC0 | `cloud.bolt.fill` |
| 15 | `campfire` | Campfire | `campfire1.m4a` | fire | St. Marys River, Michigan, US | Ambient-X | **CC-BY-4.0** | `flame.fill` |
| 16 | `cafe` | Café | `cafe1.m4a` | human | São Paulo, BR | felix.blume | CC0 | `cup.and.saucer.fill` |
| 17 | `lac` | Lake | `lac1.m4a` | water | Fritton Lake, Norfolk, GB | Yarmonics (Martin Scaiff) | CC0 | `sailboat.fill` |
| 18 | `savane` | Savanna | `savane1.m4a` | wildlife | KwaZulu-Natal, ZA | eardeer | CC0 | `sun.max.fill` |
| 19 | `jungleAmerique` | Tropical jungle | `jungleamerique1.m4a` | forest | Los Tuxtlas, Veracruz, MX | Globofonia | **CC-BY-4.0** | `leaf.fill` |
| 20 | `jungleAsie` | Asian jungle | `jungleasie1.m4a` | forest | Chiang Mai, TH | Anantich | **CC-BY-4.0** | `cloud.fog.fill` |
| 21 | `pluieFenetre` | Rain against the window | `pluieFenetre1.m4a` | shelter | Chiswick, London, GB | deleted_user_2104797 | CC0 | `window.vertical.closed` |
| 22 | `pluieForet` | Forest rain | `pluieForet1.m4a` | forest | Leipzig area, Saxony, DE *(approx.)* | Garuda1982 | CC0 | `cloud.rain.fill` |
| 23 | `fortePluie` | Heavy rain | `fortePluie1.m4a` | weather | Rural Brazil, BR | jmbphilmes | CC0 | `cloud.heavyrain.fill` |
| 24 | `ventNuit` | Night wind | `ventNuit1.m4a` | weather | Cabo Raso, PT | fran_marenco | CC0 | `wind` |
| 25 | `foretNuit` | Night forest | `foretNuit1.m4a` | forest | Tallgrass Prairie, Oklahoma, US | felix.blume | CC0 | `moon.stars.fill` |
| 26 | `crueMontagne` | Mountain river | `crueMontagne1.m4a` | water | Guilin, Guangxi, CN | lastraindrop | CC0 | `water.waves` |
| 27 | `cascade` | Waterfall | `cascade1.m4a` | water | Graz, Styria, AT | JakobGille | CC0 | `drop.fill` |
| 28 | `neigeVille` | Snowflakes | `neigeVille1.m4a` | weather | Warren, Michigan, US | Ambient-X | **CC-BY-4.0** | `snowflake` |
| 29 | `pluieCabane` | Rain under the cabin roof | `pluieCabane1.m4a` | shelter | Axelfors forest, SE | forestfjord | CC0 | `house.fill` |
| 30 | `foretChiloe` | Chiloé forest | `foretChiloe1.m4a` | forest | Cucao, Chiloé, CL | nicola_ariutti | CC0 | `leaf.fill` |
| 31 | `aubeJungle` | Jungle dawn | `aubeJungle1.m4a` | forest | Sian Ka'an Biosphere Reserve, MX | felix.blume | CC0 | `sunrise.fill` |
| 32 | `port` | Harbor | `port1.m4a` | water | Pazar, Rize, TR | micmussfilm | **CC-BY-4.0** | `sailboat.fill` |
| 33 | `chevres` | Goats with bells | `chevres1.m4a` | wildlife | Montargil, PT | Refrain | **CC-BY-4.0** | `pawprint.fill` |
| 34 | `carillons` | Wind chimes | `carillons1.m4a` | human | Santa Fe, New Mexico, US *(approx.)* | mc2method | **CC-BY-3.0** | `music.note` |
| 35 | `cloches` | Church bells | `cloches1.m4a` | human | Hanover, DE | inchadney | **CC-BY-4.0** | `bell.fill` |

**Free tier**: `oiseaux`, `vent`, `plage` (channels 1–3). Everything else is premium.

**Approximate fallback locations**: `pluieForet` and `carillons` do not publish exact geotags on their Freesound pages. They are intentionally marked `isApproximate`: `pluieForet` is placed around Leipzig/Saxony because Garuda1982's public Freesound catalogue repeatedly documents Leipzig/Saxony/Germany field recordings, and `carillons` is placed around Santa Fe, New Mexico as an invented but coherent listening setting for the wind-chime recording rather than a verified recording site.

**File-mismatch entries** (channel IDs differ from file names): `goelands`/`goelants1.m4a`, `tonnerre`/`orage1.m4a`, `village`/`ville1.m4a`. These are historical and **not** to be "fixed" — see [../operations/known-issues.md](../operations/known-issues.md).

**Visual tints and glyphs**: each channel stores a stable RGB tint and an `OasisGlyph` mapping in `SoundChannelMetadata.swift`. Runtime UI rendering boosts that tint's HSB saturation/brightness centrally in `ChannelMetadata.tint`, so mixer rows, sliders, minimaps, spatial controls, and premium teasers read more vibrant without editing every channel value. Channel identity icons use the curated Phosphor SVG subset in `Assets.xcassets/OasisGlyphs`; the SF Symbol column above remains as legacy metadata / platform fallback context, not the preferred visible iconography for Oasis-owned sound surfaces. Tints and glyph choices should still match the channel mood: bird ambience reads morning-gold, wind/harbour sounds lean airy/coastal blue, thunder is muted storm-violet, night sounds are darker blue/indigo, and shelter sounds use warmer wood/cabin tones.

**Visual backgrounds**: every ambient channel also has a subtle Pexels photo watermark mapped by `SoundChannel.backdrop` and stored in `Assets.xcassets/SoundBackgrounds`. Binaural tracks and other non-place concept cards use organic Pexels textures from `Assets.xcassets/OrganicBackgrounds` via `OrganicBackdrop`; My Ambiences can use the newer `organic_dark_satin` and `organic_blue_flow` textures when a more premium abstract surface is needed. Source photo IDs and selection rationale live in [sound-backgrounds.md](sound-backgrounds.md); keep that file in sync whenever a background asset changes.

## Licences and attribution

12 channels require visible attribution: **CC-BY-4.0** for `plage`, `foret`, `pluie`, `riviere`, `campfire`, `jungleAmerique`, `jungleAsie`, `neigeVille`, `port`, `chevres`, `cloches`; and **CC-BY-3.0** for `carillons`. Attribution is rendered by `SoundDetailSheet` from the `ChannelCredit` struct in `SoundChannelMetadata.swift`, showing the author, licence, and `freesound.org` source site inline. Removing or breaking that visible credit surface = licence violation. Re-check before any UI refactor of the detail sheet.

The remaining 23 channels are CC0 (no attribution required); we still display the author as a courtesy.

## Encoding pipeline

All ambient `.m4a` files are produced by [`scripts/convert_new_sounds.sh`](../../../scripts/convert_new_sounds.sh) with this exact ffmpeg pipeline:

1. **Optional truncation**: if source > 45 min, cut to 45:00 with offset `+30s` (avoids the slate at the start). Currently affects `foret` (source 48:18) and `mer` (source 47:33).
2. **Two-pass `loudnorm`** (EBU R128 / ITU-R BS.1770):
   ```
   I=-20 LUFS, TP=-1.5 dBTP, LRA=11 LU, linear=true
   ```
   `linear=true` applies a single global gain instead of compressing dynamics — preserves naturalness.
3. **Brick-wall limiter**: default `alimiter=limit=0.71:level=false` (~ -3 dBFS sample peak; `level=false` disables makeup gain so the limiter is purely defensive against intersample peaks). Two transient-heavy 2026-05 additions use stricter per-file settings after AAC true-peak validation: `neigeVille1.m4a` (`TP=-6`, limiter `0.25`) and `chevres1.m4a` (`TP=-3`, limiter `0.5`).
4. **Encoder**: AAC-LC, 96 kbps, stereo, 44.1 kHz. Container `.m4a` with `+faststart`.

### Why these choices (don't change without testing)

- **AAC-LC, not HE-AAC**: HE-AAC's spectral band replication invents high-frequency content, which sounds metallic on aperiodic ambient (raindrops, birds, wind). For wellness ambient, LC is transparent at 96 kbps and HE introduces audible artifacts.
- **96 kbps**: sweet spot. 64 kbps loses subtle stereo air; 128 kbps is wasted bytes given the bundle weight.
- **44.1 kHz**: sane default. Devices resample regardless; staying at 44.1 avoids one resample step.
- **-20 LUFS** (vs streaming standards -14/-16): we're a sleep / focus app, not Spotify. Quieter target preserves dynamics, leaves headroom for layering, and avoids loudness fatigue. Don't push.
- **TP -1.5 dBTP + alimiter 0.71**: belt + braces. AAC sometimes overshoots true peak; the limiter keeps every file safe under intersample peak. If post-encode validation still shows peaks above target, prefer a per-file stricter TP/limiter setting over raising loudness.
- **2-pass linear loudnorm**: 2-pass is required for accurate target in a single normalisation step; `linear=true` is the only mode that preserves dynamics.

## Bundle weight

- ~426 MB for all 35 ambient + 4 binaural files.
- New ambient channels add ~4–32 MB depending on length and complexity. `neigeVille1.m4a` is 45 min and is the largest addition (~32 MB).
- Watch the IPA size before shipping additions. App Store has a 4 GB cellular download limit, but user perception of "this app is huge" matters earlier.

## 4 binaural tracks

| Case | File | Frequency | Premium |
| --- | --- | --- | --- |
| `.delta` | `1_binaural_sleep_delta.m4a` | ~ 2 Hz | No |
| `.theta` | `2_binaural_meditation_theta.m4a` | 5–8 Hz | Yes |
| `.alpha` | `3_binaural_relax_alpha.m4a` | 8–12 Hz | Yes |
| `.beta` | `4_binaural_focus_beta.m4a` | 12–30 Hz | Yes |

Generated by [`scripts/generateBinauralSounds.py`](../../../scripts/generateBinauralSounds.py). Re-render only if you change the design — the output is committed. `BinauralTrack.beatFrequencyHz` stores one representative value per band for UI waveforms and should stay aligned with the table above.

## Adding a new channel — checklist

1. Encode the file via `convert_new_sounds.sh` (don't shortcut the pipeline).
2. Place the `.m4a` in the bundle path used by `SoundChannelMetadata.swift`.
3. Add a `SoundChannel` enum case in `Models/AppModels.swift` (lowercase French ID).
4. Add the metadata entry in `SoundChannelMetadata.swift`: file, location, author, licence, freesound URL, SF symbol, RGB tint.
5. Add `channel.<id>`, `channel.<id>.long`, `channel.<id>.location` keys in `Localizable.xcstrings` for all 6 locales (use `scripts/add_channel_translations.py`).
6. Bump the "35 sounds" claim — this number appears in fastlane metadata for 6 locales (subheads, descriptions), screenshots `01_hero` / `02_library` / `10_paywall`, and the premium paywall. Update [marketing/aso-strategy.md](../marketing/aso-strategy.md) and re-render screenshots.
7. Update this file (`content/sounds-catalog.md`) with the new row and bump `last_updated`.
8. Verify `PersistedMixerState` decoding still works with the new case (Codable enum is forgiving for extra cases at encode but old payloads simply omit the new channel — that's fine).
