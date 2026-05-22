---
title: Download Growth Sprint
status: wip
last_updated: 2026-05-22
tracks:
  - "scripts/acquisition/**"
  - "scripts/community-radar/**"
  - "marketing-video-factory/**"
  - "ios-native/OasisNative.xcodeproj/**"
related:
  - "positioning.md"
  - "aso-strategy.md"
  - "community-radar.md"
  - "video-factory.md"
---

# Download Growth Sprint

Operational plan for generating **1000+ first-time iOS downloads worldwide** for Oasis from the current App Store listing.

## Baseline

- The public App Store page is already aligned with the 1.5.x local metadata: 35 sounds, multi-use positioning, no subscription, offline use.
- User confirmed on 2026-05-22 that the App Store listing is current; this sprint excludes ASO / metadata edits unless analytics later show a listing-level conversion problem.
- Oasis is available worldwide and localized in six App Store languages (`en-US`, `fr-FR`, `de-DE`, `es-ES`, `it`, `pt-BR`). Treat multilingual distribution as a growth lever, not a footnote: track campaign tokens by language and market cluster.
- The app was previously limited to iOS 18+. Version `1.5.1` build `7` is prepared with an iOS 17+ deployment target after replacing the only iOS 18-only SwiftUI API found in `HomeView`.
- iOS 16 is not a quick win because the app uses Swift Observation (`@Observable` / `@Bindable`), which implies an iOS 17+ baseline without a broader state-layer refactor.

## Strategy

Use a 30-day global sprint with four measurable acquisition loops:

1. **Audience unlock** — ship the iOS 17 deployment-target change in the next binary so users on iOS 17 can install Oasis.
2. **Localized short-form distribution** — publish the same proof assets with localized captions, rotating `fr-FR`, `en-US`, `de-DE`, `es-ES`, `it`, and `pt-BR` copy instead of treating French as the default market.
3. **High-intent community replies** — run the community radar daily, manually reply only where the thread asks for a relevant app, and use at most one tracked App Store link per day.
4. **Owned social/API scheduling** — use official platform APIs or approved schedulers for owned accounts; use human review for forums, communities, and recommendation threads.
5. **Controlled paid search ramp** — if organic/social pace is below target after day 3, activate the multilingual Apple Ads Search Results ramp with exact-match keywords, per-market daily caps, and a 600-download contribution target.
6. **Manual multilingual outreach** — pitch relevant iOS curators, sleep/focus creators, and regional app/newsletter curators with tracked links, but send only manually after review and personalization.

If actual downloads fall below the required pace after day 3, activate the Apple Ads ramp with hard daily caps, split by language/market cluster. Use exact-intent keywords first: `sleep sounds`, `white noise`, `rain sounds`, `no subscription`, `focus sounds`, plus localized equivalents where campaign data supports it. The current model targets 600 paid first-time downloads at a 900 spend guardrail, then lets campaign-level data decide whether to continue, pause, or expand.

## Measurement

Use [`scripts/acquisition/download-sprint-report.mjs`](../../../scripts/acquisition/download-sprint-report.mjs):

```bash
node scripts/acquisition/download-sprint-report.mjs --out /tmp/oasis-download-sprint.md
```

The report reads [`scripts/acquisition/download-sprint-log.json`](../../../scripts/acquisition/download-sprint-log.json), runs the community radar, prints priority campaign links, lists all currently due actions, and computes the required daily pace. For 1000 downloads over 30 days from a zero baseline, the sprint needs about **34.5 downloads/day** after day 1.

The metrics log also contains an `actions` pipeline. Each action records date, status, channel, campaign, tracked link, expected downloads, cost, and attributed downloads. Use it to move actions from `planned` / `candidate` to `posted`, `shipped`, `running`, or `measured`.

Log these App Store Connect values once per day:

- first-time downloads;
- product page views;
- impressions;
- premium purchases;
- campaign-level first-time downloads when available.

Campaign data has privacy thresholds. Apple may hide campaign or custom-product-page data until a campaign/page has at least five first-time downloads, so absence of campaign rows is not automatically failure.

## Campaign tokens

Priority campaign IDs:

- `reddit_sleep_nosub`
- `reddit_ios_sleep_reco`
- `reddit_calm_alt`
- `reddit_focus_ambient`
- `reddit_travel_offline`
- `hn_maker_no_subscription`
- `shorts_sleep_cabin`
- `shorts_no_subscription`
- `shorts_spatial_magic`
- `shorts_sleep_cabin_en`
- `shorts_no_subscription_en`
- `shorts_spatial_magic_en`
- `shorts_no_subscription_de`
- `shorts_no_subscription_es`
- `shorts_no_subscription_it`
- `shorts_no_subscription_ptbr`

`scripts/community-radar/config.json` still has an empty `app.campaignProviderToken`. Add the App Store Connect provider token after campaign links are created so generated links include both `ct` and `pt`.

## Daily cadence

1. Update the metrics log from App Store Connect.
2. Run the sprint report.
3. If radar finds good opportunities, manually review rules/context and reply to up to five threads.
4. If radar is quiet, publish one owned short instead.
5. Use exactly one tracked link per post/reply.
6. Rotate language/market clusters daily: French, English/global, German, Spanish, Italian, Portuguese-Brazilian.
7. After day 3, compare actual downloads to required pace and decide whether to start the small Apple Ads test.

Ready-to-edit captions, reply templates, campaign links, and the conditional Apple Ads exact-match setup live in [`scripts/acquisition/launch-pack.md`](../../../scripts/acquisition/launch-pack.md).

The Product Hunt manual launch kit lives in [`scripts/acquisition/product-hunt-launch-pack.md`](../../../scripts/acquisition/product-hunt-launch-pack.md). It contributes a separate candidate action to the sprint, but it must stay manual and transparent: no vote/comment automation, no mass DMs, and no hidden developer relationship.

The manual outreach pack is generated by [`scripts/acquisition/build-outreach-pack.mjs`](../../../scripts/acquisition/build-outreach-pack.mjs) from [`scripts/acquisition/outreach-plan.json`](../../../scripts/acquisition/outreach-plan.json). It creates date-stamped target sheets and message drafts for English, French, German, Spanish, Italian, and Brazilian Portuguese market clusters under `scripts/acquisition/outreach-pack/<date>/`. Generated outreach packs are ignored by git because they are daily working files.

The global publishing queue lives in [`scripts/acquisition/global-publishing-plan.json`](../../../scripts/acquisition/global-publishing-plan.json) and [`scripts/acquisition/global-publishing-queue.md`](../../../scripts/acquisition/global-publishing-queue.md). It now defaults to the full 30-day sprint and rotates videos by language occurrence, so French and English use all ready assets instead of repeating the same one every six days.

Owned text channels can be dry-run or published through official Bluesky/Mastodon APIs with [`scripts/acquisition/publish-owned-post.mjs`](../../../scripts/acquisition/publish-owned-post.mjs). YouTube Shorts uploads can be dry-run or published through the official YouTube Data API with [`scripts/acquisition/publish-video-post.mjs`](../../../scripts/acquisition/publish-video-post.mjs) when `YOUTUBE_ACCESS_TOKEN` has the `youtube.upload` scope or when the OAuth client/refresh-token env vars are available. TikTok, Instagram Reels, and Facebook Reels still use their official account/audit/hosting flows, and forums remain human-reviewed.

[`scripts/acquisition/dispatch-due-posts.mjs`](../../../scripts/acquisition/dispatch-due-posts.mjs) is the daily execution layer. It regenerates the 30-day queue and sprint report, processes due slots for a date, dry-runs YouTube/Bluesky/Mastodon, and writes an optional JSON summary. With `--publish`, it still requires `OASIS_AUTO_PUBLISH=1` plus official API credentials; otherwise it marks eligible slots as `dry_run_only` or `missing_credentials`.

The dispatcher also refreshes release readiness, Apple Ads, and outreach packs each day. Release readiness reports whether the iOS 17+ build is export/upload-ready; Apple Ads still requires explicit campaign activation, and outreach still requires manual sending.

[`scripts/acquisition/check-release-readiness.mjs`](../../../scripts/acquisition/check-release-readiness.mjs) is the upload preflight for the iOS 17 audience-unlock build. It checks the current `OasisNative` version/build, latest archive, local signing identities, and Fastlane log. As of 2026-05-22, the archive exists for `1.5.1` build `7`, but the verdict is `blocked` because only an Apple Development identity is installed and the archive is signed with that development identity instead of an Apple/iOS Distribution certificate.

Codex automation `oasis-daily-publishing-dispatcher` runs daily and calls the dispatcher. It only publishes automatically if `OASIS_AUTO_PUBLISH=1` and the required official API credentials are present, and it never auto-posts to community, human-review, unimplemented, or unaudited channels.

For platforms that still need native schedulers or human posting, [`scripts/acquisition/export-manual-pack.mjs`](../../../scripts/acquisition/export-manual-pack.mjs) writes a per-day upload pack under `scripts/acquisition/manual-packs/<date>/` with copied video assets, localized captions, campaign links, and channel notes. Generated packs are gitignored.

After a post or release is live, use [`scripts/acquisition/record-publication.mjs`](../../../scripts/acquisition/record-publication.mjs) to update the matching action in `download-sprint-log.json`. It prefers exact localized campaign matches, then falls back to channel/locale-stripped campaign variants, and appends a `publishedChannels` entry for later attribution.

[`scripts/acquisition/build-apple-ads-pack.mjs`](../../../scripts/acquisition/build-apple-ads-pack.mjs) prepares the paid fallback. It writes a multilingual Apple Ads Search Results setup sheet with exact-match keywords, hard daily caps, negative keywords, tracked campaign links, and `budget-plan.csv` for the 600-download ramp. The pack stays `prepare_only` before day 4 unless forced; after day 3 it switches to `activate_now` when logged downloads are below the required sprint pace. Apple Ads API 5 is current as of 2026-05, and the pack intentionally starts with Search Match off for clean attribution before testing broader automation.

[`scripts/acquisition/import-metrics-csv.mjs`](../../../scripts/acquisition/import-metrics-csv.mjs) imports daily or campaign-level CSV exports into `download-sprint-log.json`. Use `--dry-run` first. The sprint report normalizes localized campaign tokens (`shorts_*_fr`, `appleads_en_*`, etc.) back to their matching action, using action locale when present so downloads are not double-counted across languages.

Ready short-form assets as of 2026-05-22:

- `shorts_sleep_cabin`: `marketing-video-factory/output/2026-05-22/oasis_sleep_cabin_fr_113508_c294c.mp4`
- `shorts_no_subscription`: `marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_fr_114414_c294d.mp4`
- `shorts_spatial_magic`: `marketing-video-factory/output/2026-05-22/oasis_spatial_magic_fr_120041_c294e.mp4`
- `shorts_no_subscription_en`: `marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_en_120442_c294f.mp4`
- `shorts_sleep_cabin_en`: `marketing-video-factory/output/2026-05-22/oasis_sleep_cabin_en_121053_c294g.mp4`
- `shorts_spatial_magic_en`: `marketing-video-factory/output/2026-05-22/oasis_spatial_magic_en_121214_c294h.mp4`
- `shorts_no_subscription_de`: `marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_de_122309_c294i.mp4`
- `shorts_no_subscription_es`: `marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_es_122750_c294j.mp4`
- `shorts_no_subscription_it`: `marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_it_122838_c296h.mp4`
- `shorts_no_subscription_ptbr`: `marketing-video-factory/output/2026-05-22/oasis_no_subscription_pitch_ptbr_122926_c296i.mp4`

The 2026-05-22 radar run found no 70+ community opportunity, so do not force a Reddit reply today; publish an owned short instead.

## Guardrails

- Never automate posts, comments, votes, DMs, or reviews.
- Always disclose the developer connection in community replies.
- Do not make medical claims around insomnia, tinnitus, anxiety, or babies.
- No subscription positioning stays central; do not test subscription language.
