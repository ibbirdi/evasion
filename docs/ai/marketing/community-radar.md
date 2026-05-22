---
title: Community Radar
status: stable
last_updated: 2026-05-22
tracks:
  - "scripts/community-radar/**"
related:
  - "positioning.md"
  - "aso-strategy.md"
  - "../codebase/build-and-test.md"
---

# Community Radar

`scripts/community-radar/` is a lightweight acquisition helper for finding high-intent community threads without automating spammy behavior. It is now part of the [download-growth sprint](download-growth-sprint.md).

## Current local state — 2026-05-22

- Defaults are broadened for daily acquisition: 21-day recency, minimum score 55, 15 max items.
- Query set now includes iOS sleep-app recommendations, Calm/Headspace subscription alternatives, insomnia/noise masking, deep-work ambience, hotel/travel noise, and maker/indie feedback threads.
- A 2026-05-22 run at score 70 found no opportunities; when the radar is quiet, use the owned short-form video loop instead of forcing a community reply.

## Purpose

The radar turns Reddit, Hacker News, and manually imported forum links into a daily Markdown digest:

1. collect recent conversations;
2. score fit against Oasis' current positioning;
3. flag community-rule and medical-context risks;
4. generate a transparent reply draft;
5. attach an optional App Store campaign link.

It never posts, comments, votes, messages users, creates accounts, or bypasses platform rules.

## Strategic fit

Best-fit angles, in priority order:

- **No subscription**: the strongest differentiator. Use when users complain about Calm, BetterSleep, subscriptions, or yearly pricing.
- **Offline travel**: hotel noise, plane use, no streaming, no account.
- **Sleep sounds**: rain, wind, white/brown noise, timer, background playback. Avoid medical claims.
- **Focus / reading**: stable ambience for long sessions, not playlist-like music.
- **Maker story**: for HN / indie communities, frame Oasis as an offline AVAudioEngine product with a lifetime unlock.

Keep replies aligned with [positioning.md](positioning.md): calm, declarative, concrete, and always transparent that the author is the developer.

## Daily operating rule

From repo root:

```bash
node scripts/community-radar/community-radar.mjs --out /tmp/oasis-community-radar.md
```

Then manually review only the top opportunities:

- max 5 useful replies per day;
- max 1 App Store link per day;
- always disclose "I am the developer of Oasis";
- never send unsolicited DMs;
- never ask for upvotes, comments, or reviews;
- never paste generated Hacker News comments.

## Inputs

- `config.json`: source queries, scoring defaults, campaign IDs, App Store URL.
- `manual-items.example.json`: import shape for non-Reddit forums.
- CLI flags can restrict sources, recency window, score threshold, output format, and manual import path.

## Measurement

Each opportunity has a campaign ID, used as the `ct` parameter in the App Store link. Add `app.campaignProviderToken` in `config.json` once an Apple campaign provider token is available.

Read results in App Store Connect by campaign:

- product page views;
- first-time downloads;
- conversion rate;
- proceeds / premium unlocks where available.

If a segment produces installs from organic replies, mirror the winning angle into a Custom Product Page or a small Reddit Ads app-install test.
