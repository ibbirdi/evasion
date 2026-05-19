---
title: Repo Structure
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/**"
  - "scripts/**"
  - "fastlane/**"
  - "marketing-video-factory/**"
related:
  - "conventions.md"
  - "build-and-test.md"
  - "../marketing/video-factory.md"
---

# Repo Structure

Map of where things live and what each directory is responsible for.

## Top-level

```
/
├── AGENTS.md                        Universal AI entrypoint (start here)
├── README.md                        Short pitch + pointer to AGENTS.md
├── docs/ai/                         AI memory (you are here)
├── ios-native/                      The Xcode project — primary code
├── fastlane/                        Release automation, metadata, screenshots
├── marketing-video-factory/         Scenario-driven social-video generator — see ../marketing/video-factory.md
├── scripts/                         Helper scripts (audio encoding, asset gen, etc.)
│   └── ai-memory/                   Memory drift-check tooling
├── .githooks/                       Git pre-commit hook (opt-in via `git config core.hooksPath`)
├── .claude/                         Claude Code settings (committed: hooks; user-local: permissions)
├── .gitignore
├── .env                             Local env (gitignored content; file presence committed)
├── Gemfile / Gemfile.lock           Ruby deps for fastlane
└── (no other top-level documentation — everything in docs/ai/)
```

## `ios-native/` — the app

```
ios-native/
├── OasisNative.xcodeproj/           Xcode project (single scheme: OasisNative)
├── OasisNative/                     App source
│   ├── OasisNativeApp.swift         @main entry
│   ├── Models/                      Plain data types
│   ├── Services/                    State, audio engine, premium logic
│   ├── Views/                       SwiftUI screens, components, overlays
│   ├── Support/                     Configuration, L10n keys, Info.plist, shader, helpers
│   ├── Resources/                   Audio (.m4a), Images, Localizable.xcstrings
│   └── Assets.xcassets/             App icon
├── OasisNativeUITests/              UI tests (screenshots + premium flow + marketing scenarios)
└── scripts/                         iOS-specific scripts (probably empty/legacy)
```

`OasisNativeUITests/` contains three Swift suites: `OasisNativeScreenshots` (App Store snapshots, see [../marketing/store-assets.md](../marketing/store-assets.md)), `OasisNativePremiumFlowTests` (paywall gating), and `MarketingScenarioRunner` (generic scenario player consumed by the marketing video factory — see [../marketing/video-factory.md](../marketing/video-factory.md)).

### `Models/`

Plain Codable types. No business logic, no AVFoundation imports.

| File | Contains |
| --- | --- |
| `AppModels.swift` | `SoundChannel` (35 cases), `BinauralTrack` (4 cases), `ChannelState`, `AutoVariationRange`, `Preset`, `SpatialPoint`, `PersistedMixerState`. |
| `SoundChannelMetadata.swift` | Per-channel metadata: file name, category, location, author, licence, SF Symbol, RGB tint. The single source of truth for the catalog. |
| `PremiumModels.swift` | `PremiumEntryPoint`, `PremiumPaywallContext`, `PremiumInlineUpsellContext`. |

### `Services/`

Business logic, engines, integrations.

| File | Contains |
| --- | --- |
| `AppModel.swift` | The hub. See [../architecture/state.md](../architecture/state.md). |
| `AudioMixerEngine.swift` | Ambient audio engine. See [../architecture/audio-engine.md](../architecture/audio-engine.md). |
| `GentleReminderScheduler.swift` | Local notification scheduler for the gentle re-open reminder after several inactive days. |
| `PremiumCoordinator.swift` | Routes premium requests (inline vs paywall). |
| `PremiumRevenueCatService.swift` | RevenueCat purchase / restore wrapper. |
| `RevenueCatObserver.swift` | Listens to RevenueCat customer info changes. |
| `PremiumAnalytics.swift` | In-app premium funnel events. |
| `TelemetryDeckAnalyticsSink.swift` | Analytics sink to TelemetryDeck (when configured). |

### `Views/`

```
Views/
├── HomeView.swift                   Main mixer board screen
├── RootView.swift                   Root: onboarding gate, paywall presentation
├── Components/                      Reusable building blocks (see ../architecture/ui.md)
├── Overlays/                        Modal panels: Presets, Binaural, Spatial, Paywall, SoundDetailSheet
└── Onboarding/                      First-launch flow
```

### `Support/`

| File | Contains |
| --- | --- |
| `AppConfiguration.swift` | Build flags, env / Info.plist readers, dev overrides. |
| `Info.plist` | App identity, RevenueCat keys, background modes, UI style. |
| `L10n.swift` | `LocalizedStringResource` keys for all UI strings. |
| `LiquidAuraShaders.metal` | Metal shader for the animated liquid aura. |
| `RoutePickerView.swift` | UIKit bridge for AirPlay / Bluetooth route picker. |

### `Resources/`

| Path | Contains |
| --- | --- |
| `Audio/*.m4a` | All ambient sounds (`oiseaux1.m4a`, `vent1.m4a`, …) and the four binaural tracks (`1_binaural_sleep_delta.m4a`, …). |
| `Images/` | Bundle images. |
| `Localizable.xcstrings` | Translations for all 6 locales (Xcode 15+ string catalog). |

### `Assets.xcassets/`

App icon. In-bundle UI images live under `Resources/Images/`.

## `fastlane/`

```
fastlane/
├── Fastfile                         Lane definitions
├── Appfile                          App identifier
├── Snapfile                         snapshot config
├── metadata/<locale>/               App Store metadata per locale (name, subtitle, keywords, description, …)
├── screenshots/<locale>/            Captured + finalised screenshots
│   └── figma-pro/                   Final composited screenshots + preview JPEGs
├── app-previews/<locale>/           Generated App Preview MP4s
├── appstore-upload/                 Staging dir for upload flow
└── buildlogs/                       Build logs (ignored / cleaned regularly)
```

Locales: `en-US`, `fr-FR`, `de-DE`, `es-ES`, `it`, `pt-BR`. See [../content/localization.md](../content/localization.md).

## `scripts/`

| Script | Purpose |
| --- | --- |
| `convert_new_sounds.sh` | Encode raw `.wav` → `.m4a` per the loudnorm pipeline. |
| `generateBinauralSounds.py` | Pre-render the 4 binaural tracks. |
| `generate_app_previews.rb` | Build App Preview videos from screenshots. |
| `generate_store_screenshot_comps.swift` | Composite the 60 final App Store screenshots. |
| `add_files_to_xcode.py` | Add files to the Xcode project programmatically. |
| `add_channel_translations.py` | Add channel L10n keys when introducing a sound. |
| `createFastlaneCountriesFolders.js` | Bootstrap fastlane metadata directory structure. |
| `generateFastlaneTxtFiles.js` | Mirror canonical App Store metadata text files from `fastlane/metadata/`. |
| `screenshot_content.json` | Source data for screenshot copy / structure. |
| `assets/` | Static assets used by the scripts above. |
| `ai-memory/` | Memory drift detection tooling — see [../meta/drift-check.md](../meta/drift-check.md). |

## Where to put new files

| You're adding… | Put it in… |
| --- | --- |
| A new sound channel data point | `ios-native/OasisNative/Models/SoundChannelMetadata.swift` |
| A new screen | `ios-native/OasisNative/Views/<NewView>.swift` |
| A reusable button / glass surface | `ios-native/OasisNative/Views/Components/` |
| A modal sheet | `ios-native/OasisNative/Views/Overlays/` |
| A new service / integration | `ios-native/OasisNative/Services/` |
| A new build helper | `scripts/` |
| A new fastlane lane | `fastlane/Fastfile` |
| A new social-video scenario | `marketing-video-factory/scenarios/<id>.json` — see [../marketing/video-factory.md](../marketing/video-factory.md) |
| New AI memory | `docs/ai/<section>/` and update [../README.md](../README.md) |
