---
title: Binaural Engine
status: stable
last_updated: 2026-05-26
tracks:
  - "ios-native/OasisNative/Services/AudioMixerEngine.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Views/Overlays/BinauralPanel.swift"
  - "ios-native/OasisNative/Views/Mac/MacBinauralSection.swift"
related:
  - "audio-engine.md"
  - "../product/premium-model.md"
---

# Binaural Engine

Brainwave entrainment tracks. Independent of the ambient mixer (different player class, separate volume control) and shared by the iOS panel and the macOS menu bar panel.

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

The global immersive audio mode also leaves this path alone. Its distance/reverb/rendering profiles are applied only to ambient `AVAudioPlayerNode`s inside the `AVAudioEnvironmentNode`.

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

[`BinauralPanel`](../../../ios-native/OasisNative/Views/Overlays/BinauralPanel.swift) presents the iOS flow:

1. The four track cards (Delta, Theta, Alpha, Beta) with their L10n names (`binaural.track.delta`, …) and lock badges on the premium ones.
2. A volume slider bound to `binauralVolume`.

The four-card grid exposes `binaural.track.grid` for screenshot extraction so App Store pop-outs can use one real simulator crop of the complete mode selector rather than four separate duplicated cards.

[`MacBinauralSection`](../../../ios-native/OasisNative/Views/Mac/MacBinauralSection.swift) exposes the same state inside the macOS mixer panel: one enable toggle, the shared volume slider, and track rows routed through `AppModel.selectBinauralTrack(_:)`.

## Why not blend with ambient

Binaural entrainment relies on precise stereo channel difference (left ear ≠ right ear at slightly different frequencies). Routing through the `AVAudioEnvironmentNode` would distort the inter-aural difference because spatial mixing applies HRTF / pan / reverb to the bus. Hence the dedicated `AVAudioPlayer` path, bypassing the engine entirely.

## Quiescence under UI tests

`AnimatedLiquidAura` (the visual aura around the play button when binaural is active) is paused under XCUITest. The audio plays normally — the freeze is purely visual so screenshot frames are deterministic.
