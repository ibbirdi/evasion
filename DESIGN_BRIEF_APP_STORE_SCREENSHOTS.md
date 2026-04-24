# Oasis — App Store Screenshots · Design Brief

Specs for the 10×6 screenshot compositions, grounded in what top-tier apps in
the Sleep / Focus / Audio category actually ship on the App Store in 2026. Every
design decision below cites references and has a numeric target — no "feels
clean", no "minimal" as an end in itself.

---

## 1. Reference set (what we benchmark against)

Observed directly on the App Store, US + FR storefronts, April 2026.

| App | Category rank | What's strong |
|---|---|---|
| **Endel** | Top 10 Health | Huge single-word headlines, deep saturated colour per slide, device shown partial |
| **Calm** | Top 5 Health | Centred short headlines, soft gradients, device straight-on with accurate bezel |
| **Headspace** | Top 5 Health | Device with visible chrome frame, high colour contrast, centred bold sans-serif |
| **Loóna** | Top 100 Health | Painterly but never busy, one clear message per slide |
| **Portal** | Top 100 Health/Nature | Landscape photo bleeds to edges, translucent card overlay with text |
| **Sleep Cycle** | Top 10 Health | Device straight, product-led not lifestyle-led, clinical typography |
| **Superhuman** | Top 100 Productivity (ref for text-only) | Pure colour background, one 180pt headline, device at 60% height |

**Common patterns across all 7:**

- Typography is **centred**, not left-aligned. Editorial layouts don't convert on a 6" preview strip.
- Backgrounds are either a **solid colour** or a **single vertical gradient** (two stops). No radial glows, no grain, no blend modes.
- Device mockup uses the **actual iPhone corner radius** (not a generic rounded rectangle).
- The bottom ~20% of the canvas is either **pure background** or the device fades off-bleed — **no brand watermarks**, no "As seen in" badges.
- One headline per slide. Often no sub-copy at all. When present, subhead is **one line**, not two.
- **No eyebrow/kicker pill.** Either no kicker, or a plain small uppercase line above the headline — never a container around it.

---

## 2. Canvas specs (non-negotiable)

- **Size**: 1320 × 2868 px (App Store Connect 6.9″ iPhone requirement, Apple downscales for smaller tiers).
- **Color space**: sRGB, no alpha channel.
- **Format**: JPEG quality 90-95, ≤ 2 MB per file.
- **Delivery**: `fastlane/screenshots/<lang>/figma-pro/<slug>.jpg`.

---

## 3. Device mockup specs

This is where my v2 was most wrong. Real iPhone corner radius matters.

- **Source capture size**: 1320 × 2868 (Fastlane output, don't scale).
- **Mockup rendered width**: 880 px (67% of canvas width).
- **Mockup aspect ratio**: 1320/2868 = 0.4603. Height at 880w = **1912 px**.
- **Corner radius**: on iPhone 17 Pro Max the physical screen corner is ~55 px at 1x (per Apple's `UIScreen.displayCornerRadius` on iOS 26). Scaled to 880-wide mockup: **55 × (880/1320) = 36.7 ≈ 37 px**. My v2 used 76 — that was an iPad/stylised shape, not an iPhone.
- **Chrome**: no thick bezel rendering. The capture itself already shows the iOS status bar; we just round the corners to match the physical device. A 1 px `rgba(255,255,255,0.08)` specular hairline at the top is acceptable; nothing else.
- **Shadow**: single shadow, not two. Offset y = +24, blur = 60, opacity 40%, same colour as background base (not pure black — pure black reads as cutout).
- **Position**: bottom edge of the mockup sits **50 px above the bottom of the canvas** (bleeds slightly off-bleed is fine, but the content must not clip). Top edge derives from mockup height.

With height 1912 and bottom margin 50, the top of the mockup is at y-from-top = 2868 − 1912 − 50 = **906 px**.

---

## 4. Type system

### 4.1 Headline (the only typography that really matters)

- **Font**: SF Pro Display, Bold (not Rounded — Rounded reads consumer-playful; Bold reads confident-premium, matches Calm/Endel).
- **Size**: 128 pt (base). Step down to 110 pt → 96 pt if the longest line would wrap past 2 lines. Never 3 lines.
- **Line height**: 0.96 (tight, headline-tight).
- **Letter spacing**: −3% of size (= −3.84 pt at 128 pt).
- **Colour**: `#FFFFFF` at 100% opacity (not 96%, not warm-white).
- **Alignment**: **centred**, not left. This is non-negotiable — Endel, Calm, Headspace, Sleep Cycle all centre. Left-aligned is editorial/magazine, wrong for App Store.
- **Max lines**: 2. Copy must be written to fit. If it doesn't, shorten the copy, don't step down the size.
- **Width**: 1160 px (80 px margin each side).

### 4.2 Subhead (optional, used on ~half the slides)

- **Font**: SF Pro Text, Regular.
- **Size**: 34 pt.
- **Line height**: 1.25.
- **Letter spacing**: 0.
- **Colour**: `#FFFFFF` at **72%** opacity.
- **Alignment**: centred.
- **Max lines**: 1. If it doesn't fit on one line → shorten the copy.
- **Width**: 1080 px (120 px margin each side — tighter than headline to feel like secondary text).

### 4.3 Eyebrow / kicker (used sparingly)

Dropped the "pill" concept. Replace with plain uppercase text, no container.

- **Font**: SF Pro Text, Semibold.
- **Size**: 24 pt.
- **Transform**: uppercase.
- **Letter spacing**: +12% (= +2.88 pt).
- **Colour**: accent colour per slide, 100% opacity (the slide's accent becomes the eyebrow — one single accent moment per slide).
- **Alignment**: centred.
- **Used on**: slides where the eyebrow adds a genuine hook (01 Hero, 10 Paywall, 08 Free Home). **Not used** on slides where the device+headline tell the story alone (03, 04, 05, 06).

---

## 5. Colour system

My v2 palette was muddy brown. Rebuild around pure, confident hues.

### 5.1 Background architecture

**One flat 2-stop vertical gradient**, no radial glow, no grain. Top stop = the mood colour saturated, bottom stop = same hue darkened 35%. Nothing else.

### 5.2 Per-slide palette

Colours are chosen to:
(a) differentiate each slide visually at thumbnail size
(b) match the semantic mood of the raw capture's content
(c) come from a single hue wheel (no jarring transitions when scrolling the 10-slide strip)

| # | Slide | Top stop | Bottom stop | Accent (eyebrow) | Mood justification |
|---|---|---|---|---|---|
| 01 | Hero | `#3A1E12` | `#1A0A04` | `#F5A35E` | Campfire warmth — hero slot, inviting |
| 02 | Library | `#1A3F2E` | `#0A1D14` | `#5CC08A` | Forest depth — abundance/nature |
| 03 | Detail | `#2A2F14` | `#11140A` | `#C9A256` | Savannah dusk — authenticity |
| 04 | Binaural | `#2A1945` | `#130929` | `#A07EE2` | Violet focus — brainwave category |
| 05 | Spatial | `#0E2E45` | `#051623` | `#5FC2E0` | Cold cyan — spatial/clinical precision |
| 06 | Presets | `#2E1648` | `#170A27` | `#D27BC7` | Twilight plum — personalisation |
| 07 | Timer | `#1A2B45` | `#0B1424` | `#8EA5D4` | Dusk navy — sleep onset |
| 08 | Free home | `#0E3755` | `#062038` | `#5BB0DF` | Ocean — clean entry point |
| 09 | Library teaser | `#1E3416` | `#0F1C0A` | `#B6D463` | Lime growth — upsell |
| 10 | Paywall | `#3D1A0C` | `#1A0705` | `#F5995B` | Lifetime amber — closing warmth |

All values: sRGB, no alpha on background.

### 5.3 Text colours

- Headline: `#FFFFFF` 100%.
- Subhead: `#FFFFFF` 72%.
- Eyebrow: the slide's accent column above, 100%.

### 5.4 What's gone

- ❌ Radial glow with screen blend mode
- ❌ Grain / noise overlay
- ❌ Accent orbs
- ❌ Blurred backdrop from the capture itself
- ❌ Halo behind the device
- ❌ Brand signature "OASIS" at bottom (redundant — the app icon shows above the screenshots in the App Store)
- ❌ Kicker pill container
- ❌ Specular highlight on the device (except the 1 px hairline)

---

## 6. Layout grid

Centred, top-down. Y distances are "from the top edge of the canvas".

```
 ┌────────────────────────── 1320 ──────────────────────────┐
 │                                                          │
 │                         (y = 140)                        │  top safe
 │                      ‹eyebrow, 24pt›                     │
 │                                                          │
 │                         (y = 200)                        │
 │                                                          │
 │                   ┌──────────────────┐                   │
 │                   │                  │                   │
 │                   │   HEADLINE       │                   │  128 pt bold
 │                   │   128pt centred  │                   │  ≤ 2 lines
 │                   │                  │                   │
 │                   └──────────────────┘                   │
 │                                                          │
 │                         (y = 560)                        │
 │                                                          │
 │                 ‹subhead, 34pt, 1 line›                  │
 │                                                          │
 │                         (y = 640)                        │
 │                                                          │
 │                                                          │
 │                ┌────────────────────┐                    │
 │                │                    │                    │
 │                │                    │                    │
 │                │     DEVICE MOCKUP  │                    │  880 × 1912
 │                │     880 px wide    │                    │  r = 37
 │                │     r = 37         │                    │
 │                │                    │                    │
 │                │                    │                    │
 │                │                    │                    │
 │                └────────────────────┘                    │  bottom at y = 2818
 │                                                          │  (50 below canvas bottom)
 └──────────────────────────────────────────────────────────┘  canvas height = 2868
```

**Offsets, from top:**

| Element | y top | height | y bottom |
|---|---:|---:|---:|
| Eyebrow | 140 | 32 | 172 |
| Gap | — | 28 | — |
| Headline (2 lines @ 128pt × 0.96 leading ≈ 246pt tall) | 200 | 256 | 456 |
| Gap | — | 104 | — |
| Subhead | 560 | 44 | 604 |
| Gap (breathing) | — | 302 | — |
| Device mockup | 906 | 1912 | 2818 |
| Bottom margin | 2818 | 50 | 2868 |

When a slide has **no eyebrow** (03, 04, 05, 06), the headline moves up 60 px to compensate (y=140 instead of y=200) so the visual centre of gravity stays the same.

When a slide has **no subhead**, the device moves up 80 px so the negative space doesn't look like a bug.

---

## 7. Copy specs

### 7.1 Length constraints derived from the grid

- Headline max width at 128 pt SF Pro Display Bold: ~22 characters per line. So **max 44 characters total** across both lines.
- Subhead max width at 34 pt SF Pro Text Regular: ~78 characters.
- Eyebrow max width at 24 pt Semibold UC: ~34 characters.

If a translation breaks these limits, we **shorten the translation**, not the size. Consistency across 60 exports beats per-slide auto-fitting.

### 7.2 Voice rules (unchanged from existing store copy)

- No exclamation marks.
- No superlatives ("best", "revolutionary", "#1").
- Never imply a subscription ("free trial" is banned — we don't do trials, we do freemium).
- Every headline maps to a claim that's already in `fastlane/metadata/<lang>/description.txt` — do not invent new differentiators.

---

## 8. Per-slide copy brief

Eyebrow fields marked `—` mean no eyebrow on that slide (device + headline carry it).

| # | Slide | Eyebrow (en) | Headline (en) | Subhead (en) |
|---|---|---|---|---|
| 01 | Hero | PAY ONCE. SLEEP FOREVER. | Fall asleep to real nature. | (none) |
| 02 | Library | — | 20 real places, in your ears. | Every track is a field recording. |
| 03 | Detail | — | A place, an author, a licence. | (none) |
| 04 | Binaural | — | Deep sleep, deeper focus. | Four binaural modes. |
| 05 | Spatial | — | Place sound around you. | Wind left. Rain ahead. Birds behind. |
| 06 | Presets | — | Your perfect night, one tap. | Save unlimited mixes. |
| 07 | Timer | GENTLE SLEEP TIMER | Drift off. We handle the rest. | (none) |
| 08 | Free home | FREE IS ACTUALLY FREE | Start tonight with 3 real sounds. | (none) |
| 09 | Library teaser | — | Unlock the whole library. | 17 more sounds, one tap. |
| 10 | Paywall | NO SUBSCRIPTION. EVER. | Pay once. Yours forever. | (none) |

6-language versions live in the Swift script `COPY[lang]`. Same editorial rules apply in each language; shortenings per-locale are fine when character limits bite.

---

## 9. Render pipeline specs

- Output bitmap via `NSBitmapImageRep` at explicit 1320 × 2868 pixels (avoids the Retina `lockFocus` doubling trap).
- JPEG encoding at compression factor 0.92.
- One Swift file at `scripts/generate_store_screenshot_comps.swift`. All 60 assets in one run, under 10 seconds.
- Data (copy, colours, layout tokens) at the top of the file. Rendering functions below. Pipeline at the bottom. No external config files.

---

## 10. Acceptance criteria

A slide is "done" when:

- [ ] Matches the background gradient exactly (top + bottom stops from §5.2)
- [ ] No radial glows, no grain, no halos, no brand watermark
- [ ] Device mockup corner radius = 37 px
- [ ] Device mockup width = 880 px, centred horizontally
- [ ] Device bottom edge sits 50 px above canvas bottom
- [ ] Headline at 128 pt (or 110 / 96 step-down), SF Pro Display Bold, centred, max 2 lines, no widow
- [ ] Subhead at 34 pt max 1 line, or omitted if the layout says so for that slide
- [ ] Eyebrow present only on slides 01, 07, 08, 10
- [ ] All text centred, no left-aligned blocks
- [ ] Special characters (ä ö ü ß ã ç ñ é è) render clean in all 6 language outputs

When all 60 exports pass the above, we're shippable.

---

## 11. Known risks / open questions before we code

- **Device frame vs no frame**: I'm currently rendering the capture inside a rounded rect directly, no black bezel. Endel and Superhuman do this. Calm and Headspace wrap the capture in a visible bezel. Proposal: try both, ship whichever looks better on 01 Hero + 04 Binaural. Default is no-bezel.
- **Off-bleed bottom**: the device bleeds 50 px below the canvas. This is intentional (prevents the composition feeling like a poster pinned inside a frame) but if you dislike the look, we raise the `phoneTopPadding` by 60 and let the device sit fully inside.
- **Eyebrow decision per-slide**: I've hand-picked slides 01/07/08/10 as the ones that need an eyebrow. If you want eyebrows on all 10 (or none), say so before I re-code — it changes the copy rhythm.
