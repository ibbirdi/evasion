#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_LOG = "scripts/acquisition/download-sprint-log.json";
const DEFAULT_OUT_DIR = "scripts/acquisition/apple-ads-pack";
const DEFAULT_DAILY_BUDGET = 10;
const DEFAULT_BID_CAP = 0.8;
const DEFAULT_CPA_GOAL = 1.5;
const DEFAULT_TARGET_DOWNLOADS = 600;
const APP_STORE_BASE_URL = "https://apps.apple.com/app/apple-store/id6759493932";

const MARKETS = [
  {
    locale: "en-US",
    slug: "en",
    name: "English core",
    weight: 0.42,
    countriesOrRegions: ["US", "GB", "CA", "AU", "NZ"],
    adGroups: [
      ["Sleep exact", ["sleep sounds", "rain sounds", "white noise", "brown noise", "sleep sound app"]],
      ["No subscription exact", ["sleep app no subscription", "white noise no subscription", "rain sounds no subscription"]],
      ["Focus exact", ["focus sounds", "background noise focus", "rain sounds study"]],
    ],
  },
  {
    locale: "fr-FR",
    slug: "fr",
    name: "Francophone",
    weight: 0.12,
    countriesOrRegions: ["FR", "BE", "CH", "CA"],
    adGroups: [
      ["Sommeil exact", ["sons pour dormir", "bruit blanc", "pluie pour dormir", "sons de pluie"]],
      ["Sans abonnement exact", ["app sommeil sans abonnement", "bruit blanc sans abonnement"]],
      ["Concentration exact", ["sons pour se concentrer", "bruit de fond concentration"]],
    ],
  },
  {
    locale: "de-DE",
    slug: "de",
    name: "DACH",
    weight: 0.13,
    countriesOrRegions: ["DE", "AT", "CH"],
    adGroups: [
      ["Schlaf exact", ["schlafgerausche", "regengeräusche", "weisses rauschen", "naturgeräusche"]],
      ["Ohne Abo exact", ["schlaf app ohne abo", "weisses rauschen ohne abo"]],
      ["Fokus exact", ["geräusche zum konzentrieren", "hintergrundgeräusche fokus"]],
    ],
  },
  {
    locale: "es-ES",
    slug: "es",
    name: "Spanish",
    weight: 0.15,
    countriesOrRegions: ["ES", "MX", "CO", "AR", "CL"],
    adGroups: [
      ["Dormir exact", ["sonidos para dormir", "sonidos de lluvia", "ruido blanco", "sonidos de naturaleza"]],
      ["Sin suscripcion exact", ["app dormir sin suscripcion", "ruido blanco sin suscripcion"]],
      ["Concentracion exact", ["sonidos para concentrarse", "ruido de fondo estudiar"]],
    ],
  },
  {
    locale: "it",
    slug: "it",
    name: "Italy",
    weight: 0.08,
    countriesOrRegions: ["IT"],
    adGroups: [
      ["Sonno exact", ["suoni per dormire", "suoni pioggia", "rumore bianco", "suoni natura"]],
      ["Senza abbonamento exact", ["app sonno senza abbonamento", "rumore bianco senza abbonamento"]],
      ["Focus exact", ["suoni per concentrarsi", "rumore di fondo studio"]],
    ],
  },
  {
    locale: "pt-BR",
    slug: "ptbr",
    name: "Brazil",
    weight: 0.10,
    countriesOrRegions: ["BR"],
    adGroups: [
      ["Sono exact", ["sons para dormir", "sons de chuva", "ruido branco", "sons da natureza"]],
      ["Sem assinatura exact", ["app sono sem assinatura", "ruido branco sem assinatura"]],
      ["Foco exact", ["sons para concentrar", "ruido de fundo estudar"]],
    ],
  },
];

const NEGATIVE_KEYWORDS = [
  "youtube",
  "spotify",
  "mp3",
  "download music",
  "alarm clock",
  "baby monitor",
  "medical treatment",
  "tinnitus cure",
];

function parseArgs(argv) {
  const args = {
    log: DEFAULT_LOG,
    outDir: DEFAULT_OUT_DIR,
    date: new Date().toISOString().slice(0, 10),
    force: false,
    dailyBudget: DEFAULT_DAILY_BUDGET,
    bidCap: DEFAULT_BID_CAP,
    cpaGoal: DEFAULT_CPA_GOAL,
    targetDownloads: DEFAULT_TARGET_DOWNLOADS,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--log") {
      args.log = next;
      i += 1;
    } else if (arg === "--out-dir") {
      args.outDir = next;
      i += 1;
    } else if (arg === "--date") {
      args.date = next;
      i += 1;
    } else if (arg === "--daily-budget") {
      args.dailyBudget = Number(next);
      i += 1;
    } else if (arg === "--bid-cap") {
      args.bidCap = Number(next);
      i += 1;
    } else if (arg === "--cpa-goal") {
      args.cpaGoal = Number(next);
      i += 1;
    } else if (arg === "--target-downloads") {
      args.targetDownloads = Number(next);
      i += 1;
    } else if (arg === "--force") {
      args.force = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(args.date)) throw new Error("--date must be YYYY-MM-DD");
  return args;
}

function printHelp() {
  console.log(`Oasis Apple Ads launch pack

Usage:
  node scripts/acquisition/build-apple-ads-pack.mjs
  node scripts/acquisition/build-apple-ads-pack.mjs --force --daily-budget 10

Options:
  --log <path>             Sprint log path. Default: ${DEFAULT_LOG}
  --out-dir <path>         Output folder. Default: ${DEFAULT_OUT_DIR}
  --date <YYYY-MM-DD>      Pack date. Default: today UTC
  --daily-budget <amount>  Per-market daily cap in account currency. Default: ${DEFAULT_DAILY_BUDGET}
  --bid-cap <amount>       Initial manual CPT bid cap. Default: ${DEFAULT_BID_CAP}
  --cpa-goal <amount>      Initial CPA guardrail. Default: ${DEFAULT_CPA_GOAL}
  --target-downloads <n>   Downloads this paid ramp should cover. Default: ${DEFAULT_TARGET_DOWNLOADS}
  --force                  Mark the pack as activate_now regardless of sprint pace
`);
}

async function readJson(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function addDaysISO(date, days) {
  const parsed = new Date(`${date}T00:00:00Z`);
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return parsed.toISOString().slice(0, 10);
}

function daysInclusive(startDate, endDate) {
  const start = new Date(`${startDate}T00:00:00Z`);
  const end = new Date(`${endDate}T00:00:00Z`);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return 1;
  return Math.max(1, Math.floor((end - start) / 86_400_000) + 1);
}

function sum(items, key) {
  return items.reduce((total, item) => total + Number(item[key] || 0), 0);
}

function campaignLink(campaign) {
  const url = new URL(APP_STORE_BASE_URL);
  url.searchParams.set("ct", campaign);
  url.searchParams.set("mt", "8");
  return url.toString();
}

function activation(log, args) {
  const targetDownloads = Number(log.targetDownloads || 1000);
  const windowDays = Number(log.windowDays || 30);
  const startDate = log.startDate || args.date;
  const endDate = args.date;
  const daily = Array.isArray(log.daily) ? log.daily : [];
  const firstTimeDownloads = sum(daily, "firstTimeDownloads");
  const elapsedDays = daysInclusive(startDate, endDate);
  const remainingDays = Math.max(1, windowDays - elapsedDays);
  const remainingDownloads = Math.max(0, targetDownloads - firstTimeDownloads);
  const currentPace = firstTimeDownloads / elapsedDays;
  const requiredPace = remainingDownloads / remainingDays;
  const shouldActivate = args.force || (elapsedDays >= 4 && currentPace < requiredPace);
  return {
    status: shouldActivate ? "activate_now" : "prepare_only",
    reason: args.force
      ? "Forced by --force."
      : elapsedDays < 4
        ? "Prepare now; activate only if organic/social pace is below target after day 3."
        : currentPace < requiredPace
          ? "Current download pace is below required pace."
          : "Current download pace is at or above required pace.",
    targetDownloads,
    windowDays,
    startDate,
    sprintEndDate: addDaysISO(startDate, windowDays - 1),
    elapsedDays,
    firstTimeDownloads,
    currentPace,
    requiredPace,
  };
}

function buildRows(args) {
  const rows = [];
  for (const market of MARKETS) {
    for (const [adGroupName, keywords] of market.adGroups) {
      const campaign = `appleads_${market.slug}_${adGroupName.toLowerCase().replace(/[^a-z0-9]+/g, "_")}`;
      for (const keyword of keywords) {
        rows.push({
          market: market.name,
          locale: market.locale,
          countriesOrRegions: market.countriesOrRegions.join("|"),
          campaignName: `Oasis ${market.name} Search Results`,
          adGroupName,
          keyword,
          matchType: "EXACT",
          searchMatch: "OFF",
          campaignToken: campaign,
          appStoreLink: campaignLink(campaign),
          dailyBudgetCap: args.dailyBudget,
          initialBidCapCpt: args.bidCap,
          cpaGoal: args.cpaGoal,
        });
      }
    }
  }
  return rows;
}

function buildBudgetRows(args) {
  return MARKETS.map((market) => {
    const expectedDownloadsAtTarget = Math.round(args.targetDownloads * market.weight);
    return {
      market: market.name,
      locale: market.locale,
      countriesOrRegions: market.countriesOrRegions.join("|"),
      campaignName: `Oasis ${market.name} Search Results`,
      weight: market.weight,
      dailyBudgetCap: args.dailyBudget,
      cpaGoal: args.cpaGoal,
      expectedDownloadsAtTarget,
      estimatedSpendAtCpaGoal: Number((expectedDownloadsAtTarget * args.cpaGoal).toFixed(2)),
    };
  });
}

function buildBudgetPlan(args, activation) {
  const totalDailyBudgetCap = MARKETS.length * args.dailyBudget;
  const estimatedDailyDownloadsAtCap = totalDailyBudgetCap / args.cpaGoal;
  const activeDaysNeeded = Math.ceil(args.targetDownloads / estimatedDailyDownloadsAtCap);
  return {
    targetDownloads: args.targetDownloads,
    totalDailyBudgetCap,
    cpaGoal: args.cpaGoal,
    estimatedDailyDownloadsAtCap,
    activeDaysNeeded,
    estimatedSpendAtCpaGoal: Number((args.targetDownloads * args.cpaGoal).toFixed(2)),
    sprintRemainingDownloads: Math.max(0, activation.targetDownloads - activation.firstTimeDownloads),
    marketRows: buildBudgetRows(args),
  };
}

function csvEscape(value) {
  const text = String(value ?? "");
  return /[",\n]/u.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function renderCsv(rows) {
  const columns = Object.keys(rows[0] || {});
  return [
    columns.join(","),
    ...rows.map((row) => columns.map((column) => csvEscape(row[column])).join(",")),
  ].join("\n") + "\n";
}

function renderMarkdown(pack) {
  const lines = [
    "# Oasis Apple Ads Launch Pack",
    "",
    `Generated: ${pack.generatedAt}`,
    `Activation: ${pack.activation.status}`,
    `Reason: ${pack.activation.reason}`,
    "",
    "Use this as a setup sheet for Apple Ads Search Results campaigns. Keep hard daily caps until App Store Connect confirms campaign-level first-time downloads.",
    "",
    "## Pace",
    "",
    `- Sprint: ${pack.activation.startDate} to ${pack.activation.sprintEndDate}`,
    `- Downloads logged: ${pack.activation.firstTimeDownloads} / ${pack.activation.targetDownloads}`,
    `- Elapsed days: ${pack.activation.elapsedDays} / ${pack.activation.windowDays}`,
    `- Current pace: ${pack.activation.currentPace.toFixed(1)} downloads/day`,
    `- Required pace: ${pack.activation.requiredPace.toFixed(1)} downloads/day`,
    "",
    "## Ramp Model",
    "",
    `- Paid ramp target: ${pack.budgetPlan.targetDownloads} first-time downloads`,
    `- Total daily cap: ${pack.budgetPlan.totalDailyBudgetCap}`,
    `- CPA guardrail: ${pack.budgetPlan.cpaGoal}`,
    `- Estimated daily downloads at cap: ${pack.budgetPlan.estimatedDailyDownloadsAtCap.toFixed(1)}`,
    `- Active days needed at cap: ${pack.budgetPlan.activeDaysNeeded}`,
    `- Estimated spend at CPA guardrail: ${pack.budgetPlan.estimatedSpendAtCpaGoal}`,
    "",
    "## Setup Rules",
    "",
    "- Placement: App Store Search Results.",
    "- Start with exact match ad groups and Search Match off for clean attribution.",
    "- Use one campaign token per market/ad group.",
    "- Pause keywords with taps but no downloads after a meaningful sample.",
    "- Move winners into broader tests only after campaign-level downloads appear.",
    "- Do not make medical claims in ad text or custom assets.",
    "",
    "## Market Budgets",
    "",
    "| Market | Countries/regions | Daily cap | Bid cap | CPA guardrail |",
    "| --- | --- | ---: | ---: | ---: |",
  ];

  for (const market of MARKETS) {
    lines.push(`| ${market.name} | ${market.countriesOrRegions.join(", ")} | ${pack.args.dailyBudget} | ${pack.args.bidCap} | ${pack.args.cpaGoal} |`);
  }

  lines.push("", "## Exact Keyword Rows", "");
  lines.push("See `keywords.csv` for the import/setup sheet.");
  lines.push("", "## Negative Keywords", "");
  lines.push(NEGATIVE_KEYWORDS.map((keyword) => `- ${keyword}`).join("\n"));
  return `${lines.join("\n").trim()}\n`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const log = await readJson(args.log);
  const outputDir = path.resolve(REPO_ROOT, args.outDir);
  await fs.mkdir(outputDir, { recursive: true });
  const rows = buildRows(args);
  const activationState = activation(log, args);
  const pack = {
    generatedAt: new Date().toISOString(),
    args,
    activation: activationState,
    budgetPlan: buildBudgetPlan(args, activationState),
    negativeKeywords: NEGATIVE_KEYWORDS,
    rows,
  };

  await fs.writeFile(path.join(outputDir, "apple-ads-pack.json"), `${JSON.stringify(pack, null, 2)}\n`);
  await fs.writeFile(path.join(outputDir, "keywords.csv"), renderCsv(rows));
  await fs.writeFile(path.join(outputDir, "budget-plan.csv"), renderCsv(pack.budgetPlan.marketRows));
  await fs.writeFile(path.join(outputDir, "README.md"), renderMarkdown(pack));
  console.log(`Wrote ${outputDir}`);
  console.log(`Activation: ${pack.activation.status}`);
  console.log(`Rows: ${rows.length}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
