# Oasis Acquisition Launch Pack

Ready-to-use copy and setup notes for the 1000-download global sprint. Keep every public post human-edited before publishing.

## Day 1 priority

1. Upload the next iOS binary with the iOS 17 deployment target.
2. Publish `sleep-cabin` as the first short-form post.
3. Review one high-intent Reddit sleep/noise thread. Reply only if the thread is asking for practical app recommendations.

## Short-form post: `sleep-cabin`

Generated asset:

```text
marketing-video-factory/output/2026-05-22/oasis_sleep_cabin_fr_113508_c294c.mp4
```

Campaign link:

```text
https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_sleep_cabin&mt=8
```

French caption:

```text
Le bruit blanc, mais plus vivant.

La pluie derrière toi, l'orage au loin, la forêt devant. Oasis transforme le bruit de fond en véritable refuge sonore.

Un achat. Pas d'abonnement. Fonctionne hors ligne.

https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_sleep_cabin&mt=8

#sommeil #pluie #bruitblanc #iphone #appios #sansabonnement
```

English caption:

```text
For the nights when your brain will not slow down.

Oasis lets you build your own ambience: rain, forest, thunder, wind, timer, background playback.

One purchase. No subscription. Works offline.

https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_sleep_cabin&mt=8

#sleep #rainsounds #whitenoise #iphone #iosapp #nosubscription
```

## Short-form post: `no-subscription-pitch`

Generated asset:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_fr_114414_c294d.mp4
```

Generated English asset:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_en_120442_c294f.mp4
```

Campaign link:

```text
https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_no_subscription&mt=8
```

French caption:

```text
Une app calme ne devrait pas te facturer tous les mois.

Oasis: 35 sons de nature, 4 modes binauraux, presets, timer.
Un achat. Pour toujours.

https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_no_subscription&mt=8

#sansabonnement #achatunique #sommeil #focus #iphone #appios
```

English caption:

```text
A calm app should not bill you every month.

Oasis: 35 nature sounds, 4 binaural modes, presets, timer.
One purchase. Yours forever.

https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_no_subscription&mt=8

#nosubscription #onetimepurchase #sleep #focus #iphone #iosapp
```

## Short-form post: `spatial-magic`

Generated asset:

```text
marketing-video-factory/output/2026-05-22/oasis_spatial_magic_fr_120041_c294e.mp4
```

Campaign link:

```text
https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_spatial_magic&mt=8
```

French caption:

```text
Mets un casque.

Avec Oasis, tu peux placer la pluie autour de toi: gauche, droite, devant, derriere.
Un refuge sonore immersif, sans abonnement.

https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_spatial_magic&mt=8

#placementsonore #pluie #binaural #sommeil #iphone #appios
```

English caption:

```text
Put on headphones.

With Oasis, you can place rain around you: left, right, in front, behind.
An immersive sound shelter, no subscription.

https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_spatial_magic&mt=8

#soundplacement #rainsounds #binaural #sleep #iphone #iosapp
```

## English short-form assets

Use these first for global English channels:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_en_120442_c294f.mp4
marketing-video-factory/output/2026-05-22/oasis_sleep_cabin_en_121053_c294g.mp4
marketing-video-factory/output/2026-05-22/oasis_spatial_magic_en_121214_c294h.mp4
```

## German short-form asset

Use this for DACH no-subscription tests:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_de_122309_c294i.mp4
```

## Spanish short-form asset

Use this for Spain and LATAM Spanish no-subscription tests:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_es_122750_c294j.mp4
```

## Italian short-form asset

Use this for Italian no-subscription tests:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_it_122838_c296h.mp4
```

## Brazilian Portuguese short-form asset

Use this for Brazilian Portuguese no-subscription tests:

```text
marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_ptbr_122926_c296i.mp4
```

## Reddit reply template

Use only when the thread is asking for app recommendations or concrete noise-masking ideas. Do not use in medical-advice-only threads.

```text
I am the developer of Oasis, so I am biased, but this is close to the use case I built it for.

It is an iOS nature sound mixer: rain, wind, ocean, birds, forest, thunder, timer, background playback, and offline audio. The free version has a few sounds; the full unlock is a one-time purchase, not a subscription.

For sleep/travel noise, I would compare any app on three things: does it keep playing with the phone locked, does it work offline, and does the pricing stay clear after day one.

Link, only if useful here: https://apps.apple.com/app/apple-store/id6759493932?ct=reddit_insomnia_noise&mt=8
```

## Apple Ads exact test

Run only if the first three days are below the sprint pace. The current paid-ramp model is designed to cover 600 of the 1000 target downloads while the owned/social queue covers the rest.

Campaign:

- Placement: Search results.
- Budget: hard daily cap before launch.
- Strategy: manual / manage bids so exact terms can be separated.
- Geography: start with the current strongest store locale, then expand.
- Custom product page: use a sleep-first page when available; otherwise default page.
- Budget model: generate `scripts/acquisition/apple-ads-pack/budget-plan.csv` and keep the first ramp under the 900 total spend guardrail unless observed CPA beats the model.

Ad groups:

| Ad group | Match | Keywords |
| --- | --- | --- |
| Sleep sounds exact | Exact | `sleep sounds`, `sleep sound app`, `rain sounds`, `white noise`, `brown noise` |
| No subscription exact | Exact | `sleep app no subscription`, `white noise no subscription`, `relax app no subscription` |
| Focus exact | Exact | `focus sounds`, `background noise focus`, `rain sounds study` |

Pause rule:

- Pause any keyword with taps but zero downloads after a meaningful sample.
- Keep only terms with first-time downloads or clear product-page-view conversion.
- Mirror winning intent into community replies, shorts, and custom product pages.

## Product Hunt launch

Use [`product-hunt-launch-pack.md`](product-hunt-launch-pack.md) for one manual global launch after the 1.5.1 iOS 17+ binary is available. This is a founder/story launch, not a posting automation: no automated votes, comments, DMs, or duplicate accounts.
