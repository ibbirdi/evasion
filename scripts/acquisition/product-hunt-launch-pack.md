# Oasis Product Hunt Launch Pack

Use this only as a coordinated manual launch. Do not automate votes, comments, follows, direct messages, or repeated reposts.

## Launch target

- Date candidate: 2026-05-28
- Campaign token: `producthunt_global_launch`
- Tracked link: `https://apps.apple.com/app/apple-store/id6759493932?ct=producthunt_global_launch&mt=8`
- Primary audience: makers, indie iOS users, focus/sleep app buyers, no-subscription app fans.
- Goal contribution: 80 first-time downloads toward the 1000-download sprint.

## Positioning

Oasis is a native iPhone ambient sound mixer for sleep, focus, travel, and quiet work. It combines 35 offline nature sounds, 4 binaural tracks, spatial placement, presets, and a sleep timer. The strongest Product Hunt angle is not "another sleep app"; it is "calm software without a subscription."

## Product Hunt tagline

```text
Offline nature sounds for sleep and focus, with no subscription
```

## Short description

```text
Oasis turns your iPhone into a calm ambient mixer: 35 nature sounds, binaural tracks, spatial placement, presets, and a sleep timer. It works offline and unlocks with one lifetime purchase instead of another monthly subscription.
```

## Maker comment

```text
Hey Product Hunt, I am Jonathan, the solo developer behind Oasis.

I built Oasis because most calm/sleep apps eventually started to feel like another subscription to manage. I wanted the opposite: a native iPhone app that works offline, sounds good with headphones, and stays simple enough to use when you are tired.

Oasis includes 35 nature sounds, 4 binaural tracks, presets, a timer, background playback, and per-sound spatial placement. The free version is usable, and the full unlock is a one-time purchase.

I would especially love feedback on two things:
- whether the spatial sound placement is clear enough;
- which sound combinations people actually use for sleep, work, or travel.

Tracked App Store link:
https://apps.apple.com/app/apple-store/id6759493932?ct=producthunt_global_launch&mt=8
```

## First-hour checklist

1. Confirm the 1.5.1 iOS 17+ binary is live or in review with the expected App Store availability.
2. Use the English `no-subscription-pitch` and `sleep-cabin` videos as supporting media.
3. Post one honest founder update on owned channels with the Product Hunt link only after the launch is public.
4. Reply manually to every substantive Product Hunt comment during the first 6 hours.
5. Record the launch URL with `record-publication.mjs` once live:

```bash
node scripts/acquisition/record-publication.mjs --campaign producthunt_global_launch --channel ProductHunt --url <launch-url> --status posted
```

## Owned-channel copy

```text
I launched Oasis on Product Hunt today.

It is a native iPhone ambient mixer for sleep and focus: 35 offline nature sounds, binaural tracks, spatial placement, presets, and no subscription.

Feedback from people who care about calm, well-made iOS apps would mean a lot.

<product-hunt-url>
```

## Guardrails

- Do not ask for upvotes.
- Do not post from unrelated accounts.
- Do not mass-message people.
- Do not make medical claims around insomnia, anxiety, tinnitus, babies, or treatment.
- Do not hide that this is your app.
