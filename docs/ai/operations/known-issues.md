---
title: Known Issues and Watch-Outs
status: stable
last_updated: 2026-05-19
tracks: []
related:
  - "../codebase/conventions.md"
  - "../content/sounds-catalog.md"
  - "../marketing/store-assets.md"
---

# Known Issues and Watch-Outs

Quirks, deliberate divergences, and footguns that an agent unfamiliar with the project will trip on. None of these are bugs to fix without thinking — they're documented because the right move is to *avoid stepping on them*, not to "clean up".

## Channel ID vs file-name drift

Three ambient channels have IDs that don't match their `.m4a` file:

| Channel ID | File name |
| --- | --- |
| `goelands` | `goelants1.m4a` |
| `tonnerre` | `orage1.m4a` |
| `village` | `ville1.m4a` |

These mismatches are **historical and persisted**. Channel IDs are the keys in user-saved `PersistedMixerState` payloads (mix volumes, presets). Renaming a case (or even renaming the file under a matching ID) requires migration code; without it, every existing user's saved presets and mix state lose those channels on the next launch.

If you absolutely must align them: write a `PersistedMixerState` decode-time migration that maps the old IDs to the new ones, ship a release where both are tolerated for ~2 versions, then drop the legacy.

Until then: treat the drift as load-bearing.

## "35 sounds" claim — repeated everywhere

The number `35` (and its derivatives `32 more`, `3 free`) appears in:

- 6 locales × `subtitle.txt`, `description.txt`, `promotional_text.txt`, `release_notes.txt`
- Screenshots `02_library`, `08_free_home`, `09_library_teaser` (rasterised JPEGs)
- Paywall copy
- `SoundChannel` enum cases in code

Adding or removing a channel is a multi-surface update. The checklist is in [content/sounds-catalog.md](../content/sounds-catalog.md). Don't ship a partial update — a "Mixer of 35 sounds" subtitle while screenshots still say "20 real places" is exactly the kind of inconsistency Apple reviewers (and customers) notice. As of 2026-05-19, App Store metadata, screenshot overlay copy, composite screenshots, and staged upload screenshots have been refreshed around the `35` total / `32` premium-extra claim; stale App Preview videos were removed from App Store Connect and are no longer staged.

## "Four binaural modes" — repeated

Same shape: copy in 6 locales + screenshot `04_binaural` + paywall benefit list + binaural panel UI. Adding or removing a mode is a wide change.

## Two design briefs — only v3 is canonical

Historically the repo had two competing design briefs for App Store screenshots:

- **Cowork brief (v2)** — older, specified SF Pro Rounded, 1080 pt device width, JPEG quality 0.90, included grain + glow + halo + watermark.
- **Design brief (v3)** — current, specifies SF Pro Display Bold, 880 px device width, JPEG quality 0.92, eliminates grain / glow / halo / watermark.

Both briefs were absorbed into [marketing/store-assets.md](../marketing/store-assets.md) and the originals deleted. **The v3 spec wins.** If you ever encounter v2 fragments (in old branches, archives, or old CPP renders), don't apply them.

## `lac1.m4a` over true-peak target

Of the pre-2026-05 ambient channels, `lac1.m4a` is the only file with a measured `+0.3 dBTP` (i.e., 0.3 dB over the `-1.5 dBTP` target). This is within the limiter's tolerance and audibly fine, but there is **no margin** to layer further processing.

Why: the source recording is exceptionally quiet (`-52 LUFS` integrated), and reaching `-20 LUFS` required `+32 dB` gain. The intersample peaks pushed past the target despite the alimiter.

If you re-encode lac with stricter limiting, audible artifacts appear in the high-frequency content. Best fix would be to re-source a louder original — that's a known but unbooked task.

## Bundle size — 426 MB ceiling-anxious

The audio bundle is ~426 MB today. New ambient channels add ~4–32 MB. App Store cellular install limit is 4 GB so we're nowhere near it, but:

- TestFlight downloads on cellular get throttled around 200 MB (anecdotally).
- App Store search results display "X.Y GB" once a release crosses 1 GB — perceptual cliff.

Watch the size before each release. If we cross 500 MB, it's worth re-encoding evaluation (HE-AAC v2 was rejected for audibly-degrading reasons — see [content/sounds-catalog.md](../content/sounds-catalog.md), but a 64 kbps test could re-open the question).

## iPhone model in screenshot file names

`fastlane/screenshots/<locale>/iPhone 17 Pro Max-<slug>.png` — the device model is in the path. When Apple ships a new "best" iPhone:

1. Update the snapshot lane in `Fastfile` to target the new simulator.
2. Update any path references in `generate_store_screenshot_comps.swift`.
3. Re-stage and re-render.

Don't blanket rename old captures — you may need them to compare conversion rates.

## Onboarding completion is sticky

`oasis.onboarding.completed` lives in `UserDefaults` and is **not** wiped by `-OASISResetState`. If you're testing onboarding flows manually:

- Delete the app and reinstall, or
- Add a temporary launch arg / debug menu to clear that key.

This is by design — UI test scenarios assume onboarding is past, so wiping it would break them.

## RevenueCat `current` offering is dashboard-side

The `RCpremium` offering name is currently configured as the *current offering* in the RevenueCat dashboard. The code reads `Purchases.shared.offerings().current` — it does not check the name.

If the current offering is unset in the dashboard (or if a renamed offering loses the "current" flag), the paywall shows nothing on launch and there's no in-app way to debug it. Always check the dashboard "current" toggle when paywall packages mysteriously disappear.

## Memory drift itself

The whole AI memory under `docs/ai/` is itself a watch-out. It's only as good as its `tracks:` declarations and `last_updated:` timestamps. Run `bash scripts/ai-memory/check-drift.sh` regularly — see [../meta/drift-check.md](../meta/drift-check.md). A stale memory is worse than no memory because it lies confidently.
