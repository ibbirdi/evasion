---
title: Sounds Catalog
status: stable
last_updated: 2026-05-18
tracks:
  - "ios-native/OasisNative/Models/SoundChannelMetadata.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Resources/Audio/*.m4a"
  - "scripts/convert_new_sounds.sh"
  - "scripts/generateBinauralSounds.py"
related:
  - "../architecture/audio-engine.md"
  - "../architecture/binaural.md"
  - "../operations/known-issues.md"
---

# Sounds Catalog

The 20 ambient channels and 4 binaural tracks. The single source of truth for runtime metadata is [`SoundChannelMetadata.swift`](../../../ios-native/OasisNative/Models/SoundChannelMetadata.swift); this file documents the *why* (encoding pipeline, sourcing, licence obligations) and provides a reading-friendly index.

## 20 ambient channels

| # | ID | Display | File | Location | Author | Licence | Tonal group | SF Symbol |
|---|---|---|---|---|---|---|---|---|
| 1 | `oiseaux` | Birds | `oiseaux1.m4a` | Nivillac, Morbihan, FR | bruno.auzet | CC0 | D3 (146.83 Hz) | `bird.fill` |
| 2 | `vent` | Wind | `vent1.m4a` | Perpignan, Occitanie, FR | Sadiquecat | CC0 | D3 | `wind` |
| 3 | `plage` | Shore | `plage1.m4a` | Shetland Islands, GB | straget | **CC-BY-4.0** | B2 (123.47 Hz) | `water.waves` |
| 4 | `goelands` | Seagulls | `goelants1.m4a` *(file mismatch — see known-issues)* | Brittany harbour, FR | Further_Roman | CC0 | B2 | `bird` |
| 5 | `foret` | Forest | `foret1.m4a` | Kampina, North Brabant, NL | klankbeeld | **CC-BY-4.0** | D3 | `tree.fill` |
| 6 | `pluie` | Rain | `pluie1.m4a` | Voghera, Pavia, IT | Stagno | **CC-BY-4.0** | C3 minor (130.81 Hz) | `cloud.rain.fill` |
| 7 | `tonnerre` | Thunder | `orage1.m4a` *(file mismatch)* | Azillanet, Hérault, FR | felix.blume | CC0 | C3 minor | `cloud.bolt.fill` |
| 8 | `cigales` | Cicadas | `cigales1.m4a` | Lampedusa, Sicily, IT | pablodavilla | CC0 | G3 sus4 (196 Hz) | `ladybug.fill` |
| 9 | `grillons` | Crickets | `grillons1.m4a` | Theneuille, Allier, FR | keng-wai-chane-chick-te | CC0 | G3 sus4 | `moon.stars` |
| 10 | `tente` | Tent | `tente1.m4a` | Bornholm island, DK | Petrosilia | CC0 | A2 neutral (110 Hz) | `tent.fill` |
| 11 | `riviere` | River | `riviere1.m4a` | Fuxing, Taoyuan, TW | calebjay | **CC-BY-4.0** | C3 open | `drop.fill` |
| 12 | `village` | Village | `ville1.m4a` *(file mismatch)* | Liuzhou, Guangxi, CN | lastraindrop | CC0 | A2 neutral | `house.fill` |
| 13 | `mer` | Sea | `mer1.m4a` | Epitalio, Western Greece, GR | yiorgis | CC0 | B2 | `water.waves` |
| 14 | `orageMontagne` | Mountain storm | `orageMontagne1.m4a` | Tremosine sul Garda, Brescia, IT | bruno.auzet | CC0 | C3 minor | `cloud.bolt.fill` |
| 15 | `campfire` | Campfire | `campfire1.m4a` | St. Marys River, Michigan, US | Ambient-X | **CC-BY-4.0** | A2 major | `flame.fill` |
| 16 | `cafe` | Café | `cafe1.m4a` | São Paulo, BR | felix.blume | CC0 | A2 neutral | `cup.and.saucer.fill` |
| 17 | `lac` | Lake | `lac1.m4a` | Fritton Lake, Norfolk, GB | Yarmonics (Martin Scaiff) | CC0 | C3 open | `sailboat.fill` |
| 18 | `savane` | Savanna | `savane1.m4a` | KwaZulu-Natal, ZA | eardeer | CC0 | D3 | `sun.max.fill` |
| 19 | `jungleAmerique` | Tropical jungle | `jungleamerique1.m4a` | Los Tuxtlas, Veracruz, MX | Globofonia | **CC-BY-4.0** | D3 | `leaf.fill` |
| 20 | `jungleAsie` | Asian jungle | `jungleasie1.m4a` | Chiang Mai, TH | Anantich | **CC-BY-4.0** | D3 | `cloud.fog.fill` |

**Free tier**: `oiseaux`, `vent`, `plage` (channels 1–3). Everything else is premium.

**File-mismatch entries** (channel IDs differ from file names): `goelands`/`goelants1.m4a`, `tonnerre`/`orage1.m4a`, `village`/`ville1.m4a`. These are historical and **not** to be "fixed" — see [../operations/known-issues.md](../operations/known-issues.md).

## Licences and attribution

7 channels are **CC-BY-4.0** and require visible attribution: `plage`, `foret`, `pluie`, `riviere`, `campfire`, `jungleAmerique`, `jungleAsie`. Attribution is rendered by `SoundDetailSheet` from the `ChannelCredit` struct in `SoundChannelMetadata.swift`, showing the author, licence, and `freesound.org` source site inline. Removing or breaking that visible credit surface = licence violation. Re-check before any UI refactor of the detail sheet.

The remaining 13 channels are CC0 (no attribution required); we still display the author as a courtesy.

## Encoding pipeline

All ambient `.m4a` files are produced by [`scripts/convert_new_sounds.sh`](../../../scripts/convert_new_sounds.sh) with this exact ffmpeg pipeline:

1. **Optional truncation**: if source > 45 min, cut to 45:00 with offset `+30s` (avoids the slate at the start). Currently affects `foret` (source 48:18) and `mer` (source 47:33).
2. **Two-pass `loudnorm`** (EBU R128 / ITU-R BS.1770):
   ```
   I=-20 LUFS, TP=-1.5 dBTP, LRA=11 LU, linear=true
   ```
   `linear=true` applies a single global gain instead of compressing dynamics — preserves naturalness.
3. **Brick-wall limiter**: `alimiter=limit=0.71:level=false` (~ -3 dBFS sample peak; `level=false` disables makeup gain so the limiter is purely defensive against intersample peaks).
4. **Encoder**: AAC-LC, 96 kbps, stereo, 44.1 kHz. Container `.m4a` with `+faststart`.

### Why these choices (don't change without testing)

- **AAC-LC, not HE-AAC**: HE-AAC's spectral band replication invents high-frequency content, which sounds metallic on aperiodic ambient (raindrops, birds, wind). For wellness ambient, LC is transparent at 96 kbps and HE introduces audible artifacts.
- **96 kbps**: sweet spot. 64 kbps loses subtle stereo air; 128 kbps is wasted bytes given the bundle weight.
- **44.1 kHz**: sane default. Devices resample regardless; staying at 44.1 avoids one resample step.
- **-20 LUFS** (vs streaming standards -14/-16): we're a sleep / focus app, not Spotify. Quieter target preserves dynamics, leaves headroom for layering, and avoids loudness fatigue. Don't push.
- **TP -1.5 dBTP + alimiter 0.71**: belt + braces. AAC sometimes overshoots true peak; the limiter keeps every file safe under intersample peak.
- **2-pass linear loudnorm**: 2-pass is required for accurate target in a single normalisation step; `linear=true` is the only mode that preserves dynamics.

## Bundle weight

- ~310 MB for all 20 ambient + 4 binaural files.
- New ambient channels add ~10–17 MB depending on length and complexity (see measured per-file sizes in commit history).
- Watch the IPA size before shipping additions. App Store has a 4 GB cellular download limit, but user perception of "this app is huge" matters earlier.

## 4 binaural tracks

| Case | File | Frequency | Premium |
| --- | --- | --- | --- |
| `.delta` | `1_binaural_sleep_delta.m4a` | ~ 2 Hz | No |
| `.theta` | `2_binaural_meditation_theta.m4a` | 5–8 Hz | Yes |
| `.alpha` | `3_binaural_relax_alpha.m4a` | 8–12 Hz | Yes |
| `.beta` | `4_binaural_focus_beta.m4a` | 12–30 Hz | Yes |

Generated by [`scripts/generateBinauralSounds.py`](../../../scripts/generateBinauralSounds.py). Re-render only if you change the design — the output is committed.

## Adding a new channel — checklist

1. Encode the file via `convert_new_sounds.sh` (don't shortcut the pipeline).
2. Place the `.m4a` in the bundle path used by `SoundChannelMetadata.swift`.
3. Add a `SoundChannel` enum case in `Models/AppModels.swift` (lowercase French ID).
4. Add the metadata entry in `SoundChannelMetadata.swift`: file, location, author, licence, freesound URL, tonal group, SF symbol, RGB tint.
5. Add `channel.<id>`, `channel.<id>.long`, `channel.<id>.location` keys in `Localizable.xcstrings` for all 6 locales (use `scripts/add_channel_translations.py`).
6. Bump the "20 sounds" claim — this number appears in fastlane metadata for 6 locales (subheads, descriptions) and in screenshots `02_library`, `09_library_teaser`. Update [marketing/aso-strategy.md](../marketing/aso-strategy.md) and re-render screenshots.
7. Update this file (`content/sounds-catalog.md`) with the new row and bump `last_updated`.
8. Verify `PersistedMixerState` decoding still works with the new case (Codable enum is forgiving for extra cases at encode but old payloads simply omit the new channel — that's fine).
