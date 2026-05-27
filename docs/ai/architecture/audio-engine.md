---
title: Audio Engine
status: stable
last_updated: 2026-05-27
tracks:
  - "ios-native/OasisNative/Services/AudioMixerEngine.swift"
  - "ios-native/OasisNative/Models/AppModels.swift"
  - "ios-native/OasisNative/Models/AmbienceModels.swift"
related:
  - "binaural.md"
  - "state.md"
  - "../content/sounds-catalog.md"
---

# Audio Engine

The ambient mixer. Implemented in [`AudioMixerEngine`](../../../ios-native/OasisNative/Services/AudioMixerEngine.swift) and shared by both iOS and macOS targets. Binaural is a separate path (see [binaural.md](binaural.md)).

## Graph

```
AVAudioEngine (ambientEngine)
└── AVAudioEnvironmentNode (environmentNode)   ← spatial + reverb
    ├── AVAudioPlayerNode  (channel oiseaux)
    ├── AVAudioPlayerNode  (channel vent)
    ├── ...
    ├── AVAudioPlayerNode  (channel cloches)      — 35 nodes, one per channel
    └── AVAudioSourceNode  (procedural noise)      — created lazily per active noise
```

`environmentNode` parameters (set in `AudioMixerEngine`):
- `distanceAttenuationParameters.distanceAttenuationModel = .linear`
- `referenceDistance = 10`, `maximumDistance = 18`, `rolloffFactor = 0` — channels stay audible at any in-app distance.
- `reverbParameters.enable = true`, `level = -18 dB` classic to about `-13 dB` immersive — subtle ambient blur.
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

## Procedural noise playback

Noise Lab layers are local `AVAudioSourceNode` generators connected to the same `environmentNode` as ambient channels. They do not ship audio files and do not need network access.

`ProceduralNoiseGenerator` produces deterministic white, brown, pink, green, fan, and aircraft-style layers from a seeded pseudo-random stream plus light filtering/oscillators. `AudioMixerEngine` lazily attaches one source node per noise type when a snapshot says it should play. Volume is just `ProceduralNoiseState.volume * masterFade`, with premium access checked before the node contributes audible output.

## Master fade

A single master multiplier `masterFade ∈ [0, 1]` is animated to mute the entire ambient bus during transitions:

| Transition | Duration | Setter |
| --- | --- | --- |
| Pause → play | 1.6 s | `transitionPlayback(to: true)` |
| Play → pause | 0.9 s default | `transitionPlayback(to: false)`; override via `setNextPauseFadeDuration(_:)` |

`animateFade(start, target, duration)` steps the value at ≥ 120 ms intervals, calling `refreshPlayerVolumes()` each tick. On fade-out completion, `pauseAllPlayers()` is called.

`refreshPlayerVolumes()` computes effective per-channel volume = `sourceVolume * masterFade * (channelState.isMuted ? 0 : 1)`, where `sourceVolume` is either `channelState.volume` or the live auto-variation value. Procedural noise and binaural paths also apply `masterFade` so play/pause transitions remain unified.

## Spatial audio

Per-channel `SpatialPoint(x, y) ∈ [-1, 1] × [-1, 1]` is mapped to the player's `position: AVAudio3DPoint`. The `AVAudioEnvironmentNode` resolves stereo bus output.

`applySpatialMixingConfiguration()` is called from `sync(with:)` and whenever `AppModel` mutates a channel's spatial position via the `SpatialAudioPanel`.

### Immersive audio mode

`AppModel.immersiveAudioEnabled` is a persisted global toggle. It affects the ambient engine path: field-recording channels and procedural noise source nodes share the `AVAudioEnvironmentNode`; binaural tracks remain on their dedicated `AVAudioPlayer` path.

When disabled, player rendering stays close to the legacy behavior:
- stereo ambience beds keep `.ambienceBed`
- mono/point sounds use `.pointSource` + `.HRTFHQ`
- the classic mapping keeps depth almost flat

When enabled, the engine crossfades an internal `immersiveBlend` over ~0.8 s and reapplies each active player's spatial config. The transition is intentionally parameter-level rather than a graph rebuild, so it can run during playback.

Profiles live in `AudioMixerEngine` as `AmbientImmersiveProfile`:
- `closeCozy` — fire, tent, window/cabin rain, cafe; closer and drier.
- `naturalOutdoor` — river, lake, beach, village, savanna, waterfall; medium distance.
- `farWeather` — thunder, mountain storm, heavy rain, wind; deeper, darker, more diffuse.
- `wideAtmosphere` — forest, rain, sea, jungle, snow; broad ambience-bed rendering.
- `smallPointSource` — birds, gulls, bells, insects, goats; precise, slightly elevated point sources.

Each profile controls distance, lateral spread, height, reverb blend, obstruction/occlusion, source mode, and rendering algorithm. This gives a maintainable place to tune the illusion of distance per sound later without changing UI state.

## Auto-variation

Per channel, an opt-in slow LFO modulates volume over time. Implemented in `AudioMixerEngine` (search for `autoVariation` / `variation`). Each channel stores an `AutoVariationRange` lower/upper bound, and the engine chooses slow random targets inside that interval.

The mixer row shows this as an editable two-handle slider when auto-variation is enabled. The same control also displays the live variation value, so the user sees the current audio level moving inside the chosen interval.

When a channel's auto-variation generates a notable change, the engine fires `onVariationChanged` so `AppModel` can persist or surface it.

## Platform audio session

The engine is shared, but session surfaces are platform-specific.

### iOS `AVAudioSession`

Configured at engine start:

- Category: `.playback`
- Options: `[.allowAirPlay, .allowBluetoothA2DP]`
- Sample rate: 44 100 Hz
- IO buffer duration: 0.046 s
- iOS 15+: `supportsMultichannelContent = true`

Background audio is enabled in `Info.plist` (`UIBackgroundModes = audio`).

### macOS

macOS does not configure `AVAudioSession`, observe route-change notifications, or publish Now Playing state from this engine. `AudioMixerEngine` keeps those branches behind `#if os(iOS)` and defaults the `AVAudioEnvironmentNode` output type to `.auto` on macOS.

## Remote commands

Remote command integration is iOS-only.

`configureRemoteCommands()` registers handlers on `MPRemoteCommandCenter.shared()`:

- `playCommand` → `onRemotePlaybackChange(true)`
- `pauseCommand` → `onRemotePlaybackChange(false)`
- `togglePlayPauseCommand` → `onRemotePlaybackChange(!isPlaying)`

`AppModel` consumes the callback and toggles via the same path the UI uses, so lock-screen / AirPlay / BT controls behave identically to the in-app button.

`updateNowPlayingInfo()` updates `MPNowPlayingInfoCenter` (title, elapsed time, artwork). Called on play / pause and at intervals during playback for the elapsed-time field.

## Audio assets

- Format: `.m4a`, AAC-LC, 96 kbps, stereo, 44.1 kHz.
- Encoded via 2-pass `loudnorm` to `I=-20 LUFS, TP=-1.5 dBTP, LRA=11 LU`, with `linear=true` (no dynamic compression). Transient-heavy additions can use stricter per-file true-peak/limiter settings after validation; see [../content/sounds-catalog.md](../content/sounds-catalog.md).
- Brick-wall limiter `alimiter=limit=0.71:level=false` (~ -3 dBFS).
- ~426 MB total bundle weight.

Full pipeline rationale and per-file measurements: [../content/sounds-catalog.md](../content/sounds-catalog.md).

## Sync barrier (`sync(with:)`)

`AudioMixerEngine.sync(with: AppModel)` is the single coupling point. Whenever `AppModel` mutates anything the engine cares about, `AppModel` calls `sync` so the engine reconciles its channel players, procedural source nodes, fades, immersive mode, and spatial positioning to match. This is intentionally one-directional: the engine does not push state back into `AppModel` except via the two callbacks `onRemotePlaybackChange` and `onVariationChanged`.
