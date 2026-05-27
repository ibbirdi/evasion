---
title: UI System
status: stable
last_updated: 2026-05-27
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
    ├── .fullScreenCover ComposePanel
    ├── .fullScreenCover PresetsPanel
    ├── .sheet  BinauralPanel
    ├── .sheet  SpatialAudioPanel
    ├── .sheet  SoundDetailSheet (per-channel)
    └── .fullScreenCover PaywallOverlay
```

`HomeView` owns the navigation toolbar. The leading item is `HomeToolbarImmersiveAudioToggle`, a compact native button for the global immersive audio mode. When enabled, it reveals a small subtitle-style "Immersive sound" label next to the icon only in normal mixer browsing; during guided routines and rituals it collapses to icon-only so the active status can breathe. Trailing items remain the timer and active-channel filter controls during normal browsing, but the active-channel filter hides while a guided routine is active because the routine surface already filters the mixer to the relevant sounds. The active-channel filter badge appears only while that filter is engaged, so remaining audible tracks after stopping a routine do not make the toolbar look selected. The central brand lockup can render a subtle mix constellation: Canvas-drawn shooting-star trails derived from active ambient channels, procedural noise layers, and binaural playback orbit the logo while audio is playing. The bottom actions live in one grouped glass rail instead of separate floating circles: playback stays visually dominant in the centre, while Routines, presets, binaural, and route picker recede as quieter secondary controls. The first bottom-bar action opens `ComposePanel`, now a full-screen guided Routines picker rather than a multi-tab control centre. The Routines button, routine status pill, routine sheet, channel rows, detail sheet, minimap pins, and preset preview chips use the curated `OasisGlyph` Phosphor subset for Oasis-owned concepts; system actions such as play, pause, close, timer, and AirPlay remain SF Symbols/native controls. After a routine starts, active ambient rows promote to the top of the mixer, inactive rows are hidden, and Home shows a compact `home.routine.status` capsule with the active routine name, countdown, and a tiny remaining-time progress line in the toolbar principal area. That capsule is tappable and reopens `ComposePanel`; a separate `home.routine.stop` button clears the guided routine, timer, and active-only filter so Home returns to normal mixing without stopping the current sound mix. Home does not insert a separate active-scene widget between sound rows, so the mixer remains a clean list of sounds. Guided routines can contain many Premium layers: Home derives routine rows directly from the active mix, keeps the first five audible ambient layers as direct controls, then folds quieter extras into a non-interactive `home.routine.supporting-layers` row so the user understands the full mix without turning the screen into a control desk. The supporting row lists up to three quieter layers and only appends `+N` for layers hidden beyond that visible list. Short/free routine states can also show a quiet `home.routine.rest-cue` footer that reassures the user the routine will hold steady and fade at the end. During that guided listening state, the bottom rail simplifies to playback and route picker only; the routine status capsule is the adjustment path, while presets and binaural return when the user is back in normal/manual mixing. The free-tier library teaser is a photo-backed ambient card with one dominant premium CTA and a quiet list toggle, not a text-heavy upsell block. It is hidden during active rituals, intact guided scenes, and active procedural-noise sessions so the listening screen stays calm and task-focused; it returns when the user is back in normal browsing/manual ambient mixing. The older timer countdown indicator stays below the header only when no ritual or guided routine is active.

Onboarding is a single overlay file: `Views/Overlays/OnboardingView.swift`. Its final page offers two explicit exits: unlock lifetime access (opens the full paywall after completing onboarding) or start free.

## macOS top-level structure

`OasisMacApp` is an accessory app (`LSUIElement`) exposed through an AppKit `NSStatusItem`. The status item uses a fixed `wind` SF Symbol as a template image and leaves `contentTintColor` nil, so AppKit renders the normal menu bar colour for the current appearance and the icon does not change between play and pause states. Clicking it opens a custom borderless `NSPanel` anchored under the status item. The panel's ideal size is `560 × 792`: a `560 × 780` content body plus a 12 pt top arrow that points back to the invoking status item. It presents [`MacMixerPanel`](../../../ios-native/OasisNative/Views/Mac/MacMixerPanel.swift), which reuses the same `AppModel` as iOS.

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

macOS intentionally uses native desktop controls where they fit: segmented pickers, `Menu`, switch toggles, popovers, hover help, compact icon buttons, scrollable lists, and a panel-like density. The mixer keeps sounds in `SoundChannel.allCases` order to match iOS. Each sound row has a small info button that opens the shared `SoundDetailSheet` as an in-panel overlay with its Apple Maps minimap and explicit close button, avoiding AppKit's separate square sheet window over the rounded menu bar panel. Sound placement is edited from each row's dedicated placement button rather than a separate tab. AUTO volume reuses the shared `AutoVariationRangeSlider` so min/max bounds stay editable on both platforms. The main mixer list hides the default macOS scroller, overlays a thin custom indicator, and fades its top/bottom edges with an alpha mask driven by native `ScrollGeometry`. The menu bar panel background is a more transparent material surface clipped to a custom popover shape; `MacPanelChromeState` keeps the arrow aligned with the status item while the `NSPanel` itself stays borderless and clear. The header stays minimal: compact counter-rotating OASIS ring logo lockup, play button, immersive toggle, timer, shuffle, AirPlay route picker, and quit only. Because the macOS lockup renders the bitmap logo much smaller than iOS, its ring artwork opts into high-quality interpolation, antialiasing, and offscreen drawing after rotation to avoid shimmer/pixelation without changing the iOS-like animation or exposure.

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

`PaywallOverlay` always presents as full-screen — no half-modal — to keep focus on the conversion moment. Its iOS layout is now image-led rather than checklist-led: an organic Pexels texture hero leads with the lifetime/no-subscription trust line, a shortened feature subtitle, four compact benefit tiles with distinct SF Symbols, one dominant lifetime CTA, and quiet restore/help footer actions. `PresetsPanel` also presents full-screen because it is now a saved-ambience surface: save the current mix, inspect saved mixes, reorder, delete, and load. Saving is a single "Save this ambience" button that opens a native name-entry alert. The default state prioritises choosing a mix; reorder/delete controls stay hidden until the user taps the localized Manage button, and destructive delete still asks for confirmation. Preset rows show a small visual thumbnail derived from the loudest active ambient channel, falling back to an organic texture for concept/noise-only mixes, plus compact ambience preview chips for the most decision-useful parts of the snapshot: key channels, procedural noise, timer, binaural, and a `+N` overflow when needed.

`BinauralPanel` leads with one organic texture-backed hero card that combines the panel title, active mode/frequency, headphone hint, enable toggle, and volume slider. The four mode cards below are intentionally quiet: no repeated waveform icon, only a tint rule plus lock/check state, so the panel reads as one listening mode selector rather than a technical dashboard.

`ComposePanel` is a full-screen guided wellbeing shortcut. It is intentionally no longer a three-tab Composer/Rituals/Noise Lab control centre. The surface is titled "Routines" and uses a two-step guided pattern: an 8-item selector with exactly 2 free routines first (Short nap, Soft reset) and 6 locked Premium routines after them (Deep sleep, Deep work, Noisy hotel, Evening reading, Rain cabin, Gentle morning); then one large organic texture-backed detail card that explains what will happen before playback: soundscape layers, noise-cover layers, the automatic fade-out chip, and a small non-interactive spatial preview that places the chosen sound layers around a listener dot. Locked Premium routines still preview their full intended mix, show a compact lock/Premium treatment, and route the CTA through the existing Composer upsell instead of applying a downgraded free fallback. That preview exists to make the recipe feel intentional instead of random; it must stay decorative and compact, not become another control surface. Routine hero titles use dark text shadow over organic imagery, and plan-row capsule backgrounds must be clipped to their rounded shape so gradient fills never square off the corners. Routine layer summaries must account for more than three active sounds: show the most readable leading items and append a compact `+N` overflow instead of silently dropping Premium layers. The pinned CTA launches, replaces, stops, or upsells depending on the selected routine and state. Starting an unlocked routine applies the deterministic recipe, starts playback, briefly confirms the action in-place, then dismisses the sheet. There is no prompt field, manual noise list, or active-scene widget in the default path. Keep this feature value-led: if a control does not help the user understand and reach a calmer sleep/focus state in a couple of taps, do not expose it here.

## Component library (`Views/Components/`)

| Component | Role |
| --- | --- |
| `GlassSurfaces` | Backdrop-blur frosted glass containers (cards, panels). Wraps `iOS 26+ glassEffect` when available. |
| `AnimatedLiquidAura` | Liquid blob aura around the play button when audio is active. Paused under XCUITest. |
| `AnimatedBackdrop` | Static full-screen deep blue/grey backdrop. It intentionally does not adapt to selected or playing channel tints. |
| `SoundBackdropImage` / `OrganicBackdropImage` | Shared visual watermark renderers. Ambient places use the darker `SoundBackdropImage` treatment with `Assets.xcassets/SoundBackgrounds`; non-place concept cards and binaural cards use the brighter `OrganicBackdropImage` treatment with `Assets.xcassets/OrganicBackgrounds`. |
| `OasisGlyphImage` | Template renderer for the curated Phosphor SVG subset stored in `Assets.xcassets/OasisGlyphs`. Use it for Oasis-specific concepts such as routine intents, masking, ambience layers, included-state badges, ambient-channel identity, minimap pins, and preset preview chips. |
| `HomeHeaderView` | Floating OASIS wordmark centered inside two same-size counter-rotating logo rings. The iOS lockup is intentionally compact (`BrandLockupView` about 0.84×, internal wordmark about 0.82×) so the OASIS letters stay inside the ring in App Store screenshots. The rings start offset, use balanced additive blending, and are darkened as a group so colours mix without overexposing the lockup. Active-mix accents render as Canvas-drawn shooting-star trails around the logo: each meteor samples its previous positions along the same rotating and radially breathing trajectory, so the tail follows the real path instead of staying parallel to a fixed circle. The trail layer fades out softly when playback stops; rings and trails freeze under screenshot automation / Reduce Motion. |
| `HomeToolbarImmersiveAudioToggle` | Top-left native toolbar button for the persisted global immersive audio mode. |
| `MixerBoardSectionView` | Mixer list. Inactive rows visually show only the sound name plus quiet controls; active rows can show a compact region label, while the full recording location stays in the accessibility label and detail sheet. Procedural noise rows live at the end of the mixer behind a small `Noise Lab` divider with on/off and volume controls, so routine-applied white/brown/pink/etc. layers remain manually adjustable after leaving guided mode without interrupting the ambient track order. Guided routine sessions derive rows from the active mix, show only active ambient/noise rows, and remove ambient placement/auto/check controls while preserving volume/mute adjustment. Premium routines may have many active layers, so the guided state caps direct ambient row controls to the first five audible layers and uses a supporting-layers row for quieter extras. |
| `HapticSlider` | Slider with `sensoryFeedback` haptics on tick. Also hosts `AutoVariationRangeSlider`, the two-handle volume interval control used when a channel is in auto-variation mode; only the two handles are draggable, not the track between them. |
| `SoundLocationMinimap` | 2D minimap for sound placement, `[-1, 1]` coordinate space. |
| `PremiumSurfaces` | Reusable upsell card and inline teaser elements. |
| `BottomBarView` | Grouped glass playback rail. Secondary actions are visually quiet; playback is the primary centre control. The Routines button highlights only while a routine/ritual is active, a named noise blend is intact, or the Routines panel is open; leftover procedural noise from a stopped routine stays editable in the mixer but does not keep the button highlighted. During an active guided routine, it reduces to playback and audio output only; routine adjustment moves to the active-status capsule in the toolbar so the listening state does not feel like a full control desk. |
| `PressScaleButtonStyle` | Tactile scale-on-press button style applied app-wide. |

`PressScaleButtonStyle.swift` also hosts the shared UI helpers:
- `.oasisFont(...)` for Dynamic Type-aware rounded/system typography while preserving the app's compact visual scale.
- `.oasisMinimumHitTarget(...)` for 44 pt minimum interaction zones around visually smaller controls.
- `OasisGlyphImage` for app-owned template glyph rendering.

Rounded image-led surfaces must clip the whole composed container, not only the image child. Apply the clip after fills, backdrop images, and gradient overlays, then draw the stroke border above the clipped result; otherwise rectangular gradient/material layers can leak past the intended corner radius on Paywall, Routines, Binaural, Presets, or Mac rows.

## macOS views (`Views/Mac/`)

macOS-specific views live in `Views/Mac/` and are not compiled into the iOS target. They may reuse shared models, services, tokens, `L10n`, and lightweight shared components, but presentation stays desktop-specific.

`macLiquidGlass(in:interactive:)` is the macOS-only glass helper. It uses native `glassEffect` on macOS 26+ and falls back to material backgrounds on earlier macOS versions, so buttons, chips, search fields, and row surfaces can share one treatment without raising the deployment target. The main `MacPanelBackground` uses a stable `.ultraThinMaterial` plus a subtle dark tint, because the top-arrow custom shape needs deterministic screenshot rendering while staying visibly more transparent than the original rounded panel.

The macOS target deliberately does not set `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`; otherwise the legacy neon-green `AccentColor` asset tints native segmented pickers. Use `MacDesign.accent` for the local macOS tint so switches and segmented controls stay pastel and aligned with the Oasis palette. iOS can keep its existing asset setting until the accent asset is normalised.

## Design tokens

Per-channel **tint** is the dominant token: each `SoundChannel` carries an `RGB` tuple in `SoundChannelMetadata.swift`, plus an `OasisGlyph` for the app-owned icon layer. `ChannelMetadata.tint` applies a central HSB saturation/brightness boost for a more vibrant runtime colour, and that tint flows into:

- The channel card background gradient.
- The minimap pin.
- The active-channel ribbon in the play button.
- The `LiquidActivityPalette.playback()` ordering — see below.

The global app backdrop stays static in a deep blue/grey range for visual sobriety; do not reintroduce active-channel colour adaptation there unless the product direction changes again.

Per-track and concept backgrounds are secondary texture, not primary content. `SoundChannel.backdrop` maps ambient tracks to Pexels place photos and `BinauralTrack.backdrop` maps conceptual binaural tracks to `OrganicBackdrop` textures. Rows keep opacity under ~18%, with the existing tint gradients and glass material above the photo so labels, sliders, and lock states remain the readable layer; Composer concept cards can run higher because they are image-led buttons with very little text.

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
- **Noise rows** (per procedural layer; `<id>` = `white`, `brown`, `pink`, `green`, `fan`, `aircraft`): `noise.section`, `noise.row.<id>`, `noise.identity.<id>`, `noise.mute.<id>`, `noise.slider.<id>`.
- **Header + bottom bar**: `home.scroll`, `home.header.immersive`, `home.header.timer`, `home.header.timer.countdown`, `home.routine.status`, `home.routine.stop`, `home.routine.rest-cue`, `home.routine.supporting-layers`, `home.ritual.active`, `home.bottom.{compose,playback,routepicker,presets,binaural}`.
- **Panels** (sheets): `panel.compose.container`, `panel.spatial.container`, `panel.presets.container`, `panel.presets.close`, `panel.binaural.container`, `panel.sound-detail.container`, `panel.timer.unlock`.
- **Routines panel**: `compose.guided.<id>` for the four selector pills, `compose.routine.detail` for the explanatory routine card, `compose.routine.plan` for the "what will happen" section heading, `compose.routine.start` for the pinned Start CTA, and `panel.compose.container`.
- **Screenshot automation compatibility**: under `AppConfiguration.isRunningScreenshotAutomation`, the compose slot temporarily exposes `home.bottom.shuffle` and calls `randomizeMix()` so existing App Store and marketing scenarios keep working.
- **Spatial drag target**: `spatial.stage` — the drag stage inside `SpatialAudioPanel`. Carries `.accessibilityElement(children: .ignore)` plus a label so XCUITest can target it for synthetic drag gestures (the underlying ZStack would otherwise not register as an accessibility leaf).
- **Presets / binaural / timer rows**: `presets.list`, `presets.row.<id>`, `presets.row.button.<id>`, `presets.name`, `presets.save`, `binaural.track.grid`, `binaural.track.<id>`, `timer.unlock.option.<duration>`.
- **Detail sheet**: `sound.detail.map`.
- **Paywall + teaser**: `premium.paywall.{container,primary,restore,close,retry,help,loading}`, `premium.library.teaser`, `premium.library.teaser.primary`, `premium.library.teaser.toggle`, `premium.banner{,.primary,.dismiss}`, `premium.inline.{composer,preset,binaural,primary,secondary,dismiss}`.

Convention: `<surface>.<role>[.<entity>]`. Lowercase, dot-separated, no spaces. The marketing video factory's scenario JSON references these strings verbatim — see [../marketing/video-factory.md](../marketing/video-factory.md).

## What lives where in `Views/`

```
Views/
├── HomeView.swift
├── RootView.swift
├── Mac/                        — macOS borderless menu bar mixer panel + sheets
├── Components/                — reusable building blocks (above)
└── Overlays/                  — modal sheets (Compose, Presets, Binaural, Spatial, Paywall, SoundDetail, Onboarding)
```

When adding a new view: a component goes in `Components/`, a modal or full-screen overlay in `Overlays/`, a top-level screen at `Views/`. Don't dump screens into `Components/`.
