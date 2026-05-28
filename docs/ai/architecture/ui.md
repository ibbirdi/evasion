---
title: UI System
status: stable
last_updated: 2026-05-28
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
    ├── .sheet  BinauralPanel
    ├── .sheet  SpatialAudioPanel
    ├── .sheet  SoundDetailSheet (per-channel)
    └── .fullScreenCover PaywallOverlay
```

`HomeView` owns the navigation toolbar. The leading item is `HomeToolbarImmersiveAudioToggle`, a compact native button for the global immersive audio mode. When enabled, it reveals a small subtitle-style "Immersive sound" label next to the icon only in normal mixer browsing; during saved ambiences and rituals it collapses to icon-only so the active status can breathe. Trailing items remain the timer and active-channel filter controls during normal browsing, but the active-channel filter hides while a saved ambience is active because that state already filters the mixer to the relevant sounds. The active-channel filter badge appears only while that filter is engaged, so remaining audible tracks after stopping an ambience do not make the toolbar look selected. The central brand lockup can render a subtle mix constellation: Canvas-drawn shooting-star trails derived from active ambient channels, procedural noise layers, and binaural playback orbit the logo while audio is playing. The bottom actions live in one grouped glass rail instead of separate floating circles: playback stays visually dominant in the centre, while My Ambiences, Shuffle, binaural, and route picker recede as quieter secondary controls; all bottom-bar circles share the same border width and inactive opacity so AirPlay/route picker does not read as a different control family. The first bottom-bar action opens `ComposePanel`, now the single full-screen My Ambiences surface; the second action runs `randomizeMix()` directly instead of opening the removed iOS Presets panel. Selector capsules in My Ambiences are image-led for every saved ambience; they do not show leading glyphs, and their titles require a strong black text shadow for legibility over photos/textures. System actions such as play, pause, shuffle, close, timer, and AirPlay remain SF Symbols/native controls. After an ambience starts, active ambient rows stay in the canonical sound order, inactive rows are hidden, row controls become read-only/visually muted until the ambience is explicitly stopped or replaced, and Home shows a compact borderless `home.ambience.status` capsule with the active ambience name and countdown in the toolbar principal area. That capsule is tappable and reopens `ComposePanel`; a separate `home.ambience.stop` button clears the active ambience title, timer, and active-only filter so Home returns to normal mixing without stopping the current sound mix. Home does not insert a separate active-scene widget between sound rows, so the mixer remains a clean list of sounds. Manual browsing also keeps the canonical `SoundChannel.allCases` order when a user activates or mutes a row; active rows should never jump to a promoted top section unless a future explicit sort mode is added. Short/free ambience states can also show a quiet `home.ambience.rest-cue` footer that reassures the user the ambience will hold steady and fade at the end. During that focused listening state, the bottom rail simplifies to playback and route picker only; the ambience status capsule is the adjustment path, while Shuffle and binaural return when the user is back in normal/manual mixing. The free-tier library teaser is a photo-backed ambient card with one dominant premium CTA and a quiet list toggle, not a text-heavy upsell block. It is hidden during active rituals, intact saved ambiences, and active procedural-noise sessions so the listening screen stays calm and task-focused; it returns when the user is back in normal browsing/manual ambient mixing. The older timer countdown indicator stays below the header only when no ritual or saved ambience is active.

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

`PaywallOverlay` always presents as full-screen — no half-modal — to keep focus on the conversion moment. Its iOS layout is now image-led rather than checklist-led: a Pexels beach hero (`paywall_beach_background`, Pok Rie photo 673865) leads with the lifetime/no-subscription trust line, a shortened feature subtitle, four compact benefit tiles with distinct SF Symbols, one dominant sand/foam CTA, and quiet restore/help footer actions. Keep the main paywall away from green/mint art direction; its palette should stay close to the photo's pink sand, white foam, and muted blue-grey water. The benefit grid is typed by premium value, so paywalls can sell 32 extra sounds, 4 extra noise layers, saved ambiences, longer timers, or binaural modes without falling back to generic checkmarks or stale Composer copy. Saved ambience management now lives inside `ComposePanel` instead of a separate iOS Presets panel. Saving is a single top-level "Save this ambience" action with a fixed lavender/blue gradient, not the selected ambience tint: free users see the preset upsell, while Premium users open a separate full-screen editor for name/background selection. User-created ambiences expose a small pencil button directly on their selector pill; tapping it opens the full-screen editor where they can be renamed, restyled, or deleted. Built-in Oasis mixes remain selectable but not destructive.

`BinauralPanel` leads with one organic texture-backed hero card that combines the panel title, active mode/frequency, headphone hint, enable toggle, and volume slider. The four mode cards below are intentionally quiet: each card uses a small fixed-width waveform strip whose density follows the track's representative beat frequency, plus lock/check state, so the panel reads as one listening mode selector rather than a technical dashboard.

`ComposePanel` is the full-screen home for saved ambiences. It is intentionally no longer a Composer/Rituals/Noise Lab control centre, and the old iOS Presets panel is no longer presented from Home. The surface is titled "My ambiences" / "Mes ambiances"; free saved Oasis mixes are grouped first, followed by locked Premium mixes. A compact duration row lets the user choose infinite, 15, 30, 60, or 120 minutes before launching; the selected duration overrides the preset timer for that run, with the usual Premium gate for long timers or premium layers. Users save the current ambience from the top of this panel; saving is Premium-only and routes free users to the preset upsell. Premium creation and editing happen in a separate full-screen `AmbienceEditorSheet` that captures a name plus one visual background chosen from the app's background library; the selected asset is stored on the `Preset` as `backdropAssetName`. The background picker grid must render every image inside fixed-size tiles, cropping the source image inside the tile so source aspect ratios never change row height or cell width. Selector pills are photo-backed for every ambience, omit the leading intent glyph, and use a large black text shadow for title readability. User-created ambiences show a small trailing pencil button directly on the pill, replacing the older manage-toggle flow; that button opens the same editor for rename, restyle, or delete. One large texture/photo-backed detail card explains what will happen before playback: soundscape layers, noise-cover layers, the selected fade-out chip when finite, and a small non-interactive spatial preview that places the chosen sound layers around a listener dot. Locked Premium ambiences still preview their full intended mix, show a compact lock/Premium treatment, and route the CTA through the existing Composer upsell instead of applying a downgraded free fallback. That preview exists to make the ambience feel intentional instead of random; it must stay decorative and compact, not become another control surface. Ambience hero titles use dark text shadow over imagery, and plan-row capsule backgrounds must be clipped to their rounded shape so gradient fills never square off the corners. Ambience layer summaries must account for more than three active sounds: show the most readable leading items and append a compact `+N` overflow instead of silently dropping Premium layers. The pinned CTA launches, replaces, stops, or upsells depending on the selected ambience, duration, and state, but its visual gradient is fixed green/gold and distinct from the save CTA rather than selected-ambience-driven. Starting an unlocked ambience applies the recipe, starts playback, briefly confirms the action in-place, then dismisses the sheet. There is no prompt field, manual noise list, guided-routine list, management toggle, or active-scene widget in the default path. Keep this feature value-led: if a control does not help the user understand and reach a calmer sleep/focus state in a couple of taps, do not expose it here.

## Component library (`Views/Components/`)

| Component | Role |
| --- | --- |
| `GlassSurfaces` | Backdrop-blur frosted glass containers (cards, panels). Wraps `iOS 26+ glassEffect` when available. |
| `AnimatedLiquidAura` | Liquid blob aura around the play button when audio is active. Paused under XCUITest. |
| `AnimatedBackdrop` | Static full-screen deep blue/grey backdrop. It intentionally does not adapt to selected or playing channel tints. |
| `SoundBackdropImage` / `OrganicBackdropImage` | Shared visual watermark renderers. Ambient places use the darker `SoundBackdropImage` treatment with `Assets.xcassets/SoundBackgrounds`; non-place concept cards and binaural cards use the brighter `OrganicBackdropImage` treatment with `Assets.xcassets/OrganicBackgrounds`. My Ambiences also exposes `AmbienceBackdropLibrary`, which combines sound, organic, binaural, and extra Pexels ambience images for the save background picker. |
| `OasisGlyphImage` | Template renderer for the curated Phosphor SVG subset stored in `Assets.xcassets/OasisGlyphs`. Use it for Oasis-specific concepts such as masking, ambience layers, included-state badges, ambient-channel identity, minimap pins, and preset preview chips. |
| `HomeHeaderView` | Floating OASIS wordmark with the old two counter-rotating logo rings retained behind the private `showsLogoRings` switch but disabled by default. The iOS lockup is intentionally compact (`BrandLockupView` about 0.84×, internal wordmark about 0.82×) for App Store screenshots. Active-mix accents render as closer-in Canvas-drawn shooting-star trails around the logo: each meteor samples a longer span of its previous positions along the same rotating and radially breathing trajectory, so the tail follows the real path instead of staying parallel to a fixed circle. The trail layer fades out softly when playback stops; trails and any re-enabled rings freeze under screenshot automation / Reduce Motion. |
| `HomeToolbarImmersiveAudioToggle` | Top-left native toolbar button for the persisted global immersive audio mode. |
| `MixerBoardSectionView` | Mixer list. Inactive rows visually show only the sound name plus quiet controls; active rows can show a compact region label, while the full recording location stays in the accessibility label and detail sheet. Active row backgrounds stay neutral and translucent instead of adding a channel-tinted wash, so the place photo remains visible behind the controls. Procedural noise rows live at the end of the mixer behind a small `Noise Lab` divider with on/off and volume controls, so ambience-applied white/brown/pink/etc. layers remain manually adjustable after leaving focused listening without interrupting the ambient track order. The list preserves canonical sound order while browsing: toggling a row changes state in place and does not promote active sounds to the top. Active saved ambiences derive rows from the active mix, show only active ambient/noise rows in canonical order, and lock row controls until the ambience is explicitly stopped or replaced. |
| `HapticSlider` | Slider with `sensoryFeedback` haptics on tick. Also hosts `AutoVariationRangeSlider`, the two-handle volume interval control used when a channel is in auto-variation mode; only the two handles are draggable, not the track between them. |
| `SoundLocationMinimap` | 2D minimap for sound placement, `[-1, 1]` coordinate space. |
| `PremiumSurfaces` | Reusable upsell card and inline teaser elements. |
| `BottomBarView` | Grouped glass playback rail. Secondary actions are visually quiet; playback is the primary centre control. Secondary buttons, the route picker, and the larger playback button share one circle-border style, with only size and active aura changing hierarchy. The My Ambiences button highlights only while an ambience/ritual is active, a named noise blend is intact, or the My Ambiences panel is open; leftover procedural noise from a stopped ambience stays editable in the mixer but does not keep the button highlighted. During an active saved ambience, it reduces to playback and audio output only; ambience adjustment moves to the active-status capsule in the toolbar so the listening state does not feel like a full control desk. |
| `PressScaleButtonStyle` | Tactile scale-on-press button style applied app-wide. |

`PressScaleButtonStyle.swift` also hosts the shared UI helpers:
- `.oasisFont(...)` for Dynamic Type-aware rounded/system typography while preserving the app's compact visual scale.
- `.oasisMinimumHitTarget(...)` for 44 pt minimum interaction zones around visually smaller controls.
- `OasisGlyphImage` for app-owned template glyph rendering.

Rounded image-led surfaces must clip the whole composed container, not only the image child. Apply the clip after fills, backdrop images, and gradient overlays, then draw the stroke border above the clipped result; otherwise rectangular gradient/material layers can leak past the intended corner radius on Paywall, My Ambiences, Binaural, Presets, or Mac rows.

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

Per-track and concept backgrounds are secondary texture, not primary content. `SoundChannel.backdrop` maps ambient tracks to Pexels place photos and `BinauralTrack.backdrop` maps conceptual binaural tracks to `OrganicBackdrop` textures. Ambient rows keep a neutral material/gradient layer above the photo so labels, sliders, and lock states remain readable without tinting active tracks; Composer concept cards can run brighter because they are image-led buttons with very little text.

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
- **Header + bottom bar**: `home.scroll`, `home.header.immersive`, `home.header.timer`, `home.header.timer.countdown`, `home.ambience.status`, `home.ambience.stop`, `home.ambience.rest-cue`, `home.ritual.active`, `home.bottom.{compose,shuffle,playback,routepicker,binaural}`.
- **Panels** (sheets): `panel.compose.container`, `panel.spatial.container`, `panel.binaural.container`, `panel.sound-detail.container`, `panel.timer.unlock`.
- **My Ambiences panel**: `compose.ambience.<id>` for saved ambience selector pills, `compose.ambience.<id>.edit` for the small edit button shown on user-created ambiences, `compose.ambience.duration` for the duration choices, `compose.ambience.save` for opening the save flow or preset upsell, `compose.ambience.editor` for the full-screen create/edit/delete surface, `compose.ambience.detail` for the explanatory ambience card, `compose.ambience.plan` for the "what will happen" section heading, `compose.ambience.start` for the pinned Start CTA, and `panel.compose.container`.
- **Shuffle**: `home.bottom.shuffle` calls `randomizeMix()` directly from the bottom bar.
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
