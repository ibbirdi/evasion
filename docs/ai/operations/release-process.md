---
title: Release Process
status: stable
last_updated: 2026-05-22
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
- **Targets**: `OasisNative` (iOS App Store binary) and `OasisMac` (macOS menu bar binary in the same App Store Connect app record via Add Platform / Universal Purchase).
- **App Store Connect username**: `jonathanluquet@me.com` (in `fastlane/Deliverfile` and `fastlane/Fastfile`).
- **Display name**: Oasis.
- **Mac App Store category**: `public.app-category.healthcare-fitness` (`LSApplicationCategoryType` in `Mac/Info.plist`), matching the committed fastlane primary category.
- **Current iOS version**: `MARKETING_VERSION = 1.5.1`, `CURRENT_PROJECT_VERSION = 7` (build).
- **Current iOS deployment target**: iOS 17.0. Version 1.5.1 is the audience-unlock patch prepared to remove the public iOS 18+ install requirement.
- **Current macOS version**: `MARKETING_VERSION = 1.0.0`, `CURRENT_PROJECT_VERSION = 1` (build).

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
- `1.4.2` (build 4) — ASO / release-note refresh for the current feature set; no-subscription and offline positioning brought forward.
- `1.4.3` (build 5) — sound-detail attribution simplification plus refreshed localized App Store screenshots and previews.
- `1.5.0` (build 6) — immersive audio mode, richer 35-sound catalogue positioning, refined presets flow, updated App Store visuals, and UI polish.
- `1.5.1` (build 7) — iOS 17+ deployment-target audience unlock for the download growth sprint.

## Pre-release checklist

Run from a clean working tree on `main`.

- [ ] Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project.
- [ ] Run the iOS build CLI (see [../codebase/build-and-test.md](../codebase/build-and-test.md)) — must pass.
- [ ] Run the release preflight: `node scripts/acquisition/check-release-readiness.mjs`. For upload, it must report `Verdict: ready`.
- [ ] If touching shared code used by the menu bar app, also run the `OasisMac` Debug build.
- [ ] Before uploading macOS, run the `OasisMac` Release build and confirm `CODE_SIGN_ENTITLEMENTS = OasisNative/Mac/OasisMac.entitlements`.
- [ ] For the first macOS release, add the macOS platform to the existing Oasis app record in App Store Connect; do not create a separate app record.
- [ ] Run `OasisNativePremiumFlowTests` — must pass.
- [ ] Re-render iOS screenshots if any iOS UI/copy changed: `bundle exec fastlane screenshots` (filtered to the App Store screenshot test), then `swift scripts/generate_store_screenshot_comps.swift` and `bundle exec fastlane stage_appstore_assets`. App Preview videos are currently excluded from staging/upload for `1.5.1`.
  - Keep snapshot launch flags in one combined `launch_arguments` string; multiple array entries produce multiple full locale passes.
- [ ] Re-render macOS screenshots if the menu bar app, macOS copy, or Mac App Store visuals changed: `bundle exec fastlane mac_appstore_screenshots`. Upload-ready files land in `fastlane/appstore-upload-macos/<locale>/`.
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

Builds local App Preview videos via [`scripts/generate_app_previews.rb`](../../../scripts/generate_app_previews.rb). The videos are visually silent and generated from the localized screenshot composites, but still include a silent stereo AAC audio track because App Store Connect rejects no-audio MP4s. As of 2026-05-19, these videos are not staged/uploaded because the current App Store previews were stale and removed.

### `mac_appstore_screenshots`

Builds `OasisMac`, captures 5 real menu bar panel scenarios in 6 locales, composites them into `2880 × 1800` JPEG masters, and stages upload-ready files under `fastlane/appstore-upload-macos/<locale>/`. Use `mac_screenshots` and `mac_appstore_assets` separately when iterating on capture state versus composition.

### `mac_appstore_release`

Pushes macOS screenshots + metadata for an existing macOS binary version. It uses `platform: "osx"`, reads upload-ready screenshots from `fastlane/appstore-upload-macos/<locale>/`, validates all 30 staged screenshots exist, and does not upload a binary.

```bash
bundle exec fastlane mac_appstore_release app_version:1.0.0
```

### `stage_appstore_assets`

Stages screenshots into `fastlane/appstore-upload/<locale>/` so the upload lane has a clean source. Screenshot files are renamed to the Variant B display order documented in [../marketing/aso-strategy.md](../marketing/aso-strategy.md). App Preview MP4s are intentionally excluded.

### `appstore_metadata`

Pushes `fastlane/metadata/<locale>/*.txt` only — no screenshots, no binary. Fast iteration on copy.

```bash
bundle exec fastlane appstore_metadata
```

Files that don't trigger Apple review: `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `support_url.txt`, `privacy_url.txt`, `marketing_url.txt`, `*_sub_category.txt`. Files that DO: `name.txt`, `subtitle.txt`, `description.txt`. See [../content/localization.md](../content/localization.md).

### `appstore_release`

Pushes screenshots + metadata for an existing binary version. It does not upload App Preview videos unless staging is explicitly re-enabled.

```bash
bundle exec fastlane appstore_release app_version:1.5.1
```

This is the typical "metadata + visuals" release lane — does not upload an `.ipa`.

## Binary upload

Use the `build_and_upload` lane to archive, export an App Store IPA, and upload it to TestFlight/App Store Connect:

```bash
bundle exec fastlane build_and_upload ipa_name:OasisNative-1.5.1-b7.ipa
```

The lane writes the IPA to `fastlane/builds/`, build logs to `fastlane/buildlogs/`, uploads with `upload_to_testflight`, and skips automatic submission. If Fastlane authentication is not available, use Xcode → Archive → Distribute App → App Store Connect as the manual fallback with the same team certificate.

If archive succeeds but export fails with `No signing certificate "iOS Distribution" found`, Xcode is currently signing the archive with an Apple Development identity. Refresh the Apple ID in Xcode, install the App Store distribution certificate/profile for team `346GF2QVCC`, then rerun the lane against the same version/build.

Use the acquisition preflight to confirm the blocker is gone:

```bash
node scripts/acquisition/check-release-readiness.mjs
```

It writes `scripts/acquisition/release-readiness.md` and `.json`, checking the current `OasisNative` version/build, latest archive, local signing identities, and the last Fastlane archive log.

### macOS platform upload

Use the existing App Store Connect app record for Oasis and add the macOS platform there. `OasisMac` intentionally shares `PRODUCT_BUNDLE_IDENTIFIER = com.jonathanluquet.drift` with iOS so the Mac binary is attached to the same Universal Purchase rather than a separate app.

Archive with the `OasisMac` scheme and a macOS destination, then upload through Xcode Organizer. The target uses `Mac/OasisMac.entitlements`: App Sandbox is required for Mac App Store distribution, and outbound network client access is enabled for RevenueCat / StoreKit-related requests. Test purchase and restore on macOS before review because the lifetime premium entitlement must unlock both iOS and macOS from the same App Store product.

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
- All 39 `.m4a` files (35 ambient + 4 binaural) — ~426 MB.
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
