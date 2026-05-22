---
title: App Store Assets
status: stable
last_updated: 2026-05-22
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

> **Important:** two design briefs existed historically — a Cowork brief (v2) and a design-handoff brief (v3). They diverge on multiple dimensions (font, device width, palette, JPEG quality). **The v3 spec below is canonical.** The Cowork brief has been retired; do not back-port any v2 specs.

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

Raw captures come from the actual `OasisMac` panel in deterministic screenshot mode: the app opens the system-rendered template status item panel automatically, seeds premium/active sounds, forces immersive audio on, pauses continuous mesh/logo animations, and applies a fixed scenario. The visible header includes the compact counter-rotating OASIS ring logo, playback, timer, shuffle, AirPlay route picker, and quit controls. Detail screenshots use the in-panel macOS `SoundDetailSheet` overlay, not an AppKit sheet window.

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

## Type system (v3)

| Element | Specs |
| --- | --- |
| Headline | **SF Pro Display Heavy**, adaptive 136 → 80 pt, line-height 0.90, LS 0. Centered. The renderer measures each locale and steps down before overflow. |
| Subhead | SF Pro Display Medium 54 pt, LH 1.16, LS 0, 80 % opacity. Centered. May wrap when needed; the renderer measures height before placing the device. |
| Eyebrow | SF Pro Display Semibold 40 pt UPPERCASE, tracking +3.0 pt, accent color. Current screenshots use an eyebrow on every slide. |

> Eyebrows were increased on 2026-05-18 because the previous size was too hard to read on iPhone. The font is **SF Pro Display** (not Rounded — Rounded was the old Cowork v2 spec, which read consumer-playful).

## Color system (v3)

Per-slide background style and accent color live in [`scripts/screenshot_content.json`](../../../scripts/screenshot_content.json), not in a duplicated Swift table. The active background styles are:

- `studioGradient`, `sageMist`, `spatialGradient`, `midnightCopper` in the current screenshot set.
- Legacy styles still supported by the renderer: `warmGradient`, `creamRadial`, `duskGradient`.

Background texture uses gradients, radial glows, subtle grain, vignette, and filled organic `drawSoundBand` shapes only. Line-based background details were removed on 2026-05-18; do not reintroduce topographic contours, wave ribbons, orbital rings, or other stroked line art unless the visual direction changes.

## Device mockup

- Uses the Apple-style bezel PNG from `bezelImage` in `screenshot_content.json`.
- The compositor uses the bezel aspect ratio `3000 / 1470` for all layout math.
- Device max widths are layout-specific: poster 1160, top 1080, bottom 1060, bleed 1150, peek-bottom 1220.
- Device size can shrink when locale text needs more vertical room.
- Shadows and subtle reflection are drawn by `drawDevice`; no manual frame edits in JPEG output.

## Layout grid

The renderer has five adaptive layouts: `poster`, `top`, `bottom`, `bleed`, and `peekBottom`. Each layout measures eyebrow, headline, and subhead first, then fits the device into the remaining canvas. This is intentional: translated copy should be natural, not forced into identical line breaks.

All current slides have an eyebrow. If a future slide has no eyebrow, the renderer falls back to the configured SF Symbol marker.

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
- Source data lives in `scripts/screenshot_content.json`; render code and pipeline code live in the Swift script.
- The renderer also writes review-size JPEGs to `fastlane/screenshots/<locale>/figma-pro/preview/`; App Store staging uses only the 10 top-level `figma-pro/<slug>.jpg` files per locale.

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

## Acceptance criteria

A finished screenshot set passes when:

- 60 JPEGs at exactly `1320 × 2868`, sRGB, no alpha, ≤ 2 MB each.
- No App Preview MP4s staged for `1.5.1`.
- Naming matches the 10 slugs above, in 6 locale folders.
- Each headline and subhead fits its measured layout budget, with no clipping or awkward orphan word.
- Devices vertical, no rotation.
- Per-slide background style and accent match `scripts/screenshot_content.json`.
- Eyebrow present on every slide, readable on iPhone-sized previews.
- Backgrounds use blobs / filled acoustic bands only, with no decorative line art.
- Special characters render correctly across all 6 locales (`ä ö ü ß` / `é è ê ç` / `ñ ¡ ¿` / `à è ì` / `ã õ ç`).
- Copy aligns with current `fastlane/metadata/<locale>/description.txt`.
