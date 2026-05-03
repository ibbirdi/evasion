---
title: Code Conventions
status: stable
last_updated: 2026-05-03
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

## Swift / SwiftUI

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
- Modal sheets and overlays at `Views/Overlays/<Name>.swift`.
- Reusable components at `Views/Components/<Name>.swift`.
- One view per file (with helper subviews allowed in the same file if private).

### Animation

- Default: `.animation(.smooth, value: …)`. Use `.spring` only when the result is intentional.
- Continuous animations (auras, waveform) **must** check `AppConfiguration.isRunningUITests` and freeze when true. Otherwise XCUITest hangs.

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
