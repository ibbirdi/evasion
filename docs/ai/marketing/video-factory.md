---
title: Marketing Video Factory
status: stable
last_updated: 2026-05-22
tracks:
  - "marketing-video-factory/**"
  - "ios-native/OasisNativeUITests/MarketingScenarioRunner.swift"
related:
  - "store-assets.md"
  - "../codebase/build-and-test.md"
  - "../architecture/ui.md"
---

# Marketing Video Factory

Local pipeline that produces social-marketing videos (TikTok, Reels, Shorts) by **scripting the live app inside a simulator**, screen-recording the result, then layering text overlays and the configured Oasis audio mix in FFmpeg.

Lives under [`marketing-video-factory/`](../../../marketing-video-factory/). Subproject is self-contained: Node + TypeScript + FFmpeg. Reuses iOS source only via the existing audio bundle and a single XCUITest target.

## Current acquisition use — 2026-05-22

The factory is one of the daily loops for the [download-growth sprint](download-growth-sprint.md). Current scenario copy is aligned with the 1.5.x listing:

- Use "35 sounds" in premium/no-subscription videos.
- Prefer "sound placement" / "immersive sound placement" over "3D audio" in visible overlays, hooks, captions, and hashtags.
- Rotate `sleep-cabin`, `no-subscription-pitch`, and `spatial-magic` before creating new scenarios.
- `no-subscription-pitch` intentionally proves sliders, binaural modes, and presets only; keep sound-placement gestures for `sleep-cabin` / `spatial-magic` so the anti-subscription asset stays robust.
- For the global 1000-download sprint, generate English variants before reusing French-overlay videos in non-French markets. Current ready EN assets: `oasis_no_subscription_pitch_en_120442_c294f.mp4`, `oasis_sleep_cabin_en_121053_c294g.mp4`, and `oasis_spatial_magic_en_121214_c294h.mp4`.
- Six-locale generation is available for scenarios that provide overlay translations. `no-subscription-pitch` currently has FR/EN/DE/ES/IT/PT-BR overlays and native ready exports for all six App Store languages: FR `oasis_no_subscription_pitch_fr_114414_c294d.mp4`, EN `oasis_no_subscription_pitch_en_120442_c294f.mp4`, DE `oasis_no_subscription_pitch_de_122309_c294i.mp4`, ES `oasis_no_subscription_pitch_es_122750_c294j.mp4`, IT `oasis_no_subscription_pitch_it_122838_c296h.mp4`, and PT-BR `oasis_no_subscription_pitch_ptbr_122926_c296i.mp4`.
- The acquisition publisher can reuse ready video metadata for owned text posts, but it does not upload videos itself; video platforms stay on official upload/scheduler flows.

## What it produces

For each run: a 1080×1920 H.264/AAC MP4 plus a `.json` sidecar with hook, caption, hashtags, mood, audio mix id, seed, and timing. Output organised by date under `marketing-video-factory/output/<YYYY-MM-DD>/`.

## Architecture

Single command (`npm run record -- --scenario <id>`) drives this pipeline:

1. **Pick / boot** an `iPhone 17 Pro Max` simulator (configurable via `--device`).
2. **Start `xcrun simctl io booted recordVideo`** in the background → raw mp4 at the device's native resolution (1290×2796).
3. **Run the XCUITest** `OasisNativeUITests/MarketingScenarioRunner/testRunScenario`, with `OASIS_SCENARIO_PATH` pointing to a temp JSON file. The test:
   - Decodes the scenario.
   - Launches the app with `-ui_testing -OASISPremiumOverride <premium|free> -OASISResetState YES -AppleLanguages (<lang>) -AppleLocale <locale>`.
   - Writes a Unix-epoch timestamp to `/tmp/oasis-marketing/scenario-started.txt` (the **sync marker**) right before executing the action timeline.
   - Replays actions on a monotonic schedule (`tap`, `setSlider`, `dragSpatial`, `swipe`, `scrollTo`, `dismissPanel`, `wait`).
4. **Stop the recording** when the test finishes.
5. **Compute boot offset** = `scenarioStartedAt - recordingStartedAt`. The Node driver reads the sync marker and uses it to seek the raw mp4 with FFmpeg's `-ss` — frame 0 of the output equals the first scenario action.
6. **FFmpeg post-process**: crop 9:16 → overlay timed text PNGs (SVG → sharp → PNG) → mix Oasis audio (`config/audio-mixes.json`) → H.264/AAC, +faststart.

## iOS coupling (small, explicit)

The XCUITest target is `OasisNativeUITests`. The runner is [`MarketingScenarioRunner.swift`](../../../ios-native/OasisNativeUITests/MarketingScenarioRunner.swift). It is **generic** — any scenario JSON works without Swift changes.

Accessibility identifiers used by scenarios (see [`architecture/ui.md`](../architecture/ui.md) for the full inventory):

- `channel.{row,identity,mute,slider,spatial,auto}.<channelId>` — mixer rows
- `home.bottom.{shuffle,playback,presets,binaural}`, `home.header.timer`, `home.scroll`
- `panel.{spatial,presets,binaural,sound-detail}.container`, `panel.timer.unlock`
- `spatial.stage` — drag target on the sound-placement widget
- `presets.row.<id>`, `binaural.track.<id>`
- Paywall surfaces — `premium.paywall.{container,primary,restore,close}`, `premium.library.teaser{,.primary}`

If a scenario needs a UI element that isn't yet identified, the rule is: add `.accessibilityIdentifier("…")` (plus `.accessibilityElement(children: .ignore)` and a label if the view is gesture-only) on the SwiftUI view. Never modify app logic for the marketing factory.

## Scenario JSON

Schema is enforced by Zod in `marketing-video-factory/src/types.ts`. A scenario declares:

- Metadata — `id`, `mood`, `angle`, `lang`, `duration`, `premium`.
- `audioMix` — references an entry in `marketing-video-factory/config/audio-mixes.json`.
- `hookCategory` / `captionCategory` / `hashtagCategories` — references pools in `config/hooks.<lang>.json`, `config/captions.<lang>.json`, `config/hashtags.json`. A deterministic hook/caption is picked per `--seed`.
- `actions[]` — timeline of XCUITest actions.
- `overlays[]` — timed text overlays (`top`/`center`/`bottom` positions; `text: { fr, en }` or `textRef: "hook" | "caption"`).

Example: [`marketing-video-factory/scenarios/sleep-rain-demo.json`](../../../marketing-video-factory/scenarios/sleep-rain-demo.json).

## Audio path

The simulator's screen recording **does not capture audio reliably**, so audio is layered in post. The Node driver symlinks the iOS bundle (`ios-native/OasisNative/Resources/Audio/*.m4a`) into `marketing-video-factory/assets/audio/` with short aliases (`rain.m4a` → `pluie1.m4a`, etc.) via `npm run sync`. The audio-mixes config references those aliases. FFmpeg combines tracks with per-track volume, mix-level fade in/out, and amix.

## Commands (subproject)

| Command | Purpose |
| --- | --- |
| `npm run validate` | Check FFmpeg + configs + scenarios. |
| `npm run list` | List scenarios and audio mixes. |
| `npm run record -- --scenario <id> [--lang fr\|en\|de\|es\|it\|ptbr] [--seed N] [--dry-run] [--keep-raw] [--debug]` | Generate one video. |
| `npm run sync` | Symlink iOS audio aliases into `assets/audio/`. |
| `npm run clean [--all]` | Remove `.tmp/` (and `output/` with `--all`). |
| `npm run typecheck` | `tsc --noEmit`. |

## Why this approach

- **Real app, real UI.** Marketing footage shows the actual product, not screenshots or mockups.
- **Reproducible.** A scenario + a seed produces an identical video. Hooks/captions/backgrounds rotate via PRNG.
- **No SaaS, no backend.** Everything runs locally. The iOS app is unchanged in functional behaviour — only `accessibilityIdentifier` additions, which are metadata.
- **Composable.** Adding a new video = writing one JSON file. The XCUITest runner is generic.

## Constraints / known limits

- The simulator boots cold per run (~5–10 s overhead). The sync marker absorbs this; final output is trimmed cleanly.
- iOS UI locale is set via `-AppleLanguages`/`-AppleLocale` launch args. The Node driver supports the six App Store languages: `fr`, `en`, `de`, `es`, `it`, and `ptbr` (see `LOCALES` in `marketing-video-factory/src/sim/runTest.ts`).
- Native device aspect is 9:19.5 → cropped to 9:16, losing ~210 px top + ~210 px bottom. The OASIS header and bottom bar remain visible; the iOS status bar and home indicator are cropped out.
- Overlays positioned at `top`/`bottom` can visually overlap the in-app header/bottom bar. The drop-shadow filter keeps them readable; for high-stakes shoots, tune `TOP_TEXT_Y`/`BOTTOM_TEXT_Y` in `src/render/renderOverlay.ts`.
