import { basename } from "node:path";
import { PROSPECTS_PATH } from "./config.js";
import { readCsvRecords, writeCsvRecords } from "./csv.js";
import type { CsvRecord, Prospect } from "./types.js";
import { PROSPECT_COLUMNS } from "./types.js";
import { nowIso } from "./utils/dates.js";
import { slugify } from "./utils/slug.js";
import { clean, normalizeToken, shortHash } from "./utils/text.js";

export async function readProspects(): Promise<Prospect[]> {
  const records = await readCsvRecords<CsvRecord>(PROSPECTS_PATH);
  return ensureUniqueIds(records.map((record) => normalizeProspect(record)));
}

export async function writeProspects(prospects: Prospect[]): Promise<void> {
  await writeCsvRecords(PROSPECTS_PATH, prospects, PROSPECT_COLUMNS);
}

export async function importProspects(filePath: string): Promise<{ imported: number; total: number; path: string }> {
  const incomingRecords = await readCsvRecords<CsvRecord>(filePath);
  const incoming = ensureUniqueIds(incomingRecords.map((record) => normalizeProspect(record)));
  const existing = await readProspects();
  const merged = mergeProspects(existing, incoming);
  await writeProspects(merged);
  return { imported: incoming.length, total: merged.length, path: basename(filePath) };
}

export function normalizeProspect(record: CsvRecord): Prospect {
  const now = nowIso();
  const prospect: Prospect = {
    id: clean(record.id),
    name: clean(record.name),
    handle: clean(record.handle),
    platform: normalizeToken(clean(record.platform)),
    profileUrl: clean(record.profileUrl),
    email: clean(record.email).toLowerCase(),
    niche: normalizeToken(clean(record.niche)),
    followers: clean(record.followers),
    engagementHint: clean(record.engagementHint),
    country: clean(record.country).toUpperCase(),
    language: clean(record.language) || "unknown",
    contactMethod: normalizeToken(clean(record.contactMethod)),
    notes: clean(record.notes),
    status: normalizeToken(clean(record.status)) || "new",
    score: clean(record.score),
    tier: clean(record.tier),
    scoreReason: clean(record.scoreReason),
    priority: clean(record.priority),
    promoCode: clean(record.promoCode),
    lastContactedAt: clean(record.lastContactedAt),
    lastFollowupAt: clean(record.lastFollowupAt),
    followupCount: clean(record.followupCount) || "0",
    createdAt: clean(record.createdAt) || now,
    updatedAt: clean(record.updatedAt) || now
  };
  prospect.id = prospect.id || buildProspectId(prospect);
  prospect.contactMethod = prospect.contactMethod || inferContactMethod(prospect);
  return prospect;
}

function mergeProspects(existing: Prospect[], incoming: Prospect[]): Prospect[] {
  const byId = new Map(existing.map((prospect) => [prospect.id, prospect]));
  for (const prospect of incoming) {
    const current = byId.get(prospect.id);
    if (!current) {
      byId.set(prospect.id, prospect);
      continue;
    }
    byId.set(prospect.id, {
      ...current,
      ...nonEmptyFields(prospect),
      createdAt: current.createdAt || prospect.createdAt,
      updatedAt: nowIso()
    });
  }
  return [...byId.values()];
}

function nonEmptyFields(prospect: Prospect): Partial<Prospect> {
  const result: Partial<Prospect> = {};
  for (const column of PROSPECT_COLUMNS) {
    const value = prospect[column];
    if (value !== "") {
      result[column] = value;
    }
  }
  return result;
}

function ensureUniqueIds(prospects: Prospect[]): Prospect[] {
  const seen = new Map<string, number>();
  return prospects.map((prospect) => {
    const count = seen.get(prospect.id) ?? 0;
    seen.set(prospect.id, count + 1);
    if (count === 0) {
      return prospect;
    }
    return { ...prospect, id: `${prospect.id}-${count + 1}` };
  });
}

function buildProspectId(prospect: Prospect): string {
  const platform = prospect.platform || "manual";
  const handle = normalizeToken(prospect.handle);
  if (handle) {
    return slugify(`${platform}-${handle}`);
  }
  const url = prospect.profileUrl ? shortHash(prospect.profileUrl) : "";
  const name = slugify(prospect.name || "prospect");
  return slugify(`${platform}-${name}-${url || shortHash(JSON.stringify(prospect))}`);
}

function inferContactMethod(prospect: Prospect): string {
  if (prospect.email) {
    return "email";
  }
  if (prospect.platform === "reddit") {
    return "comment";
  }
  if (prospect.profileUrl || prospect.handle) {
    return "dm";
  }
  return "manual";
}
