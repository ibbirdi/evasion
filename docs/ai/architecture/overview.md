---
title: Architecture Overview
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/OasisNativeApp.swift"
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Services/GentleReminderScheduler.swift"
  - "ios-native/OasisNative/Views/RootView.swift"
related:
  - "audio-engine.md"
  - "state.md"
  - "paywall.md"
  - "ui.md"
  - "../codebase/structure.md"
---

# Architecture Overview

Oasis is a single-target iOS native app. SwiftUI for everything visible, AVFoundation under the hood, RevenueCat for entitlement, UserDefaults for persistence. No backend.

## Module map

```
              ┌────────────────────────┐
              │   OasisNativeApp       │  ← @main, configures Purchases + TelemetryDeck
              └────────────┬───────────┘
                           │ holds
                           ▼
              ┌────────────────────────┐
              │   AppModel             │  ← @Observable, @MainActor, source of truth
              └─┬───────┬───────┬──────┘
                │       │       │
        owns    │  uses │       │ uses
                ▼       ▼       ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐
   │ AudioMixer   │ │ Premium      │ │ RevenueCatObserver       │
   │ Engine       │ │ Coordinator  │ │ + PremiumRevenueCatSvc   │
   └──────────────┘ └──────────────┘ └──────────────────────────┘
                │
                │ uses
                ▼
              ┌────────────────────────┐
              │ GentleReminderScheduler│  ← local re-open reminder after inactivity
              └────────────────────────┘

              ┌────────────────────────┐
              │   RootView             │  ← onboarding, root navigation
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   HomeView             │  ← mixer board, header, playback
              └────────────────────────┘
                  ▲     ▲     ▲     ▲
                  │     │     │     │  .sheet / .fullScreenCover
                  │     │     │     │
        PresetsPanel  Binaural  Spatial  Paywall
                      Panel    Panel   Overlay
```

## Key actors

| Actor | File | Role |
| --- | --- | --- |
| `OasisNativeApp` | [OasisNativeApp.swift](../../../ios-native/OasisNative/OasisNativeApp.swift) | Entry point. Configures `Purchases` (RevenueCat) and TelemetryDeck. Instantiates `AppModel`. |
| `AppModel` | [Services/AppModel.swift](../../../ios-native/OasisNative/Services/AppModel.swift) | Hub. `@Observable @MainActor`. Owns mix state, per-channel auto-variation ranges, immersive audio toggle, presets, premium state, timer, engagement metrics. Bridges UI ↔ engine ↔ RevenueCat. See [state.md](state.md). |
| `AudioMixerEngine` | [Services/AudioMixerEngine.swift](../../../ios-native/OasisNative/Services/AudioMixerEngine.swift) | The audio graph. `AVAudioEngine` + `AVAudioEnvironmentNode` + 35 `AVAudioPlayerNode`. Handles loops, fades, spatial/immersive profiles, remote commands. See [audio-engine.md](audio-engine.md). |
| `GentleReminderScheduler` | [Services/GentleReminderScheduler.swift](../../../ios-native/OasisNative/Services/GentleReminderScheduler.swift) | Local notification scheduler. Requests provisional alert permission after onboarding, cancels pending reminders on app open, and schedules one gentle re-open reminder after several inactive days. |
| `PremiumCoordinator` | [Services/PremiumCoordinator.swift](../../../ios-native/OasisNative/Services/PremiumCoordinator.swift) | Routes premium requests to inline-upsell or full-paywall. See [paywall.md](paywall.md). |
| `PremiumRevenueCatService` | [Services/PremiumRevenueCatService.swift](../../../ios-native/OasisNative/Services/PremiumRevenueCatService.swift) | Thin wrapper around `Purchases.shared` (purchase, restore, fetch offerings). |
| `RevenueCatObserver` | [Services/](../../../ios-native/OasisNative/Services/) | Subscribes to RevenueCat customer-info updates and broadcasts via `onCustomerInfoChange`. |

## Init flow

1. iOS launches → `OasisNativeApp.init()`.
2. If `AppConfiguration.shouldUseRevenueCatAccess && AppConfiguration.isRevenueCatConfigured` → `Purchases.configure(withAPIKey:)`. Debug builds set `Purchases.logLevel = .debug`.
3. TelemetryDeck initialised if `isTelemetryDeckConfigured` (currently empty in `Info.plist` → no-op).
4. `WindowGroup` instantiates `RootView` with a fresh `AppModel` and forwards `scenePhase` changes to it.
5. `AppModel.init` loads persisted state from `UserDefaults["evasion-mixer-storage"]`, hydrates `audioEngine.sync(with: self)`, and registers RevenueCat observers.
6. `RootView` decides between onboarding (first launch) and `HomeView`. Completing onboarding via the premium CTA writes the onboarding flag, requests local-notification permission for the gentle re-open reminder, switches to `HomeView`, then presents `PaywallOverlay`.

## Data flow on play

```
User taps play (HomeView)
  → AppModel.setPlayback(true)
  → audioEngine.transitionPlayback(to: true)
  → audioEngine.animateFade(0 → 1, 1.6s) updates master fade
  → refreshPlayerVolumes() rolls per-channel volumes including mute
  → updateNowPlayingInfo() updates lock-screen UI
```

## Data flow on premium request

```
User taps locked channel
  → AppModel.requestPremiumAccess(from: .channel(<id>))
  → PremiumCoordinator.route(entryPoint) decides inline vs full
  → AppModel.activePaywallContext = .full(<context>) OR activeInlineUpsell = ...
  → SwiftUI .sheet or overlay observes and presents
  → User taps "Buy" → AppModel.purchaseLifetime(package:)
  → PremiumRevenueCatService.purchase(package:) → RevenueCat
  → On success: applyCustomerInfo(updated) → isPremium = true → enforcePremiumAccess()
```

## Persistence

- **State**: `PersistedMixerState` (Codable) → `JSONEncoder` → `UserDefaults["evasion-mixer-storage"]`. Saves are debounced 350 ms via `schedulePersistence()`.
- **Engagement**: separate UserDefaults keys (`oasis.engagement.sessionCount`, `oasis.engagement.listenedSeconds`, …). Drives review-prompt and analytics.
- **Notifications**: no app-level setting or persisted toggle. `GentleReminderScheduler` schedules/cancels the single pending local reminder according to scene phase and system authorization.
- **Onboarding**: `oasis.onboarding.completed` flag.

There is no backend, no iCloud sync, no Keychain (RevenueCat handles its own). UserDefaults is the only durable store.

## Threading

`AppModel` is `@MainActor`. All UI and most state mutation runs on main. `AudioMixerEngine` schedules audio work on the audio engine's queue (driven by `AVAudioEngine`). Persistence dispatches off-main inside `schedulePersistence()` after the debounce.

## Configuration knobs

See [../operations/secrets-and-keys.md](../operations/secrets-and-keys.md) for environment variables and Info.plist keys. The most consequential at runtime: `RevenueCatAPIKey`, `RevenueCatEntitlementID`, `OASIS_REVENUECAT_API_KEY` (env override), `-OASISPremiumOverride`, `-OASISResetState`, `-OASISResetOnboarding`.
