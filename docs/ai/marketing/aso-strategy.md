---
title: ASO Strategy
status: stable
last_updated: 2026-05-03
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

## Two fields, one strategy

Apple indexes each word **once** across `name + subtitle + keywords` per locale. The pattern Oasis uses:

- **Visible** (name + subtitle): multi-use angle, "no subscription" stance, the 4 use cases.
- **Invisible** (keywords): sleep-leaning long-tail and competitor-adjacent terms (white noise, brown noise, insomnia, ASMR, tinnitus, …) — captures traffic without polluting the visible pitch.

Net effect: rank for sleep without *looking* like a sleep app.

## Recommended metadata — Variant A (multi-use)

Source: 2026-05-02 audit. Approved direction. Push these via `bundle exec fastlane appstore_metadata`.

| Locale | Name (≤30) | Subtitle (≤30) | Keywords (≤100) |
| --- | --- | --- | --- |
| en-US | `Oasis: Nature Sound Mixer 3D` | `Sleep, focus, work, nap, calm.` | `rain,white,noise,brown,pink,ambient,ocean,fan,thunder,music,meditation,timer,insomnia,reading,yoga` |
| fr-FR | `Oasis : Mixeur de Sons Nature` | `Sommeil, focus, sieste, calme.` | `pluie,bruit,blanc,brun,ambiance,ocean,orage,musique,meditation,etude,acouphene,minuteur,lecture` |
| de-DE | `Oasis: Naturklang-Mixer 3D` | `Schlaf, Fokus, Pause, Lesen.` | `regen,weiss,rauschen,braun,ambient,ozean,ventilator,donner,musik,meditation,timer,tinnitus,arbeit` |
| es-ES | `Oasis: Mezclador de Sonidos 3D` | `Sueño, foco, siesta, lectura.` | `lluvia,ruido,blanco,marron,rosa,ambiente,oceano,ventilador,trueno,musica,meditacion,estudio,insomnio` |
| it | `Oasis: Mixer Suoni Natura 3D` | `Sonno, focus, pausa, lettura.` | `pioggia,rumore,bianco,marrone,rosa,ambiente,oceano,musica,meditazione,acufene,timer,studio,lavoro` |
| pt-BR | `Oasis: Mixer de Sons Natureza` | `Sono, foco, soneca, leitura.` | `chuva,ruido,branco,marrom,rosa,ambiente,oceano,ventilador,trovao,musica,meditacao,estudo,zumbido` |

Sub-categories (in `primary_first_sub_category.txt` / `secondary_first_sub_category.txt`):

- Primary: `MIND_AND_BODY`
- Secondary: `TRAVEL`

(Currently both files are missing — adding them is a free slot.)

## Promotional Text — rotation

Rotate `promotional_text.txt` (≤170, no review) ~monthly. Three template angles:

1. **Seasonal** — "Late autumn rain mixes are now in 5 default presets." / "Long winter nights need a longer timer."
2. **Feature highlight** — "New: Mountain Storm and Sea, replacing Train and Car. Re-encode of all 20 sounds for cleaner low-end."
3. **Social proof** — when reviews / ratings hit a milestone.

Don't promise features that aren't in the current binary — Apple flags promo-text deception.

## Release notes — voice

Stop shipping `"Performance optimizations and bug fixes."` Customers and ASO crawlers both read this field. Replace with one product-flavored sentence per change:

- "Smoother fades when you swap presets at night."
- "All 20 nature sounds re-encoded for cleaner low-end."
- "Replaced Train and Car with Sea (Greece) and Mountain Storm (Italy)."

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

Reorder is done via the `appstore_release` lane; no re-rendering needed.

## App Preview video — open

There is **no App Preview video today**. Adding one is a +15 % to +30 % conversion lift in the segment. Spec:

- 20 seconds.
- No voice-over (single render works for 6 locales).
- Storyline: open → mixer with growing ambient layers → spatial minimap drag → binaural panel reveal → sleep timer setting → paywall fade with "Pay once. Yours forever." card.
- 1080×1920, MP4 H.264, ≤ 500 MB.
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
2. Add `MIND_AND_BODY` + `TRAVEL` sub-categories.
3. Rewrite `promotional_text.txt` for all 6 locales (template 1 — seasonal).
4. Rewrite `release_notes.txt` for current version 1.4.1 — replace "performance + bugs" with the actual list.
5. Render Slide 01 v2 (multi-use eyebrow + subhead) and re-stage.
6. Push first description line per locale.
7. `bundle exec fastlane appstore_metadata` to ship.

### Month 1 (~2 days)

1. Build the 20-sec App Preview video.
2. Set up two CPPs (Sleep First, Focus).
3. Reorder screenshots to Variant B.
4. Wire ASC Analytics dashboard (impressions, page views, conversion rate, search vs browse split).

### Quarter 1 (~5 days)

1. Trial-purchase post-onboarding on page 3 of `OnboardingView`.
2. Refactor the other 9 screenshots to v3 spec — see [store-assets.md](store-assets.md).
3. Drop signature preview frequency from 1×/day to 1×/week (`signaturePreviewLastPlayedAt`).
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
