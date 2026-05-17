---
title: App Store Assets
status: stable
last_updated: 2026-05-17
tracks:
  - "fastlane/screenshots/**"
  - "scripts/generate_store_screenshot_comps.swift"
  - "scripts/screenshot_content.json"
  - "ios-native/OasisNativeUITests/OasisNativeScreenshots.swift"
related:
  - "aso-strategy.md"
  - "positioning.md"
  - "video-factory.md"
  - "../codebase/build-and-test.md"
---

> **Scope.** This page covers the **10 static App Store screenshots** captured by `OasisNativeScreenshots.swift` and composited via `scripts/generate_store_screenshot_comps.swift`. For **social-marketing videos** (TikTok / Reels / Shorts) driven by a sibling XCUITest (`MarketingScenarioRunner.swift`), see [video-factory.md](video-factory.md).

# App Store Assets

Specs and copy for the 60 App Store screenshots (10 slides × 6 locales) and the App Preview video.

> **Important:** two design briefs existed historically — a Cowork brief (v2) and a design-handoff brief (v3). They diverge on multiple dimensions (font, device width, palette, JPEG quality). **The v3 spec below is canonical.** The Cowork brief has been retired; do not back-port any v2 specs.

## Canvas (non-negotiable)

- Dimensions: **1320 × 2868 px** (iPhone 17 Pro Max App Store size).
- Color: sRGB, no alpha.
- Format: JPEG, quality **0.92**, target ≤ 2 MB.
- Raw capture path: `fastlane/screenshots/<locale>/iPhone 17 Pro Max-<slug>.png`.
- Composite path: `fastlane/screenshots/<locale>/figma-pro/<slug>.jpg`.
- Upload staging path: `fastlane/appstore-upload/<locale>/<slug>.jpg`, produced by `bundle exec fastlane stage_appstore_assets`.

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
| Headline | **SF Pro Display Bold**, 128 pt base (step down 110 / 96 if overflow), line-height 0.96, letter-spacing −3 % (= −3.84 pt @ 128). Color `#FFFFFF` 100 %. Centered. Max 2 lines, ≤ 22 char/line, ≤ 44 char total. Width 1160 px. |
| Subhead | SF Pro Text Regular 34 pt, LH 1.25, LS 0, `#FFFFFF` 72 %. Centered. Max 1 line, ≤ 78 char. Width 1080 px. |
| Eyebrow | SF Pro Text Semibold 24 pt UPPERCASE, LS +12 %, accent color 100 %. Current screenshots use an eyebrow on every slide. ≤ 34 char. |

> The font is **SF Pro Display Bold** (not Rounded — Rounded was the old Cowork v2 spec, which read consumer-playful; Bold reads confident-premium and matches Calm / Endel reference set).

## Color system (v3)

Two-stop vertical gradient. Top stop = mood-saturated, bottom stop = same hue darkened 35 %. Per-slide accent color drives the eyebrow when present.

| Slide | Top | Bottom | Accent |
| --- | --- | --- | --- |
| 01 Hero | `#3A1E12` | `#1A0A04` | `#F5A35E` |
| 02 Library | `#1A3F2E` | `#0A1D14` | `#5CC08A` |
| 03 Detail | `#2A2F14` | `#11140A` | `#C9A256` |
| 04 Binaural | `#2A1945` | `#130929` | `#A07EE2` |
| 05 Spatial | `#0E2E45` | `#051623` | `#5FC2E0` |
| 06 Presets | `#2E1648` | `#170A27` | `#D27BC7` |
| 07 Timer | `#1A2B45` | `#0B1424` | `#8EA5D4` |
| 08 Free home | `#0E3755` | `#062038` | `#5BB0DF` |
| 09 Library teaser | `#1E3416` | `#0F1C0A` | `#B6D463` |
| 10 Paywall | `#3D1A0C` | `#1A0705` | `#F5995B` |

## Device mockup

- Width: 880 px (= 67 % canvas).
- Aspect: 0.4603 → height 1912 px.
- Corner radius: **37 px** (matches `UIScreen.displayCornerRadius` for the iPhone 17 Pro Max generation; *not* 76 px — that's iPad-class).
- No bezel. Hairline 1 px `rgba(255,255,255,0.08)` allowed.
- Single shadow: offset y +24, blur 60, opacity 40 %, color = the slide's *base background* (NOT pure black).
- Top of device at y = 906; bottom 50 px above canvas bottom (intentional anti-poster bleed).

## Layout grid

Centred, top-down. With eyebrow:

```
y=140   eyebrow  (height 32)
y=200   headline (height 256, 2 lines × 128 × 0.96)
y=560   subhead  (height 44)
y=906   device   (height 1912)
        50 px to bottom
```

Without eyebrow: shift headline up to y = 140. Without subhead: shift device up by 80 px.

## Per-slide copy (en-US)

| Slide | Eyebrow | Headline | Subhead |
| --- | --- | --- | --- |
| 01 Hero | `SLEEP · FOCUS · ESCAPE` | `Escape into real nature.` | `20 field recordings. Offline. No subscription.` |
| 02 Library | `REAL PLACES` | `Build a place around you.` | `Rain, forest, sea, campfire and more.` |
| 03 Detail | `FIELD RECORDINGS` | `Hear where it came from.` | `Locations, artists and licences stay visible.` |
| 04 Binaural | `BINAURAL WAVES` | `Tune your state of mind.` | `Delta, Theta, Alpha and Beta modes.` |
| 05 Spatial | `SOUND PLACEMENT` | `Place every sound around you.` | `Move each sound closer, farther, left or right.` |
| 06 Presets | `SAVED MIXES` | `Return to your favourites.` | `Save ambience presets and reload in one tap.` |
| 07 Timer | `SLEEP TIMER` | `Fade out on your time.` | `15 min, 30 min, 1 h or 2 h timers.` |
| 08 Free home | `FREE START` | `Start free, no account.` | `3 ambiences, timer and sound placement included.` |
| 09 Library teaser | `FULL LIBRARY` | `Unlock more sounds for life.` | `17 premium ambiences with one purchase.` |
| 10 Paywall | `LIFETIME PREMIUM` | `One purchase. Yours for life.` | `No subscription. No account. 100% offline.` |

The 6 localised versions (eyebrow + headline + subhead per locale) live in [`scripts/screenshot_content.json`](../../../scripts/screenshot_content.json). The Swift renderer decodes that JSON; there is no duplicate Swift copy table.

## Voice rules

- **No exclamation marks.**
- **No superlatives** ("Best", "#1", "Revolutionary") — Apple rejection bait.
- **No "Free trial"** — Oasis is freemium, not trial. Misuse = rejection.
- **No "3D audio" / "spatial audio" in user-facing copy** — use "sound placement" / "placement sonore" unless the rendering is upgraded and the wording is explicitly approved.
- Every headline must be defensible against `fastlane/metadata/<lang>/description.txt` — no orphan claims.

## Deprecated v2 elements (do NOT add back)

These were in the old Cowork v2 brief. v3 explicitly removed them:

- ❌ Radial glow / screen blends behind device
- ❌ Grain / noise texture
- ❌ Accent orbs floating around device
- ❌ Blur backdrop on device
- ❌ Halo behind device
- ❌ "OASIS" wordmark / signature at the bottom (the App Store shows the icon already)
- ❌ Kicker pill / capsule container around the eyebrow
- ❌ Specular highlight on device (except the 1 px hairline allowed above)

## Render pipeline

Single Swift script: [`scripts/generate_store_screenshot_comps.swift`](../../../scripts/generate_store_screenshot_comps.swift).

- `NSBitmapImageRep` at explicit pixel size (avoids the Retina lockFocus doubling trap).
- JPEG factor `0.92`.
- All 60 assets render in < 10 seconds.
- Source data lives in `scripts/screenshot_content.json`; render code and pipeline code live in the Swift script.

When changing copy, palette, layout, source capture mapping, or accent colors: edit `scripts/screenshot_content.json`, re-run the Swift compositor, and stage upload assets. Don't edit JPEGs by hand.

## App Preview video

Generated by [`scripts/generate_app_previews.rb`](../../../scripts/generate_app_previews.rb) from the localized composited screenshots.

- Output: `fastlane/app-previews/<locale>/01_app_preview.mp4`.
- Staged upload path: `fastlane/appstore-upload/<locale>/01_app_preview.mp4`.
- Format: 886 × 1920, 30 fps, H.264, no audio, 20 seconds.
- Slide order: `01_hero` → `02_library` → `07_timer` → `05_spatial` → `08_free_home` → `10_paywall`.
- Regenerate after screenshot copy/layout changes via `bundle exec fastlane app_previews`, then `bundle exec fastlane stage_appstore_assets`.

## Quiescence under XCUITest (raw captures)

Raw captures (the `iPhone 17 Pro Max-<slug>.png` files in `fastlane/screenshots/<locale>/`) come from `OasisNativeUITests/OasisNativeScreenshots.swift`. Two animations must be paused for screenshot determinism:

- `WaveformSignatureLine`
- `AnimatedLiquidAura`

Both check `AppConfiguration.isRunningUITests` and freeze. Don't add new continuous animations to the home screen without the same guard, or screenshot tests will hang.

The composited slides (`figma-pro/<slug>.jpg`) overlay copy onto these raw captures.

## Acceptance criteria

A finished screenshot set passes when:

- 60 JPEGs at exactly `1320 × 2868`, sRGB, no alpha, ≤ 2 MB each.
- Naming matches the 10 slugs above, in 6 locale folders.
- Each headline ≤ 2 lines, ≤ 44 char, no widows.
- Devices vertical, no rotation.
- Per-slide gradient and accent match the table above.
- Eyebrow only on slides 01 / 07 / 08 / 10.
- Special characters render correctly across all 6 locales (`ä ö ü ß` / `é è ê ç` / `ñ ¡ ¿` / `à è ì` / `ã õ ç`).
- Copy aligns with current `fastlane/metadata/<locale>/description.txt`.
