---
title: Release Process
status: stable
last_updated: 2026-05-13
tracks:
  - "fastlane/Fastfile"
  - "fastlane/Deliverfile"
  - "fastlane/Snapfile"
  - "ios-native/OasisNative.xcodeproj/**"
  - "Gemfile"
related:
  - "../codebase/build-and-test.md"
  - "secrets-and-keys.md"
  - "../marketing/aso-strategy.md"
---

# Release Process

How a new version of Oasis ships to the App Store.

## App identity

- **Bundle ID**: `com.jonathanluquet.drift` (set in `fastlane/Deliverfile`, `fastlane/Snapfile`, and `fastlane/Fastfile` lane args).
- **App Store Connect username**: `jonathanluquet@me.com` (in `fastlane/Deliverfile` and `fastlane/Fastfile`).
- **Display name**: Oasis.
- **Current version**: `MARKETING_VERSION = 1.4.1`, `CURRENT_PROJECT_VERSION = 3` (build).

Version is set in `OasisNative.xcodeproj/project.pbxproj`. Edit it directly or via Xcode's General tab.

## Versioning rules

- **Marketing version** — `MAJOR.MINOR.PATCH` (semver-ish):
  - MAJOR: a redesign or business-model shift (e.g. paywall change).
  - MINOR: meaningful new feature (new sounds bundle, binaural mode, …).
  - PATCH: bug fix, copy fix, asset re-encode.
- **Build number** — monotonically incrementing integer. Bump on every TestFlight upload, even if the marketing version doesn't change.

Recent history:
- `1.3.0` (build 1) — baseline.
- `1.4.0` (build 2) — redesigned interface + performance pass.
- `1.4.1` (build 3) — re-encoded all 20 nature sounds; replaced Train and Car with Sea and Mountain Storm; home timer countdown; ambient pad off by default.

## Pre-release checklist

Run from a clean working tree on `main`.

- [ ] Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project.
- [ ] Run the build CLI (see [../codebase/build-and-test.md](../codebase/build-and-test.md)) — must pass.
- [ ] Run `OasisNativePremiumFlowTests` — must pass.
- [ ] Re-render screenshots if any UI/copy changed: `bundle exec fastlane screenshots`. Then re-composite via `scripts/generate_store_screenshot_comps.swift`.
- [ ] Update `fastlane/metadata/<locale>/release_notes.txt` per locale — actual product changes, not "performance + bugs".
- [ ] Update memory: bump `last_updated` on any file affected by the release.
- [ ] Commit version bump + release notes + memory updates as one commit.

## Fastlane lanes

From repo root: `bundle exec fastlane <lane>`.

### `screenshots`

Captures all 10 scenarios in 6 locales on iPhone 17 Pro Max simulator. Output: `fastlane/screenshots/<locale>/iPhone 17 Pro Max-<slug>.png`.

- Bundle reused across locales (`clean: false`).
- Animation-quiescence guards apply (`WaveformSignatureLine`, `AnimatedLiquidAura`).
- `retries: 0` — fail fast.

### `app_previews`

Builds App Preview videos via [`scripts/generate_app_previews.rb`](../../../scripts/generate_app_previews.rb). One render serves all locales (no voice-over).

### `stage_appstore_assets`

Stages screenshots + previews into `fastlane/appstore-upload/<locale>/` so the upload lane has a clean source.

### `appstore_metadata`

Pushes `fastlane/metadata/<locale>/*.txt` only — no screenshots, no binary. Fast iteration on copy.

```bash
bundle exec fastlane appstore_metadata
```

Files that don't trigger Apple review: `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `support_url.txt`, `privacy_url.txt`, `marketing_url.txt`, `*_sub_category.txt`. Files that DO: `name.txt`, `subtitle.txt`, `description.txt`. See [../content/localization.md](../content/localization.md).

### `appstore_release`

Pushes screenshots + metadata for an existing binary version.

```bash
bundle exec fastlane appstore_release app_version:1.4.1
```

This is the typical "metadata + visuals" release lane — does not upload an `.ipa`.

## Binary upload (manual)

The `Fastfile` does not currently include a build-and-upload lane. Binary upload is done via Xcode → Archive → Distribute App → App Store Connect, signed with the team certificate.

If you need a CLI lane, add `gym` (or `xcodebuild archive` + `xcrun altool`) and document it here.

## Apple review timing

- **Binary**: 24–48 h.
- **Screenshots**: 24–48 h (counted as binary review).
- **`name.txt`, `subtitle.txt`, `description.txt`**: 24–48 h.
- **Everything else** (`keywords.txt`, `promotional_text.txt`, `release_notes.txt`, URLs, sub-categories): instant on push, no review.

Plan ASO experiments around this: a Variant A push that includes a name change is a 2-day cycle; a keyword-only push is same-day.

## Auth and credentials

- App Store Connect password is prompted at upload time (or stored in the Keychain by `fastlane`). Two-factor session lasts 30 days; expect prompts when launching from a fresh terminal.
- App-specific password might be required if the account uses a non-standard MFA.
- See [secrets-and-keys.md](secrets-and-keys.md) for which secrets exist and where.

## What ships in the IPA

- Compiled binary.
- All 24 `.m4a` files (20 ambient + 4 binaural) — ~310 MB.
- App icon, in-app images.
- `Localizable.xcstrings` (compiled into `.strings` per locale at build).
- `Info.plist` with `RevenueCatAPIKey`.

## What does NOT ship

- Anything in `fastlane/` (metadata, screenshots, scripts).
- Anything in `docs/`, `scripts/`, `.claude/`, `.githooks/`.
- The 4 ex-root MDs absorbed into memory.

## Rollback

App Store doesn't support binary rollback. If a release is broken:

1. Revert the offending commits on `main`.
2. Bump `CURRENT_PROJECT_VERSION` (build number must increase).
3. Re-archive, upload, expedited review request.
4. Optional: lower the price or remove the build from Sale temporarily via App Store Connect.

For metadata-only issues: re-push `fastlane appstore_metadata` immediately — no review delay for keywords / promo / release notes / URLs.
