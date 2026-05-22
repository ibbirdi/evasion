#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { spawnSync } from "node:child_process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_QUEUE = "scripts/acquisition/global-publishing-queue.json";
const DEFAULT_LOG = "scripts/acquisition/download-sprint-log.json";
const DEFAULT_REPORT = "/tmp/oasis-download-sprint.md";
const DEFAULT_MANUAL_PACK_DIR = "scripts/acquisition/manual-packs";
const DEFAULT_APPLE_ADS_PACK_DIR = "scripts/acquisition/apple-ads-pack";
const DEFAULT_OUTREACH_PACK_DIR = "scripts/acquisition/outreach-pack";
const DEFAULT_RELEASE_READINESS_OUT = "scripts/acquisition/release-readiness.md";
const TEXT_ASSETS = new Set(["text/link post", "community-radar opportunity only", "No ready video asset"]);
const TIME_ZONE = process.env.OASIS_DISPATCH_TIMEZONE || "Europe/Paris";

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
    log: DEFAULT_LOG,
    reportOut: DEFAULT_REPORT,
    manualPackDir: DEFAULT_MANUAL_PACK_DIR,
    appleAdsPackDir: DEFAULT_APPLE_ADS_PACK_DIR,
    outreachPackDir: DEFAULT_OUTREACH_PACK_DIR,
    releaseReadinessOut: DEFAULT_RELEASE_READINESS_OUT,
    out: "",
    publish: false,
    includeOverdue: false,
    skipRegenerate: false,
    skipRadar: false,
    skipManualPack: false,
    skipAppleAdsPack: false,
    skipOutreachPack: false,
    skipReleaseReadiness: false,
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
    } else if (arg === "--log") {
      args.log = next;
      i += 1;
    } else if (arg === "--report-out") {
      args.reportOut = next;
      i += 1;
    } else if (arg === "--manual-pack-dir") {
      args.manualPackDir = next;
      i += 1;
    } else if (arg === "--apple-ads-pack-dir") {
      args.appleAdsPackDir = next;
      i += 1;
    } else if (arg === "--outreach-pack-dir") {
      args.outreachPackDir = next;
      i += 1;
    } else if (arg === "--release-readiness-out") {
      args.releaseReadinessOut = next;
      i += 1;
    } else if (arg === "--out") {
      args.out = next;
      i += 1;
    } else if (arg === "--publish") {
      args.publish = true;
    } else if (arg === "--include-overdue") {
      args.includeOverdue = true;
    } else if (arg === "--skip-regenerate") {
      args.skipRegenerate = true;
    } else if (arg === "--skip-radar") {
      args.skipRadar = true;
    } else if (arg === "--skip-manual-pack") {
      args.skipManualPack = true;
    } else if (arg === "--skip-apple-ads-pack") {
      args.skipAppleAdsPack = true;
    } else if (arg === "--skip-outreach-pack") {
      args.skipOutreachPack = true;
    } else if (arg === "--skip-release-readiness") {
      args.skipReleaseReadiness = true;
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
  console.log(`Oasis due-post dispatcher

Regenerates the global publishing queue and sprint report, then processes the due owned-channel slots for a date.

Usage:
  node scripts/acquisition/dispatch-due-posts.mjs
  node scripts/acquisition/dispatch-due-posts.mjs --date 2026-05-25 --skip-radar
  OASIS_AUTO_PUBLISH=1 node scripts/acquisition/dispatch-due-posts.mjs --publish

Options:
  --date <YYYY-MM-DD>     Dispatch date. Default: today in ${TIME_ZONE}
  --include-overdue       Include slots before --date too
  --queue <path>          Queue JSON path. Default: ${DEFAULT_QUEUE}
  --log <path>            Sprint log path. Default: ${DEFAULT_LOG}
  --report-out <path>     Sprint report output. Default: ${DEFAULT_REPORT}
  --manual-pack-dir <path> Manual upload pack folder. Default: ${DEFAULT_MANUAL_PACK_DIR}
  --apple-ads-pack-dir <path> Apple Ads pack folder. Default: ${DEFAULT_APPLE_ADS_PACK_DIR}
  --outreach-pack-dir <path> Manual outreach pack folder. Default: ${DEFAULT_OUTREACH_PACK_DIR}
  --release-readiness-out <path> Release readiness Markdown. Default: ${DEFAULT_RELEASE_READINESS_OUT}
  --out <path>            Optional JSON run summary output
  --publish               Publish eligible owned-channel slots only when OASIS_AUTO_PUBLISH=1
  --skip-regenerate       Reuse the existing queue/report
  --skip-radar            Pass --skip-radar to the sprint report
  --skip-manual-pack      Do not generate the manual upload pack
  --skip-apple-ads-pack   Do not generate the Apple Ads fallback pack
  --skip-outreach-pack    Do not generate the manual outreach pack
  --skip-release-readiness Do not run the release readiness preflight

Safety:
  Only Bluesky, Mastodon, and YouTube are eligible for automatic publishing.
  Community channels, X, TikTok, Instagram, and Facebook stay manual/review-only here.
`);
}

async function readJson(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function runNode(args, options = {}) {
  const result = spawnSync(process.execPath, args, {
    cwd: REPO_ROOT,
    encoding: "utf8",
    env: process.env,
    maxBuffer: 20 * 1024 * 1024,
  });
  const command = `node ${args.join(" ")}`;
  if (result.error) throw result.error;
  if (result.status !== 0 && !options.allowFailure) {
    const output = [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
    throw new Error(`${command} failed with ${result.status}\n${output}`);
  }
  return {
    command,
    status: result.status,
    stdout: result.stdout.trim(),
    stderr: result.stderr.trim(),
  };
}

async function regenerate(args, log) {
  const startDate = log.startDate || args.date;
  const markdownQueue = args.queue.replace(/\.json$/u, ".md");
  const steps = [];
  steps.push(runNode([
    "scripts/acquisition/build-global-publishing-queue.mjs",
    "--start",
    startDate,
    "--out",
    markdownQueue,
  ]));
  steps.push(runNode([
    "scripts/acquisition/build-global-publishing-queue.mjs",
    "--start",
    startDate,
    "--format",
    "json",
    "--out",
    args.queue,
  ]));

  const reportArgs = ["scripts/acquisition/download-sprint-report.mjs", "--out", args.reportOut];
  if (args.skipRadar) reportArgs.splice(1, 0, "--skip-radar");
  steps.push(runNode(reportArgs, { allowFailure: true }));
  return steps;
}

function allSlots(queue) {
  if (Array.isArray(queue.slots)) return queue.slots;
  return (queue.days || []).flatMap((day) => day.slots || []);
}

function normalize(value) {
  return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "_");
}

function slotIsDue(slot, args) {
  if (!slot.date) return false;
  return args.includeOverdue ? slot.date <= args.date : slot.date === args.date;
}

function isTextSlot(slot) {
  return TEXT_ASSETS.has(slot.asset);
}

function isVideoSlot(slot) {
  return slot.asset && !TEXT_ASSETS.has(slot.asset);
}

function publisherKind(slot) {
  const channel = normalize(slot.channel);
  if (isTextSlot(slot) && channel.includes("bluesky")) return "owned-text";
  if (isTextSlot(slot) && channel.includes("mastodon")) return "owned-text";
  if (isVideoSlot(slot) && channel.includes("youtube")) return "owned-video";
  if (slot.mode === "human_review") return "human-review";
  return "manual";
}

function credentialsReady(kind, slot) {
  const channel = normalize(slot.channel);
  if (kind === "owned-text" && channel.includes("bluesky")) {
    return Boolean(process.env.BSKY_HANDLE && process.env.BSKY_APP_PASSWORD);
  }
  if (kind === "owned-text" && channel.includes("mastodon")) {
    return Boolean(process.env.MASTODON_BASE_URL && process.env.MASTODON_ACCESS_TOKEN);
  }
  if (kind === "owned-video" && channel.includes("youtube")) {
    return Boolean(
      process.env.YOUTUBE_ACCESS_TOKEN ||
        (process.env.YOUTUBE_CLIENT_ID && process.env.YOUTUBE_CLIENT_SECRET && process.env.YOUTUBE_REFRESH_TOKEN),
    );
  }
  return false;
}

function publisherArgs(kind, slot, shouldPublish, queuePath) {
  if (kind === "owned-text") {
    const args = [
      "scripts/acquisition/publish-owned-post.mjs",
      "--queue",
      queuePath,
      "--campaign",
      slot.campaign,
    ];
    if (shouldPublish) args.push("--publish");
    return args;
  }
  if (kind === "owned-video") {
    const args = [
      "scripts/acquisition/publish-video-post.mjs",
      "--queue",
      queuePath,
      "--campaign",
      slot.campaign,
      "--channel",
      "youtube",
    ];
    if (shouldPublish) args.push("--publish");
    return args;
  }
  return [];
}

function summarizeSlot(slot, status, details = {}) {
  return {
    date: slot.date,
    timeLocal: slot.timeLocal,
    channel: slot.channel,
    campaign: slot.campaign,
    language: slot.language,
    asset: slot.asset,
    status,
    ...details,
  };
}

function exportManualPack(args) {
  if (args.skipManualPack) return null;
  return runNode([
    "scripts/acquisition/export-manual-pack.mjs",
    "--date",
    args.date,
    "--queue",
    args.queue,
    "--out-dir",
    args.manualPackDir,
  ]);
}

function buildAppleAdsPack(args) {
  if (args.skipAppleAdsPack) return null;
  return runNode([
    "scripts/acquisition/build-apple-ads-pack.mjs",
    "--date",
    args.date,
    "--log",
    args.log,
    "--out-dir",
    args.appleAdsPackDir,
  ]);
}

function buildOutreachPack(args) {
  if (args.skipOutreachPack) return null;
  return runNode([
    "scripts/acquisition/build-outreach-pack.mjs",
    "--date",
    args.date,
    "--out-dir",
    args.outreachPackDir,
  ]);
}

function checkReleaseReadiness(args) {
  if (args.skipReleaseReadiness) return null;
  return runNode([
    "scripts/acquisition/check-release-readiness.mjs",
    "--out",
    args.releaseReadinessOut,
    "--json-out",
    args.releaseReadinessOut.replace(/\.md$/u, ".json"),
  ]);
}

async function dispatch(args) {
  const log = await readJson(args.log);
  const regen = args.skipRegenerate ? [] : await regenerate(args, log);
  const manualPack = exportManualPack(args);
  const releaseReadiness = checkReleaseReadiness(args);
  const appleAdsPack = buildAppleAdsPack(args);
  const outreachPack = buildOutreachPack(args);
  const queue = await readJson(args.queue);
  const dueSlots = allSlots(queue).filter((slot) => slotIsDue(slot, args));
  const autoPublish = args.publish && process.env.OASIS_AUTO_PUBLISH === "1";
  const results = [];

  for (const slot of dueSlots) {
    const kind = publisherKind(slot);
    if (kind === "human-review") {
      results.push(summarizeSlot(slot, "manual_review_required", { reason: slot.review }));
      continue;
    }
    if (kind === "manual") {
      results.push(summarizeSlot(slot, "manual_or_unimplemented", { reason: slot.review || slot.mode }));
      continue;
    }

    const canPublish = autoPublish && credentialsReady(kind, slot);
    const shouldPublish = canPublish;
    const commandArgs = publisherArgs(kind, slot, shouldPublish, args.queue);
    const command = `node ${commandArgs.join(" ")}`;

    if (args.publish && !autoPublish) {
      results.push(summarizeSlot(slot, "dry_run_only", {
        reason: "OASIS_AUTO_PUBLISH must be 1 to publish",
        command,
      }));
      runNode(commandArgs);
      continue;
    }
    if (autoPublish && !credentialsReady(kind, slot)) {
      results.push(summarizeSlot(slot, "missing_credentials", { command }));
      runNode(publisherArgs(kind, slot, false, args.queue));
      continue;
    }

    const run = runNode(commandArgs, { allowFailure: shouldPublish });
    results.push(summarizeSlot(slot, shouldPublish && run.status === 0 ? "published" : shouldPublish ? "publish_failed" : "dry_run", {
      command,
      exitStatus: run.status,
      output: [run.stdout, run.stderr].filter(Boolean).join("\n").slice(0, 4000),
    }));
  }

  const summary = {
    generatedAt: new Date().toISOString(),
    date: args.date,
    includeOverdue: args.includeOverdue,
    autoPublish,
    regenerated: !args.skipRegenerate,
    reportOut: args.reportOut,
    manualPack: manualPack ? {
      command: manualPack.command,
      status: manualPack.status,
      output: manualPack.stdout,
      error: manualPack.stderr,
      path: path.resolve(REPO_ROOT, args.manualPackDir, args.date),
    } : null,
    releaseReadiness: releaseReadiness ? {
      command: releaseReadiness.command,
      status: releaseReadiness.status,
      output: releaseReadiness.stdout,
      error: releaseReadiness.stderr,
      path: path.resolve(REPO_ROOT, args.releaseReadinessOut),
    } : null,
    appleAdsPack: appleAdsPack ? {
      command: appleAdsPack.command,
      status: appleAdsPack.status,
      output: appleAdsPack.stdout,
      error: appleAdsPack.stderr,
      path: path.resolve(REPO_ROOT, args.appleAdsPackDir),
    } : null,
    outreachPack: outreachPack ? {
      command: outreachPack.command,
      status: outreachPack.status,
      output: outreachPack.stdout,
      error: outreachPack.stderr,
      path: path.resolve(REPO_ROOT, args.outreachPackDir, args.date),
    } : null,
    queue: args.queue,
    totalDueSlots: dueSlots.length,
    counts: results.reduce((counts, result) => {
      counts[result.status] = (counts[result.status] || 0) + 1;
      return counts;
    }, {}),
    regenerateSteps: regen,
    results,
  };

  if (args.out) {
    const absolute = path.resolve(REPO_ROOT, args.out);
    await fs.mkdir(path.dirname(absolute), { recursive: true });
    await fs.writeFile(absolute, `${JSON.stringify(summary, null, 2)}\n`);
  }

  return summary;
}

function printSummary(summary) {
  console.log(`Oasis dispatch ${summary.date}`);
  console.log(`Due slots: ${summary.totalDueSlots}`);
  console.log(`Auto-publish: ${summary.autoPublish ? "enabled" : "disabled"}`);
  console.log(`Report: ${summary.reportOut}`);
  if (summary.manualPack) console.log(`Manual pack: ${summary.manualPack.path}`);
  if (summary.releaseReadiness) console.log(`Release readiness: ${summary.releaseReadiness.path}`);
  if (summary.appleAdsPack) console.log(`Apple Ads pack: ${summary.appleAdsPack.path}`);
  if (summary.outreachPack) console.log(`Outreach pack: ${summary.outreachPack.path}`);
  console.log("");
  for (const [status, count] of Object.entries(summary.counts)) {
    console.log(`${status}: ${count}`);
  }
  console.log("");
  for (const result of summary.results) {
    console.log(`- ${result.status}: ${result.channel} / ${result.campaign}`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const summary = await dispatch(args);
  printSummary(summary);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
