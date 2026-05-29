---
title: Architecture Overview
status: stable
last_updated: 2026-05-29
tracks:
  - "ios-native/OasisNative/OasisNativeApp.swift"
  - "ios-native/OasisNative/Mac/OasisMacApp.swift"
  - "ios-native/OasisNative/Support/AppBootstrap.swift"
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

Oasis is a native Apple-platform app with two app targets in the same Xcode project: `OasisNative` for iOS and `OasisMac` for macOS. SwiftUI for everything visible, AVFoundation under the hood, RevenueCat for entitlement, UserDefaults for persistence. No backend.

## Module map

```
              ┌────────────────────────┐
              │   OasisNativeApp       │  ← iOS @main
              │   OasisMacApp          │  ← macOS status-item @main
              └────────────┬───────────┘
                           │ configure via AppBootstrap, hold
                           ▼
              ┌────────────────────────┐
              │   AppModel             │  ← @Observable, @MainActor, source of truth
              └─┬───────┬───────┬──────┬───────────┐
                │       │       │      │           │
        owns    │  uses │       │ uses │ uses      │ uses
                ▼       ▼       ▼      ▼           ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐
   │ AudioMixer   │ │ Premium      │ │ RevenueCatObserver       │
   │ Engine       │ │ Coordinator  │ │ + PremiumRevenueCatSvc   │
   └──────────────┘ └──────────────┘ └──────────────────────────┘
   ┌──────────────────────────┐ ┌──────────────────────────┐
   │ AmbienceComposer         │ │ GentleReminderScheduler  │
   │ local prompt → recipe    │ │ local re-open reminder   │
   └──────────────────────────┘ └──────────────────────────┘

              ┌────────────────────────┐
              │   RootView             │  ← iOS onboarding, root navigation
              └────────────┬───────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   HomeView             │  ← mixer board, header, playback
              └────────────────────────┘
                  ▲     ▲     ▲     ▲     ▲
                  │     │     │     │     │  .sheet / .fullScreenCover
                  │     │     │     │     │
          ComposePanel  Presets  Binaural  Spatial  Paywall
                        Panel    Panel    Panel    Overlay

              ┌────────────────────────┐
              │   MacMixerPanel        │  ← macOS borderless menu bar panel
              └────────────────────────┘
```

## Key actors

| Actor | File | Role |
| --- | --- | --- |
| `OasisNativeApp` | [OasisNativeApp.swift](../../../ios-native/OasisNative/OasisNativeApp.swift) | iOS entry point. Calls `AppBootstrap.configure()`, instantiates `AppModel`, and presents `RootView`. |
| `OasisMacApp` | [Mac/OasisMacApp.swift](../../../ios-native/OasisNative/Mac/OasisMacApp.swift) | macOS entry point. Calls `AppBootstrap.configure()`, owns the status item app delegate using a fixed template wind icon, keeps one `AppModel`, and presents `MacMixerPanel` inside a custom borderless `NSPanel`. The status-item toggle treats stale visible/non-key panels as closed so the menu bar icon can always reopen the panel after deactivation. |
| `AppBootstrap` | [Support/AppBootstrap.swift](../../../ios-native/OasisNative/Support/AppBootstrap.swift) | Shared startup for RevenueCat + TelemetryDeck so iOS and macOS do not drift. |
| `AppModel` | [Services/AppModel.swift](../../../ios-native/OasisNative/Services/AppModel.swift) | Hub. `@Observable @MainActor`. Owns mix state, procedural noise state, active rituals, active ambience lock state, immersive audio toggle, shipped/user presets, premium state, timer, engagement metrics. Bridges UI ↔ engine ↔ RevenueCat. See [state.md](state.md). |
| `AudioMixerEngine` | [Services/AudioMixerEngine.swift](../../../ios-native/OasisNative/Services/AudioMixerEngine.swift) | The audio graph. `AVAudioEngine` + `AVAudioEnvironmentNode` + 35 `AVAudioPlayerNode` plus procedural `AVAudioSourceNode` layers. Handles loops, fades, spatial/immersive profiles, remote commands. See [audio-engine.md](audio-engine.md). |
| `AmbienceComposer` | [Services/AmbienceComposer.swift](../../../ios-native/OasisNative/Services/AmbienceComposer.swift) | Local deterministic recipe builder for Composer prompts and ritual phase templates. No network or LLM call. |
| `GentleReminderScheduler` | [Services/GentleReminderScheduler.swift](../../../ios-native/OasisNative/Services/GentleReminderScheduler.swift) | Local notification scheduler. Requests provisional alert permission after onboarding, cancels pending reminders on app open, and schedules one gentle re-open reminder after several inactive days. |
| `PremiumCoordinator` | [Services/PremiumCoordinator.swift](../../../ios-native/OasisNative/Services/PremiumCoordinator.swift) | Routes premium requests to inline-upsell or full-paywall. See [paywall.md](paywall.md). |
| `PremiumRevenueCatService` | [Services/PremiumRevenueCatService.swift](../../../ios-native/OasisNative/Services/PremiumRevenueCatService.swift) | Thin wrapper around `Purchases.shared` (purchase, restore, fetch offerings). |
| `RevenueCatObserver` | [Services/](../../../ios-native/OasisNative/Services/) | Subscribes to RevenueCat customer-info updates and broadcasts via `onCustomerInfoChange`. |

## Init flow

1. iOS launches → `OasisNativeApp.init()`; macOS launches → `OasisMacApp.init()`.
2. Both call `AppBootstrap.configure()`. If `AppConfiguration.shouldUseRevenueCatAccess && AppConfiguration.isRevenueCatConfigured` → `Purchases.configure(withAPIKey:)`. Debug builds keep RevenueCat at `.error` unless `-OASISRevenueCatDebugLogs` or `OASIS_REVENUECAT_DEBUG_LOGS=1` is set.
3. TelemetryDeck initialised if `isTelemetryDeckConfigured` (currently empty in `Info.plist` / `Mac/Info.plist` → no-op).
4. iOS `WindowGroup` instantiates `RootView`; macOS `MacAppDelegate` creates an `NSStatusItem` and a custom borderless `NSPanel` that hosts `MacMixerPanel`. Both inject the same `AppModel` type and forward foreground/background lifecycle changes into the model. Under `-OASISMacScreenshot`, the app delegate opens the status-item panel automatically for deterministic Mac App Store captures.
5. `AppModel.init` loads persisted state from `UserDefaults["evasion-mixer-storage"]`, hydrates `audioEngine.sync(with: self)`, and registers RevenueCat observers.
6. iOS `RootView` decides between onboarding (first launch) and `HomeView`. macOS opens directly to the mixer panel because it is an accessory app surface, not an onboarding-first phone flow.

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

## Data flow on Composer / Ritual

```
User opens ComposePanel
  → ComposePanel builds an AmbienceRecipe from the selected saved Preset
  → AppModel.applyAmbienceRecipe(recipe) OR startRitual(preset)
  → AppModel updates channels, procedural noise, binaural, immersive, timer
  → audioEngine.sync(with:) reconciles file players and source nodes
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

See [../operations/secrets-and-keys.md](../operations/secrets-and-keys.md) for environment variables and Info.plist keys. The most consequential at runtime: `RevenueCatAPIKey`, `RevenueCatEntitlementID`, `OASIS_REVENUECAT_API_KEY` (env override), `-OASISPremiumOverride`, `-OASISResetState`, `-OASISResetOnboarding`, `-OASISImmersiveAudioEnabled`, `-OASISMacScreenshot`, `-OASISMacScreenshotScenario`, and `-OASISMacScreenshotOutput`.
