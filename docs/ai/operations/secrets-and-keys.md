---
title: Secrets and Keys
status: stable
last_updated: 2026-05-20
tracks:
  - "ios-native/OasisNative/Support/Info.plist"
  - "ios-native/OasisNative/Mac/Info.plist"
  - "ios-native/OasisNative/Mac/OasisMac.entitlements"
  - "ios-native/OasisNative/Support/AppConfiguration.swift"
  - "fastlane/Deliverfile"
  - "fastlane/Fastfile"
related:
  - "release-process.md"
  - "../architecture/paywall.md"
---

# Secrets and Keys

Where every key lives, what it controls, and what to do if it's missing. **Values are not in this file** — only locations and shapes.

## RevenueCat

| Setting | Read from | Default | Required? |
| --- | --- | --- | --- |
| API key | env `OASIS_REVENUECAT_API_KEY` → target `Info.plist[RevenueCatAPIKey]` | (none — empty string) | Yes for purchase / restore |
| Entitlement ID | target `Info.plist[RevenueCatEntitlementID]` | `"premium"` | Yes |

Resolution order: env var first (lets local dev override), then the active target's `Info.plist`. iOS uses `Support/Info.plist`; macOS uses `Mac/Info.plist`. Both are read in [`AppConfiguration.swift`](../../../ios-native/OasisNative/Support/AppConfiguration.swift).

The RevenueCat client API key (the `appl_...` value) is **publishable** by design — RevenueCat's threat model expects it embedded in the binary. Don't conflate with the *secret* server API key, which never appears in the app.

`AppConfiguration.isRevenueCatConfigured` returns true when the resolved API key is non-empty. `Purchases.configure` is only called when this is true AND `shouldUseRevenueCatAccess` is true (i.e., not in `-OASISPremiumOverride free|premium` mode).

## TelemetryDeck

| Setting | Read from | Default | Required? |
| --- | --- | --- | --- |
| App ID | env `OASIS_TELEMETRYDECK_APP_ID` → target `Info.plist[TelemetryDeckAppID]` | empty | No — when empty, analytics no-op |

Currently empty in the app plists — TelemetryDeck is wired but not active. To enable: set the App ID either in env or the active target's `Info.plist`.

## App Store Connect

- Username: `jonathanluquet@me.com` (committed in `fastlane/Deliverfile` and `fastlane/Fastfile`).
- Password: prompted at upload time, or stored in the macOS Keychain by `fastlane`. Two-factor session lasts ~30 days.
- App-specific password: may be required depending on account MFA setup.

These are not committed.

## Apple developer / signing

- Team ID and certificates: managed via Xcode (Signing & Capabilities → Automatically manage signing).
- Provisioning profiles: auto-managed locally.
- macOS App Store sandboxing: `OasisMac` uses `Mac/OasisMac.entitlements` with `com.apple.security.app-sandbox = true` and `com.apple.security.network.client = true`. The network entitlement is needed for RevenueCat / StoreKit-related HTTP access; avoid broader entitlements unless a feature needs them.
- For CI: `match` (fastlane's signing helper) is **not** wired. Builds happen on Jonathan's local Mac.

## Local environment

- `.env` may exist at the repo root for local overrides. Used to set:
  - `OASIS_REVENUECAT_API_KEY` (override Info.plist for local dev / testing)
  - `OASIS_TELEMETRYDECK_APP_ID` (enable analytics locally)
- The app does **not** auto-load `.env`. The env vars must be set in the shell that launches Xcode or in the Xcode scheme's environment.

## Launch arguments (development overrides)

These bypass production settings during development, UI tests, and fastlane snapshots:

| Arg | Effect |
| --- | --- |
| `-OASISPremiumOverride free` | Force `isPremium = false`, skip RevenueCat. |
| `-OASISPremiumOverride premium` | Force `isPremium = true`, skip RevenueCat. |
| `-OASISPremiumOverride revenueCat` | Default — use real RevenueCat. |
| `-OASISResetState YES` | Wipe `UserDefaults["evasion-mixer-storage"]` on launch. |
| `-OASISRevenueCatDebugLogs` | Enable verbose RevenueCat SDK logs in Debug builds. |
| `-OASISImmersiveAudioEnabled YES|NO` | Force the global immersive audio toggle for deterministic screenshot/dev launches. |
| `-FASTLANE_SNAPSHOT YES` | Set automatically by fastlane; combines with the above. |
| `-ui_testing` | Set by XCUITest target; freezes auras / waveform. |

Defined in [`AppConfiguration.swift`](../../../ios-native/OasisNative/Support/AppConfiguration.swift). Premium override parsing lives under `DevelopmentPremiumOverride`; general launch-argument parsing lives in the `ProcessInfo` helpers at the bottom of the file.

## Secret hygiene

- Don't commit the RevenueCat **secret** API key (server-side) — it should never be in this repo.
- Don't commit `.env` content. The file is in `.gitignore` (only its presence is tracked).
- App Store Connect password / app-specific password: never committed; rely on Keychain or prompt.
- The publishable RevenueCat client key is in `Info.plist` and ships in the binary — that's intentional.

## What to do when keys go missing

| Symptom | Cause | Fix |
| --- | --- | --- |
| App launches but paywall is empty | `RevenueCatAPIKey` is empty or invalid | Set in `Info.plist` or `OASIS_REVENUECAT_API_KEY` env |
| Purchase tap does nothing | RevenueCat configure failed silently | Relaunch with `-OASISRevenueCatDebugLogs` and check the Xcode console |
| `appstore_metadata` lane fails with auth | ASC session expired | Re-run, fastlane will prompt |
| TelemetryDeck events don't appear | App ID empty | Set `TelemetryDeckAppID` |
| Premium override sticky after testing | Launch args persist in scheme | Clear from Xcode Scheme → Run → Arguments |
