# Memory Changelog

Material changes to the memory itself (not to the code it documents). Append entries — newest on top.

## 2026-05-03 — Memory bootstrapped

- Created [`AGENTS.md`](../../../AGENTS.md) universal entrypoint at repo root.
- Created [`docs/ai/`](..) structure with 6 sections (`product/`, `architecture/`, `codebase/`, `content/`, `marketing/`, `operations/`) plus `meta/`.
- Absorbed and deleted 4 legacy root MDs:
  - `AUDIT_ASO_OASIS.md` → [`marketing/aso-strategy.md`](../marketing/aso-strategy.md) + [`marketing/positioning.md`](../marketing/positioning.md)
  - `COWORK_BRIEF_APP_STORE_ASSETS.md` → [`marketing/store-assets.md`](../marketing/store-assets.md)
  - `DESIGN_BRIEF_APP_STORE_SCREENSHOTS.md` → [`marketing/store-assets.md`](../marketing/store-assets.md) (the v3 spec from this brief overrides the older Cowork brief — see file)
  - `FREESOUND_SOURCES.md` → [`content/sounds-catalog.md`](../content/sounds-catalog.md)
- Reduced root [`README.md`](../../../README.md) to a short pitch + pointer to `AGENTS.md` (no duplication of detail).
- Added drift detection: `scripts/ai-memory/check-drift.sh`, `.githooks/pre-commit`, Claude Code `Stop` hook in `.claude/settings.json`.
- Replaced the old `ios-native/AGENTS.md` (was a one-liner about XcodeBuildMCP) with a pointer to the root `AGENTS.md`.
