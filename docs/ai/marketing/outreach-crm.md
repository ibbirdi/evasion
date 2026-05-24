---
title: Promo Code Outreach CRM
status: stable
last_updated: 2026-05-23
tracks:
  - "marketing-outreach/README.md"
  - "marketing-outreach/.gitignore"
  - "marketing-outreach/package.json"
  - "marketing-outreach/tsconfig.json"
  - "marketing-outreach/src/**"
  - "marketing-outreach/config/**"
  - "marketing-outreach/templates/**"
  - "marketing-outreach/data/*.example.csv"
related:
  - "download-growth-sprint.md"
  - "community-radar.md"
  - "../codebase/build-and-test.md"
  - "../codebase/structure.md"
---

# Promo Code Outreach CRM

`marketing-outreach/` is a local TypeScript CLI for distributing Oasis Premium promo codes through a controlled, human-reviewed outreach process.

## Purpose

The tool helps build a small feedback / influencer CRM around the 500 available Premium promo codes:

1. import manually sourced prospects;
2. validate data quality and compliance guardrails;
3. score fit for Oasis;
4. assign one unique promo code per prospect;
5. render localized messages;
6. export daily contact plans;
7. track status, notes, replies, follow-ups, and reports.

It is deliberately not a sending or scraping system.

## Guardrails

- No automatic DMs, emails, comments, posts, browser automation, or scraping.
- `config/outreach-rules.json` keeps `allowAutoSend: false` and `requireManualApproval: true`.
- Daily contact plans are capped by `dailyContactLimit` (20 by default).
- Follow-ups are capped by `maxFollowups` and `minDaysBeforeFollowup`.
- `do_not_contact` prospects are blocked from plans and code assignment.
- Email outreach prints a France/EU B2C consent warning.
- Manual-search keywords in `config/niches.json` are for human research only.

## Data model

Versioned examples:

- `data/prospects.example.csv`
- `data/promo-codes.example.csv`

Ignored local working files:

- `data/prospects.csv`
- `data/promo-codes.csv`
- `data/outreach-log.csv`
- `data/responses.csv`
- `exports/*`

Promo codes are treated as sensitive. The CLI never prints all codes, only the single code assigned/rendered for one prospect.

## Languages

V1 supports every Oasis App Store language:

- `fr`
- `en`
- `es`
- `de`
- `it`
- `pt-BR`

`unknown` is accepted in `prospects.csv`, but message rendering falls back to English and emits a manual-review warning. Plans can be filtered by language with `--lang`.

## Commands

Run from `marketing-outreach/`:

```bash
npm install
npm run outreach:import -- --file data/prospects.csv
npm run outreach:codes:import -- --file data/promo-codes.csv
npm run outreach:validate
npm run outreach:score
npm run outreach:codes:assign-batch -- --tier A --limit 20
npm run outreach:plan -- --limit 20 --lang fr
npm run outreach:message -- --prospect-id <id>
npm run outreach:sent -- --prospect-id <id>
npm run outreach:reply -- --prospect-id <id> --type positive
npm run outreach:followups -- --days 5
npm run outreach:report
npm run typecheck
```

The README in the subproject is the operational source of truth for CSV columns, templates, and the daily workflow.

## Strategic fit

Use this tool for manual creator/reviewer feedback loops: sleep, focus, productivity, meditation, study, ADHD-friendly, desk setup, night routine, iOS app review, indie apps, and wellness audiences.

It complements the community radar and short-form publishing loop in [download-growth-sprint.md](download-growth-sprint.md), but it should stay slower and more selective: roughly 20 good contacts per day rather than broad outreach.
