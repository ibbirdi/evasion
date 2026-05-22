# AGENTS.md

> Universal entry point for AI agents working on **Oasis** (iOS sleep/ambience app).
> Compatible with Claude Code, OpenAI Codex, Cursor, Aider, Continue, Zed, ChatGPT (paste this file).

## Project snapshot

- **Product**: Oasis — iOS native ambient mixer (35 nature sounds, 4 binaural tracks, per-sound placement).
- **Bundle ID**: `com.jonathanluquet.drift` — current version **1.5.1** (build 7).
- **Stack**: Swift / SwiftUI (`@Observable`), AVAudioEngine, RevenueCat (one-time lifetime purchase, **no subscription, ever**).
- **Target**: iOS 17+, portrait-only, dark-mode-only, offline-first (~310 MB audio bundle).
- **Localised** in 6 languages: en-US, fr-FR, de-DE, es-ES, it, pt-BR.
- **Solo dev** focused on ASO + revenue growth. This repo is the source of truth for code, copy, assets, and strategy.

## How to use this memory

All durable knowledge lives under [`docs/ai/`](docs/ai/). Read the index first, then load only the files relevant to your task:

→ **[docs/ai/README.md](docs/ai/README.md)** — index, task-based reading paths, file map, frontmatter conventions.

If you can only load one file before starting, load that index. Each file under `docs/ai/` is short (≤ 200 lines), focused on a single concern, and starts with YAML frontmatter declaring which source files it tracks.

## Memory update protocol — MANDATORY

When you finish a task that modified the codebase, the product, or any asset, **you must update the memory before considering the task done.**

**Rule.** If you edited a file, find every memory entry whose `tracks:` frontmatter matches that file. Update those entries. Bump their `last_updated` field to today's date.

**Memory-affecting changes (non-exhaustive):**
- Adding/removing a sound channel, binaural track, preset, language → `content/` + `marketing/`
- Editing `AppModel`, `AudioMixerEngine`, `PaywallOverlay`, `HomeView` → `architecture/`
- Renaming files, restructuring folders → `codebase/structure.md`
- Changing premium gating, pricing, RevenueCat config → `product/premium-model.md` + `architecture/paywall.md`
- Editing `fastlane/metadata/`, screenshots, ASO copy → `marketing/`
- Introducing a new convention, pattern, or tool → `codebase/conventions.md`

**Not memory-affecting:**
- Whitespace / formatting / comment-only edits
- Bug fixes that change neither contract nor surface
- Single-string copy tweaks already captured in fastlane metadata

When in doubt, run `bash scripts/ai-memory/check-drift.sh` from repo root. It tells you which memory entries are stale relative to source changes.

Full policy and edge cases: [docs/ai/meta/update-policy.md](docs/ai/meta/update-policy.md).

## Quick references

| You need to… | Read |
| --- | --- |
| Understand the audio engine | [docs/ai/architecture/audio-engine.md](docs/ai/architecture/audio-engine.md) |
| Touch premium / RevenueCat | [docs/ai/product/premium-model.md](docs/ai/product/premium-model.md) + [docs/ai/architecture/paywall.md](docs/ai/architecture/paywall.md) |
| Add or change a sound | [docs/ai/content/sounds-catalog.md](docs/ai/content/sounds-catalog.md) |
| Build, test, screenshot | [docs/ai/codebase/build-and-test.md](docs/ai/codebase/build-and-test.md) |
| Update ASO / App Store copy | [docs/ai/marketing/aso-strategy.md](docs/ai/marketing/aso-strategy.md) |
| Ship a release | [docs/ai/operations/release-process.md](docs/ai/operations/release-process.md) |

## Build (one-liner)

```bash
xcodebuild -scheme OasisNative -project "ios-native/OasisNative.xcodeproj" \
  -configuration Debug -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" \
  build CODE_SIGNING_ALLOWED=NO
```

## Conventions

- All memory and code-related comments are in **English**. Product copy stays multilingual via `Localizable.xcstrings` and `fastlane/metadata/`.
- One concern per memory file. Keep each file ≤ 200 lines.
- Cross-link aggressively (relative paths). Don't duplicate facts — link to the canonical entry.
- If a memory file becomes outdated, fix it; don't wrap stale facts in caveats.
- No emojis in code, memory, or commits (user preference).

## Tooling-specific notes

- **Claude Code**: a `Stop` hook in [.claude/settings.json](.claude/settings.json) reminds you to update memory at end of session.
- **OpenAI Codex / Cursor / Aider**: discover this file automatically. No additional setup.
- **ChatGPT / other web LLMs**: paste this file into the conversation as system context, then paste the specific `docs/ai/` files relevant to your task.
- **XcodeBuildMCP**: use the installed XcodeBuildMCP skill before calling its tools.
