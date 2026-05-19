---
title: State Model and Persistence
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Services/GentleReminderScheduler.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Support/AppConfiguration.swift"
related:
  - "overview.md"
  - "audio-engine.md"
  - "paywall.md"
  - "../product/premium-model.md"
---

# State Model and Persistence

`AppModel` is the source of truth. Everything else (engine, views, RevenueCat observer) reconciles around it.

## Class shape

```swift
@Observable @MainActor
final class AppModel {
  // Playback
  var isPlaying: Bool = false
  var timerDurationMinutes: Int?           // nil = no timer; valid: 15, 30, 60, 120
  var timerEndDate: Date?                  // wall-clock target; computed when timer set

  // Mix (persisted)
  var channels: [SoundChannel: ChannelState]   // 35 ambient channels
  var presets: [Preset]
  var currentPresetID: String?

  // Binaural (persisted)
  var isBinauralActive: Bool = false
  var activeBinauralTrack: BinauralTrack = .delta
  var binauralVolume: Double = 0.5
  var immersiveAudioEnabled: Bool = false  // global ambient spatial-depth mode

  // Premium (derived from RevenueCat or override)
  var isPremium: Bool
  var activePaywallContext: PremiumPaywallContext?
  var activeInlineUpsell: PremiumInlineUpsellContext?

  // UI flags (transient)
  var showsBinauralPanel: Bool = false
  var showsPresetsPanel: Bool = false
  var showsSpatialPanel: Bool = false
  var showsOnlyActiveChannels: Bool = false
  var showsPremiumHomeBanner: Bool = false

  // Internals (not observed)
  @ObservationIgnored private let audioEngine: AudioMixerEngine
  @ObservationIgnored private let gentleReminderScheduler: GentleReminderScheduler
  @ObservationIgnored private let revenueCatObserver: RevenueCatObserver
  @ObservationIgnored private let premiumCoordinator: PremiumCoordinator
  @ObservationIgnored private let premiumRevenueCatService: PremiumRevenueCatService
}
```

Use `@ObservationIgnored` for any helper that shouldn't trigger SwiftUI invalidation. The hubs above are deliberate.

## `ChannelState`

```swift
struct ChannelState: Codable, Equatable {
  var volume: Double          // [0, 1]
  var isMuted: Bool
  var autoVariationEnabled: Bool
  var autoVariationRange: AutoVariationRange // persisted [lower, upper] interval for auto-volume
  var spatialPosition: SpatialPoint   // [-1, 1] x [-1, 1]
}
```

`AutoVariationRange` stores the user-selected lower/upper volume bounds for automatic variation. Older persisted `ChannelState` payloads decode with a default range centred around `volume`, so no top-level `PersistedMixerState` migration is needed.

## `Preset`

```swift
struct Preset: Codable, Identifiable, Equatable {
  let id: String              // "preset_default_starter", "preset_user_<ts>", "preset_signature_oasis"
  var name: String            // L10n key for defaults; user-typed for user presets
  var channels: [SoundChannel: ChannelState]
}
```

## Persistence shape

`PersistedMixerState` is the on-disk codable record:

```swift
struct PersistedMixerState: Codable {
  var channels: [SoundChannel: ChannelState]
  var presets: [Preset]
  var currentPresetID: String?
  var isBinauralActive: Bool
  var activeBinauralTrack: BinauralTrack
  var binauralVolume: Double
  var selectedLanguage: String?              // legacy, unused — keep for backward compat
  var premiumBannerLastDismissedAt: Date?
  var signaturePreviewLastPlayedAt: Date?
  var immersiveAudioEnabled: Bool?           // optional for backward compat
}
```

**Rule:** when adding a field, make it `Optional` (and provide a sensible default at decode) for backward compat. Existing users have older payloads.

### Storage

- `UserDefaults.standard`
- Key: `"evasion-mixer-storage"` (defined in [`AppConfiguration.persistenceKey`](../../../ios-native/OasisNative/Support/AppConfiguration.swift))
- Encoder: `JSONEncoder` (default settings)
- Read: `loadPersistedState()` on init
- Write: `persistState()` called by `schedulePersistence()`, debounced 350 ms

### Persistence is disabled when

`AppConfiguration.shouldPersistState = !isRunningScreenshotAutomation`. UI tests and fastlane snapshots run with persistence off so each scenario starts from a known mix injected via `-OASISResetState YES`.

## Engagement metrics (separate keys)

Stored directly in `UserDefaults` (not inside `PersistedMixerState`) because they're orthogonal to mix state:

| Key | Purpose |
| --- | --- |
| `oasis.engagement.sessionCount` | Total app launches. |
| `oasis.engagement.listenedSeconds` | Cumulative seconds with audio playing. |
| `oasis.engagement.didTrackFirstPlay` | One-shot flag for analytics. |
| `oasis.engagement.didTrackListened60s` | One-shot flag (60s milestone). |
| `oasis.engagement.didRequestReview` | Once-per-version flag for SKStoreReviewController. |
| `oasis.onboarding.completed` | First-launch onboarding flag. |

`GentleReminderScheduler` does not add a user setting or persisted app-level preference. After onboarding, it requests provisional system alert authorization automatically for a quieter default notification path; on backgrounding it schedules one local reminder for several inactive days later, and on reopening it cancels that pending reminder.

Completing onboarding from the final page can also open the lifetime paywall when the premium CTA is tapped. The flag is still written first, so dismissing the paywall lands in `HomeView` instead of returning to onboarding.

For simulator/dev verification, `-OASISResetOnboarding` clears only this onboarding flag on launch. `-OASISResetState` still resets mixer state but does not imply onboarding reset.

## Engine sync barrier

Whenever the model mutates anything the audio engine cares about (channel state, binaural state, playback flag, immersive audio flag), `AppModel` calls `audioEngine.sync(with: self)`. The engine is responsible for reconciling its internal players. See [audio-engine.md](audio-engine.md).

`OasisNativeApp` forwards `scenePhase` changes into `AppModel.handleScenePhase(_:)`, which keeps the local re-open reminder aligned with foreground/background transitions.

## Premium reconciliation (`enforcePremiumAccess`)

Triggered on:
- App launch (after `loadPersistedState`)
- RevenueCat customer info change (`applyCustomerInfo`)
- Premium override change (dev / UI-test launch arg)

Effect: for every premium-gated channel, force `isMuted = true` (and reset volume/spatial to safe defaults) if `!isPremium && !inSignaturePreview`. Same for binaural — reset `activeBinauralTrack` to `.delta` if previously on a premium track. Same for timer — clamp to ≤ 30 min if previously 60/120.

This is what handles refunds gracefully: the user reverts to free without crashing or playing premium content silently.

## Concurrency

- `AppModel` is `@MainActor` — all mutation runs on main.
- The audio engine schedules audio on its own queue; its callbacks (`onRemotePlaybackChange`, `onVariationChanged`) hop back to main before mutating `AppModel`.
- Persistence runs off-main (inside the debounce closure), but the JSON encode reads a snapshot built on main first.

## Adding a persisted field — checklist

1. Add the field to `PersistedMixerState` as `Optional`.
2. Add it to `AppModel` (with a default).
3. Wire encode/decode in the existing `persistState`/`loadPersistedState`.
4. Update [docs/ai/architecture/state.md](state.md) (this file) — bump `last_updated`.
5. If user-facing, also update [../product/glossary.md](../product/glossary.md).
