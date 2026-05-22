# AI Memory Index

Single source of truth for any AI agent working on Oasis. Read [../../AGENTS.md](../../AGENTS.md) first if you haven't.

## Reading paths per task

Don't load everything. Pick the path matching your task.

### "I'm investigating the codebase for the first time"
1. [product/vision.md](product/vision.md)
2. [product/premium-model.md](product/premium-model.md)
3. [architecture/overview.md](architecture/overview.md)
4. [codebase/structure.md](codebase/structure.md)

### "I need to change something in the audio engine"
1. [architecture/audio-engine.md](architecture/audio-engine.md)
2. [architecture/binaural.md](architecture/binaural.md) — if binaural-related
3. [architecture/state.md](architecture/state.md) — for AppModel ↔ engine sync
4. [content/sounds-catalog.md](content/sounds-catalog.md) — if touching channels

### "I'm working on the paywall or premium gating"
1. [product/premium-model.md](product/premium-model.md)
2. [architecture/paywall.md](architecture/paywall.md)
3. [architecture/state.md](architecture/state.md) — for `enforcePremiumAccess`

### "I'm updating ASO copy / App Store metadata"
1. [marketing/positioning.md](marketing/positioning.md)
2. [marketing/aso-strategy.md](marketing/aso-strategy.md)
3. [content/localization.md](content/localization.md) — for fastlane locales

### "I'm doing a release"
1. [operations/release-process.md](operations/release-process.md)
2. [codebase/build-and-test.md](codebase/build-and-test.md)
3. [operations/secrets-and-keys.md](operations/secrets-and-keys.md)

### "I'm adding a new sound channel"
Touch in this order:
1. [content/sounds-catalog.md](content/sounds-catalog.md) — encoding pipeline, naming, licence
2. [architecture/audio-engine.md](architecture/audio-engine.md) — loading, looping
3. [architecture/state.md](architecture/state.md) — `PersistedMixerState` backward-compat
4. [content/localization.md](content/localization.md) — `channel.{id}` keys ×6 locales
5. [marketing/store-assets.md](marketing/store-assets.md) — "35 sounds" claim updates

### "I'm working on the UI / SwiftUI views"
1. [architecture/ui.md](architecture/ui.md)
2. [codebase/conventions.md](codebase/conventions.md)
3. The relevant feature file (paywall, state, audio…)

### "I'm producing TikTok / Reels / Shorts marketing videos"
1. [marketing/video-factory.md](marketing/video-factory.md)
2. [codebase/build-and-test.md](codebase/build-and-test.md) — UI test target overview
3. [architecture/ui.md](architecture/ui.md) — accessibility identifier inventory

### "I'm doing Reddit / forum acquisition"
1. [marketing/community-radar.md](marketing/community-radar.md)
2. [marketing/positioning.md](marketing/positioning.md)
3. [marketing/aso-strategy.md](marketing/aso-strategy.md) — campaign links / Custom Product Pages

### "I'm trying to increase downloads"
1. [marketing/download-growth-sprint.md](marketing/download-growth-sprint.md)
2. [marketing/community-radar.md](marketing/community-radar.md)
3. [marketing/video-factory.md](marketing/video-factory.md)
4. [marketing/aso-strategy.md](marketing/aso-strategy.md) — only if analytics show a listing conversion issue

## File map

```
product/         — what Oasis is, why it exists, who it serves
  vision.md           Mission, audience, multi-use positioning
  premium-model.md    Free/premium split, RevenueCat config, lifetime rationale
  glossary.md         Channel, preset, signature, binaural, spatial — vocabulary

architecture/    — how the app works internally
  overview.md         Modules, data flow, key dependencies
  audio-engine.md     AVAudioEngine graph, loops, fades, spatial
  binaural.md         Delta/Theta/Alpha/Beta — separate AVAudioPlayer per track
  state.md            AppModel, persistence, presets, observability
  paywall.md          RevenueCat integration, entitlement, gating points
  ui.md               SwiftUI patterns, components library, design tokens

codebase/        — where things live, how to read the repo
  structure.md        Directory map and responsibilities
  conventions.md      Naming, file patterns, SwiftUI idioms used here
  build-and-test.md   xcodebuild, fastlane lanes, scripts/, UI tests

content/         — material the app ships
  sounds-catalog.md   35 channels + 4 binaurals, sources, licences, encoding
  sound-backgrounds.md Pexels background image sources and per-track visual rationale
  localization.md     6 locales, AppCopy, fastlane metadata, key conventions

marketing/       — how Oasis is sold
  aso-strategy.md     Title/subtitle/keywords per locale, screenshot order
  store-assets.md     Screenshot specs, brief reconciliation, Figma workflow
  positioning.md      Multi-use angle, competitors, moats
  download-growth-sprint.md  1000-download sprint, metrics loop, campaign IDs
  community-radar.md  Reddit / HN / forum opportunity radar and manual reply rules
  video-factory.md    Scenario-driven social-video pipeline (simulator + FFmpeg)

operations/      — how Oasis ships and runs
  release-process.md  Versioning, fastlane lanes, App Store Connect upload flow
  secrets-and-keys.md RevenueCat key, TelemetryDeck, App Store creds (locations only)
  known-issues.md     Naming drift in code, technical debt, watch-outs

meta/            — how this memory itself is maintained
  update-policy.md    The rule every agent follows (mirror of AGENTS.md protocol)
  drift-check.md      How `scripts/ai-memory/check-drift.sh` works
  changelog.md        Material changes to the memory itself
```

## Frontmatter conventions

Every file under `docs/ai/` (except this index and `meta/changelog.md`) starts with:

```yaml
---
title: Human-readable title
status: stable | wip | deprecated
last_updated: YYYY-MM-DD
tracks:
  - "path/to/source/file.swift"
  - "path/glob/**/*.txt"
related:
  - "../sibling/file.md"
---
```

- **`tracks:`** — list of source paths this memory mirrors. Consumed by [`scripts/ai-memory/check-drift.sh`](../../scripts/ai-memory/check-drift.sh).
- **`last_updated:`** — bump to today (UTC) on every content change.
- **`related:`** — relative links for navigation, not for drift detection.

## Universality

This memory is plain Markdown. Any LLM can ingest it.

- **Filesystem-aware tools** (Claude Code, Codex, Cursor, Aider, Continue, Zed): discover [AGENTS.md](../../AGENTS.md) at root automatically.
- **Web LLMs without filesystem** (ChatGPT web, Claude web): paste [AGENTS.md](../../AGENTS.md) + the files listed in the relevant reading path above.

Avoid in memory: tool-specific syntax (no `@code-reviewer`, no `/command`), assumed shell context, emojis.
