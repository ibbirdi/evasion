#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_QUEUE = "scripts/acquisition/global-publishing-queue.json";
const DEFAULT_OUT_DIR = "scripts/acquisition/manual-packs";
const TEXT_ASSETS = new Set(["text/link post", "community-radar opportunity only", "No ready video asset"]);
const MANUAL_CHANNELS = new Set([
  "TikTok",
  "Instagram Reels",
  "Facebook Reels",
  "X",
  "Reddit",
  "Hacker News",
  "Product Hunt",
]);
const TIME_ZONE = process.env.OASIS_DISPATCH_TIMEZONE || "Europe/Paris";

const PLATFORM_NOTES = {
  "TikTok": "Upload with the official TikTok app, web uploader, or audited Content Posting API. Do not use browser automation.",
  "Instagram Reels": "Upload through Instagram professional tools or Meta Business Suite. Use the localized caption and campaign link.",
  "Facebook Reels": "Upload through Meta tools. Cross-post only when the audience is distinct enough.",
  "X": "Use the native scheduler or official API access. Keep one tracked link.",
  "Reddit": "Use only if the community radar finds a high-intent thread and rules allow a relevant reply. Disclose the developer relationship.",
  "Hacker News": "Use only for a genuinely interesting founder/story angle. Do not force a promotional post.",
  "Product Hunt": "Use only during the coordinated launch window.",
};

function localDateISO(date = new Date(), timeZone = TIME_ZONE) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);
  const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
  return `${values.year}-${values.month}-${values.day}`;
}

function parseArgs(argv) {
  const args = {
    date: localDateISO(),
    queue: DEFAULT_QUEUE,
    outDir: DEFAULT_OUT_DIR,
    includeOwnedDryRuns: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--date") {
      args.date = next;
      i += 1;
    } else if (arg === "--queue") {
      args.queue = next;
      i += 1;
    } else if (arg === "--out-dir") {
      args.outDir = next;
      i += 1;
    } else if (arg === "--include-owned-dry-runs") {
      args.includeOwnedDryRuns = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(args.date)) {
    throw new Error("--date must be YYYY-MM-DD");
  }

  return args;
}

function printHelp() {
  console.log(`Oasis manual upload pack exporter

Usage:
  node scripts/acquisition/export-manual-pack.mjs --date 2026-05-25

Options:
  --date <YYYY-MM-DD>          Pack date. Default: today in ${TIME_ZONE}
  --queue <path>               Queue JSON path. Default: ${DEFAULT_QUEUE}
  --out-dir <path>             Output folder. Default: ${DEFAULT_OUT_DIR}
  --include-owned-dry-runs     Also include YouTube/Bluesky/Mastodon slots for reference
`);
}

async function readJson(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function allSlots(queue) {
  if (Array.isArray(queue.slots)) return queue.slots;
  return (queue.days || []).flatMap((day) => day.slots || []);
}

function isManualSlot(slot, includeOwnedDryRuns) {
  if (MANUAL_CHANNELS.has(slot.channel)) return true;
  if (!includeOwnedDryRuns) return false;
  return ["YouTube Shorts", "Bluesky", "Mastodon"].includes(slot.channel);
}

function isVideoSlot(slot) {
  return slot.asset && !TEXT_ASSETS.has(slot.asset);
}

function fileSafe(value) {
  return String(value || "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function caption(slot) {
  return String(slot.copy || "")
    .replace(/<br\s*\/?>/gi, "\n")
    .trim();
}

async function copyAsset(slot, outputDir) {
  if (!isVideoSlot(slot)) return "";
  const source = path.resolve(REPO_ROOT, slot.asset);
  const extension = path.extname(slot.asset) || ".mp4";
  const targetName = `${slot.timeLocal === "manual" ? "manual" : slot.timeLocal.replace(/:/g, "")}-${fileSafe(slot.channel)}-${slot.campaign}${extension}`;
  const target = path.join(outputDir, targetName);
  await fs.copyFile(source, target);
  return targetName;
}

function renderMarkdown(pack) {
  const lines = [
    `# Oasis Manual Publishing Pack — ${pack.date}`,
    "",
    `Generated: ${pack.generatedAt}`,
    `Language: ${pack.language || "mixed"}`,
    "",
    "Use one tracked link per post. Do not post in communities unless the fit is real and the rules allow it.",
    "",
  ];

  for (const slot of pack.slots) {
    lines.push(`## ${slot.timeLocal} — ${slot.channel}`);
    lines.push("");
    lines.push(`- Campaign: \`${slot.campaign}\``);
    lines.push(`- Language: \`${slot.language}\``);
    lines.push(`- Link: ${slot.link}`);
    lines.push(`- Asset: ${slot.exportedAsset ? `\`${slot.exportedAsset}\`` : slot.asset}`);
    lines.push(`- Note: ${PLATFORM_NOTES[slot.channel] || slot.review || "Manual review required."}`);
    lines.push("");
    lines.push("Caption:");
    lines.push("");
    lines.push("```text");
    lines.push(caption(slot));
    if (slot.channel !== "Reddit" && slot.channel !== "Hacker News" && slot.channel !== "Product Hunt" && !caption(slot).includes(slot.link)) {
      lines.push("");
      lines.push(slot.link);
    }
    lines.push("```");
    lines.push("");
  }

  return `${lines.join("\n").trim()}\n`;
}

async function exportPack(args) {
  const queue = await readJson(args.queue);
  const due = allSlots(queue)
    .filter((slot) => slot.date === args.date)
    .filter((slot) => isManualSlot(slot, args.includeOwnedDryRuns));
  const outputDir = path.resolve(REPO_ROOT, args.outDir, args.date);
  await fs.mkdir(outputDir, { recursive: true });

  const slots = [];
  for (const slot of due) {
    const exportedAsset = await copyAsset(slot, outputDir);
    slots.push({ ...slot, exportedAsset });
  }

  const pack = {
    generatedAt: new Date().toISOString(),
    date: args.date,
    language: slots[0]?.language || "",
    outputDir,
    slots,
  };

  await fs.writeFile(path.join(outputDir, "pack.json"), `${JSON.stringify(pack, null, 2)}\n`);
  await fs.writeFile(path.join(outputDir, "README.md"), renderMarkdown(pack));
  return pack;
}

function printSummary(pack) {
  console.log(`Wrote manual pack: ${pack.outputDir}`);
  console.log(`Slots: ${pack.slots.length}`);
  for (const slot of pack.slots) {
    console.log(`- ${slot.channel}: ${slot.campaign}${slot.exportedAsset ? ` (${slot.exportedAsset})` : ""}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const pack = await exportPack(args);
  printSummary(pack);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
