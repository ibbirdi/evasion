---
title: Build and Test
status: stable
last_updated: 2026-05-26
tracks:
  - "ios-native/OasisNative.xcodeproj/**"
  - "ios-native/OasisNativeUITests/**"
  - "fastlane/Fastfile"
  - "scripts/**"
  - "marketing-outreach/package.json"
  - "marketing-outreach/src/**"
  - "Gemfile"
related:
  - "../operations/release-process.md"
  - "../operations/secrets-and-keys.md"
  - "../marketing/video-factory.md"
  - "../marketing/community-radar.md"
  - "../marketing/outreach-crm.md"
---

# Build and Test

## Build (CLI)

From repo root:

### iOS simulator

```bash
xcodebuild -scheme OasisNative -project "ios-native/OasisNative.xcodeproj" \
  -configuration Debug -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  build CODE_SIGNING_ALLOWED=NO
```

### macOS

```bash
xcodebuild -scheme OasisMac -project "ios-native/OasisNative.xcodeproj" \
  -configuration Debug -destination "platform=macOS" \
  build CODE_SIGNING_ALLOWED=NO
```

For a release-shaped compile check:

```bash
xcodebuild -scheme OasisMac -project "ios-native/OasisNative.xcodeproj" \
  -configuration Release -destination "generic/platform=macOS" \
  build CODE_SIGNING_ALLOWED=NO
```

`CODE_SIGNING_ALLOWED=NO` lets the build pass without provisioning profiles.

## Schemes and configurations

- Schemes: `OasisNative` (iOS) and `OasisMac` (macOS menu bar app).
- Configurations: `Debug` and `Release`. Debug keeps RevenueCat at `.error` by default so dashboard health warnings do not look like app failures in Xcode; add `-OASISRevenueCatDebugLogs` (or env `OASIS_REVENUECAT_DEBUG_LOGS=1`) when actively debugging purchases.
- Target iOS: 17+ baseline; certain effects require iOS 26+ (the codebase guards them with `if #available`). The iOS app uses Swift Observation, so iOS 16 would require replacing `@Observable`/`@Bindable` across the shared model layer.
- Target macOS: 15+ baseline, accessory menu bar app (`LSUIElement`) with an `NSStatusItem` opening a custom borderless mixer `NSPanel`. The target includes shared UI helpers such as `HapticSlider`, `SoundDetailSheet`, and `SoundLocationMinimap` so the menu bar mixer can reuse the iOS auto-volume range slider, detail sheet, and Apple Maps minimap.
- macOS local Run scheme: `OasisMac.xcscheme` passes `-OASISPremiumOverride premium` in Debug so normal Xcode launches do not start RevenueCat without a Mac App Store receipt. Switch that launch argument to `revenueCat` only when actively testing StoreKit / RevenueCat purchase flows.
- macOS signing: `OasisMac` uses `Mac/OasisMac.entitlements` with App Sandbox enabled and outbound network access for RevenueCat / StoreKit-backed purchase flows. Keep the entitlement set minimal; add new permissions only for features that genuinely require them.
- macOS metadata: `Mac/Info.plist` sets `LSApplicationCategoryType = public.app-category.healthcare-fitness` to match the App Store category and keep archives warning-free.

In Xcode, build the macOS app with the `OasisMac` scheme and `My Mac` destination. The `OasisNative` scheme is iOS-only; it must not list `macosx` in `SUPPORTED_PLATFORMS`, otherwise Xcode can try to compile UIKit views with the macOS SDK.

## UI tests

Located in `ios-native/OasisNativeUITests/`. Two suites:

### `OasisNativeScreenshots.swift` — fastlane snapshot scenarios

Ten scenarios driven by `setUpWithError` reading launch arguments. Each produces one `.png` per locale:

| Slug | What it captures |
| --- | --- |
| `01_hero` | Mix playing with active header logo and playback aura, premium override. |
| `02_library` | Mixer scrolled to expose premium channel locks. |
| `03_detail_sheet` | `SoundDetailSheet` open on Savanna. |
| `04_binaural` | `BinauralPanel` with the four tracks. |
| `05_spatial` | `SpatialAudioPanel` sound-placement minimap. |
| `06_presets` | `PresetsPanel` with default + signature presets. |
| `07_timer` | Timer menu showing the 4 options. |
| `08_free_home` | Free-tier home (3 channels, locks visible). |
| `09_library_teaser` | Free-tier library showing locked premium card. |
| `10_paywall` | Full paywall. |

The screenshot lane is filtered to `OasisNativeUITests/OasisNativeScreenshots/testAppStoreScreenshots` so it does not run premium-flow tests or the social-video `MarketingScenarioRunner`.

The App Store screenshot suite also writes real simulator element crops into `fastlane/screenshots/<locale>/extracted-assets/` for the v4 compositor. `SnapshotHelper` deletes and recreates that folder at screenshot setup so stale assets cannot survive between runs. `SnapshotHelper.snapshotElement` crops `XCUIScreen.main.screenshot().image` using the visible `XCUIElement` frame plus a small element-specific padding, then writes both a PNG and JSON metadata (`elementFramePoints`, padded `visibleFramePoints`, `paddingPoints`, screen size, and image pixel size). These extracted assets are captured from the same live scenarios as the raw screenshots, not from a separate mock view. Current approved pop-out crops include active rows for Forest, River, Rain, Birds, and Beach; one full `binaural.track.grid` crop; the detail map; spatial stage; preset rows; library teaser; and paywall CTA.

Launch arguments used by these tests:

- `-FASTLANE_SNAPSHOT YES` (set by fastlane)
- `-OASISResetState YES` (force known mix)
- `-OASISPremiumOverride premium` (or `free` for 08/09/10)
- `-OASISImmersiveAudioEnabled YES` (force the global immersive sound toggle on for every App Store screenshot)

Fastlane `launch_arguments` must stay as one combined string in the lane / `Snapfile` (for example `"-OASISResetState YES -OASISImmersiveAudioEnabled YES"`). Snapshot treats each array element as a separate launch-argument set; splitting these flags into two strings doubles the full locale pass.

Manual onboarding checks can add `-OASISResetOnboarding` to clear only the first-launch flag. Do not use it in screenshot lanes; those intentionally bypass onboarding via screenshot automation.

### `OasisNativePremiumFlowTests.swift` — premium gating

Flow tests that verify the upsell-then-paywall logic:

- `testLockedPresetShowsInlineUpsellBeforePaywall`
- `testLockedBinauralTrackKeepsPanelOpen`
- `testFreeShortTimerDoesNotShowPaywall`
- `testPremiumLongTimerShowsUnlockPanelBeforePaywall`

Presets and binaural entry points live in the bottom bar, so the tests target `home.bottom.presets` and `home.bottom.binaural` (not the older header identifiers). Run these manually or in Xcode when touching premium gating; the App Store screenshot lane intentionally filters them out.

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
| `app_previews` | Build local App Preview videos (Ruby pipeline); currently not staged for App Store upload. |
| `mac_screenshots` | Build `OasisMac` and capture 5 localized menu bar panel scenarios into `fastlane/screenshots-macos/<locale>/`. |
| `mac_appstore_assets` | Render upload-ready `2880×1800` macOS App Store screenshots from the raw panel captures into `fastlane/appstore-upload-macos/<locale>/`. |
| `mac_appstore_screenshots` | Full macOS visual pipeline: capture raw panel screenshots, then render upload-ready App Store assets. |
| `mac_appstore_release app_version:1.0.0` | Upload macOS screenshots + metadata for an existing macOS binary version. Uses `platform: "osx"` and does not upload a binary. |
| `stage_appstore_assets` | Stage screenshots into `fastlane/appstore-upload/<locale>/`; screenshots are renamed to the Variant B display order and App Preview videos are intentionally excluded. |
| `appstore_metadata` | Push metadata only, no binary. Fast iteration on text. |
| `build_and_upload ipa_name:OasisNative-1.5.1-b7.ipa` | Archive/export the iOS App Store IPA and upload it to TestFlight/App Store Connect without automatic submission. |
| `appstore_release app_version:1.5.1` | Push screenshots + metadata for an existing binary version. |

The `Fastfile` autodetects the repo root by looking for `ios-native/OasisNative.xcodeproj` in 4 candidate paths.

App Store Connect username: `jonathanluquet@me.com` (in `Fastfile`). The password is prompted (or fastlane reads it from Keychain).

### Snapshot tuning

- Languages: `en-US, fr-FR, de-DE, es-ES, it, pt-BR`.
- Devices: iPhone 17 Pro Max.
- `clean: false` so the bundle is reused across locales (faster).
- `retries: 0` — fail fast.
- During visual iteration, run only the French validation pass with `SCREENSHOT_LANGUAGES=fr-FR OASIS_SCREENSHOT_PARTIAL=1 bundle exec fastlane screenshots`, then render with `swift scripts/generate_store_screenshot_comps.swift --lang fr-FR`. Wait for design approval before running every locale.

## Helper scripts

All under `scripts/`. Purpose-specific, not part of the build pipeline.

| Script | When to run |
| --- | --- |
| `convert_new_sounds.sh` | When adding/replacing an ambient channel — encodes raw `.wav` to `.m4a` via the 2-pass loudnorm pipeline. See [../content/sounds-catalog.md](../content/sounds-catalog.md). |
| `generateBinauralSounds.py` | When changing the binaural design (rare). Produces the 4 m4a files. |
| `generate_store_screenshot_comps.swift` | When updating App Store screenshots — renders the canonical v4 dynamic scenes from raw captures and exports JPEGs at `1320×2868`; `--classic` writes the old v3 fallback into `figma-pro-classic/`. See [../marketing/store-assets.md](../marketing/store-assets.md). |
| `capture_macos_screenshots.rb` | When updating macOS App Store screenshots — builds `OasisMac`, opens the menu bar panel in deterministic screenshot mode, and captures 5 scenarios × 6 locales. |
| `generate_mac_store_screenshot_comps.swift` | Composites real macOS panel captures into `2880×1800` Mac App Store screenshots and stages them separately from iOS assets. |
| `mac_screenshot_content.json` | Source data for macOS screenshot copy, slide ordering, source capture mapping, and accent colours. |
| `generate_app_previews.rb` | When updating App Preview videos; outputs silent videos with a required stereo AAC track for App Store Connect. |
| `add_files_to_xcode.py` | When adding many files to the Xcode project at once (manual `.pbxproj` edits are error-prone). |
| `add_channel_translations.py` | When adding/replacing a channel — pre-fills or refreshes `channel.<id>.*` keys in `Localizable.xcstrings` for the current 35-channel catalog. |
| `createFastlaneCountriesFolders.js` | Bootstrap a new locale's metadata folder structure. |
| `generateFastlaneTxtFiles.js` | Mirror the canonical `fastlane/metadata/<locale>/*.txt` files into the script metadata output path. |
| `community-radar/community-radar.mjs` | Daily Reddit / HN / forum acquisition radar. Outputs a manual-review digest only; it never posts. |
| `acquisition/check-release-readiness.mjs` | Before retrying App Store upload — checks the iOS version/build, latest archive, local distribution signing identity, and last Fastlane archive log. |

## Community radar

Organic acquisition helper at `scripts/community-radar/`:

```bash
node scripts/community-radar/community-radar.mjs --out /tmp/oasis-community-radar.md
```

Use `--sources reddit`, `--sources hn`, or `--sources manual` to isolate a channel. The script has no package dependencies and can be syntax-checked with:

```bash
node --check scripts/community-radar/community-radar.mjs
```

Strategy, guardrails, and measurement are documented in [../marketing/community-radar.md](../marketing/community-radar.md).

## Marketing video factory

Subproject at `marketing-video-factory/` generates TikTok/Reels/Shorts videos by scripting the live app inside a simulator. End-to-end flow, scenario format, and the `MarketingScenarioRunner` test integration are documented in [../marketing/video-factory.md](../marketing/video-factory.md).

Run from inside the subproject:

```bash
cd marketing-video-factory
npm install
npm run sync                                    # symlink Oasis audio aliases
npm run record -- --scenario sleep-rain-demo
```

## Marketing outreach CRM

Subproject at `marketing-outreach/` manages human-reviewed Premium promo-code outreach. It is a local TypeScript CLI and never sends messages automatically.

Run from inside the subproject:

```bash
cd marketing-outreach
npm install
npm run typecheck
npm run outreach:validate
npm run outreach:score
npm run outreach:plan -- --limit 20 --lang fr
```

Full workflow and compliance guardrails are documented in [../marketing/outreach-crm.md](../marketing/outreach-crm.md).

## Drift check

Memory consistency check against the source code:

```bash
bash scripts/ai-memory/check-drift.sh
```

See [../meta/drift-check.md](../meta/drift-check.md).
