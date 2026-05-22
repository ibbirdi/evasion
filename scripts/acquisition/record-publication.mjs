#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_LOG = "scripts/acquisition/download-sprint-log.json";
const VALID_STATUSES = new Set(["posted", "shipped", "running", "measured", "skipped"]);
const CHANNEL_SUFFIXES = ["_bluesky", "_mastodon", "_x"];
const LOCALE_SUFFIXES = ["_fr", "_en", "_de", "_es", "_it", "_ptbr"];

function parseArgs(argv) {
  const args = {
    log: DEFAULT_LOG,
    action: "",
    campaign: "",
    status: "posted",
    channel: "",
    url: "",
    date: new Date().toISOString().slice(0, 10),
    note: "",
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--log") {
      args.log = next;
      i += 1;
    } else if (arg === "--action") {
      args.action = next;
      i += 1;
    } else if (arg === "--campaign") {
      args.campaign = next;
      i += 1;
    } else if (arg === "--status") {
      args.status = next;
      i += 1;
    } else if (arg === "--channel") {
      args.channel = next;
      i += 1;
    } else if (arg === "--url") {
      args.url = next;
      i += 1;
    } else if (arg === "--date") {
      args.date = next;
      i += 1;
    } else if (arg === "--note") {
      args.note = next;
      i += 1;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!args.action && !args.campaign) {
    throw new Error("Provide --action or --campaign.");
  }
  if (!VALID_STATUSES.has(args.status)) {
    throw new Error(`--status must be one of: ${Array.from(VALID_STATUSES).join(", ")}`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(args.date)) {
    throw new Error("--date must be YYYY-MM-DD");
  }

  return args;
}

function printHelp() {
  console.log(`Oasis publication recorder

Usage:
  node scripts/acquisition/record-publication.mjs --campaign shorts_no_subscription_es --channel "TikTok" --url https://... --status posted
  node scripts/acquisition/record-publication.mjs --action ship-ios17-binary --status shipped --note "Uploaded 1.5.1"

Options:
  --log <path>         Sprint log path. Default: ${DEFAULT_LOG}
  --action <id>        Exact action id
  --campaign <id>      Campaign id from the queue or action log
  --status <status>    posted, shipped, running, measured, skipped. Default: posted
  --channel <name>     Published channel name
  --url <url>          Live post/release URL
  --date <YYYY-MM-DD>  Publication date. Default: today UTC
  --note <text>        Extra note appended to the action
`);
}

async function readJson(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return { absolute, json: JSON.parse(raw) };
}

function campaignCandidateGroups(campaign) {
  const exact = new Set([campaign]);
  const withoutChannel = new Set();
  for (const suffix of CHANNEL_SUFFIXES) {
    if (campaign.endsWith(suffix)) withoutChannel.add(campaign.slice(0, -suffix.length));
  }
  const withoutLocale = new Set();
  for (const value of [campaign, ...withoutChannel]) {
    for (const suffix of LOCALE_SUFFIXES) {
      if (value.endsWith(suffix)) withoutLocale.add(value.slice(0, -suffix.length));
    }
  }
  return [exact, withoutChannel, withoutLocale].filter((group) => group.size > 0);
}

function findAction(actions, args) {
  if (args.action) return actions.find((action) => action.id === args.action);
  for (const candidates of campaignCandidateGroups(args.campaign)) {
    const action = actions.find((entry) => {
      const childCampaigns = Array.isArray(entry.childCampaigns) ? entry.childCampaigns : [];
      const campaignPrefixes = Array.isArray(entry.campaignPrefixes) ? entry.campaignPrefixes : [];
      return (
        candidates.has(entry.campaign) ||
        candidates.has(entry.id?.replace(/-/g, "_")) ||
        childCampaigns.some((campaign) => candidates.has(campaign)) ||
        campaignPrefixes.some((prefix) => args.campaign.startsWith(prefix))
      );
    });
    if (action) return action;
  }
  return undefined;
}

function publicationEntry(args) {
  return {
    date: args.date,
    status: args.status,
    channel: args.channel || "",
    campaign: args.campaign || "",
    url: args.url || "",
    note: args.note || "",
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const { absolute, json } = await readJson(args.log);
  const action = findAction(json.actions || [], args);
  if (!action) {
    throw new Error(`No action matched ${args.action || args.campaign}.`);
  }

  const entry = publicationEntry(args);
  action.status = args.status;
  action.publishedAt = args.date;
  action.publishedChannels = Array.isArray(action.publishedChannels) ? action.publishedChannels : [];
  action.publishedChannels.push(entry);
  const noteParts = [action.notes || ""];
  const summary = [
    `${args.date}: marked ${args.status}`,
    args.channel ? `on ${args.channel}` : "",
    args.url ? `(${args.url})` : "",
    args.note || "",
  ].filter(Boolean).join(" ");
  noteParts.push(summary);
  action.notes = noteParts.filter(Boolean).join(" ");

  await fs.writeFile(absolute, `${JSON.stringify(json, null, 2)}\n`);
  console.log(`Updated ${action.id} -> ${args.status}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
