---
title: Code Conventions
status: stable
last_updated: 2026-05-29
tracks:
  - "ios-native/OasisNative/**/*.swift"
  - "ios-native/OasisNative/Support/L10n.swift"
  - "marketing-outreach/**/*.ts"
  - "marketing-outreach/templates/**"
related:
  - "structure.md"
  - "../architecture/ui.md"
  - "../operations/known-issues.md"
  - "../marketing/outreach-crm.md"
---

# Code Conventions

Patterns this codebase has settled on. Follow these by default — diverge only with a reason that fits in a one-line comment.

## Language

- **Code, identifiers, comments**: English only.
- **UI strings**: never hardcoded. Always go through `L10n` (`Support/L10n.swift` keys, `Resources/Localizable.xcstrings` translations).
- **User-facing copy in 6 locales**: `en-US, fr-FR, de-DE, es-ES, it, pt-BR`.
- **Sound-placement wording**: user-facing copy says "sound placement" / localized equivalents, not "3D audio" or "spatial audio".
- **Marketing outreach templates**: keep operational code in English, but keep creator-facing templates localized in `fr`, `en`, `es`, `de`, `it`, and `pt-BR`. The outreach CLI must remain human-in-the-loop: no automatic sending, scraping, or platform login automation.

## Swift / SwiftUI

### Platform split

- Keep product logic in shared models/services whenever it can serve both targets (`AppModel`, `AudioMixerEngine`, premium services, `L10n`).
- Put platform entry points and platform-only UI in dedicated folders (`Mac/`, `Views/Mac/`, `Support/Platform/`) and wire them into only the relevant Xcode target.
- Hide Apple-framework differences behind small adapters or `#if os(...)` branches at the edge. Do not leak UIKit/AppKit into shared model code.
- `OasisNativeApp` and `OasisMacApp` both call `AppBootstrap.configure()`; do not duplicate RevenueCat / TelemetryDeck startup.

### State

- One root `@Observable` model: `AppModel`. Inject via `@Environment(AppModel.self)`.
- Avoid `@StateObject`, `@ObservedObject`, `ObservableObject`. The codebase is `@Observable` throughout (Swift 5.9+).
- For non-observable internal helpers in `AppModel`: `@ObservationIgnored private let …`.
- Local feature generators such as `AmbienceComposer` stay deterministic and offline for legacy prompt/ritual recipes, while `AppModel` owns applying them and enforcing premium gates. On iOS, My Ambiences is now the only saved-mix standard: it lists `Preset` snapshots, saves new ambience snapshots, and lets Premium users rename, restyle, delete, or export user-created presets without adding a second storage model. Saving or editing presets is Premium-only; free users should hit the preset upsell before any persisted preset is created or renamed. Persist the chosen selector image with `Preset.backdropAssetName` and route selectable backgrounds through `AmbienceBackdropLibrary` rather than hardcoding asset names in views. My Ambiences should sort the two free shipped ambiences before the four locked Premium ambiences, render every selector capsule with a background image and strong title shadow, expose edit affordances directly on editable ambience cards instead of through a separate manage toggle, expose a JSON export control for the iPhone-to-code authoring flow, expose a clear "what will happen" preview before playback, keep the top save action and pinned launch CTA reachable with fixed gradients rather than selection-derived tint, make the launch CTA visually distinct from the save CTA, let the user choose a finite duration or infinite playback before launch, and leave a Home status after launch rather than starting an opaque "random" state. While a saved ambience is active, prefer a calmer listening surface: relevant active rows only in canonical sound order, row controls locked/read-only until the ambience is explicitly stopped or replaced, advanced placement/auto controls hidden, bottom-bar actions reduced to playback and audio output, and the active-status capsule used as the adjustment path. The iOS bottom bar uses Shuffle as a direct action and the My Ambiences toolbar action uses `bookmark.fill`, matching the panel's save/library icon; do not reintroduce a separate iOS Presets panel entry or guided-routine surface.

### Threading

- `AppModel` is `@MainActor`.
- Audio work runs on the engine's queue (driven by `AVAudioEngine`); engine callbacks hop to main before mutating model.
- Don't introduce a second main-actor model. If you need actor isolation elsewhere, prefer a struct + `@MainActor`-isolated wrapper.

### View structure

- Top-level screens at `Views/<Name>.swift`.
- macOS-only panel surfaces at `Views/Mac/<Name>.swift`.
- Modal sheets and overlays at `Views/Overlays/<Name>.swift`.
- Reusable components at `Views/Components/<Name>.swift`.
- One view per file (with helper subviews allowed in the same file if private).
- For macOS panel glass, use `macLiquidGlass(in:interactive:)` from `Views/Mac/MacSupportViews.swift`; it gates native macOS 26 `glassEffect` behind a material fallback for the macOS 15 target.
- Keep native macOS controls visually native: use local `.tint(MacDesign.accent)` for switches and segmented pickers instead of the legacy `AccentColor` asset, and keep stronger channel/premium colours inside custom Oasis controls such as rows, badges, and the playback aura.
- Keep the menu bar status item icon local to AppKit. It currently uses a fixed template `wind` SF Symbol and leaves `contentTintColor` nil so AppKit renders the standard menu bar colour for the active appearance and selection state. Do not vary this icon by playback state.
- Keep the main menu bar panel's chrome in SwiftUI. `MacPanelPopoverShape` clips the content and draws the top arrow; `MacPanelChromeState` receives the status item anchor from `MacMenuBarPanelController`. The `NSPanel` content layer stays clear and unclipped so the arrow and transparent material are not cut off.
- The menu bar status item sends its action on mouse-down so the first click after launch is not swallowed by `LSUIElement` activation. Defer panel presentation by one MainActor yield before touching SwiftUI/AppKit layout; opening a SwiftUI-backed `NSPanel` directly inside button tracking can trip AttributeGraph on recent macOS builds. Treat `NSPanel.isVisible` as insufficient for toggle state: after `hidesOnDeactivate`, a stale visible/non-key panel must be forced through `show(relativeTo:)` instead of toggled closed.

### Animation

- Default: `.animation(.smooth, value: …)`. Use `.spring` only when the result is intentional.
- Continuous animations (auras, rotating logo rings) **must** check `AppConfiguration.isRunningUITests` and freeze when true. Otherwise XCUITest hangs.
- Continuous decorative animations must also respect `accessibilityReduceMotion`.
- When decorative motion follows a curved or breathing path, prefer a small async `Canvas` with continuous stroked paths. Use conic/linear gradients, sampled paths, and per-strand phase/velocity values for smooth ribbons; avoid per-segment round-capped strokes that read as bead strings. Header halo colours should include the active playback palette instead of only fixed brand colours.
- macOS continuous meshes such as the menu bar play button must also pause for screenshot automation and inactive scene phase, because the menu bar panel is often validated through scripted builds/screenshots.

### Accessibility and sizing

- Use `.oasisFont(...)` for app UI text so typography participates in Dynamic Type while keeping Oasis' compact rounded style.
- Use `.oasisMinimumHitTarget()` around icon-only or visually compact controls; the visible chrome may stay smaller, but the tappable area should be at least 44 pt.
- Iconography is split by role: keep SF Symbols/native controls for platform actions (play, pause, close, timer, AirPlay), and use the curated Phosphor-based `OasisGlyph` assets for Oasis-specific concepts such as ambience layers, masking layers, included-state marks, channel identity, minimap pins, and preset preview chips. Add only selected SVGs to `Assets.xcassets/OasisGlyphs` instead of vendoring a full icon package.
- When resizing OASIS logo lockups, scale any visible ring artwork, canvas/frame, vertical offset or height cap, and wordmark type together. The iOS header currently keeps its ring code behind `showsLogoRings = false`; the macOS header still renders the compact ring lockup.
- Keep the iOS header halo keyed to active source membership rather than live volume samples. Native slider drags should not reset or rebuild continuous decorative timelines.
- Hide decorative SF Symbols from VoiceOver when the surrounding button/row already provides the semantic label.
- If a custom gesture is required, provide a button or custom accessibility action path too.
- When a parent test identifier wraps tappable children, set the parent as `.accessibilityElement(children: .contain)` so SwiftUI does not propagate the parent identifier over the child button identifiers.
- When summarising a Premium ambience in the My Ambiences preview, do not assume a maximum of three active sounds. Show the leading items that fit and append a compact `+N` overflow when needed. In the active Home state, preserve `SoundChannel.allCases` order so toggling a lower row does not make it jump to the top.
- The active-ambience rest cue at the bottom of short focused-listening states is intentionally one line of copy, with equal-sized palette dots above it. Do not reintroduce a descriptive subtitle under that message.
- When reopening My Ambiences from an active ambience, seed the current ambience selection and make the CTA state explicit: "Stop ambience" for the running ambience and matching duration, and "Replace ambience" after the user selects another ambience or duration.
- My Ambiences copy should describe intent and outcome in human terms. Prefer labels like soundscape, noise cover, and fade out over technical language that makes the feature feel like an audio control desk.
- For rounded containers with images, material fills, or gradient overlays, clip the complete composed surface to the same shape before applying the border. Clipping only the image layer still lets unmasked gradient/material overlays show square corners. Mixer row cards use this pattern for both channel photos and procedural-noise material fills.
- Keep native and custom sliders visually aligned with SwiftUI's native `Slider`: no extra outer container, a full-width neutral rail, tinted selected range, round solid system-like handles that can overhang the rail edges where applicable, haptic ticks, and explicit VoiceOver actions for custom handles. Native single-value sliders should keep drag samples local to `HapticSlider`, throttle binding/model commits below the 32 Hz system reporting threshold (currently 24 Hz), and force one final commit on release. If mimicking the iOS 26 native slider interaction in custom range sliders, apply interactive Liquid Glass only to the actively dragged handle so the rail remains visible through it; avoid always-on glass handles, which visually merge into blobs instead of reading as native controls. Keep the active handle in gesture-scoped state rather than persistent `@State`, and do not implicitly animate the solid/glass body swap; otherwise interrupted drags can leave glass ghosts or transparent handles.

### Sheets and covers

- `.sheet(item:)` for modals carrying a payload.
- `.fullScreenCover` for focused flows that should not feel like transient controls: paywall, saved ambience management, and My Ambiences.
- Never push the paywall via `NavigationStack`; always present.
- Keep conversion overlays visually sparse: one dominant CTA, quiet secondary actions, and short scannable benefit tiles rather than repeated checkmark lists.

## Naming

### Sound channels

Channel IDs are **lowercase French** (legacy from initial design):

```
oiseaux, vent, plage, goelands, foret, pluie, tonnerre, cigales, grillons,
tente, riviere, village, mer, orageMontagne, campfire, cafe, lac,
savane, jungleAmerique, jungleAsie
```

These IDs are persisted in user `UserDefaults` payloads. **Renaming a case requires a migration** in `PersistedMixerState` decoding. Don't rename casually.

Per-sound background assets use stable asset names derived from these IDs, e.g. `sound_oiseaux_background` and `sound_orage_montagne_background`. Keep the asset name stable when swapping the image, and update `SoundChannel.backdrop` plus [../content/sound-backgrounds.md](../content/sound-backgrounds.md) when a source photo changes. Non-place surfaces should use `OrganicBackdrop` / `Assets.xcassets/OrganicBackgrounds` instead of borrowing a place photo from a channel. Extra save-picker imagery for personal ambiences belongs in `Assets.xcassets/RoutineBackgrounds` and must be registered in `AmbienceBackdropLibrary.extraBackdrops` with its Pexels source documented in `sound-backgrounds.md`.

There are three known mismatches between channel IDs and underlying file names — see [../operations/known-issues.md](../operations/known-issues.md):

| Channel ID | File name |
| --- | --- |
| `goelands` | `goelants1.m4a` |
| `tonnerre` | `orage1.m4a` |
| `village` | `ville1.m4a` |

These are intentional historical drift. Don't "fix" them.

### Binaural tracks

Track IDs are English: `delta`, `theta`, `alpha`, `beta`. File names are numbered + descriptive: `1_binaural_sleep_delta.m4a`, `2_binaural_meditation_theta.m4a`, etc.

### L10n keys

Dotted, all lowercase, hierarchical:

```
channel.<id>                          channel.birds, channel.wind, channel.thunder
channel.<id>.long                     longer / descriptive variant
channel.<id>.location                 location label
binaural.track.<id>                   binaural.track.delta
paywall.<scope>.<key>                 paywall.title.generic, paywall.benefits.sounds
premium.inline.<entry_point>          premium.inline.preset
presets.<scope>.<key>                 presets.panel.title, presets.default.starter
compose.<scope>.<key>                 compose.ritual.sleep.title
noise.<id>[.subtitle]                 noise.brown.subtitle
timer.option<minutes>                 timer.option15, timer.option60
header.<key>                          header.timer
spatial.<key>
onboarding.<step>.<key>
```

Add new keys in this scheme. The full list lives in `Localizable.xcstrings`; helpers are in `L10n.swift`.

### Files and types

- View files match their primary view's name (`HomeView.swift` defines `HomeView`).
- Service files match their primary type.
- Avoid umbrella files — one type per file unless clearly tightly coupled.
- Test files end in `Tests.swift` for flow tests, `Screenshots.swift` for snapshot.

## Persistence

- Always extend `PersistedMixerState` with **optional** fields for backward compat.
- Provide a sensible default in `loadPersistedState()` for old payloads.
- Never delete a stored field without a migration plan.
- For nested persisted structs such as `ChannelState`, decode new fields with `decodeIfPresent` and derive a default from existing fields when possible.

## Premium gating

- All premium gates go through `AppModel.requestPremiumAccess(from:)`. Do not call `Purchases.shared` from views.
- New gating points must add a `PremiumEntryPoint` case so analytics and the coordinator can route correctly.

## Comments

- Default to no comment. Identifiers should self-document.
- Comment only the *why*: a non-obvious constraint, a workaround, an invariant the next reader couldn't infer.
- Don't reference current tasks, PR numbers, or "TODO @author". Use the issue tracker if you have one; the codebase doesn't track those.

## Imports

- `import Foundation` first, then SwiftUI / Combine / AVFoundation, then RevenueCat / TelemetryDeck. One blank line between groups if both are present, otherwise no separator.
- No `@_implementationOnly`, no `@_exported`.

## Error handling

- Internal calls: `try?` if the failure is benign (audio scheduling occasionally fails on background interruption — handled by remaining engine state).
- User-facing: surface as `ErrorMessage` on the model and let SwiftUI present an alert. Never crash on a network or RevenueCat hiccup.

## Tests

- `OasisNativeUITests/OasisNativeScreenshots.swift` — 10 scenarios × 6 locales for fastlane.
- `OasisNativeUITests/OasisNativePremiumFlowTests.swift` — premium gating flow tests.
- Add new flow tests next to the relevant existing one. Add new screenshot scenarios with the next-numbered slug.
