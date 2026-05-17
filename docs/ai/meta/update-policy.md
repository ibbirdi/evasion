---
title: Memory Update Policy
status: stable
last_updated: 2026-05-17
tracks:
  - "AGENTS.md"
  - "docs/ai/**"
related:
  - "drift-check.md"
  - "../README.md"
---

# Memory Update Policy

The contract every AI agent must honour when working on Oasis. The high-level summary is in [AGENTS.md](../../../AGENTS.md); this file covers edge cases.

## When you must update memory

| You modified… | You must update… |
| --- | --- |
| `Services/AudioMixerEngine.swift` or `Services/TonalBedSynth.swift` | `architecture/audio-engine.md` |
| `Services/AppModel.swift` | `architecture/state.md` (and feature file if behaviour changed) |
| `Services/PremiumCoordinator.swift` or `Services/PremiumRevenueCatService.swift` | `architecture/paywall.md` |
| `Views/Overlays/PaywallOverlay.swift` | `architecture/paywall.md`, `marketing/positioning.md` (if pitch changed) |
| `Views/HomeView.swift`, `Views/Components/**` | `architecture/ui.md` |
| `Models/AppModels.swift` | `architecture/state.md`, plus `content/sounds-catalog.md` if `SoundChannel` cases changed |
| `Models/SoundChannelMetadata.swift` | `content/sounds-catalog.md` |
| `Support/AppConfiguration.swift`, `Support/Info.plist` | `operations/secrets-and-keys.md` |
| `Support/L10n.swift`, `Resources/Localizable.xcstrings` | `content/localization.md` (if a key family was added) |
| A `.m4a` file in `Assets/` | `content/sounds-catalog.md` (re-run loudnorm measurements!) |
| `fastlane/metadata/<locale>/*.txt` | `marketing/aso-strategy.md` |
| `fastlane/screenshots/...` or `figma-pro/` | `marketing/store-assets.md` |
| `Fastfile`, anything in `fastlane/` | `operations/release-process.md` |
| `scripts/**` | `codebase/build-and-test.md` |
| File renames, moves, deletions | `codebase/structure.md` |
| New convention or pattern adopted | `codebase/conventions.md` |

## When you do NOT need to update memory

- Whitespace, formatting, or comment-only edits
- Single-string copy tweak already in fastlane metadata
- Bug fixes that change neither contract nor observable surface
- Refactors that preserve public symbols, file paths, and persistent state

## How to update

1. **Find** memory entries whose `tracks:` field matches the file you changed:
   ```bash
   grep -l "AudioMixerEngine.swift" docs/ai/**/*.md
   ```
2. **Edit** only the sections that became different. Don't rewrite the file.
3. **Bump** `last_updated:` in the frontmatter to today (UTC).
4. **Cross-check** the `related:` field — propagate ripple effects.
5. **Run** `bash scripts/ai-memory/check-drift.sh` before considering the task done.

## Anti-patterns

- Don't add "Note: this might be outdated" — fix it instead.
- Don't duplicate code in memory. Link to file paths with line numbers.
- Don't write what the code already self-explains. Memory captures the *why* and the *non-obvious*.
- Don't extend a memory file past 200 lines — split into a sub-topic and update the index.
- Don't create a new memory file without adding it to [docs/ai/README.md](../README.md) and the file map.
- Don't paraphrase user feedback — keep it verbatim under "feedback" in `meta/changelog.md` if material.

## Universality reminder

The memory is consumed by Claude, GPT, Cursor, and humans. Avoid:
- Tool-specific syntax (no `@code-reviewer`, no `/command`)
- Assumed shell context (always say "from repo root, run …")
- Emojis (user preference)
- Implicit references to "the previous conversation" — every file must read cold

## Drift detection (summary)

See [drift-check.md](drift-check.md) for full mechanics. Three layers:

1. **`scripts/ai-memory/check-drift.sh`** — on-demand report.
2. **`.githooks/pre-commit`** — non-blocking warning at commit time. Activate once with `git config core.hooksPath .githooks`.
3. **Claude Code `Stop` hook** — reminder at end of session. Configured in [.claude/settings.json](../../../.claude/settings.json).
