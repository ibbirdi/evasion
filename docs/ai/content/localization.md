---
title: Localization
status: stable
last_updated: 2026-05-29
tracks:
  - "ios-native/OasisNative/Support/L10n.swift"
  - "ios-native/OasisNative/Resources/Localizable.xcstrings"
  - "fastlane/metadata/**"
  - "scripts/screenshot_content.json"
related:
  - "sounds-catalog.md"
  - "../codebase/conventions.md"
  - "../marketing/aso-strategy.md"
---

# Localization

## Supported locales

Six locales, in order of priority:

1. `en-US` — English (United States)
2. `fr-FR` — French (France)
3. `de-DE` — German
4. `es-ES` — Spanish (Spain)
5. `it` — Italian
6. `pt-BR` — Portuguese (Brazil)

These are the locales for both:
- **In-app strings** — `Localizable.xcstrings` (single string-catalog file).
- **App Store metadata** — `fastlane/metadata/<locale>/`.

## In-app strings

Source of truth: [`Localizable.xcstrings`](../../../ios-native/OasisNative/Resources/Localizable.xcstrings) (Xcode 15+ string catalog format, single file).

Access from Swift via `LocalizedStringResource` keys exposed in [`L10n.swift`](../../../ios-native/OasisNative/Support/L10n.swift):

```swift
Text(L10n.channelBirds)               // resolves channel.birds for current locale
Text(L10n.paywallTitleGeneric)
```

### Key naming scheme

```
channel.<id>                          short label (e.g. "Birds")
channel.<id>.long                     longer/contextual label
channel.<id>.location                 location string (e.g. "Brittany, France")
binaural.track.<id>                   delta / theta / alpha / beta
paywall.<scope>.<key>
premium.inline.<entry_point>
presets.<scope>.<key>
presets.default.<id>                  legacy/default preset names when shipped defaults exist
timer.option<minutes>                 timer.option15, timer.option30, …
header.<key>
home.controls.<key>
compose.<scope>.<key>
noise.<id>[.subtitle]
spatial.<key>
mac.<surface>.<key>
sound.detail.<key>
mixer.accessibility.<key>
notifications.<scope>.<key>
onboarding.<step>.<key>
errors.<key>
```

`header.immersive`, `header.immersive.sound`, `header.immersive.enabled`, and `header.immersive.disabled` localize the home toolbar toggle, its active visible label, and its accessibility value.

`home.controls.*`, `mixer.accessibility.*`, `binaural.volume/enabled/disabled`, and `spatial.stage.*` cover VoiceOver-only labels, hints, values, and custom actions. Keep these translated as natural UI phrases, not literal descriptions of SF Symbols. `home.controls.compose` now opens My Ambiences / Mes ambiances, not a technical composer.

`spatial.center` is the only user-facing center/reset action in the sound-placement panel. There is no separate `spatial.reset` key because the old "Recenter sound" button duplicated the center preset.

The iOS My Ambiences panel reuses `presets.save.*`, `presets.edit.*`, `presets.delete.confirm.*`, `presets.export.*`, and `presets.status.*` keys for saving, editing, deleting, and exporting ambiences because those ambiences are persisted as `Preset` snapshots. The old iOS manage-toggle copy is not used in My Ambiences; `presets.manage*` remains for the legacy Presets surface/macOS section.

Shipped default ambience names use `presets.default.*` keys, including the six iPhone-authored defaults returned by `Array.defaultPresets()`: beach rest, distant storm, light shower, relaxing chimes, under the tent, and cicadas/bells. Keep these localized in all six locales because free users see the two unlocked defaults and locked Premium defaults in My Ambiences.

The My Ambiences sheet uses `home.controls.compose` and `compose.*` keys. Keep this family fully translated because the panel is visible in normal gameplay: the sheet title/subtitle, save background label, "what will happen" heading, explanatory sentence, natural layer labels, CTA states, legacy recipe titles/subtitles, and the dedicated premium-ambience/paywall copy all live here. Saved ambiences appear in the selector and use the generic preset save/edit/delete/status copy; creating or editing them is Premium-only, so free users should see the preset upsell. That upsell must not claim the first save is free. Some localization keys still keep historical `compose.routine.*` / `home.routine.*` names for migration stability, but their values and comments should describe ambiences only. The Home follow-up status covers the passive listening cue and explicit active-ambience stop action; `home.routine.rest.title` is now the single rest-cue message and should translate "Put your iPhone down and relax" naturally in each locale. My Ambiences and Premium copy should use natural phrasing in each locale and stay truthful for both free and premium users. Write from the user's point of view: avoid internal product language such as "combines layers" when a clearer sentence can say what happens on tap, what starts, and how the chosen duration is used. Prefer wellbeing language ("soundscape", "noise cover", "fade out") over technical or jargon-heavy labels like "masking" or "procedural". Premium ambience summaries can exceed three sounds, so localized preview copy should support compact `+N` overflow rather than enumerating every layer.

`notifications.gentleReminder.title` and `notifications.gentleReminder.body` localize the single local notification that invites inactive users back to Oasis after several days.

macOS panel copy uses the `mac.*` namespace (`mac.section.*`, `mac.mixer.*`, `mac.presets.*`, `mac.premium.*`, `mac.command.*`). Keep it short and desktop-native: segmented-control labels, menu bar panel labels, placeholders, and status badges should fit compactly in a 560 pt menu bar panel.

Paywall price-anchor copy lives at `paywall.anchor.dailyPrice`. It should keep the Paris cafe moment but phrase the coffee/croissant bundle naturally in each locale rather than translating a slash literally.

When adding a new channel, run [`scripts/add_channel_translations.py`](../../../scripts/add_channel_translations.py) to scaffold or refresh the three `channel.<id>.*` entries in all 6 locales. The helper reflects the current 35-channel catalog, including the 2026-05 rain/forest/water/wildlife/human additions; do not reintroduce retired `train` / `carRide` keys.

### Special characters

The catalog handles all needed glyphs:
- German: `ä ö ü ß`
- French: `é è ê ç à`
- Spanish: `ñ ¡ ¿`
- Italian: `à è ì`
- Portuguese: `ã õ ç`

Don't normalise away accents in keys or values.

## App Store metadata

Per-locale text files in `fastlane/metadata/<locale>/`. Each locale has a fixed set:

| File | Apple character cap | Notes |
| --- | --- | --- |
| `name.txt` | 30 | App name. Indexed by ASO. |
| `subtitle.txt` | 30 | App subtitle. Indexed by ASO. |
| `keywords.txt` | 100 | Comma-separated, no spaces. Indexed but invisible. |
| `description.txt` | 4 000 | Long description. Apple weighs the **first line** heavily for SERP. |
| `promotional_text.txt` | 170 | Editable without binary review. Updated monthly. |
| `release_notes.txt` | 4 000 | Per-version "What's new". Indexed for the current version. |
| `support_url.txt` | URL | Required by ASC. |
| `privacy_url.txt` | URL | Required when using RevenueCat / IAP. |
| `marketing_url.txt` | URL | Optional. |
| `primary_first_sub_category.txt` | enum | Keep blank unless App Store Connect exposes valid subcategories for the chosen primary category. |
| `secondary_first_sub_category.txt` | enum | Keep blank unless App Store Connect exposes valid subcategories for the chosen secondary category. |

### Apple's deduplication rule

Apple indexes each unique word **once** across `name + subtitle + keywords`. Repeating "Sleep" in the name and the keyword field wastes ~30 characters of search surface. Always check that name + subtitle + keywords have **zero word overlap** per locale.

### Approval timing per file

- `name.txt`, `subtitle.txt`, `description.txt`, screenshots, app icon → **24–48 h Apple review** on submit.
- `keywords.txt`, `promotional_text.txt`, `release_notes.txt`, `support_url.txt`, `privacy_url.txt`, `marketing_url.txt`, sub-categories → **no review**, instant on push.

## Adding a new locale — checklist

1. Add the locale to `Localizable.xcstrings` (Xcode auto-fills English keys; you fill the translations).
2. Create `fastlane/metadata/<locale>/` (use `scripts/createFastlaneCountriesFolders.js` or copy an existing locale).
3. Add the locale to the `screenshots` lane's `languages:` array in `fastlane/Fastfile`.
4. Add the locale-specific kicker, headline, subhead in [`scripts/screenshot_content.json`](../../../scripts/screenshot_content.json) and re-render screenshots via `generate_store_screenshot_comps.swift`.
5. Update [marketing/aso-strategy.md](../marketing/aso-strategy.md) with the new locale's metadata.
6. Bump this file's `last_updated`.

## App Store Connect surface (per locale)

Each locale has its own ASC view: name, subtitle, description, keywords, promotional text, release notes, screenshots, optional App Preview videos, optional URLs. fastlane lanes push metadata and screenshots; App Preview videos are currently excluded from staging/upload for `1.5.2`. See [../operations/release-process.md](../operations/release-process.md).

Non-localized review information lives in `fastlane/metadata/review_information/`. The macOS `1.0.0` review note explains that the Mac build is the native menu bar adaptation of the existing iOS app, shares the same bundle ID and lifetime Premium entitlement, and must be opened from the macOS menu bar icon.

As of 2026-05-28, ASO copy and screenshot overlays in all 6 locales use the current catalogue promise: `35` total nature sounds to mix, with `32` extra sounds unlocked by the lifetime purchase. Premium paywall and screenshot copy also sell the `4` extra noise layers (pink/green/fan/aircraft cabin) instead of hiding them behind generic Premium wording. The localized `1.5.2` release notes focus on the graphic refresh, My Ambiences / Mes ambiances, and Premium noise layers; the French description must not claim free users can save a first personal mix. Screenshot overlays were adapted per language after FR approval, not translated word-for-word; each locale should keep natural local phrasing for My Ambiences, sound masking, sound placement, and lifetime Premium. Keep those numbers aligned with [sounds-catalog.md](sounds-catalog.md), [product/premium-model.md](../product/premium-model.md), and [marketing/store-assets.md](../marketing/store-assets.md).

## Feature notes

- The legacy `selectedLanguage` field in `PersistedMixerState` is unused (kept for backward compat). The app honours the system locale; there is no in-app language picker.
- Premium sound-library and sound-paywall copy should list current nature channels only. The canonical exemplar set is rain / forest / thunder / river / sea, localized per locale.
- ASO keyword fields intentionally avoid baby / parent targeting. Use adult moments instead: study, reading, work, travel, sleep, calm.
- User-facing ASO and onboarding copy should not claim "3D audio" / "spatial audio". Use localized sound-placement language instead (`sound placement`, `placement sonore`, `Klangplatzierung`, `ubicación sonora`, `posizione dei suoni`, `posição dos sons`).
- Onboarding should lead with escape / real field recordings, then offline timer behavior, then the free-start / lifetime purchase model. Avoid sleep-only framing on page 1.
- Onboarding final-page CTAs are deliberately explicit: primary unlocks lifetime access; secondary starts free. Do not label the premium path as a generic "start listening" action.
- Premium preview limit copy should say the next signature preview is available next week; the cooldown is weekly, not daily.
- ASO copy and brand lines (e.g. "No subscription. Ever.", "Pay once, yours forever.") have approved translations in 6 locales — see `marketing/store-assets.md` for the full table. Don't paraphrase them in random surfaces.
