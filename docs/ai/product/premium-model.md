---
title: Premium Model
status: stable
last_updated: 2026-05-17
tracks:
  - "ios-native/OasisNative/Services/PremiumCoordinator.swift"
  - "ios-native/OasisNative/Services/PremiumRevenueCatService.swift"
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Views/Overlays/PaywallOverlay.swift"
  - "ios-native/OasisNative/Support/AppConfiguration.swift"
  - "ios-native/OasisNative/Support/Info.plist"
related:
  - "vision.md"
  - "../architecture/paywall.md"
  - "../operations/secrets-and-keys.md"
---

# Premium Model

## Free vs premium matrix

| Feature | Free | Premium |
| --- | --- | --- |
| Ambient channels | 3 (Birds / Wind / Beach) | All 20 |
| Mixer (volume, mute, auto-variation) | On the 3 free channels | All channels |
| Random mix | Yes, restricted to free channels | Yes, full library |
| Sound placement | Yes, on accessible channels | Yes, on accessible channels |
| Binaural tracks | Delta only | Delta / Theta / Alpha / Beta |
| Sleep timer | 15 / 30 min | 15 / 30 / 60 / 120 min |
| Presets panel | Hidden in UI | Create, load, delete, reorder |
| Saved presets cap | 1 | Unlimited |
| Tonal bed (harmonic pad) | On free channels | On all accessible channels |
| Restoration | N/A | Yes |

## Purchase model

- **Type**: one-time lifetime purchase. No subscription. No trial.
- **Provider**: RevenueCat iOS SDK.
- **Entitlement ID**: `premium` (read from `Info.plist` `RevenueCatEntitlementID`, defaults to `"premium"` if missing).
- **Offering**: the *current* offering (configurable in RevenueCat dashboard). At time of writing, named `RCpremium`. The code does not depend on the offering name, only on the offering being marked current.
- **Package**: `$rc_lifetime`.
- **App Store product**: `premium`.

The "no subscription, ever" stance is the **primary moat** and is repeated in screenshot 10 (paywall), the paywall copy, the multi-locale store description, and release notes. Don't introduce subscription mechanics without the user explicitly authorizing it (see user feedback `feedback_no_subscription`).

## Pricing copy

The paywall anchors the price as "less than the price of a coffee in Paris" / "moins qu'un café à Paris" — confirmed converting (commits `e4ba1e6`, `2b9072a`). Keep "Paris" anchor across all locales. If RevenueCat pricing changes, recheck this metaphor still holds.

## Coordinator flow

[`PremiumCoordinator`](../../../ios-native/OasisNative/Services/PremiumCoordinator.swift) decides whether a premium request shows an inline upsell first or jumps straight to the full paywall:

- `.preset`, `.binaural` entry points → inline upsell first; if dismissed and re-triggered, full paywall.
- All other entry points (`.channel`, `.timer`, `.spatial`, `.signature_preview`, `.home_banner`, …) → full paywall directly.

The active context is exposed via `AppModel.activePaywallContext` (full paywall) and `AppModel.activeInlineUpsell` (inline upsell). Views observe these and present accordingly.

The onboarding final page has an explicit premium moment: the primary CTA completes onboarding and opens the lifetime paywall (`.onboarding` source), while the secondary CTA starts the free tier without opening the paywall. Keep this transparent; do not hide the paywall behind a generic "start listening" action.

## Banner & previews

Two engagement nudges, both throttled in `AppModel`:

- **Premium home banner** — dismissable; reappears after a cooldown driven by `premiumBannerLastDismissedAt`.
- **Signature preset preview** — 45-second taste of the signature mix. Throttled to 1 per week via `signaturePreviewLastPlayedAt` to keep the preview valuable without becoming a daily substitute for Premium.

## Override for development & screenshots

`-OASISPremiumOverride free|premium|revenueCat` launch argument forces a state (defaults to RevenueCat). Used heavily by UI tests and fastlane snapshots. See [`AppConfiguration.swift`](../../../ios-native/OasisNative/Support/AppConfiguration.swift) `DevelopmentPremiumOverride`.

## Restore

`AppModel.restorePurchases()` calls `PremiumRevenueCatService.restorePurchases()` → broadcasts via `RevenueCatObserver.onCustomerInfoChange` → `applyCustomerInfo()`. Available from the paywall and presumably an "About" screen.

## Reactive entitlement

`RevenueCatObserver` listens to RevenueCat customer-info updates. Every change calls `AppModel.applyCustomerInfo(_:)` which re-derives `isPremium` and triggers `enforcePremiumAccess()` to mute/lock channels that became inaccessible (e.g. after refund). See [../architecture/state.md](../architecture/state.md) for that flow.
