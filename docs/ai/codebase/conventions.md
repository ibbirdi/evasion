---
title: Code Conventions
status: stable
last_updated: 2026-05-20
tracks:
  - "ios-native/OasisNative/**/*.swift"
  - "ios-native/OasisNative/Support/L10n.swift"
related:
  - "structure.md"
  - "../architecture/ui.md"
  - "../operations/known-issues.md"
---

# Code Conventions

Patterns this codebase has settled on. Follow these by default — diverge only with a reason that fits in a one-line comment.

## Language

- **Code, identifiers, comments**: English only.
- **UI strings**: never hardcoded. Always go through `L10n` (`Support/L10n.swift` keys, `Resources/Localizable.xcstrings` translations).
- **User-facing copy in 6 locales**: `en-US, fr-FR, de-DE, es-ES, it, pt-BR`.
- **Sound-placement wording**: user-facing copy says "sound placement" / localized equivalents, not "3D audio" or "spatial audio".

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
- The menu bar status item sends its action on mouse-down so the first click after launch is not swallowed by `LSUIElement` activation. Defer panel presentation by one MainActor yield before touching SwiftUI/AppKit layout; opening a SwiftUI-backed `NSPanel` directly inside button tracking can trip AttributeGraph on recent macOS builds.

### Animation

- Default: `.animation(.smooth, value: …)`. Use `.spring` only when the result is intentional.
- Continuous animations (auras, waveform) **must** check `AppConfiguration.isRunningUITests` and freeze when true. Otherwise XCUITest hangs.
- Continuous decorative animations must also respect `accessibilityReduceMotion`.
- macOS continuous meshes such as the menu bar play button must also pause for screenshot automation and inactive scene phase, because the menu bar panel is often validated through scripted builds/screenshots.

### Accessibility and sizing

- Use `.oasisFont(...)` for app UI text so typography participates in Dynamic Type while keeping Oasis' compact rounded style.
- Use `.oasisMinimumHitTarget()` around icon-only or visually compact controls; the visible chrome may stay smaller, but the tappable area should be at least 44 pt.
- Hide decorative SF Symbols from VoiceOver when the surrounding button/row already provides the semantic label.
- If a custom gesture is required, provide a button or custom accessibility action path too.

### Sheets and covers

- `.sheet(item:)` for modals carrying a payload.
- `.fullScreenCover` only for the paywall (focus moment).
- Never push the paywall via `NavigationStack`; always present.

## Naming

### Sound channels

Channel IDs are **lowercase French** (legacy from initial design):

```
oiseaux, vent, plage, goelands, foret, pluie, tonnerre, cigales, grillons,
tente, riviere, village, mer, orageMontagne, campfire, cafe, lac,
savane, jungleAmerique, jungleAsie
```

These IDs are persisted in user `UserDefaults` payloads. **Renaming a case requires a migration** in `PersistedMixerState` decoding. Don't rename casually.

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
