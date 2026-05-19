---
title: Binaural Engine
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Services/AudioMixerEngine.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Views/Overlays/BinauralPanel.swift"
related:
  - "audio-engine.md"
  - "../product/premium-model.md"
---

# Binaural Engine

Brainwave entrainment tracks. Independent of the ambient mixer (different player class, separate volume control).

## Tracks

| Case | File | Frequency band | Premium |
| --- | --- | --- | --- |
| `.delta` | `1_binaural_sleep_delta.m4a` | ~ 2 Hz | No (free) |
| `.theta` | `2_binaural_meditation_theta.m4a` | 5–8 Hz | Yes |
| `.alpha` | `3_binaural_relax_alpha.m4a` | 8–12 Hz | Yes |
| `.beta` | `4_binaural_focus_beta.m4a` | 12–30 Hz | Yes |

The `BinauralTrack` enum lives in [`Models/AppModels.swift`](../../../ios-native/OasisNative/Models/AppModels.swift). `isPremium` is a computed property on the enum.

The four files are pre-rendered (not generated at runtime) by [`scripts/generateBinauralSounds.py`](../../../scripts/generateBinauralSounds.py). The script produces isochronic-tone style tracks at the target frequencies. Re-run only if you redesign the binaural sound; the output is committed to the bundle.

## Player path

Unlike ambient channels (which run through `AVAudioEngine`), each binaural track has its own `AVAudioPlayer`:

```swift
binauralPlayers: [BinauralTrack: AVAudioPlayer]
```

Each player:
- `numberOfLoops = -1` (infinite loop)
- Volume = `binauralVolume` (single shared value across tracks)
- Started lazily on first activation; preloaded eagerly via `preloadBinauralTrack(_:)` when the user opens the panel

This isolation is intentional: binaural tracks must not be processed by the spatial environment node or the master fade. They're a separate layer.

## State surface

`AppModel` exposes:

- `isBinauralActive: Bool` — master switch.
- `activeBinauralTrack: BinauralTrack` — defaults to `.delta`.
- `binauralVolume: Double` — `[0, 1]`.

All three are persisted in `PersistedMixerState`.

## Activation gate

`selectBinauralTrack(_:)` runs the premium gate:

```swift
if !isPremium && track.isPremium {
  requestPremiumAccess(from: .binaural)
  return
}
activeBinauralTrack = track
```

`PremiumCoordinator` routes `.binaural` to **inline upsell first**, then full paywall on retry — see [paywall.md](paywall.md).

When `isBinauralActive` flips off, the active player is paused but kept allocated for fast re-activation. When it flips on, the active player is started (or resumed).

## UI

[`BinauralPanel`](../../../ios-native/OasisNative/Views/Overlays/BinauralPanel.swift) presents:

1. The four track cards (Delta, Theta, Alpha, Beta) with their L10n names (`binaural.track.delta`, …) and lock badges on the premium ones.
2. A volume slider bound to `binauralVolume`.
3. The tonal-bed toggle at the bottom (controls `AppModel.isTonalBedEnabled` — see [audio-engine.md](audio-engine.md)).

Localised in 6 languages. The French copy uses "Souffle harmonique" for the tonal bed (commit `583537e`).

## Why not blend with ambient

Binaural entrainment relies on precise stereo channel difference (left ear ≠ right ear at slightly different frequencies). Routing through the `AVAudioEnvironmentNode` would distort the inter-aural difference because spatial mixing applies HRTF / pan / reverb to the bus. Hence the dedicated `AVAudioPlayer` path, bypassing the engine entirely.

## Quiescence under UI tests

`AnimatedLiquidAura` (the visual aura around the play button when binaural is active) is paused under XCUITest. The audio plays normally — the freeze is purely visual so screenshot frames are deterministic.
