---
title: Localization
status: stable
last_updated: 2026-05-19
tracks:
  - "ios-native/OasisNative/Support/L10n.swift"
  - "ios-native/OasisNative/Resources/Localizable.xcstrings"
  - "fastlane/metadata/**"
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
presets.default.<id>                  default preset names (starter / calm / storm)
timer.option<minutes>                 timer.option15, timer.option30, …
header.<key>
home.controls.<key>
spatial.<key>
sound.detail.<key>
mixer.accessibility.<key>
notifications.<scope>.<key>
onboarding.<step>.<key>
errors.<key>
```

`header.immersive`, `header.immersive.sound`, `header.immersive.enabled`, and `header.immersive.disabled` localize the home toolbar toggle, its active visible label, and its accessibility value.

`home.controls.*`, `mixer.accessibility.*`, `binaural.volume/enabled/disabled`, and `spatial.stage.*` cover VoiceOver-only labels, hints, values, and custom actions. Keep these translated as natural UI phrases, not literal descriptions of SF Symbols.

`spatial.center` is the only user-facing center/reset action in the sound-placement panel. There is no separate `spatial.reset` key because the old "Recenter sound" button duplicated the center preset.

The full-screen presets panel uses `presets.save.*`, `presets.delete.confirm.*`, `presets.list.*`, and `presets.status.*` keys for its save button + name-entry alert, delete confirmation, list section, and row badges.

`notifications.gentleReminder.title` and `notifications.gentleReminder.body` localize the single local notification that invites inactive users back to Oasis after several days.

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

Each locale has its own ASC view: name, subtitle, description, keywords, promotional text, release notes, screenshots, optional App Preview videos, optional URLs. fastlane lanes push metadata and screenshots; App Preview videos are currently excluded from staging/upload for `1.5.0`. See [../operations/release-process.md](../operations/release-process.md).

As of 2026-05-19, visible ASO copy and screenshot overlays in all 6 locales use the current catalogue promise: `35` total nature sounds to mix, with `32` extra sounds unlocked by the lifetime purchase. The `1.5.0` release notes are also localized from the approved French source about immersive sound, 35 nature sounds, automatic volume-variation ranges, and redesigned presets. Keep those numbers aligned with [sounds-catalog.md](sounds-catalog.md) and [marketing/store-assets.md](../marketing/store-assets.md).

## Feature notes

- The legacy `selectedLanguage` field in `PersistedMixerState` is unused (kept for backward compat). The app honours the system locale; there is no in-app language picker.
- Premium sound-library and sound-paywall copy should list current nature channels only. The canonical exemplar set is rain / forest / thunder / river / sea, localized per locale.
- ASO keyword fields intentionally avoid baby / parent targeting. Use adult moments instead: study, reading, work, travel, sleep, calm.
- User-facing ASO and onboarding copy should not claim "3D audio" / "spatial audio". Use localized sound-placement language instead (`sound placement`, `placement sonore`, `Klangplatzierung`, `ubicación sonora`, `posizione dei suoni`, `posição dos sons`).
- Onboarding should lead with escape / real field recordings, then offline timer behavior, then the free-start / lifetime purchase model. Avoid sleep-only framing on page 1.
- Onboarding final-page CTAs are deliberately explicit: primary unlocks lifetime access; secondary starts free. Do not label the premium path as a generic "start listening" action.
- Premium preview limit copy should say the next signature preview is available next week; the cooldown is weekly, not daily.
- ASO copy and brand lines (e.g. "No subscription. Ever.", "Pay once, yours forever.") have approved translations in 6 locales — see `marketing/store-assets.md` for the full table. Don't paraphrase them in random surfaces.
