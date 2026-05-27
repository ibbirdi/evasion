---
title: Premium Model
status: stable
last_updated: 2026-05-27
tracks:
  - "ios-native/OasisNative/Services/PremiumCoordinator.swift"
  - "ios-native/OasisNative/Services/PremiumRevenueCatService.swift"
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Models/PremiumModels.swift"
  - "ios-native/OasisNative/Models/AmbienceModels.swift"
  - "ios-native/OasisNative/Views/Overlays/PaywallOverlay.swift"
  - "ios-native/OasisNative/Views/Mac/MacPaywallSheet.swift"
  - "ios-native/OasisNative/Views/Mac/MacInlineUpsellSheet.swift"
  - "ios-native/OasisNative/Support/AppConfiguration.swift"
  - "ios-native/OasisNative/Support/Info.plist"
  - "ios-native/OasisNative/Mac/Info.plist"
related:
  - "vision.md"
  - "../architecture/paywall.md"
  - "../operations/secrets-and-keys.md"
---

# Premium Model

## Free vs premium matrix

| Feature | Free | Premium |
| --- | --- | --- |
| Ambient channels | 3 (Birds / Wind / Beach) | All 35 |
| Mixer (volume, mute, auto-variation) | On the 3 free channels | All channels |
| Random mix | Yes, restricted to free channels | Yes, full library |
| Sound placement | Yes, on accessible channels | Yes, on accessible channels |
| Binaural tracks | Delta only | Delta / Theta / Alpha / Beta |
| Guided routines | 2 prepared routines: Short nap and Soft reset, both limited to free ambient channels, free noises, Delta or no binaural, and timers ≤ 30 min | 6 additional prepared routines: Deep sleep, Deep work, Noisy hotel, Evening reading, Rain cabin, and Gentle morning, with full-library channels, premium noises, binaural modes, longer timers where useful, and `+N` UI overflow when there are many audible layers |
| Procedural noise engine | Used behind guided routines where helpful | Premium-only layers remain gated when surfaced by future UX |
| Sleep timer | 15 / 30 min | 15 / 30 / 60 / 120 min |
| Presets | 1 saved user ambience | Create, load, delete, reorder full ambience snapshots |
| Saved presets cap | 1 | Unlimited |
| Restoration | N/A | Yes |

## Purchase model

- **Type**: one-time lifetime purchase. No subscription. No trial.
- **Provider**: RevenueCat Apple-platform SDK.
- **Entitlement ID**: `premium` (read from `Info.plist` `RevenueCatEntitlementID`, defaults to `"premium"` if missing).
- **Offering**: the *current* offering (configurable in RevenueCat dashboard). At time of writing, named `RCpremium`. The code does not depend on the offering name, only on the offering being marked current.
- **Package**: `$rc_lifetime`.
- **App Store product**: `premium`. Keep it available to the macOS platform in the same App Store Connect app record so the lifetime unlock behaves as a Universal Purchase across iOS and macOS.

The "no subscription, ever" stance is the **primary moat** and is repeated in screenshot 10 (paywall), the paywall copy, the multi-locale store description, and release notes. On iOS, `PaywallOverlay` makes this the first visual claim in the organic hero and keeps the purchase path to one dominant lifetime CTA. Don't introduce subscription mechanics without the user explicitly authorizing it (see user feedback `feedback_no_subscription`).

## Pricing copy

The paywall anchors the price as "less than the price of a coffee in Paris" / "moins qu'un café à Paris" — confirmed converting (commits `e4ba1e6`, `2b9072a`). Keep "Paris" anchor across all locales. If RevenueCat pricing changes, recheck this metaphor still holds.

## Coordinator flow

[`PremiumCoordinator`](../../../ios-native/OasisNative/Services/PremiumCoordinator.swift) decides whether a premium request shows an inline upsell first or jumps straight to the full paywall:

- `.preset`, `.binaural`, `.composer`, `.ritual`, and `.noise` entry points → inline upsell first; if dismissed and re-triggered, full paywall.
- All other entry points (`.channel`, `.timer`, `.spatial`, `.signature_preview`, `.home_banner`, …) → full paywall directly.

The active context is exposed via `AppModel.activePaywallContext` (full paywall) and `AppModel.activeInlineUpsell` (inline upsell). iOS and macOS observe the same state and present platform-specific paywall surfaces.

The onboarding final page has an explicit premium moment: the primary CTA completes onboarding and opens the lifetime paywall (`.onboarding` source), while the secondary CTA starts the free tier without opening the paywall. Keep this transparent; do not hide the paywall behind a generic "start listening" action.

## Banner & previews

Two engagement nudges, both throttled in `AppModel`:

- **Premium home banner** — dismissable; reappears after a cooldown driven by `premiumBannerLastDismissedAt`.
- **Signature preset preview** — 45-second taste of the signature mix. Throttled to 1 per week via `signaturePreviewLastPlayedAt` to keep the preview valuable without becoming a daily substitute for Premium.

## Override for development & screenshots

`-OASISPremiumOverride free|premium|revenueCat` launch argument forces a state (defaults to RevenueCat). Used heavily by UI tests and fastlane snapshots. `-OASISRevenueCatDebugLogs` opt-ins to verbose RevenueCat logs for purchase debugging; normal Debug launches keep SDK warnings quiet. Other screenshot-only launch arguments, such as `-OASISImmersiveAudioEnabled`, live beside these in [`AppConfiguration.swift`](../../../ios-native/OasisNative/Support/AppConfiguration.swift).

## Restore

`AppModel.restorePurchases()` calls `PremiumRevenueCatService.restorePurchases()` → broadcasts via `RevenueCatObserver.onCustomerInfoChange` → `applyCustomerInfo()`. Available from the iOS paywall and the macOS menu bar paywall sheet.

## Reactive entitlement

`RevenueCatObserver` listens to RevenueCat customer-info updates. Every change calls `AppModel.applyCustomerInfo(_:)` which re-derives `isPremium` and triggers `enforcePremiumAccess()` to mute/lock channels that became inaccessible (e.g. after refund). See [../architecture/state.md](../architecture/state.md) for that flow.
