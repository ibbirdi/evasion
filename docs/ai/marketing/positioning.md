---
title: Positioning
status: stable
last_updated: 2026-05-17
tracks:
  - "fastlane/metadata/**/description.txt"
  - "fastlane/metadata/**/subtitle.txt"
  - "ios-native/OasisNative/Views/Overlays/PaywallOverlay.swift"
related:
  - "../product/vision.md"
  - "../product/premium-model.md"
  - "aso-strategy.md"
  - "store-assets.md"
---

# Positioning

The strategic frame derived from the 2026-05-02 ASO audit. This is the lens any marketing copy or product decision should be checked against.

## The tension

- **60–70 %** of search volume in the segment (Audio Wellness iOS, 2025-2026 Sensor Tower / Mobile Action data) is dominated by sleep-led queries.
- Sleep-led positioning is also where competitors (Calm, Headspace, Portal, Sleep Cycle) are strongest.
- Oasis can win sleep traffic without positioning *only* on sleep — and it has technical features (mixer, per-sound placement, binaural, presets) that work for non-sleep contexts.

**Resolution.** Keep sleep-heavy keywords in the keyword field (capture traffic invisibly) but pivot the visible surfaces — title, subtitle, hero screenshot, first description line — to a multi-use frame.

## The four use cases

| # | Use case | Anchor moment |
| --- | --- | --- |
| 1 | **Sleep** | Drift off, mask hotel/street noise, beat insomnia. |
| 2 | **Nap / power-rest** | 15–30 min recharge during the day. |
| 3 | **Focus / deep work** | Replace lo-fi or Spotify for work / study. |
| 4 | **Reading / calm** | Meditation, journaling, racing-thoughts wind-down. |

Every visible copy moment should be readable from at least 2 of these four contexts. Single-use ("for sleep only") = leaves traffic and use-cases on the table.

## The moats — in priority order

1. **No subscription. Ever.** One-time lifetime purchase. Every future premium sound included. → This is the **primary** moat. Copy in screenshot 10, paywall, description bullet, release notes. Protect verbatim.
2. **Authentic field recordings.** 20 named places, named authors, real licences (CC0 / CC-BY-4.0). Every sound has a story. → Rendered in `SoundDetailSheet`. Backs claims of "real nature", "hand-recorded".
3. **Per-sound placement.** Users can move each channel around the listener. → Market this as sound placement, not "3D audio" or "spatial audio"; the latter sounds cheap and overclaims the current experience.
4. **Four binaural modes.** Sleep / meditation / relax / focus. → Pairs with the 4 use cases.
5. **100 % offline.** No streaming, no account. → Plane, tent, off-grid. Underlines no-subscription stance ("you actually own it").

Secondary moats (not headline material but supporting evidence):
- Tonal bed / harmonic pad
- Auto-variation
- Presets (premium)
- Sleep timer
- Multi-locale at launch (6)

## Anti-personae

- **Subscription-fatigued user**: had 3+ wellness-app subs, cancelled them, looking for one-time purchase. Primary target.
- **Traveler**: needs offline, predictable battery, no signup friction.
- **Insomniac / shift worker**: high-intent, repeat user, willing to pay for privacy and reliability.
- **Focus seeker**: came for sleep, stays for work blocks.
- **Reader / meditator**: low-intensity, long sessions, values calm UI.

We don't target: parents (we don't do white-noise-for-baby positioning to avoid liability), enterprise / coworking, mood-based playlists fans, social-share users.

## Competitor frame

| Competitor | Stance | Where Oasis wins |
| --- | --- | --- |
| Calm | Subscription, big content library, celebrity narrators | No subscription; deeper sound engine |
| Headspace | Subscription, meditation-led | We're not meditation; better for ambient long-listen |
| Portal | Subscription, photo + ambient pairing | Mixer + sound placement + binaural + offline |
| Rainy Mood | Free + ads / micro-IAP | Offline, real recordings, no ads |
| Endel | Subscription, generative | We're curated + offline, not generative; cheaper long-term |
| Sleep Cycle | Tracker + sounds | We don't track; we just sound right |

Aesthetic positioning: closer to **Endel, Reflectly, Mirror** (premium-feel, restrained, dark, organic) than **Calm / Headspace / Portal** (over-saturated, illustration-heavy).

## Pricing-anchor copy

- "Less than the price of a coffee in Paris" / "moins qu'un café à Paris" — confirmed converting (commits `2b9072a`, `e4ba1e6`).
- Apply across all 6 locales (translation-tested).
- Don't introduce "less than X subscription apps for Y months" comparisons — they age fast and complicate copy.

## Voice

- Calm, declarative, restrained.
- No exclamation marks. No superlatives ("Best", "#1", "Revolutionary"). No "Free trial" wording (Oasis is freemium, not trial — using "trial" is rejection-bait at Apple review).
- Active verbs. Concrete nouns ("rain", "wind", "campfire") preferred over abstractions ("relaxation", "wellness").
- French copy: not literal translations of English. The French market expects warmer, more poetic phrasing — but never marketing-fluffy.

## Strategic asks (open at memory bootstrap)

These came out of the audit and aren't yet shipped — track them:

- A/B "Less than one month of a subscription app. For life." vs the coffee anchor.
- Trial-purchase post-onboarding (page 3 of `OnboardingView`).
- Drop signature preview frequency from 1×/day to 1×/week.
- Add a 6th use case "hotel / travel" if data supports it.

Closed asks (decisions taken, don't reopen without new evidence):

- ❌ Subscription option — explicitly rejected by user.
- ❌ Annual / monthly tiers — same.
- ❌ Paid expansion packs after launch — undermines "every future Premium sound included".
