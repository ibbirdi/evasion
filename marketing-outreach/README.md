# Oasis Marketing Outreach

Local, human-in-the-loop outreach CRM for distributing Oasis Premium promo codes to carefully selected creators, reviewers, and community members.

The tool prepares prospect lists, scores fit, assigns one unique promo code per prospect, renders localized message drafts, exports daily plans, tracks replies, and reports results. It never sends email, DMs, comments, posts, or automated browser actions.

## What It Does

- Imports prospects from CSV into `data/prospects.csv`.
- Validates emails, URLs, duplicates, statuses, languages, contact channels, and promo code assignments.
- Scores prospects by niche fit, audience size, language, public contact path, engagement hints, and manual notes.
- Assigns unique promo codes from `data/promo-codes.csv`.
- Generates localized messages for `fr`, `en`, `es`, `de`, `it`, and `pt-BR`.
- Creates daily outreach plans as Markdown and CSV under `exports/`.
- Tracks status updates, notes, sent codes, replies, follow-ups, and summary reports.

## What It Does Not Do

- No automatic DMs.
- No automatic emails.
- No scraping.
- No platform login automation.
- No mass outreach.
- No bypassing TikTok, Instagram, YouTube, Reddit, or email rules.

Every message is a draft. You review, personalize, and send manually through an allowed channel.

## Install

```bash
cd marketing-outreach
npm install
```

Before using real campaigns, edit `config/app.json`:

```json
{
  "appStoreUrl": "https://apps.apple.com/...",
  "senderName": "Jonathan"
}
```

## Sensitive Files

Real data is ignored by git:

- `data/prospects.csv`
- `data/promo-codes.csv`
- `data/outreach-log.csv`
- `data/responses.csv`
- `exports/*`

Only example CSV files are versioned.

## Import Prospects

Create your working CSV from the example:

```bash
cp data/prospects.example.csv data/prospects.csv
```

Expected columns:

```csv
id,name,handle,platform,profileUrl,email,niche,followers,engagementHint,country,language,contactMethod,notes,status
example-sleep-creator-fr,Marie Dupont,@marie.sleep,instagram,https://www.instagram.com/marie.sleep,,sleep,8200,high engagement on night routine posts,FR,fr,dm,Posts about sleep routines,new
```

Import or normalize:

```bash
npm run outreach:import -- --file data/prospects.csv
```

Allowed `platform` values:

```text
tiktok, instagram, youtube, reddit, blog, newsletter, other
```

Allowed `contactMethod` values:

```text
dm, email, comment, form, manual
```

Allowed `status` values:

```text
new, shortlisted, contacted, replied, code_sent, posted, reviewed, rejected, no_response, do_not_contact
```

Allowed `language` values:

```text
fr, en, es, de, it, pt-BR, unknown
```

If language is `unknown`, message generation falls back to English and prints a manual-review warning.

## Import Promo Codes

Create your local promo-code file:

```bash
cp data/promo-codes.example.csv data/promo-codes.csv
```

Format:

```csv
code,status,assignedToProspectId,assignedAt,redeemed,notes
YOUR-CODE-0001,available,,,,
YOUR-CODE-0002,available,,,,
```

Import:

```bash
npm run outreach:codes:import -- --file data/promo-codes.csv
```

The tool never prints all codes. It only prints a code when it has just been assigned or rendered into a message for one prospect.

## Validate

```bash
npm run outreach:validate
```

Validation checks:

- invalid emails;
- invalid URLs;
- missing handles/profile URLs on social prospects;
- duplicates by email, profile URL, or platform/handle;
- missing or unusable contact channels;
- unknown statuses, platforms, contact methods, or languages;
- codes assigned to more than one prospect;
- codes assigned to missing prospect IDs;
- `do_not_contact` records that still carry risky state;
- compliance guardrails.

## Score

```bash
npm run outreach:score
```

Scoring writes these fields to `data/prospects.csv`:

- `score`
- `tier`
- `scoreReason`
- `priority`

Tier guide:

- `A`: best targets for today;
- `B`: good fit;
- `C`: maybe later or needs more context;
- `D`: low fit or risky.

Scoring favors supported App Store languages, especially prospects in `fr`, `en`, `es`, `de`, `it`, and `pt-BR`.

## Assign Codes

Assign one code:

```bash
npm run outreach:codes:assign -- --prospect-id example-sleep-creator-fr
```

Assign codes to the best eligible tier A prospects:

```bash
npm run outreach:codes:assign-batch -- --tier A --limit 20
```

Rules:

- a code can only be assigned once;
- `do_not_contact` prospects are blocked;
- statuses must be eligible;
- `new` prospects become `shortlisted` when a code is assigned.

## Generate One Message

Use the prospect language automatically:

```bash
npm run outreach:message -- --prospect-id example-sleep-creator-fr
```

Force a language:

```bash
npm run outreach:message -- --prospect-id example-sleep-creator-fr --lang en
```

Force a template:

```bash
npm run outreach:message -- --prospect-id example-sleep-creator-fr --template dm-instagram.fr
```

The command prints the message and writes it to:

```text
exports/messages/YYYY-MM-DD/
```

Available template families:

- `dm-instagram`
- `dm-tiktok`
- `dm-creator`
- `email-creator`
- `email-reviewer`
- `reddit-feedback`
- `followup-1`
- `followup-2`

Each exists in `fr`, `en`, `es`, `de`, `it`, and `pt-BR`.

## Generate A Daily Plan

French:

```bash
npm run outreach:plan -- --limit 20 --lang fr
```

English:

```bash
npm run outreach:plan -- --limit 20 --lang en
```

Other supported languages:

```bash
npm run outreach:plan -- --limit 20 --lang es
npm run outreach:plan -- --limit 20 --lang de
npm run outreach:plan -- --limit 20 --lang it
npm run outreach:plan -- --limit 20 --lang pt-BR
```

Exports:

```text
exports/outreach-plan-YYYY-MM-DD-LANG.md
exports/outreach-plan-YYYY-MM-DD-LANG.csv
```

The plan includes:

- name;
- platform;
- handle;
- URL;
- score and tier;
- niche;
- contact method;
- recommended template;
- assigned code or `to assign`;
- copyable message;
- next action.

The plan is capped by `config/outreach-rules.json` `dailyContactLimit`.

## Update Statuses

Mark contacted:

```bash
npm run outreach:update -- --prospect-id example-sleep-creator-fr --status contacted
```

Add a note:

```bash
npm run outreach:note -- --prospect-id example-sleep-creator-fr --note "A répondu positivement, code envoyé"
```

Mark assigned code as manually sent:

```bash
npm run outreach:sent -- --prospect-id example-sleep-creator-fr
```

Record a response:

```bash
npm run outreach:reply -- --prospect-id example-sleep-creator-fr --type positive
```

Response types:

```text
positive, neutral, negative, asked_question, posted, review_left, no_interest
```

## Follow-ups

Generate follow-up drafts for prospects contacted more than 5 days ago:

```bash
npm run outreach:followups -- --days 5
```

Optional limit:

```bash
npm run outreach:followups -- --days 5 --limit 10
```

If you manually send all generated follow-ups and want the tool to increment `followupCount`, use:

```bash
npm run outreach:followups -- --days 5 --record
```

The tool respects:

- `maxFollowups`;
- `minDaysBeforeFollowup`;
- `do_not_contact`;
- no-response status only;
- manual sending only.

## Report

```bash
npm run outreach:report
```

Exports:

```text
exports/reports/outreach-report-YYYY-MM-DD.md
exports/reports/outreach-report-YYYY-MM-DD.csv
exports/reports/outreach-report-YYYY-MM-DD.json
```

Metrics include:

- total prospects;
- counts by platform, niche, and tier;
- codes available, assigned, sent, redeemed;
- positive responses;
- posts obtained;
- App Store reviews obtained;
- response rate;
- contact to code-sent rate;
- code-sent to feedback rate.

## Daily Workflow

1. Add 20 to 50 manually found prospects to `data/prospects.csv`.
2. Run `npm run outreach:import -- --file data/prospects.csv`.
3. Run `npm run outreach:validate`.
4. Fix warnings that matter.
5. Run `npm run outreach:score`.
6. Run `npm run outreach:codes:assign-batch -- --tier A --limit 20`.
7. Run `npm run outreach:plan -- --limit 20 --lang fr` or another language.
8. Open the Markdown plan, review each profile manually, personalize if useful.
9. Send manually only through compliant public/professional channels.
10. After sending a code, run `npm run outreach:sent -- --prospect-id ...`.
11. Record replies with `npm run outreach:reply`.
12. Run `npm run outreach:report` at the end of the day.

## Compliance And Anti-Spam Rules

The V1 is intentionally conservative:

- `allowAutoSend` is `false`.
- `requireManualApproval` is `true`.
- daily plans are capped.
- follow-ups are capped.
- `do_not_contact` prospects are excluded.
- unknown languages require manual review.
- email use prints a warning because B2C email outreach in France/EU generally requires prior consent.

Prefer:

- public professional contact addresses;
- official contact forms;
- respectful manual DMs where platform rules allow it;
- transparent community feedback requests;
- no pressure, no obligation, no review incentives.

Avoid:

- private-data collection;
- harvested email lists;
- mass DMs;
- automated comments;
- hidden developer relationships;
- asking for positive reviews.

## Manual Research Keywords

`config/niches.json` contains manual-search keywords per niche. They are prompts for human research, not scraping instructions.

## Quality Checks

```bash
npm run typecheck
npm run outreach:validate
```
