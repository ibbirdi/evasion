---
title: Product Vision
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Views/RootView.swift"
  - "ios-native/OasisNative/Views/Overlays/OnboardingView.swift"
  - "fastlane/metadata/**/description.txt"
related:
  - "premium-model.md"
  - "../marketing/positioning.md"
---

# Product Vision

## What Oasis is

A native iOS ambient mixer. The user combines up to 35 hand-curated field recordings, optional per-sound placement, and optional binaural brainwave tracks. They save mixes as presets and run them with a sleep timer.

## Who it serves

The app explicitly targets four use cases — not just "sleep". This positioning was sharpened in the 2026-05-02 ASO audit (see [../marketing/positioning.md](../marketing/positioning.md)):

1. **Sleep** — drift off, mask hotel/street noise, beat insomnia.
2. **Nap / power-rest** — 15–30 minute sessions during the day.
3. **Focus / deep work** — replace lo-fi/Spotify playlists for work or study.
4. **Reading / calm** — meditation, journaling, racing-thoughts wind-down.

The keyword field still captures the high-volume sleep traffic (60–70 % of segment search volume), but title, subtitle, screenshots, and description push the multi-use angle.

## Why it exists

Sleep / wellness audio apps are dominated by subscription products (Calm, Headspace, Portal, Rainy Mood). Oasis takes the opposite stance:

- **One-time lifetime purchase.** No subscription, ever. Every future premium sound included.
- **Offline-first.** ~426 MB bundled audio. Works on a plane, in a tent, off-grid.
- **Authenticity.** Each ambient channel is a real field recording from a real place, with the author and licence shown in-app.
- **Craft.** Per-sound placement, binaural tracks, auto-variation, and presets — features that long-running listeners notice over days.

## What Oasis is NOT

Decisions taken explicitly:

- Not a meditation app (no guided audio, no breathing exercises).
- Not a music app (no songs, no curated mood playlists).
- Not a sleep tracker (no HealthKit, no metrics, no "sleep score").
- Not a social product (no profiles, no sharing).
- Not a streamer (everything ships in the bundle).
- Not a subscription product. Ever.

## Free vs premium

Free is intentionally usable, not crippled. See [premium-model.md](premium-model.md) for the full breakdown. Headline: 3 of 35 channels, 1 of 4 binaural tracks (Delta), 15/30 min timer, no presets panel. The free 3 are Birds, Wind, Beach — chosen for breadth of mood (forest-ish, weather, water).

The final onboarding page states this model directly: users can unlock lifetime access immediately or start free. Keep both choices visible so the paywall feels like a clear purchase moment, not a surprise gate.

## Bundle weight

The 426 MB audio bundle is a deliberate trade-off. We pay it once at install for an offline experience that competitors can't match without a download model. New channels add ~4–32 MB each — track it (`content/sounds-catalog.md`) and watch the IPA size before shipping new sounds.
