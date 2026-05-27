---
title: State Model and Persistence
status: stable
last_updated: 2026-05-27
tracks:
  - "ios-native/OasisNative/Services/AppModel.swift"
  - "ios-native/OasisNative/Services/GentleReminderScheduler.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Models/AmbienceModels.swift"
  - "ios-native/OasisNative/Support/AppConfiguration.swift"
  - "ios-native/OasisNative/Support/Platform/AppReviewRequester.swift"
related:
  - "overview.md"
  - "audio-engine.md"
  - "paywall.md"
  - "../product/premium-model.md"
---

# State Model and Persistence

`AppModel` is the source of truth. Everything else (engine, iOS views, macOS views, RevenueCat observer) reconciles around it.

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
  var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]
  var presets: [Preset]
  var currentPresetID: String?
  var activeComposerRecipeTitle: String?
  var activeNoiseBlendTitle: String?

  // Binaural (persisted)
  var isBinauralActive: Bool = false
  var activeBinauralTrack: BinauralTrack = .delta
  var binauralVolume: Double = 0.5
  var immersiveAudioEnabled: Bool = false  // global ambient spatial-depth mode

  // Premium (derived from RevenueCat or override)
  var isPremium: Bool
  var activePaywallContext: PremiumPaywallContext?
  var activeInlineUpsell: PremiumInlineUpsellContext?

  // UI flags / runtime session
  var showsBinauralPanel: Bool = false
  var showsPresetsPanel: Bool = false
  var showsSpatialPanel: Bool = false
  var showsComposePanel: Bool = false
  var showsOnlyActiveChannels: Bool = false
  var showsPremiumHomeBanner: Bool = false
  var activeRitualSession: ActiveRitualSession?

  // Internals (not observed)
  @ObservationIgnored private let audioEngine: AudioMixerEngine
  @ObservationIgnored private let gentleReminderScheduler: GentleReminderScheduler
  @ObservationIgnored private let revenueCatObserver: RevenueCatObserver
  @ObservationIgnored private let premiumCoordinator: PremiumCoordinator
  @ObservationIgnored private let premiumRevenueCatService: PremiumRevenueCatService
  @ObservationIgnored private var ritualTask: Task<Void, Never>?
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

`AutoVariationRange` also normalises non-finite values back into `[0, 1]`. This keeps older or corrupted simulator/user defaults from leaking `NaN` into the UI, the audio engine, or VoiceOver values.

## Guided routines, legacy rituals and procedural noise

`AmbienceRecipe` is the shared recipe type for guided routines, the legacy Composer path, and built-in rituals. It can set ambient channel states, procedural noise layers, binaural state, immersive mode, and an optional timer in one model-level transaction.

Guided routines are keyed by `GuidedRoutineKind`. The free surface has exactly 2 routines (`nap`, `reset`) whose recipes only use the 3 free ambient channels, free procedural noises, Delta/no binaural, and timers no longer than 30 minutes. The premium surface adds exactly 6 routines (`deepSleep`, `deepWork`, `noisyHotel` shown to users as Travel cocoon, `reading`, `rainCabin`, `morning`) whose deterministic recipes use premium channels/noises/binaurals where those layers make the ambience distinct. `AppModel.composeGuidedRoutine(_:)` returns the full recipe for preview; `applyAmbienceRecipe(_:)` remains the gate that routes locked recipes to the Composer upsell/paywall before mutating audio state.

`ProceduralNoiseState` mirrors the lightweight part of `ChannelState` used by generated noise layers: `{ volume: Double, isMuted: Bool }`. The free tier includes white and brown noise; the premium tier adds pink, green, fan, and aircraft layers.

`applyProceduralNoiseBlend(_:title:startPlayback:)` replaces the current procedural noise layer set with a one-tap blend. It refuses locked blends before mutating, requests the paywall from the first locked noise, cancels any active ritual, clears the active Composer recipe title, stores an optional localized blend title for the Home badge / active strip, starts playback by default, persists, and resynchronizes the audio engine. Manual row toggles and sliders clear the blend title, so edited noise layers fall back to the procedural-noise count.

`clearProceduralNoises()` mutes every active procedural layer in one transaction. It cancels any ritual, clears the active Composer recipe title and active blend title, stops playback if no other audio source remains, then persists and resynchronizes the audio engine.

`ActiveRitualSession` is runtime state persisted with the mixer so long-running rituals survive app relaunch. Starting a `RitualPreset` applies its first phase, starts playback, sets a total timer, then advances phases with `ritualTask` while the app is playing. The session carries intent, phase count, phase start/end dates, duration, and paused remaining values so the Home toolbar status pill and Rituals-tab active card can show live progress, expose the current phase subtitle, expose the current phase recipe for ingredient chips, expose the next queued phase from the active preset, pause/resume can restart phase scheduling from the correct point, and relaunch can restore the correct phase from wall-clock time. `advanceActiveRitualToNextPhase()` manually skips to the next phase, reapplies that phase's recipe, reschedules future phase advancement, shortens the total remaining duration to the queued phases, and preserves paused playback when invoked while paused. User edits to the mix cancel the active ritual so manual control always wins.

`activeComposerRecipeTitle` names the currently-applied guided routine / generated Composer recipe on Home. It is set only when a generated `AmbienceRecipe` is applied, persisted with the mixer state, restored after signature-preview playback, and cleared as soon as the user manually changes the composition, loads or saves through the generic Presets surface, starts a ritual, or randomizes the mix. The dedicated `saveCurrentScene(named:)` path used by active generated scenes saves the current ambience as a preset while preserving the active scene title so the listening context does not collapse into a generic preset state.

`stopGuidedRoutine()` is the explicit exit from guided listening. It clears the active routine title, active noise-blend title, active-only filter, and timer state while preserving the current ambient/noise/binaural mix and playback state, so the user can return to normal manual mixing without an abrupt audio reset.

Premium guided routines may apply more than five ambient/noise layers at once. That is valid model state: do not truncate the recipe or assume a three-sound maximum. The Home UI is responsible for keeping the listening state calm by showing leading layers as direct controls and summarising softer extras in `home.routine.supporting-layers`.

`activeNoiseBlendTitle` names a one-tap Noise Lab blend while that blend remains intact. It is persisted with the mixer state, shown in the Home bottom compose badge and Noise Lab active strip, and cleared by manual procedural-noise edits, clearing all noise layers, loading presets, applying Composer recipes, starting rituals, or premium reconciliation when no procedural noise remains. Noise-only manual edits therefore fall back to the procedural-noise count instead of a stale intention name.

## `Preset`

```swift
struct Preset: Codable, Identifiable, Equatable {
  let id: String              // "preset_default_starter", "preset_user_<ts>", "preset_signature_oasis"
  var name: String            // L10n key for defaults; user-typed for user presets
  var channels: [SoundChannel: ChannelState]
  var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]? // optional for old presets
  var isBinauralActive: Bool?
  var activeBinauralTrack: BinauralTrack?
  var binauralVolume: Double?
  var timerDurationMinutes: Int?
  var immersiveAudioEnabled: Bool?
}
```

New presets saved from the Presets panel, Composer recipe card, or active scene bookmark capture the full ambience: ambient channels, procedural noise layers, binaural state, immersive mode, and timer. Older decoded presets that lack the optional fields are treated as channel-only snapshots and reset the extra layers to safe defaults when loaded.

`currentPresetID` is cleared by user edits that make the live mix diverge from the saved snapshot, including timer changes and procedural-noise blend/manual edits. The active scene bookmark can then accurately reflect whether the current listening state is still the saved ambience.

## Persistence shape

`PersistedMixerState` is the on-disk codable record:

```swift
struct PersistedMixerState: Codable {
  var channels: [SoundChannel: ChannelState]
  var presets: [Preset]
  var currentPresetID: String?
  var activeComposerRecipeTitle: String?      // optional for backward compat
  var activeNoiseBlendTitle: String?          // optional for backward compat
  var activeRitualSession: ActiveRitualSession? // optional for backward compat
  var isBinauralActive: Bool
  var activeBinauralTrack: BinauralTrack
  var binauralVolume: Double
  var proceduralNoises: [ProceduralNoise: ProceduralNoiseState]? // optional for backward compat
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

`AppConfiguration.shouldPersistState = !isRunningScreenshotAutomation`. UI tests and fastlane snapshots run with persistence off so each scenario starts from a known mix injected via `-OASISResetState YES`. App Store screenshot runs can also force `immersiveAudioEnabled` with `-OASISImmersiveAudioEnabled YES`, applied after persisted-state loading and before the first audio sync.

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

For simulator/dev verification, `-OASISResetOnboarding` clears only this onboarding flag on launch. `-OASISResetState` still resets mixer state but does not imply onboarding reset. `-OASISImmersiveAudioEnabled YES|NO` is a launch-only override for deterministic screenshots and development checks. Screenshot-only random-mix templates also seed known active channels; the free-tier template includes Birds, Wind, and Beach so App Store captures can highlight active free rows without premium content.

## Engine sync barrier

Whenever the model mutates anything the audio engine cares about (channel state, procedural noise state, binaural state, playback flag, immersive audio flag), `AppModel` calls `audioEngine.sync(with: self)`. The engine is responsible for reconciling its internal players. See [audio-engine.md](audio-engine.md).

`OasisNativeApp` forwards `scenePhase` changes into `AppModel.handleScenePhase(_:)`, which keeps the local re-open reminder aligned with foreground/background transitions.

`OasisMacApp` does the same from its AppKit app delegate. The macOS status item opens a borderless panel that uses the same persisted state and premium reconciliation as iOS; it only swaps the presentation layer.

## Platform adapters

Keep platform APIs out of `AppModel` where possible. The current shared adapter is [`AppReviewRequester`](../../../ios-native/OasisNative/Support/Platform/AppReviewRequester.swift): it calls `AppStore.requestReview(in:)` with a foreground `UIWindowScene` on iOS and returns `false` on macOS.

## Premium reconciliation (`enforcePremiumAccess`)

Triggered on:
- App launch (after `loadPersistedState`)
- RevenueCat customer info change (`applyCustomerInfo`)
- Premium override change (dev / UI-test launch arg)

Effect: for every premium-gated channel, force `isMuted = true` (and reset volume/spatial to safe defaults) if `!isPremium && !inSignaturePreview`. Same for premium procedural noise layers — mute them. Same for binaural — reset `activeBinauralTrack` to `.delta` if previously on a premium track. Same for timer — clamp to ≤ 30 min if previously 60/120.

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
