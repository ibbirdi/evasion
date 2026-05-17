---
title: Paywall and Premium Gating
status: stable
last_updated: 2026-05-17
tracks:
  - "ios-native/OasisNative/Services/PremiumCoordinator.swift"
  - "ios-native/OasisNative/Services/PremiumRevenueCatService.swift"
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Views/Overlays/PaywallOverlay.swift"
  - "ios-native/OasisNative/Models/PremiumModels.swift"
related:
  - "../product/premium-model.md"
  - "state.md"
  - "../operations/secrets-and-keys.md"
---

# Paywall and Premium Gating

Where free becomes paid. The contract is set by [../product/premium-model.md](../product/premium-model.md); this file documents the wiring.

## RevenueCat configuration

| Setting | Source | Default | Notes |
| --- | --- | --- | --- |
| API key | Env `OASIS_REVENUECAT_API_KEY` → `Info.plist[RevenueCatAPIKey]` | (none) | Configured at app start by `OasisNativeApp`. |
| Entitlement ID | `Info.plist[RevenueCatEntitlementID]` | `"premium"` | The code is agnostic to the value, but **don't change** it without migrating existing users (the dashboard binds product to entitlement). |
| Offering | RevenueCat dashboard → "current offering" | `RCpremium` (today) | The code uses the offering marked *current*; the name `RCpremium` is dashboard-side only. |
| Package | `$rc_lifetime` | (RC default) | `Purchases.shared.offerings().current.lifetime` |

`AppConfiguration.shouldUseRevenueCatAccess` returns `false` when `-OASISPremiumOverride free|premium` is passed (UI tests, fastlane). In that mode RevenueCat is never queried.

## Coordinator routing

[`PremiumCoordinator`](../../../ios-native/OasisNative/Services/PremiumCoordinator.swift) takes a `PremiumEntryPoint` and returns either an inline-upsell context or a full-paywall context.

```
.preset, .binaural               →  inline upsell first (if not yet shown for this entry point)
                                    →  full paywall on retry

.channel(<id>), .timer, .spatial,
.signature_preview, .home_banner,
.onboarding                      →  full paywall directly
```

The "if not yet shown for this entry point" memory is held in the coordinator (transient, not persisted). After dismissing the inline once, the next attempt opens the full paywall.

## State surface in `AppModel`

```swift
var activePaywallContext: PremiumPaywallContext?      // full paywall presentation
var activeInlineUpsell: PremiumInlineUpsellContext?   // inline upsell presentation
```

Setting either to non-nil triggers the corresponding SwiftUI presentation (a `.fullScreenCover` for paywall, a `.sheet` or in-flow card for inline).

`requestPremiumAccess(from:)` is the single entry to ask for premium. Don't call `Purchases` directly from views — go through the coordinator.

## Purchase flow

```
View → AppModel.purchaseLifetime(package:)
     → PremiumRevenueCatService.purchase(package:)
     → Purchases.shared.purchase(package:)
     → on success: applyCustomerInfo(updatedCustomerInfo)
     → isPremium = true
     → enforcePremiumAccess()  (relock nothing — this just unlocks)
     → activePaywallContext = nil
```

## Restore flow

```
View → AppModel.restorePurchases()
     → PremiumRevenueCatService.restorePurchases()
     → Purchases.shared.restorePurchases()
     → broadcasts via RevenueCatObserver.onCustomerInfoChange
     → AppModel.applyCustomerInfo(...)
```

The "Restore" button is exposed in the paywall and (typically) in an "About" view.

## Gating points (where the lock fires)

| Surface | Gate | Behaviour |
| --- | --- | --- |
| Channel card (mixer) | `isChannelLocked(_:)` | Tapping a locked channel calls `requestPremiumAccess(from: .channel(id))`. |
| Preset save | `canSaveFreePreset` | Free tier capped at 1 preset; the second save attempt routes to upsell. |
| Preset load | `isPresetLocked(_:)` | Loading a preset that contains premium channels in non-zero state routes to upsell. |
| Binaural panel | `selectBinauralTrack(_:)` | Tapping Theta/Alpha/Beta as free user → inline upsell. |
| Timer menu | `canUseTimer(_:)` | 60 / 120 min options route to paywall. |
| Spatial panel | inherits channel lock | Premium channels remain greyed out in the minimap. |
| Signature preview | `signaturePreviewLastPlayedAt` cooldown + `isPremium` | Free users get a 45 s preview, throttled to once per week. |
| Onboarding final page | `completeOnboarding(..., presentPaywall: true)` | Primary final CTA completes onboarding and opens the full paywall; secondary CTA enters the free tier. |
| Home banner | `showsPremiumHomeBanner` | Dismissable; cooldown via `premiumBannerLastDismissedAt`. |

`enforcePremiumAccess()` (in [`AppModel`](../../../ios-native/OasisNative/Services/AppModel.swift)) is called on every premium state change. It mutes premium channels, resets the active binaural track to `.delta`, and clamps the timer if the user just lost premium (e.g. refund). See [state.md](state.md).

## Paywall copy & context

`PremiumPaywallContext` carries which feature triggered the paywall. The `PaywallOverlay` view selects:
- A title variant (generic vs feature-targeted).
- A list of benefits, with the triggering feature pinned at the top.
- The "price of a coffee in Paris" anchor — keep across all locales (commits `2b9072a`, `e4ba1e6`).

Localisation: every paywall string is in `Localizable.xcstrings` under `paywall.*` and `premium.inline.*`.

## Analytics

`PremiumAnalytics` (with `TelemetryDeckAnalyticsSink`) emits:

- `paywall_shown` { context }
- `paywall_dismissed` { context, reason }
- `purchase_started` / `purchase_succeeded` / `purchase_failed`
- `inline_shown` / `inline_dismissed` { context }
- `signature_preview_started` / `signature_preview_finished`
- `restore_succeeded` / `restore_failed`

These flow through TelemetryDeck (when `TelemetryDeckAppID` is configured) and into `PremiumAnalytics` for in-app debug overlays. See [../operations/secrets-and-keys.md](../operations/secrets-and-keys.md).

## Override for development & UI tests

`-OASISPremiumOverride free|premium|revenueCat` bypasses RevenueCat entirely:

- `free` → `isPremium = false`, no RevenueCat calls.
- `premium` → `isPremium = true`, no RevenueCat calls. Used by every screenshot scenario except `08_free_home`, `09_library_teaser`, `10_paywall`.
- `revenueCat` (default) → normal flow.

Defined in [`DevelopmentPremiumOverride`](../../../ios-native/OasisNative/Support/AppConfiguration.swift).
