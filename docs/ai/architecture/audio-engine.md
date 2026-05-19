---
title: Audio Engine
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Services/AudioMixerEngine.swift"
  - "ios-native/OasisNative/Services/TonalBedSynth.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
related:
  - "binaural.md"
  - "state.md"
  - "../content/sounds-catalog.md"
---

# Audio Engine

The ambient mixer. Implemented in [`AudioMixerEngine`](../../../ios-native/OasisNative/Services/AudioMixerEngine.swift). Binaural is a separate path (see [binaural.md](binaural.md)).

## Graph

```
AVAudioEngine (ambientEngine)
├── AVAudioEnvironmentNode (environmentNode)   ← spatial + reverb
│   ├── AVAudioPlayerNode  (channel oiseaux)
│   ├── AVAudioPlayerNode  (channel vent)
│   ├── ...
│   └── AVAudioPlayerNode  (channel cloches)      — 35 nodes, one per channel
│
└── AVAudioMixerNode (tonalMixerNode)
    └── AVAudioSourceNode  (TonalBedSynth — procedural pad)
```

`environmentNode` parameters (set in `AudioMixerEngine`):
- `distanceAttenuationParameters.distanceAttenuationModel = .linear`
- `referenceDistance = 10`, `maximumDistance = 10`, `rolloffFactor = 0` — channels stay audible at any in-app distance.
- `reverbParameters.enable = true`, `level = -18 dB` — subtle ambient blur.
- `listenerPosition = (0, 0, 0)` — origin.

## Channel playback (`AmbientChannelPlayback`)

Each channel is wrapped in:

```swift
struct AmbientChannelPlayback {
  let node: AVAudioPlayerNode
  var scheduledFile: AVAudioFile
  var scheduleToken: UUID    // invalidates stale completion blocks
}
```

### Scheduling loop (`scheduleAmbientLoop`)

The loop is hand-rolled because we want randomised in-points to avoid perceptible seams across sessions:

1. Pick a random `startFrame` within the file's frame length.
2. `scheduleSegment(file, startingFrame: startFrame, frameCount: ..., at: nil, completionHandler: …)`.
3. Completion handler captures the current `scheduleToken`. If the token still matches when the segment ends, schedule the next segment. Otherwise discard (the channel was muted, paused, or replaced).

`scheduleToken` is critical: without it, swapping channels or pausing leaves dangling completion handlers that would re-trigger and double-schedule.

## Master fade

A single master multiplier `masterFade ∈ [0, 1]` is animated to mute the entire ambient bus during transitions:

| Transition | Duration | Setter |
| --- | --- | --- |
| Pause → play | 1.6 s | `transitionPlayback(to: true)` |
| Play → pause | 0.9 s default | `transitionPlayback(to: false)`; override via `setNextPauseFadeDuration(_:)` |

`animateFade(start, target, duration)` steps the value at ≥ 120 ms intervals, calling `refreshPlayerVolumes()` each tick. On fade-out completion, `pauseAllPlayers()` is called.

`refreshPlayerVolumes()` computes effective per-channel volume = `channelState.volume * masterFade * (channelState.isMuted ? 0 : 1) * autoVariationFactor`.

## Spatial audio

Per-channel `SpatialPoint(x, y) ∈ [-1, 1] × [-1, 1]` is mapped to the player's `position: AVAudio3DPoint`. The `AVAudioEnvironmentNode` resolves stereo bus output. Z is fixed at 0.

`applySpatialMixingConfiguration()` is called from `sync(with:)` and whenever `AppModel` mutates a channel's spatial position via the `SpatialAudioPanel`.

## Auto-variation

Per channel, an opt-in slow LFO modulates volume over time. Implemented in `AudioMixerEngine` (search for `autoVariation` / `variation`). Visible in UI as a small toggle on each channel card.

When a channel's auto-variation generates a notable change, the engine fires `onVariationChanged` so `AppModel` can persist or surface it.

## `AVAudioSession`

Configured at engine start:

- Category: `.playback`
- Options: `[.allowAirPlay, .allowBluetoothA2DP]`
- Sample rate: 44 100 Hz
- IO buffer duration: 0.046 s
- iOS 15+: `supportsMultichannelContent = true`

Background audio is enabled in `Info.plist` (`UIBackgroundModes = audio`).

## Remote commands

`configureRemoteCommands()` registers handlers on `MPRemoteCommandCenter.shared()`:

- `playCommand` → `onRemotePlaybackChange(true)`
- `pauseCommand` → `onRemotePlaybackChange(false)`
- `togglePlayPauseCommand` → `onRemotePlaybackChange(!isPlaying)`

`AppModel` consumes the callback and toggles via the same path the UI uses, so lock-screen / AirPlay / BT controls behave identically to the in-app button.

`updateNowPlayingInfo()` updates `MPNowPlayingInfoCenter` (title, elapsed time, artwork). Called on play / pause and at intervals during playback for the elapsed-time field.

## Tonal bed (procedural pad)

[`TonalBedSynth`](../../../ios-native/OasisNative/Services/TonalBedSynth.swift) renders an `AVAudioSourceNode` with three voices (fundamental + perfect fifth at 1.5× + octave at 2×). Base amplitude `0.18` (~15 dB below ambient bus). Frequencies and amplitude are linearly ramped to avoid clicks.

`applySignature(_:)` accepts a "signature" derived from the dominant active channel's tonal group (D3, B2, C3 minor, G3 sus4, A2 neutral, A2 major, C3 open — see [content/sounds-catalog.md](../content/sounds-catalog.md)). The fundamental locks to that group's anchor note.

The pad is **off by default since v1.4.1**. Toggled via `AppModel.isTonalBedEnabled`. UI: `BinauralPanel` (bottom of the panel).

## Audio assets

- Format: `.m4a`, AAC-LC, 96 kbps, stereo, 44.1 kHz.
- Encoded via 2-pass `loudnorm` to `I=-20 LUFS, TP=-1.5 dBTP, LRA=11 LU`, with `linear=true` (no dynamic compression). Transient-heavy additions can use stricter per-file true-peak/limiter settings after validation; see [../content/sounds-catalog.md](../content/sounds-catalog.md).
- Brick-wall limiter `alimiter=limit=0.71:level=false` (~ -3 dBFS).
- ~426 MB total bundle weight.

Full pipeline rationale and per-file measurements: [../content/sounds-catalog.md](../content/sounds-catalog.md).

## Sync barrier (`sync(with:)`)

`AudioMixerEngine.sync(with: AppModel)` is the single coupling point. Whenever `AppModel` mutates anything the engine cares about, `AppModel` calls `sync` so the engine reconciles its players, fades, and spatial positioning to match. This is intentionally one-directional: the engine does not push state back into `AppModel` except via the two callbacks `onRemotePlaybackChange` and `onVariationChanged`.
