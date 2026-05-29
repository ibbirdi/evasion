---
title: Paywall and Premium Gating
status: stable
last_updated: 2026-05-29
tracks:
  - "ios-native/OasisNative/Services/PremiumCoordinator.swift"
  - "ios-native/OasisNative/Services/PremiumRevenueCatService.swift"
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Views/Overlays/PaywallOverlay.swift"
  - "ios-native/OasisNative/Views/Mac/MacPaywallSheet.swift"
  - "ios-native/OasisNative/Views/Mac/MacInlineUpsellSheet.swift"
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
.preset, .binaural,
.composer, .ritual(<id>),
.noise(<id>)                     →  inline upsell first (if not yet shown for this entry point)
                                    →  full paywall on retry

.channel(<id>), .timer, .spatial,
.signature_preview, .home_banner,
.onboarding                      →  full paywall directly
```

The "if not yet shown for this entry point" memory is held in the coordinator (transient, not persisted). After dismissing the inline once, the next attempt opens the full paywall.

Shipped Premium ambiences are gated by `Preset.requiresPremium`: loading a default ambience whose active channels/noise/binaural/timer require Premium exits before mutation and calls `requestPremiumAccess(from: .presetLoad)`.

## State surface in `AppModel`

```swift
var activePaywallContext: PremiumPaywallContext?      // full paywall presentation
var activeInlineUpsell: PremiumInlineUpsellContext?   // inline upsell presentation
```

Setting either to non-nil triggers the corresponding SwiftUI presentation. iOS uses `PaywallOverlay` / `InlinePremiumUpsell`, while macOS uses [`MacPaywallSheet`](../../../ios-native/OasisNative/Views/Mac/MacPaywallSheet.swift) and [`MacInlineUpsellSheet`](../../../ios-native/OasisNative/Views/Mac/MacInlineUpsellSheet.swift) from the same model state.

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

The "Restore" button is exposed in both the iOS paywall and the macOS paywall sheet.

## Gating points (where the lock fires)

| Surface | Gate | Behaviour |
| --- | --- | --- |
| Channel card (mixer) | `isChannelLocked(_:)` | Tapping a locked channel calls `requestPremiumAccess(from: .channel(id))`. |
| Preset save/edit | Premium-only save/edit gate | Free users cannot persist or rename ambiences; tapping Save routes to the preset upsell before any preset is created. Premium users can rename and restyle any preset. |
| Preset load | `isPresetLocked(_:)` | Loading a preset that contains premium channels, premium noise, a premium binaural track, or a long timer routes to upsell. |
| Preset delete/export | `canDeletePreset(_:)` / `exportUserPresetsData()` | Premium users can delete any preset and export user-created presets for the iPhone-to-code authoring flow. User presets remain deletable after entitlement loss so a downgraded user can clean up personal saved state. Legacy built-in preset IDs are filtered on launch so removed pre-recorded ambiences do not come back. |
| Binaural panel | `selectBinauralTrack(_:)` | Tapping Theta/Alpha/Beta as free user → inline upsell. |
| Timer menu | `canUseTimer(_:)` | 60 / 120 min options route to paywall. |
| My Ambiences | `applyAmbienceRecipe(_:)` | Free saved ambiences apply directly; locked saved ambiences and any recipe that requires inaccessible premium content route to the premium-ambience inline upsell first, then the paywall. |
| Rituals | `startRitual(_:)` | Free users can start the free Sleep Descent ritual; premium rituals route to the Composer inline upsell first, then the paywall. |
| Noise Lab | `toggleProceduralNoise(_:)` / `setProceduralNoiseVolume(_:)` | Premium noise layers route to the Composer inline upsell first, then the paywall when locked. |
| Spatial panel | inherits channel lock | Premium channels remain greyed out in the minimap. |
| Signature preview | `signaturePreviewLastPlayedAt` cooldown + `isPremium` + shipped signature presence | Free users get a 45 s preview only when a signature preset exists, throttled to once per week. |
| Onboarding final page | `completeOnboarding(..., presentPaywall: true)` | Primary final CTA completes onboarding and opens the full paywall; secondary CTA enters the free tier. |
| Home banner | `showsPremiumHomeBanner` | Dismissable; cooldown via `premiumBannerLastDismissedAt`. |

`enforcePremiumAccess()` (in [`AppModel`](../../../ios-native/OasisNative/Services/AppModel.swift)) is called on every premium state change. It mutes premium channels and premium noise layers, resets the active binaural track to `.delta`, and clamps the timer if the user just lost premium (e.g. refund). See [state.md](state.md).

## Paywall copy & context

`PremiumPaywallContext` carries which feature triggered the paywall. The `PaywallOverlay` view selects:
- A title variant (generic vs feature-targeted).
- A beach/photo-backed lifetime hero. The hero and full-screen backdrop use `paywall_beach_background` (Pexels 673865 by Pok Rie), with a sand/foam/water palette rather than the older green aurora treatment. The "one purchase / lifetime access / no subscription" trust line is the first visual claim, and the feature subtitle is shortened to the first useful sentence to avoid repeating the subscription message.
- A compact 2x2 benefit tile grid with distinct SF Symbols and the triggering feature pinned first. Every full paywall context should include the Premium noise value somewhere in those four tiles (`4 bruits en plus` / 4 extra noise layers), alongside sounds, ambiences, timer, or binaural as context demands. Keep these tiles scannable; avoid returning to long checkmark lists.
- The "price of coffee and a croissant in Paris" anchor — keep Paris across all locales, with natural local food phrasing (e.g. Italian `cornetto`).

Localisation: every paywall string is in `Localizable.xcstrings` under `paywall.*` and `premium.inline.*`.

Legacy composer, ritual, and Noise Lab entry points still share the internal `.composer` accent/category, but visible copy must not sell a "Composer" screen. The inline card, paywall title, and benefits should talk about richer premium ambiences, noise cover, premium binaural support, and longer fade-outs rather than a removed feature or technical procedural-noise wording.

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
- `premium` → `isPremium = true`, no RevenueCat calls. Used by every screenshot scenario except `08_free_home` and `10_paywall`; `09_noise` uses Premium so the extra noise layers are visible.
- `revenueCat` (default) → normal flow.

Defined in [`DevelopmentPremiumOverride`](../../../ios-native/OasisNative/Support/AppConfiguration.swift). Non-premium launch arguments, such as the App Store screenshot immersive-audio override, live beside it in `AppConfiguration`.
