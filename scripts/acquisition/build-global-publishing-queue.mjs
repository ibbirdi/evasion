#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_PLAN = "scripts/acquisition/global-publishing-plan.json";
const DEFAULT_LOG = "scripts/acquisition/download-sprint-log.json";
const DEFAULT_OUT = "scripts/acquisition/global-publishing-queue.md";

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function addDaysISO(date, days) {
  const parsed = new Date(`${date}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return date;
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return parsed.toISOString().slice(0, 10);
}

function parseArgs(argv) {
  const args = {
    plan: DEFAULT_PLAN,
    log: DEFAULT_LOG,
    out: DEFAULT_OUT,
    start: todayISO(),
    days: 30,
    format: "markdown",
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--plan") {
      args.plan = next;
      i += 1;
    } else if (arg === "--log") {
      args.log = next;
      i += 1;
    } else if (arg === "--out") {
      args.out = next;
      i += 1;
    } else if (arg === "--start") {
      args.start = next;
      i += 1;
    } else if (arg === "--days") {
      args.days = Number(next);
      i += 1;
    } else if (arg === "--format") {
      args.format = next;
      i += 1;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!["markdown", "json"].includes(args.format)) {
    throw new Error("--format must be markdown or json");
  }

  return args;
}

function printHelp() {
  console.log(`Oasis global publishing queue

Usage:
  node scripts/acquisition/build-global-publishing-queue.mjs [options]

Options:
  --plan <path>       Global publishing plan JSON. Default: ${DEFAULT_PLAN}
  --log <path>        Sprint log JSON. Default: ${DEFAULT_LOG}
  --out <path>        Output path. Default: ${DEFAULT_OUT}
  --start <YYYY-MM-DD>
  --days <n>          Number of calendar days. Default: 30
  --format <fmt>      markdown or json. Default: markdown
`);
}

async function readJson(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function campaignLink(baseUrl, campaign, localeSlug) {
  if (!baseUrl) return "";
  const url = new URL(baseUrl);
  url.searchParams.set("ct", localizedCampaign(campaign, localeSlug));
  url.searchParams.set("mt", "8");
  return url.toString();
}

function localizedCampaign(campaign, localeSlug) {
  if (!campaign) return `oasis_global_${localeSlug}`;
  return campaign.endsWith(`_${localeSlug}`) ? campaign : `${campaign}_${localeSlug}`;
}

function inferAngle(campaign) {
  if (campaign.includes("no_subscription")) return "premium";
  if (campaign.includes("spatial")) return "spatial";
  return "sleep";
}

function readyVideoActions(log) {
  return (log.actions || [])
    .filter((action) => action.channel === "short-form")
    .filter((action) => ["ready", "posted", "running", "measured"].includes(action.status))
    .map((action) => ({
      id: action.id,
      locale: action.locale || "",
      campaign: action.campaign,
      asset: action.asset,
      angle: inferAngle(action.campaign || action.id || ""),
      link: action.link,
    }));
}

function selectChannels(plan, cadence) {
  return (plan.channels || []).filter((channel) => channel.cadence === cadence);
}

function buildQueue(plan, log, args) {
  const baseUrl = "https://apps.apple.com/app/apple-store/id6759493932";
  const languages = plan.languages || [];
  const videoAssets = readyVideoActions(log);
  const videoChannels = selectChannels(plan, "daily_video");
  const textChannels = selectChannels(plan, "daily_text");
  const communityChannels = (plan.channels || []).filter((channel) => channel.mode === "human_review");
  const days = [];
  const languageOccurrences = new Map();

  for (let offset = 0; offset < args.days; offset += 1) {
    const date = addDaysISO(args.start, offset);
    const language = languages[offset % languages.length];
    const occurrence = languageOccurrences.get(language.slug) || 0;
    languageOccurrences.set(language.slug, occurrence + 1);
    const exactLocaleVideos = videoAssets.filter((asset) => asset.locale === language.slug);
    const fallbackLocaleVideos = videoAssets.filter((asset) => asset.locale === "en");
    const candidateVideos = exactLocaleVideos.length > 0
      ? exactLocaleVideos
      : fallbackLocaleVideos.length > 0
        ? fallbackLocaleVideos
        : videoAssets;
    const video = candidateVideos[occurrence % Math.max(1, candidateVideos.length)];
    const angle = video?.angle || "sleep";
    const copy = plan.localizedCopy?.[language.id]?.[angle] || "";
    const campaign = localizedCampaign(video?.campaign || "oasis_global", language.slug);
    const link = campaignLink(baseUrl, video?.campaign || "oasis_global", language.slug);
    const slots = [];

    for (const channel of videoChannels) {
      slots.push({
        date,
        timeLocal: channel.recommendedSlotsLocal?.[0] || "manual",
        channel: channel.label,
        mode: channel.mode,
        language: language.id,
        market: language.market,
        asset: video?.asset || "No ready video asset",
        campaign,
        link,
        copy,
        review: channel.mode.includes("official") ? "setup credentials / scheduler" : "manual",
      });
    }

    for (const channel of textChannels) {
      slots.push({
        date,
        timeLocal: channel.recommendedSlotsLocal?.[0] || "manual",
        channel: channel.label,
        mode: channel.mode,
        language: language.id,
        market: language.market,
        asset: "text/link post",
        campaign: `${campaign}_${channel.id}`,
        link,
        copy: `${copy}\n\n${link}`,
        review: "safe to schedule on owned account after human copy glance",
      });
    }

    if (offset % 3 === 0) {
      for (const channel of communityChannels) {
        slots.push({
          date,
          timeLocal: "manual",
          channel: channel.label,
          mode: channel.mode,
          language: language.id,
          market: language.market,
          asset: "community-radar opportunity only",
          campaign: `community_${language.slug}_${channel.id}`,
          link: campaignLink(baseUrl, `community_${channel.id}`, language.slug),
          copy: "Use only if radar finds a high-intent thread and the community rules allow it.",
          review: "human review required",
        });
      }
    }

    days.push({ date, language, video, slots });
  }

  return {
    generatedAt: new Date().toISOString(),
    objective: plan.objective,
    targetDownloads: log.targetDownloads,
    windowDays: log.windowDays,
    days,
    slots: days.flatMap((day) => day.slots || []),
  };
}

function renderMarkdown(queue, plan) {
  const lines = [
    "# Oasis Global Publishing Queue",
    "",
    `Generated: ${queue.generatedAt}`,
    `Objective: ${queue.objective}`,
    `Target: ${queue.targetDownloads} first-time downloads over ${queue.windowDays} days`,
    "",
    "## Policy",
    "",
    `- Owned accounts: ${plan.automationPolicy.ownedAccounts}`,
    `- Communities: ${plan.automationPolicy.communities}`,
    `- Forbidden: ${plan.automationPolicy.forbidden.join(", ")}`,
    "",
    "## Sources For Official Posting",
    "",
    "| Channel | Mode | Source |",
    "| --- | --- | --- |",
  ];

  for (const channel of plan.channels || []) {
    lines.push(`| ${channel.label} | ${channel.mode} | ${channel.source || ""} |`);
  }

  lines.push("", "## Queue", "");

  for (const day of queue.days) {
    lines.push(`### ${day.date} — ${day.language.id} (${day.language.market})`, "");
    lines.push("| Time | Channel | Mode | Campaign | Asset | Copy / action |");
    lines.push("| --- | --- | --- | --- | --- | --- |");
    for (const slot of day.slots) {
      const copy = slot.copy.replace(/\n/g, "<br>").replace(/\|/g, "\\|");
      const asset = String(slot.asset || "").replace(/\|/g, "\\|");
      lines.push(`| ${slot.timeLocal} | ${slot.channel} | ${slot.mode} | ${slot.campaign} | ${asset} | ${copy} |`);
    }
    lines.push("");
  }

  return lines.join("\n");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const plan = await readJson(args.plan);
  const log = await readJson(args.log);
  const queue = buildQueue(plan, log, args);
  const output = args.format === "json" ? JSON.stringify(queue, null, 2) + "\n" : renderMarkdown(queue, plan);
  const outPath = path.resolve(REPO_ROOT, args.out);
  await fs.mkdir(path.dirname(outPath), { recursive: true });
  await fs.writeFile(outPath, output, "utf8");
  console.log(`Wrote ${outPath}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
