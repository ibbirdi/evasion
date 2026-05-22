# Oasis Global Download Sprint

This folder contains the lightweight monitoring loop for the global download-growth sprint.

## Daily report

```bash
node scripts/acquisition/download-sprint-report.mjs --out /tmp/oasis-download-sprint.md
```

The report combines:

- the local sprint metrics log;
- the acquisition action pipeline;
- the community radar;
- priority campaign links;
- the day's operating checklist.

Use `--skip-radar` for a fast local metrics-only report.

## Launch pack

[`launch-pack.md`](launch-pack.md) contains ready-to-edit captions, a safe Reddit reply template, campaign links, and the conditional Apple Ads exact-match test plan.

[`product-hunt-launch-pack.md`](product-hunt-launch-pack.md) contains the manual Product Hunt launch kit. Use it for one coordinated global launch only; it is not an automation target.

Generate the manual multilingual outreach pack:

```bash
node scripts/acquisition/build-outreach-pack.mjs --date 2026-05-22
```

The outreach pack writes target categories, tracked campaign links, and per-track message drafts under `scripts/acquisition/outreach-pack/<date>/`. It is manual only: review every target, personalize every message, and send from Jonathan's real account.

## Global publishing queue

```bash
node scripts/acquisition/build-global-publishing-queue.mjs --start 2026-05-22 --days 30 --out scripts/acquisition/global-publishing-queue.md
```

The queue uses [`global-publishing-plan.json`](global-publishing-plan.json) to rotate language clusters, ready video assets, owned-channel scheduling targets, and human-reviewed community slots. Owned accounts should use official APIs or approved schedulers; forums and recommendation communities stay manual.

Generate a JSON queue for automation:

```bash
node scripts/acquisition/build-global-publishing-queue.mjs --format json --out scripts/acquisition/global-publishing-queue.json
```

Dry-run an owned text post:

```bash
node scripts/acquisition/publish-owned-post.mjs --campaign shorts_sleep_cabin_fr_bluesky
```

Text publishing is implemented only for owned Bluesky and Mastodon accounts through their official APIs. Use `--publish` only after configuring the documented environment variables.

Dry-run an owned video upload:

```bash
node scripts/acquisition/publish-video-post.mjs --campaign shorts_no_subscription_es --channel youtube
```

Video publishing is implemented for YouTube through `videos.insert` when either `YOUTUBE_ACCESS_TOKEN` has the `youtube.upload` OAuth scope or `YOUTUBE_CLIENT_ID` / `YOUTUBE_CLIENT_SECRET` / `YOUTUBE_REFRESH_TOKEN` are available for token refresh. TikTok, Instagram Reels, and Facebook Reels still require their official account/audit/hosting flows, so the queue remains the source of truth for those uploads.

Run the daily dispatcher:

```bash
node scripts/acquisition/dispatch-due-posts.mjs --skip-radar --out /tmp/oasis-dispatch.json
```

The dispatcher regenerates the 30-day queue and sprint report, dry-runs due owned-channel slots, and lists manual/review-only slots. To allow actual publication, set `OASIS_AUTO_PUBLISH=1`, provide the relevant official API credentials, and pass `--publish`. It still refuses to auto-post to human-review or unimplemented channels.

Check App Store release readiness before retrying the iOS 17 build upload:

```bash
node scripts/acquisition/check-release-readiness.mjs
```

The preflight inspects the current iOS version/build, the latest `OasisNative` archive, local signing identities, and the last Fastlane archive log. It writes `scripts/acquisition/release-readiness.md` and `.json`, and should read `Verdict: ready` before rerunning `bundle exec fastlane build_and_upload`.

Export the manual upload pack for channels that still require native schedulers or human review:

```bash
node scripts/acquisition/export-manual-pack.mjs --date 2026-05-25
```

The pack copies due video assets and writes a per-day `README.md` with localized captions, campaign links, and channel notes under `scripts/acquisition/manual-packs/<date>/`. The generated pack folder is ignored by git because it contains binary video copies.

Record a live publication back into the sprint log:

```bash
node scripts/acquisition/record-publication.mjs --campaign shorts_no_subscription_es --channel TikTok --url https://example.com/post --status posted
```

The recorder updates the matching action in `download-sprint-log.json`, appends a publication entry, and keeps the report from treating already-live work as untouched.

Prepare the conditional Apple Ads fallback:

```bash
node scripts/acquisition/build-apple-ads-pack.mjs
```

The Apple Ads pack writes a multilingual exact-match setup sheet under `scripts/acquisition/apple-ads-pack/`. It stays in `prepare_only` until day 4 unless forced with `--force`, or until the logged download pace is below the pace required for the 1000-download sprint.

It also writes `budget-plan.csv`, which models a 600-download paid ramp across the six market clusters with hard per-market daily caps and the configured CPA guardrail.

The daily dispatcher also refreshes this Apple Ads pack, so the fallback status stays aligned with the current sprint pace.

The daily dispatcher also refreshes the release-readiness preflight and the outreach pack so the upload blocker and manual pitching queue stay aligned with the sprint date.

## Metrics log

Update `download-sprint-log.json` from App Store Connect once per day after analytics refresh.

```json
{
  "date": "2026-05-23",
  "firstTimeDownloads": 0,
  "productPageViews": 0,
  "impressions": 0,
  "premiumPurchases": 0,
  "notes": "Optional context"
}
```

Use `campaigns` entries when App Store Connect shows campaign-level data:

```json
{
  "date": "2026-05-23",
  "campaign": "reddit_sleep_nosub",
  "firstTimeDownloads": 0,
  "productPageViews": 0,
  "premiumPurchases": 0
}
```

Apple campaign and custom-product-page analytics appear only after privacy thresholds are met, so a blank campaign table does not mean the campaign failed.

Import daily or campaign metrics from CSV exports:

```bash
node scripts/acquisition/import-metrics-csv.mjs --file exports/app-store-daily.csv
node scripts/acquisition/import-metrics-csv.mjs --file exports/campaigns.csv --type campaign
```

The importer recognizes common column names for dates, first-time downloads, page views, impressions, premium purchases, campaign tokens, spend, and taps. Use `--dry-run` first to preview added/updated rows.

## Action pipeline

Use `actions` entries to track the actual work that can generate downloads.

```json
{
  "id": "shorts-sleep-cabin-fr",
  "date": "2026-05-22",
  "status": "planned",
  "channel": "short-form",
  "campaign": "shorts_sleep_cabin",
  "asset": "marketing-video-factory scenario sleep-cabin",
  "link": "https://apps.apple.com/app/apple-store/id6759493932?ct=shorts_sleep_cabin&mt=8",
  "cost": 0,
  "expectedDownloads": 8,
  "actualFirstTimeDownloads": 0,
  "notes": "Post first on the strongest owned channel."
}
```

Statuses:

- `candidate`: review manually before using.
- `ready`: generated and ready for a final human review/post.
- `planned`: ready to execute.
- `conditional`: execute only if the stated condition is true.
- `deferred`: intentionally held until a better opportunity appears.
- `posted`, `shipped`, `running`: live and waiting for attribution.
- `measured`: performance has been read back into `campaigns` or `actualFirstTimeDownloads`.
- `skipped`: intentionally not used.
