---
title: Memory Drift Check
status: stable
last_updated: 2026-05-03
tracks:
  - "scripts/ai-memory/**"
  - ".githooks/pre-commit"
  - ".claude/settings.json"
related:
  - "update-policy.md"
---

# Memory Drift Check

How automatic memory-staleness detection works.

## Three drift sources

1. **Stale memory** — a source file listed in `tracks:` was modified after `last_updated:`.
2. **Orphan source** — a Swift/Plist/metadata file exists but no memory entry tracks it.
3. **Dead reference** — a `tracks:` glob matches no file (renamed or deleted source).

## Tooling layers

### `scripts/ai-memory/check-drift.sh` — on demand

Run from repo root:

```bash
bash scripts/ai-memory/check-drift.sh
```

Exit code: `0` if memory is fresh, `1` otherwise. Output groups findings by drift source and lists exact paths.

### `.githooks/pre-commit` — at commit time

Non-blocking warning. Activate once per clone:

```bash
git config core.hooksPath .githooks
```

If you stage source files matching any tracked pattern but no `docs/ai/**` file, the hook prints a warning and lets the commit proceed. Bypass with `--no-verify` only when justified — that's how memory rots.

### Claude Code `Stop` hook — at end of session

Configured in [.claude/settings.json](../../../.claude/settings.json). At the end of a Claude Code session, if the working tree contains modifications to source files but none under `docs/ai/`, the hook prints a reminder injected back to the agent so it can self-correct or surface to the user.

## Writing a good `tracks:` field

Use the most specific patterns possible. Specificity reduces false positives.

Good:
```yaml
tracks:
  - "ios-native/OasisNative/Services/AudioMixerEngine.swift"
  - "ios-native/OasisNative/Services/TonalBedSynth.swift"
```

Acceptable:
```yaml
tracks:
  - "ios-native/OasisNative/Views/Overlays/PaywallOverlay.swift"
  - "ios-native/OasisNative/Services/Premium*.swift"
```

Avoid:
```yaml
tracks:
  - "ios-native/**"   # too broad, every iOS edit triggers staleness
```

## What is NOT tracked (and shouldn't be)

The drift script excludes by default:

- Build artifacts: `build/`, `DerivedData/`, `*.xcuserstate`, `xcuserdata/`
- Lock files: `Gemfile.lock`, `Podfile.lock`
- VCS internal: `.git/`, `.claude/worktrees/`, `.DS_Store`
- Generated assets: `fastlane/screenshots/*/iPhone*.png` (raw captures), `fastlane/buildlogs/`
- This file (`meta/drift-check.md`) and `meta/changelog.md` — structural

## Frequency

Aim for: every commit that touches source code = a commit that also touches the relevant memory. The pre-commit hook nudges you when you forget. Treat the warning seriously — over time, ignored warnings become divergent memory.
