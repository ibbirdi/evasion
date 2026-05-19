---
title: Architecture Overview
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/OasisNativeApp.swift"
  - "ios-native/OasisNative/Services/AppModel.swift"
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
   │ + TonalBed   │ └──────────────┘ └──────────────────────────┘
   │   Synth      │
   └──────────────┘

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
| `AppModel` | [Services/AppModel.swift](../../../ios-native/OasisNative/Services/AppModel.swift) | Hub. `@Observable @MainActor`. Owns mix state, presets, premium state, timer, engagement metrics. Bridges UI ↔ engine ↔ RevenueCat. See [state.md](state.md). |
| `AudioMixerEngine` | [Services/AudioMixerEngine.swift](../../../ios-native/OasisNative/Services/AudioMixerEngine.swift) | The audio graph. `AVAudioEngine` + `AVAudioEnvironmentNode` + 35 `AVAudioPlayerNode` + `TonalBedSynth`. Handles loops, fades, spatial, remote commands. See [audio-engine.md](audio-engine.md). |
| `TonalBedSynth` | [Services/TonalBedSynth.swift](../../../ios-native/OasisNative/Services/TonalBedSynth.swift) | Procedural 3-voice harmonic pad. `AVAudioSourceNode`. Locked to the dominant channel's tonal group. |
| `PremiumCoordinator` | [Services/PremiumCoordinator.swift](../../../ios-native/OasisNative/Services/PremiumCoordinator.swift) | Routes premium requests to inline-upsell or full-paywall. See [paywall.md](paywall.md). |
| `PremiumRevenueCatService` | [Services/PremiumRevenueCatService.swift](../../../ios-native/OasisNative/Services/PremiumRevenueCatService.swift) | Thin wrapper around `Purchases.shared` (purchase, restore, fetch offerings). |
| `RevenueCatObserver` | [Services/](../../../ios-native/OasisNative/Services/) | Subscribes to RevenueCat customer-info updates and broadcasts via `onCustomerInfoChange`. |

## Init flow

1. iOS launches → `OasisNativeApp.init()`.
2. If `AppConfiguration.shouldUseRevenueCatAccess && AppConfiguration.isRevenueCatConfigured` → `Purchases.configure(withAPIKey:)`. Debug builds set `Purchases.logLevel = .debug`.
3. TelemetryDeck initialised if `isTelemetryDeckConfigured` (currently empty in `Info.plist` → no-op).
4. `WindowGroup` instantiates `RootView` with a fresh `AppModel`.
5. `AppModel.init` loads persisted state from `UserDefaults["evasion-mixer-storage"]`, hydrates `audioEngine.sync(with: self)`, and registers RevenueCat observers.
6. `RootView` decides between onboarding (first launch) and `HomeView`. Completing onboarding via the premium CTA writes the onboarding flag, switches to `HomeView`, then presents `PaywallOverlay`.

## Data flow on play

```
User taps play (HomeView)
  → AppModel.setPlayback(true)
  → audioEngine.transitionPlayback(to: true)
  → audioEngine.animateFade(0 → 1, 1.6s) updates master fade
  → refreshPlayerVolumes() rolls per-channel volumes including mute
  → updateNowPlayingInfo() updates lock-screen UI
  → TonalBedSynth picks up `applySignature()` if a tonal channel is loud enough
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
- **Onboarding**: `oasis.onboarding.completed` flag.

There is no backend, no iCloud sync, no Keychain (RevenueCat handles its own). UserDefaults is the only durable store.

## Threading

`AppModel` is `@MainActor`. All UI and most state mutation runs on main. `AudioMixerEngine` schedules audio work on the audio engine's queue (driven by `AVAudioEngine`). Persistence dispatches off-main inside `schedulePersistence()` after the debounce.

## Configuration knobs

See [../operations/secrets-and-keys.md](../operations/secrets-and-keys.md) for environment variables and Info.plist keys. The most consequential at runtime: `RevenueCatAPIKey`, `RevenueCatEntitlementID`, `OASIS_REVENUECAT_API_KEY` (env override), `-OASISPremiumOverride`, `-OASISResetState`, `-OASISResetOnboarding`.
