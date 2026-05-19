---
title: UI System
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Views/**"
  - "ios-native/OasisNative/Support/Info.plist"
related:
  - "overview.md"
  - "../codebase/conventions.md"
  - "../marketing/video-factory.md"
---

# UI System

SwiftUI throughout. iOS 16+ baseline; some surfaces opt into iOS 26+ refinements (zoom transitions, glass effects).

## Global constraints

- **Dark mode only.** `Info.plist` sets `UIUserInterfaceStyle = Dark`. Don't introduce light-mode variants.
- **Portrait only.** `UISupportedInterfaceOrientations` is portrait. The mixer board and minimap assume vertical layout.
- **No accent color override.** The app uses per-channel tints; the global `accentColor` is left default.

## Top-level structure

```
RootView                     — onboarding flag check, crossfades to HomeView
└── HomeView                 — mixer board, header, playback button
    ├── .fullScreenCover PresetsPanel
    ├── .sheet  BinauralPanel
    ├── .sheet  SpatialAudioPanel
    ├── .sheet  SoundDetailSheet (per-channel)
    └── .fullScreenCover PaywallOverlay
```

`HomeView` owns the navigation toolbar. The leading item is `HomeToolbarImmersiveAudioToggle`, a compact native button for the global immersive audio mode. When enabled, it reveals a small subtitle-style "Immersive sound" label next to the icon. Trailing items remain the timer and active-channel filter controls.

Onboarding is a single overlay file: `Views/Overlays/OnboardingView.swift`. Its final page offers two explicit exits: unlock lifetime access (opens the full paywall after completing onboarding) or start free.

## SwiftUI patterns used here

### `@Observable` + `@Environment` injection

`AppModel` is created in `OasisNativeApp` and injected through the environment. Views access it with `@Environment(AppModel.self)` (no `@ObservedObject`).

### `@Namespace` zoom transitions (iOS 26+)

`HomeView` declares a `@Namespace` and uses `.navigationTransition(.zoom(sourceID:in:))` so the channel cards expand into the `SoundDetailSheet`. Falls back to a plain sheet on older iOS.

### `.sheet(item:)` for modals with payload

Most overlays bind to an optional state on `AppModel` and present when non-nil:

```swift
.sheet(item: $appModel.activeChannelDetail) { channel in
  SoundDetailSheet(channel: channel)
}
```

### `.fullScreenCover` for focused flows

`PaywallOverlay` always presents as full-screen — no half-modal — to keep focus on the conversion moment. `PresetsPanel` also presents full-screen because it is now a management surface: save the current mix, inspect saved mixes, reorder, delete, and load. Saving is a single "Save this ambience" button that opens a native name-entry alert; destructive delete asks for confirmation, and row actions / primary controls use the shared glass surface language for visual consistency with the mixer.

## Component library (`Views/Components/`)

| Component | Role |
| --- | --- |
| `GlassSurfaces` | Backdrop-blur frosted glass containers (cards, panels). Wraps `iOS 26+ glassEffect` when available. |
| `AnimatedLiquidAura` | Liquid blob aura around the play button when audio is active. Paused under XCUITest. |
| `AnimatedBackdrop` | Full-screen animated gradient/shape backdrop. |
| `WaveformSignatureLine` | Audio-reactive signature line in the header. Paused under XCUITest. |
| `HomeToolbarImmersiveAudioToggle` | Top-left native toolbar button for the persisted global immersive audio mode. |
| `MixerBoardSectionView` | One row of the mixer board. |
| `HapticSlider` | Slider with `sensoryFeedback` haptics on tick. Also hosts `AutoVariationRangeSlider`, the two-handle volume interval control used when a channel is in auto-variation mode. |
| `SoundLocationMinimap` | 2D minimap for sound placement, `[-1, 1]` coordinate space. |
| `PremiumSurfaces` | Reusable upsell card and inline teaser elements. |
| `PressScaleButtonStyle` | Tactile scale-on-press button style applied app-wide. |

`PressScaleButtonStyle.swift` also hosts the shared UI helpers:
- `.oasisFont(...)` for Dynamic Type-aware rounded/system typography while preserving the app's compact visual scale.
- `.oasisMinimumHitTarget(...)` for 44 pt minimum interaction zones around visually smaller controls.

## Design tokens

Per-channel **tint** is the dominant token: each `SoundChannel` carries an `RGB` tuple in `SoundChannelMetadata.swift`, and that tint flows into:

- The channel card background gradient.
- The minimap pin.
- The active-channel ribbon in the play button.
- The `LiquidActivityPalette.playback()` ordering — see below.

`LiquidActivityPalette.playback()` returns the tints of currently-active channels, ordered by volume. The aura cycles through them.

There is no centralised colour file beyond `SoundChannelMetadata.swift` for channel tints. Other UI colours (background, glass, text) are defined inline in their components — keep them local unless we adopt a tokens system.

## Animations

- Use `.animation(.smooth, value: …)` as default. Avoid `.spring` unless tuning is intentional.
- Crossfades for state transitions; no horizontal slides between top-level views.
- Animation durations: short (≤ 250 ms) for UI feedback, long (~ 1.6 s) for audio play fade-in synchronisation.
- Continuous decorative motion must also respect `accessibilityReduceMotion`, not only XCUITest freeze flags.

## XCUITest quiescence

`AnimatedLiquidAura` and `WaveformSignatureLine` check for `AppConfiguration.isRunningUITests` and freeze their animation state. Without this, `XCUIApplication` waits indefinitely for "no animations in progress" and screenshot UI tests run for hours. Don't add new continuous animations without applying the same pattern.

## Localisation in views

Use `Text(L10n.someKey)` (where `L10n.someKey` returns a `LocalizedStringResource`). Don't pass raw strings. See [../content/localization.md](../content/localization.md).

## Accessibility

`HapticSlider` exposes its bound value as an accessibility value. `AutoVariationRangeSlider` exposes the current lower/upper interval and custom VoiceOver actions for increasing/decreasing each bound, because the two-handle gesture is too fine to be the only control path. Channel cards expose their channel name, location, mute/locked/auto state, and hints for detail / placement actions. The paywall, presets, spatial, sound detail, timer unlock, and binaural panels have explicit labels and decorative icons hidden from VoiceOver.

`SpatialAudioPanel` keeps the draggable stage but also offers one-tap placement presets: left, front, center, back, right. This preserves the original gesture while making sound placement more discoverable and accessible.

### Identifier inventory (XCUITest)

The same identifiers serve VoiceOver and UI tests (screenshots, premium-flow tests, marketing video scenarios). Add new identifiers here when introducing a new control, not in the test files.

- **Mixer rows** (per channel; `<id>` = `pluie`, `vent`, `foret`, `tonnerre`, `mer`, `plage`, `oiseaux`, etc.): `channel.row.<id>`, `channel.identity.<id>`, `channel.mute.<id>`, `channel.slider.<id>` (single volume slider normally, two-handle auto-variation range slider when AUTO is enabled), `channel.spatial.<id>`, `channel.auto.<id>`.
- **Header + bottom bar**: `home.scroll`, `home.header.immersive`, `home.header.timer`, `home.bottom.{shuffle,playback,routepicker,presets,binaural}`.
- **Panels** (sheets): `panel.spatial.container`, `panel.presets.container`, `panel.binaural.container`, `panel.sound-detail.container`, `panel.timer.unlock`.
- **Spatial drag target**: `spatial.stage` — the drag stage inside `SpatialAudioPanel`. Carries `.accessibilityElement(children: .ignore)` plus a label so XCUITest can target it for synthetic drag gestures (the underlying ZStack would otherwise not register as an accessibility leaf).
- **Presets / binaural / timer rows**: `presets.row.<id>`, `presets.name`, `presets.save`, `binaural.track.<id>`, `timer.unlock.option.<duration>`.
- **Paywall + teaser**: `premium.paywall.{container,primary,restore,close,retry,help,loading}`, `premium.library.teaser`, `premium.library.teaser.primary`, `premium.library.teaser.toggle`, `premium.banner{,.primary,.dismiss}`, `premium.inline.{primary,secondary,dismiss}`.

Convention: `<surface>.<role>[.<entity>]`. Lowercase, dot-separated, no spaces. The marketing video factory's scenario JSON references these strings verbatim — see [../marketing/video-factory.md](../marketing/video-factory.md).

## What lives where in `Views/`

```
Views/
├── HomeView.swift
├── RootView.swift
├── Components/                — reusable building blocks (above)
└── Overlays/                  — modal sheets (Presets, Binaural, Spatial, Paywall, SoundDetail, Onboarding)
```

When adding a new view: a component goes in `Components/`, a modal or full-screen overlay in `Overlays/`, a top-level screen at `Views/`. Don't dump screens into `Components/`.
