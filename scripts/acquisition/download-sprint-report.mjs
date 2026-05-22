#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";
import { spawnSync } from "node:child_process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_METRICS_PATH = "scripts/acquisition/download-sprint-log.json";
const DEFAULT_TARGET_DOWNLOADS = 1000;
const DEFAULT_WINDOW_DAYS = 30;
const DEFAULT_RADAR_MIN_SCORE = 55;
const DEFAULT_RADAR_MAX_ITEMS = 8;
const DEFAULT_RADAR_DAYS_BACK = 21;

const priorityCampaigns = [
  "reddit_sleep_nosub",
  "reddit_ios_sleep_reco",
  "reddit_calm_alt",
  "reddit_focus_ambient",
  "reddit_travel_offline",
  "hn_maker_no_subscription",
  "shorts_sleep_cabin",
  "shorts_no_subscription",
];

function parseArgs(argv) {
  const args = {
    metrics: DEFAULT_METRICS_PATH,
    out: null,
    skipRadar: false,
    radarMinScore: DEFAULT_RADAR_MIN_SCORE,
    radarMaxItems: DEFAULT_RADAR_MAX_ITEMS,
    radarDaysBack: DEFAULT_RADAR_DAYS_BACK,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--metrics") {
      args.metrics = next;
      i += 1;
    } else if (arg === "--out") {
      args.out = next;
      i += 1;
    } else if (arg === "--skip-radar") {
      args.skipRadar = true;
    } else if (arg === "--radar-min-score") {
      args.radarMinScore = Number(next);
      i += 1;
    } else if (arg === "--radar-max-items") {
      args.radarMaxItems = Number(next);
      i += 1;
    } else if (arg === "--radar-days-back") {
      args.radarDaysBack = Number(next);
      i += 1;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function printHelp() {
  console.log(`Oasis download sprint report

Usage:
  node scripts/acquisition/download-sprint-report.mjs [options]

Options:
  --metrics <path>          Metrics JSON path. Default: ${DEFAULT_METRICS_PATH}
  --out <path>              Write Markdown report to file instead of stdout
  --skip-radar              Do not run the community radar
  --radar-min-score <n>     Community radar threshold. Default: ${DEFAULT_RADAR_MIN_SCORE}
  --radar-max-items <n>     Max radar opportunities. Default: ${DEFAULT_RADAR_MAX_ITEMS}
  --radar-days-back <n>     Radar recency window. Default: ${DEFAULT_RADAR_DAYS_BACK}
`);
}

async function readJsonIfExists(filePath) {
  const absolute = path.resolve(REPO_ROOT, filePath);
  try {
    const raw = await fs.readFile(absolute, "utf8");
    return { data: JSON.parse(raw), path: absolute, exists: true };
  } catch (error) {
    if (error.code === "ENOENT") return { data: null, path: absolute, exists: false };
    throw error;
  }
}

async function pathExists(filePath) {
  try {
    await fs.access(path.resolve(REPO_ROOT, filePath));
    return true;
  } catch {
    return false;
  }
}

function todayISO() {
  return new Date().toISOString().slice(0, 10);
}

function addDaysISO(date, days) {
  const parsed = new Date(`${date}T00:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return date;
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return parsed.toISOString().slice(0, 10);
}

function daysInclusive(startDate, endDate) {
  if (!startDate || !endDate) return 1;
  const start = new Date(`${startDate}T00:00:00Z`);
  const end = new Date(`${endDate}T00:00:00Z`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return 1;
  return Math.max(1, Math.floor((end - start) / 86_400_000) + 1);
}

function sum(items, key) {
  return items.reduce((total, item) => total + Number(item[key] || 0), 0);
}

function pct(value) {
  if (!Number.isFinite(value)) return "n/a";
  return `${(value * 100).toFixed(1)}%`;
}

function num(value, digits = 0) {
  if (!Number.isFinite(value)) return "n/a";
  return value.toLocaleString("en-US", {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  });
}

function buildCampaignLink(appConfig, campaign) {
  if (!appConfig?.appStoreBaseUrl) return "";
  const url = new URL(appConfig.appStoreBaseUrl);
  if (appConfig.campaignProviderToken) {
    url.searchParams.set("pt", appConfig.campaignProviderToken);
  }
  url.searchParams.set("ct", campaign);
  url.searchParams.set("mt", "8");
  return url.toString();
}

async function runRadar(args) {
  if (args.skipRadar) {
    return { skipped: true, opportunities: [] };
  }

  const result = spawnSync(process.execPath, [
    "scripts/community-radar/community-radar.mjs",
    "--format",
    "json",
    "--min-score",
    String(args.radarMinScore),
    "--max-items",
    String(args.radarMaxItems),
    "--days-back",
    String(args.radarDaysBack),
  ], {
    cwd: REPO_ROOT,
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 4,
  });

  if (result.status !== 0) {
    return {
      error: (result.stderr || result.stdout || "Community radar failed").trim(),
      opportunities: [],
    };
  }

  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    return { error: `Could not parse radar output: ${error.message}`, opportunities: [] };
  }
}

function summarizeMetrics(metrics) {
  const daily = Array.isArray(metrics?.daily) ? metrics.daily : [];
  const campaigns = Array.isArray(metrics?.campaigns) ? metrics.campaigns : [];
  const actions = Array.isArray(metrics?.actions) ? metrics.actions : [];
  const targetDownloads = Number(metrics?.targetDownloads || DEFAULT_TARGET_DOWNLOADS);
  const windowDays = Number(metrics?.windowDays || DEFAULT_WINDOW_DAYS);
  const startDate = metrics?.startDate || daily[0]?.date || todayISO();
  const reportDate = todayISO();
  const latestMetricDate = daily.at(-1)?.date;
  const endDate = metrics?.endDate || latestMetricDate || reportDate;
  const sprintEndDate = addDaysISO(startDate, windowDays - 1);

  const firstTimeDownloads = sum(daily, "firstTimeDownloads");
  const productPageViews = sum(daily, "productPageViews");
  const impressions = sum(daily, "impressions");
  const premiumPurchases = sum(daily, "premiumPurchases");
  const elapsedDays = daysInclusive(startDate, endDate);
  const remainingDownloads = Math.max(0, targetDownloads - firstTimeDownloads);
  const remainingDays = Math.max(0, windowDays - elapsedDays);

  const campaignTotals = new Map();
  for (const row of campaigns) {
    const key = row.campaign || "unknown";
    const current = campaignTotals.get(key) || {
      campaign: key,
      firstTimeDownloads: 0,
      productPageViews: 0,
      premiumPurchases: 0,
    };
    current.firstTimeDownloads += Number(row.firstTimeDownloads || 0);
    current.productPageViews += Number(row.productPageViews || 0);
    current.premiumPurchases += Number(row.premiumPurchases || 0);
    campaignTotals.set(key, current);
  }

  return {
    targetDownloads,
    windowDays,
    startDate,
    endDate,
    sprintEndDate,
    daily,
    campaigns: [...campaignTotals.values()].sort((a, b) => b.firstTimeDownloads - a.firstTimeDownloads),
    actions: actions
      .map((action) => ({
        ...action,
        cost: Number(action.cost || 0),
        plannedBudget: Number(action.plannedBudget || 0),
        expectedDownloads: Number(action.expectedDownloads || 0),
        actualFirstTimeDownloads: Number(action.actualFirstTimeDownloads || 0),
      }))
      .sort((a, b) => String(a.date || "").localeCompare(String(b.date || ""))),
    firstTimeDownloads,
    productPageViews,
    impressions,
    premiumPurchases,
    elapsedDays,
    remainingDownloads,
    remainingDays,
    dailyAverage: firstTimeDownloads / elapsedDays,
    requiredDailyAverage: remainingDays > 0 ? remainingDownloads / remainingDays : remainingDownloads,
    appStoreConversion: productPageViews > 0 ? firstTimeDownloads / productPageViews : null,
    impressionToPageView: impressions > 0 ? productPageViews / impressions : null,
    purchaseRate: firstTimeDownloads > 0 ? premiumPurchases / firstTimeDownloads : null,
  };
}

function summarizeActions(actions, campaigns) {
  const campaignDownloads = campaigns.map((campaign) => ({
    campaign: campaign.campaign,
    normalized: normalizeCampaign(campaign.campaign),
    locale: campaignLocale(campaign.campaign),
    firstTimeDownloads: Number(campaign.firstTimeDownloads || 0),
  }));
  const today = todayISO();
  const actionableStatuses = new Set(["ready", "planned", "candidate", "conditional"]);
  const completedStatuses = new Set(["posted", "shipped", "running", "measured"]);
  const open = actions.filter((action) => actionableStatuses.has(action.status));
  const completed = actions.filter((action) => completedStatuses.has(action.status));
  const due = open.filter((action) => !action.date || action.date <= today);
  const upcoming = open.filter((action) => action.date && action.date > today);
  const expectedOpenDownloads = open.reduce((total, action) => total + action.expectedDownloads, 0);
  const actualActionDownloads = actions.reduce((total, action) => {
    if (action.actualFirstTimeDownloads > 0) return total + action.actualFirstTimeDownloads;
    return total + campaignDownloadsForAction(action, campaignDownloads);
  }, 0);
  const totalCost = actions.reduce((total, action) => total + action.cost, 0);
  const plannedOpenBudget = open.reduce((total, action) => total + action.plannedBudget, 0);

  return {
    open,
    completed,
    due,
    upcoming,
    expectedOpenDownloads,
    actualActionDownloads,
    totalCost,
    plannedOpenBudget,
    costPerDownload: actualActionDownloads > 0 ? totalCost / actualActionDownloads : null,
  };
}

function normalizeCampaign(campaign) {
  let value = String(campaign || "");
  for (const suffix of ["_bluesky", "_mastodon", "_x"]) {
    if (value.endsWith(suffix)) value = value.slice(0, -suffix.length);
  }
  const localeSuffix = value.match(/_(fr|en|de|es|it|ptbr)$/u);
  if (localeSuffix) value = value.slice(0, -localeSuffix[0].length);
  const appleAdsLocale = value.match(/^appleads_(fr|en|de|es|it|ptbr)_(.+)$/u);
  if (appleAdsLocale) value = `appleads_${appleAdsLocale[2]}`;
  return value;
}

function campaignLocale(campaign) {
  let value = String(campaign || "");
  for (const suffix of ["_bluesky", "_mastodon", "_x"]) {
    if (value.endsWith(suffix)) value = value.slice(0, -suffix.length);
  }
  const suffix = value.match(/_(fr|en|de|es|it|ptbr)$/u);
  if (suffix) return suffix[1];
  const appleAdsLocale = value.match(/^appleads_(fr|en|de|es|it|ptbr)_/u);
  return appleAdsLocale?.[1] || "";
}

function campaignDownloadsForAction(action, campaignDownloads) {
  const actionCampaign = String(action.campaign || "");
  const campaignPrefixes = Array.isArray(action.campaignPrefixes)
    ? action.campaignPrefixes.map((prefix) => String(prefix || "")).filter(Boolean)
    : [];
  if (campaignPrefixes.length > 0) {
    return campaignDownloads.reduce((total, campaign) => (
      campaignPrefixes.some((prefix) => campaign.campaign.startsWith(prefix))
        ? total + campaign.firstTimeDownloads
        : total
    ), 0);
  }

  const normalizedAction = normalizeCampaign(actionCampaign);
  const actionLocale = action.locale || campaignLocale(actionCampaign);
  return campaignDownloads.reduce((total, campaign) => {
    if (campaign.campaign === actionCampaign) {
      return total + campaign.firstTimeDownloads;
    }
    if (campaign.normalized === normalizedAction && (!actionLocale || campaign.locale === actionLocale)) {
      return total + campaign.firstTimeDownloads;
    }
    return total;
  }, 0);
}

function renderMetricsSection(summary, metricsResult) {
  const lines = [
    "## Download Target",
    "",
    `- Metrics file: ${metricsResult.exists ? metricsResult.path : `${metricsResult.path} (missing)`}`,
    `- Sprint window: ${summary.startDate} to ${summary.sprintEndDate} (${summary.elapsedDays}/${summary.windowDays} days elapsed)`,
    `- First-time downloads: ${num(summary.firstTimeDownloads)} / ${num(summary.targetDownloads)} (${pct(summary.firstTimeDownloads / summary.targetDownloads)})`,
    `- Remaining: ${num(summary.remainingDownloads)}`,
    `- Current pace: ${num(summary.dailyAverage, 1)} downloads/day`,
    `- Required pace: ${num(summary.requiredDailyAverage, 1)} downloads/day`,
    `- App Store page conversion: ${summary.appStoreConversion == null ? "add product page views" : pct(summary.appStoreConversion)}`,
    `- Impression to page view: ${summary.impressionToPageView == null ? "add impressions" : pct(summary.impressionToPageView)}`,
    `- Premium purchase rate: ${summary.purchaseRate == null ? "add premium purchases" : pct(summary.purchaseRate)}`,
    "",
  ];

  if (!metricsResult.exists || summary.daily.length === 0) {
    lines.push(
      "No daily metrics logged yet. Add App Store Connect values to the metrics file after the next Sales and Trends / Analytics refresh.",
      "",
    );
  }

  if (summary.campaigns.length > 0) {
    lines.push("### Campaign Totals", "");
    lines.push("| Campaign | Downloads | Page views | Premium purchases |");
    lines.push("| --- | ---: | ---: | ---: |");
    for (const campaign of summary.campaigns.slice(0, 8)) {
      lines.push(`| ${campaign.campaign} | ${campaign.firstTimeDownloads} | ${campaign.productPageViews} | ${campaign.premiumPurchases} |`);
    }
    lines.push("");
  }

  return lines;
}

function renderActionPipeline(summary) {
  const actionSummary = summarizeActions(summary.actions, summary.campaigns);
  const lines = [
    "## Action Pipeline",
    "",
    `- Open actions: ${actionSummary.open.length}`,
    `- Due today or overdue: ${actionSummary.due.length}`,
    `- Expected downloads still in open actions: ${num(actionSummary.expectedOpenDownloads)}`,
    `- Downloads attributed in action log/campaigns: ${num(actionSummary.actualActionDownloads)}`,
    `- Tracked spend: ${num(actionSummary.totalCost, 2)}`,
    `- Planned open budget: ${num(actionSummary.plannedOpenBudget, 2)}`,
    `- Cost per attributed download: ${actionSummary.costPerDownload == null ? "n/a" : num(actionSummary.costPerDownload, 2)}`,
    "",
  ];

  if (summary.actions.length === 0) {
    lines.push("No actions logged yet. Add `actions` entries to the sprint metrics file.", "");
    return lines;
  }

  if (actionSummary.due.length > 0) {
    lines.push("### Due Now", "");
    lines.push("| Date | Status | Channel | Campaign | Action | Expected | Link |");
    lines.push("| --- | --- | --- | --- | --- | ---: | --- |");
    for (const action of actionSummary.due.slice(0, 8)) {
      const asset = String(action.asset || action.id || "").replace(/\|/g, "\\|");
      const link = action.link ? `[link](${action.link})` : "";
      lines.push(`| ${action.date || ""} | ${action.status} | ${action.channel || ""} | ${action.campaign || ""} | ${asset} | ${action.expectedDownloads} | ${link} |`);
    }
    lines.push("");
  }

  if (actionSummary.upcoming.length > 0) {
    lines.push("### Next Planned", "");
    lines.push("| Date | Status | Channel | Campaign | Action | Expected |");
    lines.push("| --- | --- | --- | --- | --- | ---: |");
    for (const action of actionSummary.upcoming.slice(0, 6)) {
      const asset = String(action.asset || action.id || "").replace(/\|/g, "\\|");
      lines.push(`| ${action.date || ""} | ${action.status} | ${action.channel || ""} | ${action.campaign || ""} | ${asset} | ${action.expectedDownloads} |`);
    }
    lines.push("");
  }

  return lines;
}

function renderRadarSection(radar) {
  const lines = ["## Acquisition Radar", ""];

  if (radar.skipped) {
    lines.push("Community radar skipped for this run.", "");
    return lines;
  }

  if (radar.error) {
    lines.push(`Community radar error: ${radar.error}`, "");
    return lines;
  }

  const opportunities = Array.isArray(radar.opportunities) ? radar.opportunities : [];
  if (opportunities.length === 0) {
    lines.push("No community opportunities crossed the threshold today.", "");
    lines.push("Action: post one owned-channel short/video instead of forcing a low-fit community reply.", "");
    return lines;
  }

  lines.push("| Score | Source | Segment | Campaign | Thread |");
  lines.push("| ---: | --- | --- | --- | --- |");
  for (const item of opportunities.slice(0, 8)) {
    const source = item.community ? `${item.sourceName} / ${item.community}` : item.sourceName;
    const title = String(item.title || "Untitled").replace(/\|/g, "\\|");
    lines.push(`| ${item.score} | ${source} | ${item.segment} | ${item.campaign} | [${title}](${item.url || item.discussionUrl || "#"}) |`);
  }
  lines.push("");
  lines.push("Manual rule: reply to at most 5 genuinely useful threads today, and use at most 1 tracked App Store link.", "");

  return lines;
}

function uniqueCampaignsFrom(summary) {
  const campaigns = new Set(priorityCampaigns);
  for (const action of summary.actions || []) {
    if (action.campaign && !action.campaign.startsWith("audience_unlock")) {
      campaigns.add(action.campaign);
    }
    for (const childCampaign of action.childCampaigns || []) {
      if (childCampaign) campaigns.add(childCampaign);
    }
  }
  for (const campaign of summary.campaigns || []) {
    if (campaign.campaign) campaigns.add(campaign.campaign);
  }
  return [...campaigns].sort();
}

function renderCampaignLinks(configResult, summary) {
  const appConfig = configResult.data?.app;
  const hasProviderToken = Boolean(appConfig?.campaignProviderToken);
  const lines = [
    "## Campaign Links",
    "",
    hasProviderToken
      ? "Provider token is configured in `scripts/community-radar/config.json`."
      : "Provider token is not configured yet. Create campaign links in App Store Connect, then add the provider token to `scripts/community-radar/config.json` for full attribution.",
    "",
    "| Campaign | Link |",
    "| --- | --- |",
  ];

  for (const campaign of uniqueCampaignsFrom(summary)) {
    lines.push(`| ${campaign} | ${buildCampaignLink(appConfig, campaign)} |`);
  }

  lines.push("");
  return lines;
}

function renderTodayPlan(summary, radar) {
  const hasRadarHits = Array.isArray(radar.opportunities) && radar.opportunities.length > 0;
  const actionSummary = summarizeActions(summary.actions, summary.campaigns);
  const dueActions = actionSummary.due
    .slice(0, 4)
    .map((action) => `${action.id} (${action.status}, ${action.channel})`);
  const lines = [
    "## Today",
    "",
    "1. Log yesterday's App Store Connect metrics in the sprint metrics file.",
    dueActions.length > 0
      ? `2. Work through due actions: ${dueActions.join("; ")}.`
      : hasRadarHits
        ? "2. Manually review the top radar hits and answer only where the reply is clearly useful."
        : "2. Use owned channels today: post one short built from `sleep-cabin`, `no-subscription-pitch`, or `spatial-magic`.",
    "3. Use exactly one campaign token per post/reply so downloads can be attributed.",
    "4. Update the action status to `posted`, `shipped`, or `running` once it is live.",
    "5. If daily downloads are below the required pace after day 3, activate the multilingual Apple Ads exact-match ramp with hard per-market daily caps.",
    "",
    `Required pace from here: ${num(summary.requiredDailyAverage, 1)} downloads/day.`,
    "",
  ];

  return lines;
}

async function renderExecutionPacks() {
  const lines = ["## Execution Packs", ""];
  const manualPackPath = "scripts/acquisition/manual-packs";
  const appleAdsPackPath = "scripts/acquisition/apple-ads-pack/README.md";
  const releaseReadinessPath = "scripts/acquisition/release-readiness.md";
  lines.push(`- Daily dispatcher: \`node scripts/acquisition/dispatch-due-posts.mjs --out /tmp/oasis-dispatch.json\``);
  lines.push(await pathExists(releaseReadinessPath)
    ? `- Release readiness: [${releaseReadinessPath}](../../../${releaseReadinessPath})`
    : "- Release readiness: generate with `check-release-readiness.mjs` before retrying the App Store upload.");
  lines.push(await pathExists(manualPackPath)
    ? `- Manual upload packs: [${manualPackPath}](../../../${manualPackPath})`
    : "- Manual upload packs: generated by the dispatcher or `export-manual-pack.mjs`.");
  lines.push(await pathExists(appleAdsPackPath)
    ? `- Apple Ads fallback: [${appleAdsPackPath}](../../../${appleAdsPackPath})`
    : "- Apple Ads fallback: generate with `build-apple-ads-pack.mjs` if pace is below target after day 3.");
  const outreachPackPath = `scripts/acquisition/outreach-pack/${todayISO()}/README.md`;
  lines.push(await pathExists(outreachPackPath)
    ? `- Manual outreach pack: [${outreachPackPath}](../../../${outreachPackPath})`
    : "- Manual outreach pack: generated by the dispatcher or `build-outreach-pack.mjs`.");
  lines.push("");
  return lines;
}

async function renderReport(args) {
  const metricsResult = await readJsonIfExists(args.metrics);
  const configResult = await readJsonIfExists("scripts/community-radar/config.json");
  const metrics = metricsResult.data || {};
  const summary = summarizeMetrics(metrics);
  const radar = await runRadar(args);

  const lines = [
    `# Oasis ${num(summary.targetDownloads)}-Download Global Sprint`,
    "",
    `Generated: ${new Date().toISOString()}`,
    "",
    ...renderMetricsSection(summary, metricsResult),
    ...renderActionPipeline(summary),
    ...renderTodayPlan(summary, radar),
    ...(await renderExecutionPacks()),
    ...renderRadarSection(radar),
    ...renderCampaignLinks(configResult, summary),
  ];

  return lines.join("\n");
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const report = await renderReport(args);

  if (args.out) {
    const absolute = path.resolve(REPO_ROOT, args.out);
    await fs.mkdir(path.dirname(absolute), { recursive: true });
    await fs.writeFile(absolute, `${report}\n`, "utf8");
    console.log(`Wrote ${absolute}`);
  } else {
    process.stdout.write(`${report}\n`);
  }
}

main().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
