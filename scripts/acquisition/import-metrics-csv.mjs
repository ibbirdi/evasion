#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_LOG = "scripts/acquisition/download-sprint-log.json";

const FIELD_ALIASES = {
  date: ["date", "day", "report date", "start date", "Date"],
  campaign: ["campaign", "campaign name", "campaign id", "ct", "Campaign"],
  firstTimeDownloads: [
    "first time downloads",
    "first-time downloads",
    "firsttimedownloads",
    "downloads",
    "units",
    "app units",
    "redownloads excluded",
  ],
  productPageViews: ["product page views", "page views", "app store product page views", "productpageviews"],
  impressions: ["impressions", "app store impressions", "ad impressions"],
  premiumPurchases: ["premium purchases", "purchases", "in-app purchases", "iap", "sales"],
  spend: ["spend", "amount spent", "cost", "total spend"],
  taps: ["taps", "clicks"],
};

function parseArgs(argv) {
  const args = {
    log: DEFAULT_LOG,
    file: "",
    type: "auto",
    dryRun: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--log") {
      args.log = next;
      i += 1;
    } else if (arg === "--file") {
      args.file = next;
      i += 1;
    } else if (arg === "--type") {
      args.type = next;
      i += 1;
    } else if (arg === "--dry-run") {
      args.dryRun = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!args.file) throw new Error("Provide --file <csv>.");
  if (!["auto", "daily", "campaign"].includes(args.type)) {
    throw new Error("--type must be auto, daily, or campaign");
  }
  return args;
}

function printHelp() {
  console.log(`Oasis metrics CSV importer

Usage:
  node scripts/acquisition/import-metrics-csv.mjs --file exports/daily.csv
  node scripts/acquisition/import-metrics-csv.mjs --file exports/campaigns.csv --type campaign
  node scripts/acquisition/import-metrics-csv.mjs --file exports/daily.csv --dry-run

Recognized daily fields:
  date, firstTimeDownloads, productPageViews, impressions, premiumPurchases

Recognized campaign fields:
  date, campaign, firstTimeDownloads, productPageViews, premiumPurchases, spend, taps
`);
}

async function readJson(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return { absolute, json: JSON.parse(raw) };
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];
    if (inQuotes) {
      if (char === '"' && next === '"') {
        value += '"';
        i += 1;
      } else if (char === '"') {
        inQuotes = false;
      } else {
        value += char;
      }
    } else if (char === '"') {
      inQuotes = true;
    } else if (char === ",") {
      row.push(value);
      value = "";
    } else if (char === "\n") {
      row.push(value);
      rows.push(row);
      row = [];
      value = "";
    } else if (char !== "\r") {
      value += char;
    }
  }
  if (value.length > 0 || row.length > 0) {
    row.push(value);
    rows.push(row);
  }
  return rows.filter((entry) => entry.some((cell) => String(cell).trim() !== ""));
}

function normalizeHeader(header) {
  return String(header || "")
    .trim()
    .replace(/^\uFEFF/u, "")
    .toLowerCase()
    .replace(/[_-]+/g, " ")
    .replace(/\s+/g, " ");
}

function headerMap(headers) {
  const normalized = headers.map(normalizeHeader);
  const map = {};
  for (const [field, aliases] of Object.entries(FIELD_ALIASES)) {
    const index = normalized.findIndex((header) => aliases.map(normalizeHeader).includes(header));
    if (index !== -1) map[field] = index;
  }
  return map;
}

function numberValue(value) {
  const cleaned = String(value || "")
    .replace(/[$€£,\s]/g, "")
    .replace(/^--?$/u, "");
  const parsed = Number(cleaned);
  return Number.isFinite(parsed) ? parsed : 0;
}

function dateValue(value) {
  const raw = String(value || "").trim();
  if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw;
  const match = raw.match(/^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$/u);
  if (match) {
    const [, a, b, y] = match;
    const year = y.length === 2 ? `20${y}` : y;
    const first = Number(a);
    const second = Number(b);
    const month = first > 12 ? second : first;
    const day = first > 12 ? first : second;
    return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
  }
  const parsed = new Date(raw);
  if (!Number.isNaN(parsed.getTime())) return parsed.toISOString().slice(0, 10);
  return raw;
}

function rowsFromCsv(text, type) {
  const parsed = parseCsv(text);
  if (parsed.length < 2) return [];
  const headers = parsed[0];
  const map = headerMap(headers);
  const hasCampaign = map.campaign != null;
  const inferredType = type === "auto" ? hasCampaign ? "campaign" : "daily" : type;
  if (map.date == null) throw new Error("CSV must include a date column.");
  if (inferredType === "campaign" && map.campaign == null) throw new Error("Campaign CSV must include a campaign column.");

  return parsed.slice(1).map((row) => {
    const record = {
      date: dateValue(row[map.date]),
      firstTimeDownloads: numberValue(row[map.firstTimeDownloads]),
      productPageViews: numberValue(row[map.productPageViews]),
      premiumPurchases: numberValue(row[map.premiumPurchases]),
    };
    if (inferredType === "daily") {
      record.impressions = numberValue(row[map.impressions]);
      return { type: "daily", record };
    }
    record.campaign = String(row[map.campaign] || "").trim();
    if (map.spend != null) record.spend = numberValue(row[map.spend]);
    if (map.taps != null) record.taps = numberValue(row[map.taps]);
    return { type: "campaign", record };
  }).filter(({ record }) => record.date && (record.campaign == null || record.campaign));
}

function mergeByKey(items, incoming, keyFn, mergeFn) {
  const output = [...items];
  const indexByKey = new Map(output.map((item, index) => [keyFn(item), index]));
  let added = 0;
  let updated = 0;
  for (const item of incoming) {
    const key = keyFn(item);
    if (indexByKey.has(key)) {
      output[indexByKey.get(key)] = mergeFn(output[indexByKey.get(key)], item);
      updated += 1;
    } else {
      indexByKey.set(key, output.length);
      output.push(item);
      added += 1;
    }
  }
  return { output, added, updated };
}

function mergeMetrics(log, imported) {
  const dailyRecords = imported.filter((row) => row.type === "daily").map((row) => row.record);
  const campaignRecords = imported.filter((row) => row.type === "campaign").map((row) => row.record);

  const daily = mergeByKey(
    Array.isArray(log.daily) ? log.daily : [],
    dailyRecords,
    (item) => item.date,
    (existing, incoming) => ({ ...existing, ...incoming }),
  );
  const campaigns = mergeByKey(
    Array.isArray(log.campaigns) ? log.campaigns : [],
    campaignRecords,
    (item) => `${item.date}::${item.campaign}`,
    (existing, incoming) => ({ ...existing, ...incoming }),
  );

  return {
    log: {
      ...log,
      daily: daily.output.sort((a, b) => String(a.date).localeCompare(String(b.date))),
      campaigns: campaigns.output.sort((a, b) => String(a.date).localeCompare(String(b.date)) || String(a.campaign).localeCompare(String(b.campaign))),
    },
    summary: {
      dailyAdded: daily.added,
      dailyUpdated: daily.updated,
      campaignAdded: campaigns.added,
      campaignUpdated: campaigns.updated,
    },
  };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const sourcePath = path.resolve(REPO_ROOT, args.file);
  const source = await fs.readFile(sourcePath, "utf8");
  const imported = rowsFromCsv(source, args.type);
  const { absolute, json } = await readJson(args.log);
  const { log, summary } = mergeMetrics(json, imported);

  console.log(JSON.stringify({ file: sourcePath, imported: imported.length, ...summary }, null, 2));
  if (!args.dryRun) {
    await fs.writeFile(absolute, `${JSON.stringify(log, null, 2)}\n`);
    console.log(`Updated ${absolute}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
