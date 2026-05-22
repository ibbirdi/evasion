---
title: UI System
status: stable
last_updated: 2026-05-22
tracks:
  - "ios-native/OasisNative/Views/**"
  - "ios-native/OasisNative/Support/Info.plist"
related:
  - "overview.md"
  - "../codebase/conventions.md"
  - "../marketing/video-factory.md"
---

# UI System

SwiftUI throughout. iOS 17+ baseline for `OasisNative`, macOS 15+ for `OasisMac`; some iOS surfaces opt into iOS 26+ refinements (zoom transitions, glass effects).

## Global constraints

- **Dark mode only.** `Info.plist` sets `UIUserInterfaceStyle = Dark`. Don't introduce light-mode variants.
- **Portrait only.** `UISupportedInterfaceOrientations` is portrait. The mixer board and minimap assume vertical layout.
- **Launch screen.** `Info.plist` points to `LaunchScreen.storyboard`, which displays the `SplashScreen` asset edge-to-edge with aspect-fill cover behaviour.
- **Avoid asset-wide accent overrides.** The UI uses per-channel tints. The macOS target applies a local pastel Oasis accent through `MacDesign.accent` / `.tint(...)` for native controls, instead of the legacy neon-green `AccentColor` asset. iOS still carries the legacy asset setting until it is normalised.

## iOS top-level structure

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

## macOS top-level structure

`OasisMacApp` is an accessory app (`LSUIElement`) exposed through an AppKit `NSStatusItem`. The status item uses a fixed `wind` SF Symbol as a template image and leaves `contentTintColor` nil, so AppKit renders the normal menu bar colour for the current appearance and the icon does not change between play and pause states. Clicking it opens a custom borderless `NSPanel` anchored under the status item. The panel's ideal size is `560 × 780` and it presents [`MacMixerPanel`](../../../ios-native/OasisNative/Views/Mac/MacMixerPanel.swift), which reuses the same `AppModel` as iOS.

```
NSStatusItem
└── Borderless NSPanel
    └── MacMixerPanel
        ├── MacMixerHeader            — compact counter-rotating OASIS ring logo lockup, native MeshGradient play button, timer, random mix, AirPlay route picker, immersive toggle
        ├── segmented section picker  — mixer / presets / binaural
        ├── MacMixerSection           — search, active/all filter, iOS-order sound rows, volume/range sliders, info sheets, placement popovers
        ├── MacPresetsSection         — save, load, delete mixes
        ├── MacBinauralSection        — enable, volume, track selection
        ├── .sheet MacPaywallSheet
        └── .sheet MacInlineUpsellSheet
```

macOS intentionally uses native desktop controls where they fit: segmented pickers, `Menu`, switch toggles, popovers, hover help, compact icon buttons, scrollable lists, and a panel-like density. The mixer keeps sounds in `SoundChannel.allCases` order to match iOS. Each sound row has a small info button that opens the shared `SoundDetailSheet` as an in-panel overlay with its Apple Maps minimap and explicit close button, avoiding AppKit's separate square sheet window over the rounded menu bar panel. Sound placement is edited from each row's dedicated placement button rather than a separate tab. AUTO volume reuses the shared `AutoVariationRangeSlider` so min/max bounds stay editable on both platforms. The main mixer list hides the default macOS scroller, overlays a thin custom indicator, and fades its top/bottom edges with an alpha mask driven by native `ScrollGeometry`. The menu bar panel background is a translucent Liquid Glass/material surface, and the header stays minimal: compact counter-rotating OASIS ring logo lockup, play button, immersive toggle, timer, shuffle, AirPlay route picker, and quit only.

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
| `AnimatedBackdrop` | Static full-screen deep blue/grey backdrop. It intentionally does not adapt to selected or playing channel tints. |
| `SoundBackdropImage` | Shared photo watermark renderer for sound rows, binaural cards, and `SoundDetailSheet`; images come from `Assets.xcassets/SoundBackgrounds` and are intentionally low-opacity, desaturated, and darkened. |
| `HomeHeaderView` | Floating OASIS wordmark centered inside two same-size counter-rotating logo rings. The rings start offset, use balanced additive blending, and are darkened as a group so colours mix without overexposing the lockup. The rings freeze under screenshot automation / Reduce Motion. |
| `HomeToolbarImmersiveAudioToggle` | Top-left native toolbar button for the persisted global immersive audio mode. |
| `MixerBoardSectionView` | One row of the mixer board. |
| `HapticSlider` | Slider with `sensoryFeedback` haptics on tick. Also hosts `AutoVariationRangeSlider`, the two-handle volume interval control used when a channel is in auto-variation mode. |
| `SoundLocationMinimap` | 2D minimap for sound placement, `[-1, 1]` coordinate space. |
| `PremiumSurfaces` | Reusable upsell card and inline teaser elements. |
| `PressScaleButtonStyle` | Tactile scale-on-press button style applied app-wide. |

`PressScaleButtonStyle.swift` also hosts the shared UI helpers:
- `.oasisFont(...)` for Dynamic Type-aware rounded/system typography while preserving the app's compact visual scale.
- `.oasisMinimumHitTarget(...)` for 44 pt minimum interaction zones around visually smaller controls.

## macOS views (`Views/Mac/`)

macOS-specific views live in `Views/Mac/` and are not compiled into the iOS target. They may reuse shared models, services, tokens, `L10n`, and lightweight shared components, but presentation stays desktop-specific.

`macLiquidGlass(in:interactive:)` is the macOS-only glass helper. It uses native `glassEffect` on macOS 26+ and falls back to material backgrounds on earlier macOS versions, so the panel background, buttons, chips, search fields, and row surfaces can share one treatment without raising the deployment target. `MacPanelBackground` stays slightly transparent so the borderless menu bar panel reads as Liquid Glass rather than a flat window.

The macOS target deliberately does not set `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`; otherwise the legacy neon-green `AccentColor` asset tints native segmented pickers. Use `MacDesign.accent` for the local macOS tint so switches and segmented controls stay pastel and aligned with the Oasis palette. iOS can keep its existing asset setting until the accent asset is normalised.

## Design tokens

Per-channel **tint** is the dominant token: each `SoundChannel` carries an `RGB` tuple in `SoundChannelMetadata.swift`. `ChannelMetadata.tint` applies a central HSB saturation/brightness boost for a more vibrant runtime colour, and that tint flows into:

- The channel card background gradient.
- The minimap pin.
- The active-channel ribbon in the play button.
- The `LiquidActivityPalette.playback()` ordering — see below.

The global app backdrop stays static in a deep blue/grey range for visual sobriety; do not reintroduce active-channel colour adaptation there unless the product direction changes again.

Per-track photo backgrounds are secondary texture, not primary content. `SoundChannel.backdrop` and `BinauralTrack.backdrop` map each track to a Pexels-sourced image and crop focus. Rows keep opacity under ~18%, with the existing tint gradients and glass material above the photo so labels, sliders, and lock states remain the readable layer.

`LiquidActivityPalette.playback()` returns the tints of currently-active channels, ordered by volume. iOS uses those colours in `AnimatedLiquidAura`; macOS uses them in the native `MacAnimatedPlaybackMesh` play button, avoiding black mesh stops so active mixes stay luminous.

There is no centralised colour file beyond `SoundChannelMetadata.swift` for channel tints. Other UI colours (background, glass, text) are defined inline in their components — keep them local unless we adopt a tokens system.

## Animations

- Use `.animation(.smooth, value: …)` as default. Avoid `.spring` unless tuning is intentional.
- Crossfades for state transitions; no horizontal slides between top-level views.
- Animation durations: short (≤ 250 ms) for UI feedback, long (~ 1.6 s) for audio play fade-in synchronisation.
- Continuous decorative motion must also respect `accessibilityReduceMotion`, not only XCUITest freeze flags.

## XCUITest quiescence

`AnimatedLiquidAura`, `MacAnimatedPlaybackMesh`, and the rotating iOS/macOS header rings check screenshot automation / UI-test flags and freeze their animation state. `MacMixerPanel` also reads `-OASISMacScreenshotScenario` to seed the visible section, detail overlay, timer, binaural state, and auto-volume range for Mac App Store captures. Without these guards, automated screenshot runs can wait indefinitely for "no animations in progress" or produce nondeterministic panels. Don't add new continuous animations or screenshot scenarios without applying the same pattern.

## Localisation in views

Use `Text(L10n.someKey)` (where `L10n.someKey` returns a `LocalizedStringResource`). Don't pass raw strings. See [../content/localization.md](../content/localization.md).

## Accessibility

`HapticSlider` exposes its bound value as an accessibility value. `AutoVariationRangeSlider` exposes the current lower/upper interval and custom VoiceOver actions for increasing/decreasing each bound, because the two-handle gesture is too fine to be the only control path. Channel cards expose their channel name, location, mute/locked/auto state, and hints for detail / placement actions. The paywall, presets, spatial, sound detail, timer unlock, and binaural panels have explicit labels and decorative icons hidden from VoiceOver.

`SpatialAudioPanel` keeps the draggable stage but also offers one-tap placement presets: left, front, center, back, right. This preserves the original gesture while making sound placement more discoverable and accessible. The `center` preset is the reset action; don't add a separate "recenter sound" button.

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
├── Mac/                        — macOS borderless menu bar mixer panel + sheets
├── Components/                — reusable building blocks (above)
└── Overlays/                  — modal sheets (Presets, Binaural, Spatial, Paywall, SoundDetail, Onboarding)
```

When adding a new view: a component goes in `Components/`, a modal or full-screen overlay in `Overlays/`, a top-level screen at `Views/`. Don't dump screens into `Components/`.
