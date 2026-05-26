---
title: App Store Assets
status: stable
last_updated: 2026-05-26
tracks:
  - "fastlane/Fastfile"
  - "fastlane/Snapfile"
  - "fastlane/screenshots/**"
  - "scripts/generate_store_screenshot_comps.swift"
  - "scripts/generate_mac_store_screenshot_comps.swift"
  - "scripts/capture_macos_screenshots.rb"
  - "scripts/screenshot_content.json"
  - "scripts/mac_screenshot_content.json"
  - "ios-native/OasisNativeUITests/OasisNativeScreenshots.swift"
  - "ios-native/OasisNative/Mac/**"
  - "ios-native/OasisNative/Views/Mac/**"
related:
  - "aso-strategy.md"
  - "positioning.md"
  - "video-factory.md"
  - "../codebase/build-and-test.md"
---

> **Scope.** This page covers the **10 static iOS App Store screenshots** captured by `OasisNativeScreenshots.swift` and composited via `scripts/generate_store_screenshot_comps.swift`, plus the **5 static macOS App Store screenshots** captured from the real `OasisMac` menu bar panel and composited via `scripts/generate_mac_store_screenshot_comps.swift`. For **social-marketing videos** (TikTok / Reels / Shorts) driven by a sibling XCUITest (`MarketingScenarioRunner.swift`), see [video-factory.md](video-factory.md).

# App Store Assets

Specs and copy for the 60 App Store screenshots (10 slides × 6 locales). App Preview videos are local-only for now and are not uploaded for version `1.5.1`.

> **Important:** two design briefs existed historically — a Cowork brief (v2) and a design-handoff brief (v3). They diverged on multiple dimensions (font, device width, palette, JPEG quality). **The v4 dynamic-scene compositor is canonical for iOS App Store screenshots.** The v3 renderer is retained as a `--classic` fallback only.

## Canvas (non-negotiable)

- Dimensions: **1320 × 2868 px** (iPhone 17 Pro Max App Store size).
- Color: sRGB, no alpha.
- Format: JPEG, quality **0.92**, target ≤ 2 MB.
- Raw capture path: `fastlane/screenshots/<locale>/iPhone 17 Pro Max-<slug>.png`.
- Composite path: `fastlane/screenshots/<locale>/figma-pro/<slug>.jpg`.
- Upload staging path: `fastlane/appstore-upload/<locale>/<slug>.jpg`, produced by `bundle exec fastlane stage_appstore_assets`.

## macOS asset track

Apple requires Mac screenshots for the macOS platform. Accepted Mac sizes are 16:10: `1280 × 800`, `1440 × 900`, `2560 × 1600`, or `2880 × 1800`; Oasis uses `2880 × 1800` masters. App Store Connect accepts 1–10 screenshots per locale, and Mac app previews are optional but landscape-only.

Mac screenshots sell the native menu bar experience and never reuse iPhone mockups. The current set is:

```
01_menu_bar_mixer     02_sound_detail        03_auto_range
04_saved_ambiences    05_binaural_timer
```

Raw captures come from the actual `OasisMac` panel in deterministic screenshot mode: the app opens the system-rendered template status item panel automatically, seeds premium/active sounds, forces immersive audio on, pauses continuous mesh/logo animations, and applies a fixed scenario. The visible panel uses the same popover-style top arrow as native system route panels and points it at the status item. The visible header includes the compact antialiased counter-rotating OASIS ring logo at the shared 1.2 lockup scale, playback, timer, shuffle, AirPlay route picker, and quit controls. Detail screenshots use the in-panel macOS `SoundDetailSheet` overlay, not an AppKit sheet window.

The macOS copy mirrors the iOS App Store screenshots while selling the native menu bar panel: lead with `35 sounds`, `mixing`, and `escape into real nature`; use detail, saved mixes, and binaural/timer slides as proof points rather than mechanical feature explanations. The bottom-left copy block is text-only: no icon or capsule before the eyebrow.

- Raw capture path: `fastlane/screenshots-macos/<locale>/<slug>.png`.
- Composite path: `fastlane/screenshots-macos/<locale>/appstore/<index>_<slug>.jpg`.
- Upload staging path: `fastlane/appstore-upload-macos/<locale>/<index>_<slug>.jpg`.
- Preview path for review: `fastlane/screenshots-macos/<locale>/appstore/preview/<index>_<slug>.jpg` at `1440 × 900`.

The macOS compositor uses a very large text scale for App Store thumbnail legibility: eyebrow `50 pt`, adaptive subhead `66 → 48 pt`, and oversized adaptive heavy headlines. Keep this larger than the in-app panel typography.

Run the full macOS visual pipeline with `bundle exec fastlane mac_appstore_screenshots`, or split it into `mac_screenshots` and `mac_appstore_assets` while iterating. The Ruby capture script builds `OasisMac`, launches it once per locale/scenario with `-OASISMacScreenshot`, asks the app to render its own visible panel PNG via `-OASISMacScreenshotOutput`, and terminates the app between captures. This avoids relying on macOS Screen Recording permission while still using the real SwiftUI menu bar panel.

Upload the prepared macOS screenshots and shared metadata to App Store Connect with `bundle exec fastlane mac_appstore_release app_version:1.0.0`. This lane targets App Store Connect platform `osx`, validates that all 30 staged Mac screenshots exist, and skips binary upload because the macOS `.pkg` is uploaded separately.

## The 10 slugs

Exact file names (do not rename — they're indexed by `Fastfile` and the rendering script):

```
01_hero               02_library            03_detail_sheet       04_binaural
05_spatial            06_presets            07_timer              08_free_home
09_library_teaser     10_paywall
```

Recommended ordering on the App Store (Variant B, multi-use lead — see [aso-strategy.md](aso-strategy.md)):

```
01 → 02 → 07 → 05 → 08 → 03 → 04 → 06 → 09 → 10
```

The slug is *what the slide depicts*. The position is *where it appears in the carousel*.

`fastlane stage_appstore_assets` copies source composites into `fastlane/appstore-upload/<locale>/` and renames them to this display order, so App Store Connect receives alphabetically sorted files in the intended carousel sequence.

## Type system (v4)

| Element | Specs |
| --- | --- |
| Headline | **SF Pro Condensed Black** via the system font API, adaptive 148 → 84 pt, line-height 0.90, LS 0. Usually left-aligned in a top editorial block. Manual headline line breaks are avoided unless a locale truly needs them; the renderer checks total height and unbreakable word width before choosing a size. |
| Subhead | Avenir Next Medium 66 pt, LH 0.96, LS 0, 76 % opacity. Usually left-aligned below the headline. |
| Eyebrow | Avenir Next Demi Bold 48 pt UPPERCASE, tracking +4.2 pt, accent color. Current screenshots use an eyebrow on every slide. |

> The canonical iOS App Store compositor uses **SF Pro Condensed** for headlines and **Avenir Next** for eyebrow/subhead support text. Do not use SF Rounded for App Store assets.

## Color system (v4)

Per-slide scene mood, background style, and accent color live in [`scripts/screenshot_content.json`](../../../scripts/screenshot_content.json), not in a duplicated Swift table. The v4 scene renderer uses mood palettes:

- `aurora`, `lagoon`, `violet`, `copper` for dark premium / immersive slides.
- `mist`, `dawn`, `graphite` for light editorial slides.

The v3/classic fallback background styles are still supported:

- `studioGradient`, `sageMist`, `spatialGradient`, `midnightCopper` in the current screenshot set.
- Legacy styles still supported by the renderer: `warmGradient`, `creamRadial`, `duskGradient`.

Background texture uses gradients, radial glows, subtle grain, vignette, and filled organic `drawSoundBand` / kinetic wash shapes only. Line-based background details were removed on 2026-05-18; do not reintroduce topographic contours, wave ribbons, orbital rings, or other stroked line art unless the visual direction changes.

## Device mockup

- Uses the Apple-style bezel PNG from `bezelImage` in `screenshot_content.json`.
- The compositor uses the bezel aspect ratio `3000 / 1470` for all layout math.
- In v4, each slide's `scene.device` controls `x`, `y`, `width`, `rotation`, and opacity. Current iOS App Store direction is upright phones only (`rotation: 0`); do not reintroduce tilted devices without a new visual direction.
- The classic fallback still has layout-specific max widths: poster 1160, top 1080, bottom 1060, bleed 1150, peek-bottom 1220.
- Shadows and subtle reflection are drawn by `drawDeviceImage`; no manual frame edits in JPEG output.

## Layout grid

The canonical renderer uses `scene` objects in `screenshot_content.json` for mood, text block, and device placement only. Do not use configured JSON highlight layers for the App Store set: the professional pop-out emphasis system is metadata-anchored to real simulator captures.

UI elements that float above the phone must come from `fastlane/screenshots/<locale>/extracted-assets/*.png` plus their sibling JSON metadata, both written by `OasisNativeScreenshots.swift` from live simulator scenarios. The extractor adds a small element-specific capture padding so the PNG is not cut at the UI edge. The compositor maps each padded `visibleFramePoints` rect back onto the phone's real screen rect, then scales it around its own origin so the pop-out overlaps the source UI instead of becoming a duplicate elsewhere.

The classic fallback renderer still has five adaptive layouts: `poster`, `top`, `bottom`, `bleed`, and `peekBottom`. It measures eyebrow, headline, and subhead first, then fits the device into the remaining canvas.

## Per-slide copy (en-US)

| Slide | Eyebrow | Headline | Subhead |
| --- | --- | --- | --- |
| 01 Hero | `SLEEP · FOCUS · ESCAPE` | `Escape into / real nature.` | `35 real-world sounds to mix. Offline. No subscription.` |
| 02 Library | `IMMERSION` | `Build your / refuge.` | `Rain, forest, sea, campfire and much more.` |
| 03 Detail | `REALISM` | `Real / recordings.` | `Every sound was carefully recorded around the world.` |
| 04 Binaural | `BINAURAL WAVES` | `Calm your mind / with 4 brainwave modes.` | `Delta, Theta, Alpha and Beta.` |
| 05 Spatial | `SOUND PLACEMENT` | `Place sounds / around you.` | `Spatial audio engine.` |
| 06 Presets | `SAVED MIXES` | `Return to / your ambiences.` | `Save your mixes and reload them in one tap.` |
| 07 Timer | `SLEEP TIMER` | `Fall asleep / at your pace.` | `15 min, 30 min, 1 h or 2 h.` |
| 08 Free home | `START FREE` | `Start / right now.` | `3 ambiences, timer and sound placement included.` |
| 09 Library teaser | `FULL LIBRARY` | `Unlock more / sounds for life.` | `32 extra sounds with one purchase.` |
| 10 Paywall | `LIFETIME PREMIUM` | `One purchase. / Yours for life.` | `No subscription. No account. 100% offline.` |

The 6 localised versions (eyebrow + headline + subhead per locale) live in [`scripts/screenshot_content.json`](../../../scripts/screenshot_content.json). The Swift renderer decodes that JSON; there is no duplicate Swift copy table.

## Voice rules

- **No exclamation marks.**
- **No superlatives** ("Best", "#1", "Revolutionary") — Apple rejection bait.
- **No "Free trial"** — Oasis is freemium, not trial. Misuse = rejection.
- **No "3D audio" in user-facing copy.** Prefer "sound placement" / "placement sonore" for headlines. The 2026-05-18 screenshot subhead `Spatial audio engine.` is an approved exception because the French source says `Moteur audio spatial.`
- Every headline must be defensible against `fastlane/metadata/<lang>/description.txt` — no orphan claims.

## Deprecated elements (do NOT add back)

These either came from the old Cowork v2 brief or were removed during the 2026-05-18 cleanup:

- ❌ Accent orbs floating around device
- ❌ Blur backdrop on device
- ❌ Halo behind device
- ❌ "OASIS" wordmark / signature at the bottom (the App Store shows the icon already)
- ❌ Kicker pill / capsule container around the eyebrow
- ❌ Specular highlight on device (except the 1 px hairline allowed above)
- ❌ Line-art backgrounds: topographic contours, wave ribbons, orbital rings, decorative strokes

## Render pipeline

Single Swift script: [`scripts/generate_store_screenshot_comps.swift`](../../../scripts/generate_store_screenshot_comps.swift).

- `NSBitmapImageRep` at explicit pixel size (avoids the Retina lockFocus doubling trap).
- JPEG factor `0.92`.
- All 60 assets render in < 10 seconds.
- Source data lives in `scripts/screenshot_content.json`; v4 scene render code and fallback classic code live in the Swift script.
- Extracted UI emphasis assets live in `fastlane/screenshots/<locale>/extracted-assets/`. Each PNG is a padded crop from `XCUIScreen.main.screenshot().image` using the real `XCUIElement` frame, and each JSON file stores the element frame, padded visible frame, capture padding, and screen size.
- The v4 compositor does not read manual overlay coordinates for these elements. It auto-anchors each extracted PNG to the original phone screen position before applying a controlled scale, extra-large rounded clipping mask, 20%-opacity white border, faint inner white hairline, and a strong soft box shadow cast by an opaque underlay hidden beneath the real crop. Do not re-card or redraw the inside of the crop; the simulator PNG must remain the visual content.
- The renderer strictly validates `extracted-assets` before drawing. Each locale must contain only the approved simulator captures, each with fresh metadata including `elementFramePoints` and `paddingPoints`. Stale generated PNGs or unexpected files such as old separate binaural crops must make rendering fail.
- During design iteration, validate one locale only: `SCREENSHOT_LANGUAGES=fr-FR OASIS_SCREENSHOT_PARTIAL=1 bundle exec fastlane screenshots`, then `swift scripts/generate_store_screenshot_comps.swift --lang fr-FR`. Do not run all 6 locales until the French set is approved.
- `swift scripts/generate_store_screenshot_comps.swift` renders the canonical v4 set into `figma-pro/`.
- `swift scripts/generate_store_screenshot_comps.swift --classic` renders the old v3/classic set into `figma-pro-classic/` for comparison or rollback.

When changing copy, palette, layout, source capture mapping, or accent colors: edit `scripts/screenshot_content.json`, re-run the Swift compositor, and stage upload assets. Don't edit JPEGs by hand.

## App Preview video

Generated by [`scripts/generate_app_previews.rb`](../../../scripts/generate_app_previews.rb) from the localized composited screenshots, but currently **not staged or uploaded** by the App Store lanes. The 2026-05-19 `1.5.0` upload removed all remote App Previews because the videos were stale.

- Output: `fastlane/app-previews/<locale>/01_app_preview.mp4`.
- Format: 886 × 1920, 30 fps, H.264, silent AAC stereo 44.1 kHz, 20 seconds. Apple rejects no-audio MP4s with `MOV_RESAVE_STEREO`.
- Slide order: `01_hero` → `02_library` → `07_timer` → `05_spatial` → `08_free_home` → `10_paywall`.
- Regenerate after screenshot copy/layout changes via `bundle exec fastlane app_previews`; only re-enable staging after reviewing the MP4s.

## Quiescence under XCUITest (raw captures)

Raw captures (the `iPhone 17 Pro Max-<slug>.png` files in `fastlane/screenshots/<locale>/`) come from `OasisNativeUITests/OasisNativeScreenshots.swift`. The fastlane lane is filtered to `OasisNativeUITests/OasisNativeScreenshots/testAppStoreScreenshots`; do not let the social-video runner participate in static App Store screenshot capture. Two animations must be paused for screenshot determinism:

- `WaveformSignatureLine`
- `AnimatedLiquidAura`

Both check `AppConfiguration.isRunningUITests` and freeze. Don't add new continuous animations to the home screen without the same guard, or screenshot tests will hang.

Every App Store screenshot launches with `-OASISImmersiveAudioEnabled YES`, and `OasisNativeScreenshots.launchApp` asserts that `home.header.immersive` is selected before capturing. This keeps the visible "Immersive sound" / localized label present anywhere the home toolbar is visible.

Keep the Fastlane / `Snapfile` `launch_arguments` value as one combined string. Snapshot interprets multiple array entries as multiple complete runs, not multiple arguments, so splitting reset and immersive flags causes every locale to be captured twice.

The composited slides (`figma-pro/<slug>.jpg`) overlay copy onto these raw captures.

The screenshot test also captures selected real UI elements after the matching raw scenario. Current extracted assets are:

```
01_active_forest      02_active_river       03_detail_map
04_binaural_modes     05_spatial_stage      06_preset_starter
06_preset_calm        06_preset_storm       07_active_rain
08_active_birds       09_active_shore       09_library_teaser
10_paywall_primary
```

These are the only approved source for floating UI emphasis in v4 App Store assets. `04_binaural_modes` is one single crop of the full four-card grid; separate `04_binaural_delta`, `04_binaural_theta`, `04_binaural_alpha`, and `04_binaural_beta` crops are deprecated and must not reappear. Active-row pop-outs must be active in the underlying simulator screenshot, and free-tier screenshots use the deterministic screenshot shuffle so Birds, Wind, and Beach can be highlighted without premium content.

## Acceptance criteria

A finished screenshot set passes when:

- 60 JPEGs at exactly `1320 × 2868`, sRGB, no alpha, ≤ 2 MB each.
- During pre-approval iteration, only the `fr-FR` validation set should exist under `fastlane/screenshots/`; the full 6-locale set is generated only after visual approval.
- No App Preview MP4s staged for `1.5.1`.
- Naming matches the 10 slugs above, in 6 locale folders.
- Each headline and subhead fits its measured layout budget, with no clipping or awkward orphan word.
- Phones are cleanly framed and upright (`rotation == 0` for the current v4 direction).
- `scripts/screenshot_content.json` has no configured highlight layers for the canonical set.
- Floating UI emphasis uses real padded simulator PNGs plus metadata, preserves aspect ratio, overlaps the source element, and improves readability through scale, rounded clipping, accent-harmonised borders, and breathing room instead of duplicating arbitrary UI elsewhere.
- The single binaural pop-out is `04_binaural_modes`; old per-track binaural PNGs are absent.
- Per-slide background style and accent match `scripts/screenshot_content.json`.
- Eyebrow present on every slide, readable on iPhone-sized previews.
- Backgrounds use blobs / filled acoustic bands only, with no decorative line art.
- Special characters render correctly across all 6 locales (`ä ö ü ß` / `é è ê ç` / `ñ ¡ ¿` / `à è ì` / `ã õ ç`).
- Copy aligns with current `fastlane/metadata/<locale>/description.txt`.
