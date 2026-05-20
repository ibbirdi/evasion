# Oasis Community Radar

Daily acquisition radar for finding high-intent Reddit, Hacker News, and manual forum opportunities without automating publication.

The tool collects recent conversations, scores commercial fit, drafts transparent replies, and prints a Markdown digest. It never posts, votes, comments, or sends DMs.

## Run

From repo root:

```bash
node scripts/community-radar/community-radar.mjs --out /tmp/oasis-community-radar.md
```

Useful options:

```bash
node scripts/community-radar/community-radar.mjs --min-score 75 --max-items 8
node scripts/community-radar/community-radar.mjs --sources reddit --out /tmp/reddit-radar.md
node scripts/community-radar/community-radar.mjs --sources manual --manual scripts/community-radar/manual-items.example.json
node scripts/community-radar/community-radar.mjs --format json --out /tmp/oasis-community-radar.json
```

## Workflow

1. Run the radar once per day.
2. Open the top 5 opportunities only.
3. Read the community rules and thread context.
4. Edit the proposed reply in your own voice.
5. Post manually only when the reply helps the conversation.
6. Use at most one tracked App Store link per day.

## Guardrails

- Always disclose that you are the developer of Oasis.
- Do not post the generated draft blindly.
- Do not post the same reply twice.
- Do not use unsolicited DMs.
- Do not ask for upvotes, comments, or fake reviews.
- Do not post on Hacker News with AI-generated wording. Use the digest as research, then write manually.

## Campaign Links

Set `app.campaignProviderToken` in `config.json` when you have an Apple campaign provider token. The radar appends `ct=<campaign>` and `mt=8` to the App Store URL, and adds `pt=<token>` when configured.
