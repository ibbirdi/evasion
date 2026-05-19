---
title: Glossary
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Models/SoundChannelMetadata.swift"
  - "ios-native/OasisNative/Support/L10n.swift"
related:
  - "../architecture/audio-engine.md"
  - "../architecture/binaural.md"
  - "../content/sounds-catalog.md"
---

# Glossary

Vocabulary used inside the codebase, the UI copy, and these memory files. Some terms have French aliases because the in-app copy is multilingual and the user thinks in French.

## Audio terms

**Channel** (`SoundChannel`). One of the 35 ambient sounds. Persistent identifier (e.g. `oiseaux`, `vent`, `tonnerre`). Each has a volume, mute state, auto-variation flag/range, and 2D spatial position. See [content/sounds-catalog.md](../content/sounds-catalog.md).

**Free channel.** One of the 3 channels accessible without premium: Birds (`oiseaux`), Wind (`vent`), Beach (`plage`). Defined as `freeChannels` in code. The other 32 are premium.

**Channel state** (`ChannelState`). `{ volume: Double, isMuted: Bool, autoVariationEnabled: Bool, autoVariationRange: AutoVariationRange, spatialPosition: SpatialPoint }`.

**Sound placement / spatial position** (`SpatialPoint`). 2D point in `[-1, 1] × [-1, 1]`. Origin = listener. Mapped internally to `AVAudio3DPoint` for the `AVAudioEnvironmentNode`, but user-facing copy should call this sound placement, not "3D audio".

**Immersive audio mode.** Persisted global home toggle that makes ambient channels feel farther and wider by applying per-channel distance/diffusion/rendering profiles in `AudioMixerEngine`. It is intentionally ambient-only; binaural tracks keep their separate stereo path.

**Auto-variation.** Slow automatic modulation of a channel's volume over time. Per-channel toggle plus a persisted lower/upper volume interval selected directly from the mixer slider. Used to keep mixes alive over multi-hour listening.

**Master fade.** Multiplier applied to all ambient players during play/pause transitions. Animated 0 → 1 over 1.6 s on play, 1 → 0 over 0.9 s on pause (customizable per call via `setNextPauseFadeDuration`).

**Binaural track** (`BinauralTrack`). One of `.delta`, `.theta`, `.alpha`, `.beta`. Played by a dedicated `AVAudioPlayer`, looped infinitely. Delta is free; the other three are premium. See [architecture/binaural.md](../architecture/binaural.md).

## Mix and presets

**Preset** (`Preset`). Named snapshot of `[SoundChannel: ChannelState]`. Fields: `id`, `name`, `channels`. Persisted in `PersistedMixerState`.

**Default presets.** Three shipped presets: `preset_default_starter`, `preset_default_calm`, `preset_default_storm`. Always present.

**Signature preset** (`preset_signature_oasis`). Special preview-able preset showcasing the "best of premium". Free users can preview it for 45 s, throttled to once per week (see [premium-model.md](premium-model.md)).

**User preset.** `preset_user_<timestamp>`. Created by the user. Free tier caps at 1; premium has no cap.

**Random mix.** UI affordance to generate a random ambient mix. Restricted to accessible channels.

## Premium

**Entitlement.** RevenueCat term for "the user has paid". The `premium` entitlement unlocks the full app.

**Premium entry point** (`PremiumEntryPoint`). Categorisation of *why* the paywall was triggered (channel locked, preset, binaural, timer, signature preview, onboarding, home banner, …). Drives whether `PremiumCoordinator` shows an inline upsell first or the full paywall.

**Inline upsell.** Compact in-context teaser shown for `.preset` and `.binaural` entry points. If dismissed and the user re-attempts, falls through to the full paywall.

**Paywall context** (`PremiumPaywallContext`). The state passed to `PaywallOverlay` describing what triggered it, used to colour the copy.

## Timer

**Sleep timer.** Optional countdown after which playback fades to silence. Durations: 15 / 30 / 60 / 120 minutes. 15 and 30 are free; 60 and 120 are premium.

## Localization

**Locale.** One of the 6 supported app-store locales: `en-US`, `fr-FR`, `de-DE`, `es-ES`, `it`, `pt-BR`. See [content/localization.md](../content/localization.md).

**L10n key.** Dotted identifier resolved by `LocalizedStringResource`, e.g. `channel.birds`, `paywall.title.generic`. Source of truth: `Localizable.xcstrings`.

## Build / test

**Premium override.** `-OASISPremiumOverride free|premium|revenueCat` launch argument that bypasses RevenueCat and forces a tier. Used by UI tests and fastlane.

**Reset state.** `-OASISResetState YES` clears persisted state on launch. Used by screenshot automation to start from a known mix.

**Quiescence animations.** `WaveformSignatureLine` and `AnimatedLiquidAura` are paused under XCUITest so the snapshot frame is deterministic.
