---
title: Build and Test
status: stable
last_updated: 2026-05-17
tracks:
  - "ios-native/OasisNative.xcodeproj/**"
  - "ios-native/OasisNativeUITests/**"
  - "fastlane/Fastfile"
  - "scripts/**"
  - "Gemfile"
related:
  - "../operations/release-process.md"
  - "../operations/secrets-and-keys.md"
  - "../marketing/video-factory.md"
---

# Build and Test

## Build (CLI)

From repo root:

```bash
xcodebuild -scheme OasisNative -project "ios-native/OasisNative.xcodeproj" \
  -configuration Debug -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  build CODE_SIGNING_ALLOWED=NO
```

`CODE_SIGNING_ALLOWED=NO` lets the build pass without provisioning profiles.

## Schemes and configurations

- Scheme: `OasisNative` (single).
- Configurations: `Debug` (sets `Purchases.logLevel = .debug` in `OasisNativeApp`), `Release`.
- Target iOS: 16+ baseline; certain effects require iOS 26+ (the codebase guards them with `if #available`).

## UI tests

Located in `ios-native/OasisNativeUITests/`. Two suites:

### `OasisNativeScreenshots.swift` — fastlane snapshot scenarios

Ten scenarios driven by `setUpWithError` reading launch arguments. Each produces one `.png` per locale:

| Slug | What it captures |
| --- | --- |
| `01_hero` | Mix playing with active waveform, premium override. |
| `02_library` | Mixer scrolled to expose premium channel locks. |
| `03_detail_sheet` | `SoundDetailSheet` open on Savanna. |
| `04_binaural` | `BinauralPanel` with the four tracks. |
| `05_spatial` | `SpatialAudioPanel` sound-placement minimap. |
| `06_presets` | `PresetsPanel` with default + signature presets. |
| `07_timer` | Timer menu showing the 4 options. |
| `08_free_home` | Free-tier home (3 channels, locks visible). |
| `09_library_teaser` | Free-tier library showing locked premium card. |
| `10_paywall` | Full paywall. |

Launch arguments used by these tests:

- `-FASTLANE_SNAPSHOT YES` (set by fastlane)
- `-OASISResetState YES` (force known mix)
- `-OASISPremiumOverride premium` (or `free` for 08/09/10)

### `OasisNativePremiumFlowTests.swift` — premium gating

Flow tests that verify the upsell-then-paywall logic:

- `testLockedPresetShowsInlineUpsellBeforePaywall`
- `testLockedBinauralTrackKeepsPanelOpen`
- `testFreeShortTimerDoesNotShowPaywall`
- `testPremiumLongTimerShowsUnlockPanelBeforePaywall`

Presets and binaural entry points live in the bottom bar, so the tests target `home.bottom.presets` and `home.bottom.binaural` (not the older header identifiers). Fastlane snapshot runs the whole UI test target, so these must stay green before screenshots can complete cleanly.

Run from Xcode's Test navigator or `xcodebuild test`.

### `MarketingScenarioRunner.swift` — generic scenario player

One `testRunScenario` test that decodes a JSON scenario from `OASIS_SCENARIO_PATH` (or `/tmp/oasis-marketing/scenario.json`) and replays its action timeline against the live app. Consumed by the marketing video factory — see [../marketing/video-factory.md](../marketing/video-factory.md). Launches the app with `-ui_testing -OASISPremiumOverride <premium|free> -OASISResetState YES -AppleLanguages (<lang>) -AppleLocale <locale>`.

Not part of CI / fastlane lanes. Invoked exclusively by `marketing-video-factory/`.

## Fastlane lanes

From repo root, run `bundle exec fastlane <lane>`:

| Lane | Purpose |
| --- | --- |
| `screenshots` | Snapshot all 10 scenarios in 6 locales on iPhone 17 Pro Max. Output: `fastlane/screenshots/<locale>/iPhone 17 Pro Max-<slug>.png`. |
| `screenshots_only` | Skips the build step — useful when iterating on snapshot scenarios with the same binary. |
| `app_previews` | Build App Preview videos (Ruby pipeline). |
| `stage_appstore_assets` | Stage screenshots + previews into `fastlane/appstore-upload/<locale>/`. |
| `appstore_metadata` | Push metadata only, no binary. Fast iteration on text. |
| `appstore_release app_version:1.4.2` | Push screenshots + metadata for an existing binary version. |

The `Fastfile` autodetects the repo root by looking for `ios-native/OasisNative.xcodeproj` in 4 candidate paths.

App Store Connect username: `jonathanluquet@me.com` (in `Fastfile`). The password is prompted (or fastlane reads it from Keychain).

### Snapshot tuning

- Languages: `en-US, fr-FR, de-DE, es-ES, it, pt-BR`.
- Devices: iPhone 17 Pro Max.
- `clean: false` so the bundle is reused across locales (faster).
- `retries: 0` — fail fast.

## Helper scripts

All under `scripts/`. Purpose-specific, not part of the build pipeline.

| Script | When to run |
| --- | --- |
| `convert_new_sounds.sh` | When adding/replacing an ambient channel — encodes raw `.wav` to `.m4a` via the 2-pass loudnorm pipeline. See [../content/sounds-catalog.md](../content/sounds-catalog.md). |
| `generateBinauralSounds.py` | When changing the binaural design (rare). Produces the 4 m4a files. |
| `generate_store_screenshot_comps.swift` | When updating App Store screenshots — composites the 10 slides over their backgrounds and exports JPEGs at `1320×2868`. See [../marketing/store-assets.md](../marketing/store-assets.md). |
| `generate_app_previews.rb` | When updating App Preview videos. |
| `add_files_to_xcode.py` | When adding many files to the Xcode project at once (manual `.pbxproj` edits are error-prone). |
| `add_channel_translations.py` | When adding/replacing a channel — pre-fills or refreshes `channel.<id>.*` keys in `Localizable.xcstrings` for the current 20-channel catalog. |
| `createFastlaneCountriesFolders.js` | Bootstrap a new locale's metadata folder structure. |
| `generateFastlaneTxtFiles.js` | Mirror the canonical `fastlane/metadata/<locale>/*.txt` files into the script metadata output path. |

## Marketing video factory

Subproject at `marketing-video-factory/` generates TikTok/Reels/Shorts videos by scripting the live app inside a simulator. End-to-end flow, scenario format, and the `MarketingScenarioRunner` test integration are documented in [../marketing/video-factory.md](../marketing/video-factory.md).

Run from inside the subproject:

```bash
cd marketing-video-factory
npm install
npm run sync                                    # symlink Oasis audio aliases
npm run record -- --scenario sleep-rain-demo
```

## Drift check

Memory consistency check against the source code:

```bash
bash scripts/ai-memory/check-drift.sh
```

See [../meta/drift-check.md](../meta/drift-check.md).
