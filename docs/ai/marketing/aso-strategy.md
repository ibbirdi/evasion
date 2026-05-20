---
title: ASO Strategy
status: stable
last_updated: 2026-05-20
tracks:
  - "fastlane/metadata/**"
  - "fastlane/screenshots/**"
related:
  - "positioning.md"
  - "store-assets.md"
  - "../content/localization.md"
---

# ASO Strategy

Synthesised from the 2026-05-02 audit (v2 of the original audit doc, post sleep-led → multi-use pivot). Numbers below are based on app version 1.4.1 and `fastlane/metadata/` snapshot 2026-04-26.

The big picture is in [positioning.md](positioning.md). This file is the operational layer: what to ship, in what order.

## Current local state — 2026-05-19

The latest low-risk ASO pass cleaned the invisible keyword fields, updated the screenshot hooks toward immersion / escape, and refreshed the visual treatment of the App Store screenshots.

- Removed `baby` / `bebe` targeting from all 6 keyword files, in line with [positioning.md](positioning.md)'s anti-persona guidance.
- Replaced those slots with adult use cases such as study, reading, work, and calm; all locales remain ≤100 chars and have zero indexed-word overlap across `name + subtitle + keywords`.
- Removed `3D` from all App Store names. Screenshot headlines use sound-placement language; the slide 05 subhead keeps the approved French-source idea of a spatial audio engine.
- Keep sub-category files blank: App Store Connect currently reports no valid subcategories for `HEALTH_AND_FITNESS`, `LIFESTYLE`, or `TRAVEL`, and rejects invalid `primarySubcategoryOne` values.
- Re-rendered and staged 60 composite screenshots from the current raw captures; slide 01 now leads with `35 real-world sounds to mix. Offline. No subscription.`, and slide 09 now states `32 extra sounds with one purchase.` in English and natural equivalents in the other 5 locales.
- Increased screenshot eyebrow size for readability and removed line-art background details, keeping only blob-like acoustic fields, gradients, glows, grain, and vignette.
- App Preview videos are disabled for the `1.5.0` App Store upload: the existing remote previews were deleted on 2026-05-19, and `stage_appstore_assets` now stages screenshots only until new videos are regenerated.
- Bumped the app to version `1.5.0`; localized `release_notes.txt` now use the approved French source about immersive sound, 35 nature sounds, automatic volume-variation ranges, and redesigned presets.
- Replaced the first line of each `description.txt` with the approved multi-use opening line.

## macOS review notes — 2026-05-20

`fastlane/metadata/review_information/notes.txt` explains that Oasis macOS `1.0.0` is the Mac adaptation of the existing iOS app under the same bundle ID. It tells reviewers to open Oasis from the macOS menu bar icon, states that there is no separate main window, and clarifies that the sound catalogue, localizations, RevenueCat entitlement, and one-time lifetime Premium purchase model are shared with iOS.

## Two fields, one strategy

Apple indexes each word **once** across `name + subtitle + keywords` per locale. The pattern Oasis uses:

- **Visible** (name + subtitle): multi-use angle, "no subscription" stance, the 4 use cases.
- **Invisible** (keywords): sleep-leaning long-tail and competitor-adjacent terms (white noise, brown noise, insomnia, ASMR, tinnitus, …) — captures traffic without polluting the visible pitch.

Net effect: rank for sleep without *looking* like a sleep app.

## Recommended metadata — Variant A (multi-use)

Source: 2026-05-02 audit. Approved direction. Push these via `bundle exec fastlane appstore_metadata`.

| Locale | Name (≤30) | Subtitle (≤30) | Keywords (≤100) |
| --- | --- | --- | --- |
| en-US | `Oasis: Nature Sound Mixer` | `Sleep, focus. No subscription.` | `rain,white,noise,thunder,ocean,binaural,meditation,insomnia,tinnitus,calm,relax,study,anxiety,asmr` |
| fr-FR | `Oasis : Mixeur Sons Nature` | `Sommeil, focus. Achat unique` | `pluie,bruit,blanc,orage,ocean,binaural,meditation,acouphene,dormir,detente,lecture,insomnie,stress` |
| de-DE | `Oasis: Naturklang-Mixer` | `Schlaf, Fokus. Kein Abo.` | `regen,rauschen,weiss,gewitter,ozean,binaural,meditation,tinnitus,einschlafen,entspannung,arbeit,asmr` |
| es-ES | `Oasis: Mezclador Sonidos` | `Sueño, foco. Sin suscripción.` | `lluvia,ruido,blanco,trueno,oceano,binaural,meditacion,insomnio,tinnitus,dormir,leer,estres,descanso` |
| it | `Oasis: Mixer Suoni Natura` | `Sonno, focus. Senza abbon.` | `pioggia,rumore,bianco,temporale,oceano,binaurale,meditazione,acufene,dormire,insonnia,ansia,lettura` |
| pt-BR | `Oasis: Mixer Sons Natureza` | `Sono, foco. Sem assinatura.` | `chuva,ruido,branco,trovao,oceano,binaural,meditacao,zumbido,dormir,insonia,leitura,ansiedade,calma` |

Sub-categories (in `primary_first_sub_category.txt` / `secondary_first_sub_category.txt`):

- Primary: blank
- Secondary: blank

These files are present locally as blank placeholders as of 2026-05-18.

## Promotional Text — rotation

Rotate `promotional_text.txt` (≤170, no review) ~monthly. Three template angles:

1. **Seasonal** — "Late autumn rain mixes are now in 5 default presets." / "Long winter nights need a longer timer."
2. **Feature highlight** — "35 field recordings to mix, with sound placement and offline playback."
3. **Social proof** — when reviews / ratings hit a milestone.

Don't promise features that aren't in the current binary — Apple flags promo-text deception.

## Release notes — voice

Stop shipping `"Performance optimizations and bug fixes."` Customers and ASO crawlers both read this field. Replace with one product-flavored sentence per change:

- "Smoother fades when you swap presets at night."
- "35 nature sounds to mix, with sound placement and offline playback."
- "Two new nature ambiences: Sea and Mountain Storm."

Each release-note entry is indexed by Apple for the *current* version only. Use them.

## Description — opening line

Apple weights the first line of `description.txt` heavily in search. Rewrite first line per locale:

- en-US: "Build the ambience that fits your moment. Sleep, focus, work, rest — your call."
- fr-FR: "Composez l'ambiance qui colle à votre moment. Sommeil, focus, travail, repos."
- de-DE: "Schaffe die Atmosphäre, die zu deinem Moment passt. Schlaf, Fokus, Arbeit, Ruhe."
- es-ES: "Crea la atmósfera de tu momento. Sueño, foco, trabajo, descanso."
- it: "Crea l'atmosfera del tuo momento. Sonno, focus, lavoro, riposo."
- pt-BR: "Monte a atmosfera do seu momento. Sono, foco, trabalho, descanso."

The body re-tools the "WHY OASIS" block toward positive benefits (`Pay once, keep forever`, `Plays on a plane, in a tent, anywhere — no internet needed`) and the "USE OASIS TO" block as 6 lines: drift off, power-nap 20 min, focus deep-work, mask office/hotel, read or meditate, calm racing thoughts. Approved phrasing per locale lives in the audit document.

## Screenshot order — Variant B (multi-use)

Reorder the existing 10 captures to lead with multi-use moments before binaural (which is opaque to a casual viewer):

```
01_hero → 02_library → 07_timer → 05_spatial → 08_free_home →
03_detail_sheet → 04_binaural → 06_presets → 09_library_teaser → 10_paywall
```

Reorder is done during `stage_appstore_assets` / `appstore_release`: source composites keep their slug names, while upload-ready staged files are renamed to numeric display order. No re-rendering is needed.

## App Preview video — disabled for current upload

Local App Preview MP4s can still be generated in 6 locales from the composited screenshots, but they are **not staged or uploaded** by `stage_appstore_assets` / `appstore_release` as of 2026-05-19. Re-enable staging only after the videos are regenerated and reviewed.

- 20 seconds.
- No voice-over.
- Storyline: hero → full library → timer → sound placement → free start → paywall.
- 886×1920, MP4 H.264, ≤ 500 MB.
- Generation: `bundle exec fastlane app_previews` (Ruby pipeline at [`scripts/generate_app_previews.rb`](../../../scripts/generate_app_previews.rb)).

## Custom Product Pages

ASC allows up to **35** Custom Product Pages per app. Plan three:

- **Main** — Variant A above (multi-use).
- **Sleep First** — sleep-led headline, screenshots reordered with `01_hero` → `07_timer` → `04_binaural` (Delta foreground) → `06_presets` (Sleep mix). Used for ads to insomnia / "sleep sounds" search.
- **Focus** — focus-led, lead with `05_spatial` → `06_presets` (focus mix) → `04_binaural` (Beta). Used for ads to "focus music" / "study sounds" cohorts.

CPPs are free; spawn them as A/B vehicles without touching the main page.

## Action plan — three horizons

### Week 1 (~7 h of work)

1. Push Variant A names / subtitles / keywords for all 6 locales.
2. Leave sub-category files blank unless App Store Connect exposes valid subcategories for these primary categories. **Verified locally 2026-05-18.**
3. Rewrite `promotional_text.txt` for all 6 locales (template 1 — seasonal). **Done locally 2026-05-17.**
4. Rewrite `release_notes.txt` for current version 1.5.0 — replace "performance + bugs" with the actual list. **Done locally 2026-05-19.**
5. Render Slide 01 v2 (multi-use eyebrow + subhead) and re-stage. **Done locally 2026-05-17.**
6. Push first description line per locale. **Done locally 2026-05-17.**
7. `bundle exec fastlane appstore_metadata` to ship.

### Month 1 (~2 days)

1. Build the 20-sec App Preview video. **Done locally 2026-05-17.**
2. Set up two CPPs (Sleep First, Focus).
3. Reorder screenshots to Variant B.
4. Wire ASC Analytics dashboard (impressions, page views, conversion rate, search vs browse split).

### Quarter 1 (~5 days)

1. Add explicit lifetime-unlock CTA on page 3 of `OnboardingView`, with a visible free-tier alternative. **Done locally 2026-05-17.**
2. Refactor the other 9 screenshots to v3 spec — see [store-assets.md](store-assets.md).
3. Drop signature preview frequency from 1×/day to 1×/week (`signaturePreviewLastPlayedAt`). **Done locally 2026-05-17.**
4. Investigate a 6th "Hotel / Travel" use case — if Travel sub-category drives meaningful traffic.
5. A/B paywall CTA copy: "Pay once. Yours forever." vs "Less than one month of a subscription app. For life."

## Metrics

ASC native:
- Impressions, Product Page Views, Conversion Rate (impressions → install).
- Search vs Browse vs Web split.
- Top searches landing on the listing.
- App Preview vs Screenshot impressions.

In-app (`PremiumAnalytics` → `TelemetryDeckAnalyticsSink`):
- `paywall_shown`, `paywall_dismissed`, `purchase_succeeded` — funnel.
- `preview_started`, `preview_finished` — signature preview.
- `inline_shown`, `inline_dismissed` — inline upsell.
- `listened_60s`, `listened_5m` — engagement.
- `review_prompt_requested` — review trigger.

Move slowly: change one variable, wait 4–7 days, read the delta. Apple's ASC analytics smooth daily noise.
