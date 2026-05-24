import { PROMO_CODES_PATH } from "./config.js";
import { appendOutreachLog, readCsvRecords, writeCsvRecords } from "./csv.js";
import { readProspects, writeProspects } from "./prospectImporter.js";
import { canAssignCodeStatus, scoreProspect } from "./scoring.js";
import type { CsvRecord, PromoCode, ScoreTier } from "./types.js";
import { PROMO_CODE_COLUMNS } from "./types.js";
import { nowIso } from "./utils/dates.js";
import { clean, maskPromoCode } from "./utils/text.js";

export async function readPromoCodes(): Promise<PromoCode[]> {
  const records = await readCsvRecords<CsvRecord>(PROMO_CODES_PATH);
  return records.map(normalizePromoCode).filter((code) => code.code);
}

export async function writePromoCodes(codes: PromoCode[]): Promise<void> {
  await writeCsvRecords(PROMO_CODES_PATH, codes, PROMO_CODE_COLUMNS);
}

export async function importPromoCodes(filePath: string): Promise<{ imported: number; total: number }> {
  const incoming = (await readCsvRecords<CsvRecord>(filePath)).map(normalizePromoCode).filter((code) => code.code);
  const existing = await readPromoCodes();
  const unique = mergeCodes(existing, incoming);
  await writePromoCodes(unique);
  return { imported: incoming.length, total: unique.length };
}

export async function assignCodeToProspect(prospectId: string): Promise<{ code: string; alreadyAssigned: boolean }> {
  const prospects = await readProspects();
  const codes = await readPromoCodes();
  const prospect = prospects.find((item) => item.id === prospectId);
  if (!prospect) {
    throw new Error(`Prospect not found: ${prospectId}`);
  }
  if (prospect.status === "do_not_contact") {
    throw new Error(`Prospect ${prospectId} is marked do_not_contact.`);
  }
  if (!canAssignCodeStatus(prospect.status)) {
    throw new Error(`Prospect ${prospectId} has status '${prospect.status}', which is not eligible for code assignment.`);
  }

  const existing = codes.find((code) => code.assignedToProspectId === prospectId && ["assigned", "sent", "redeemed"].includes(code.status));
  if (existing) {
    prospect.promoCode = existing.code;
    await writeProspects(prospects);
    return { code: existing.code, alreadyAssigned: true };
  }

  const available = codes.find((code) => code.status === "available" && !code.assignedToProspectId);
  if (!available) {
    throw new Error("No available promo code found.");
  }

  available.status = "assigned";
  available.assignedToProspectId = prospectId;
  available.assignedAt = nowIso();
  prospect.promoCode = available.code;
  if (prospect.status === "new") {
    prospect.status = "shortlisted";
  }
  prospect.updatedAt = nowIso();

  await writePromoCodes(codes);
  await writeProspects(prospects);
  await appendOutreachLog({
    timestamp: nowIso(),
    prospectId,
    action: "code_assigned",
    status: prospect.status,
    responseType: "",
    note: "Promo code assigned locally. No message was sent.",
    template: "",
    language: prospect.language,
    codeMasked: maskPromoCode(available.code)
  });
  return { code: available.code, alreadyAssigned: false };
}

export async function assignBatch(options: {
  tier?: ScoreTier;
  limit: number;
}): Promise<Array<{ prospectId: string; code: string; alreadyAssigned: boolean }>> {
  const prospects = await readProspects();
  const ranked = prospects
    .filter((prospect) => !prospect.promoCode)
    .filter((prospect) => prospect.status !== "do_not_contact")
    .filter((prospect) => canAssignCodeStatus(prospect.status))
    .map((prospect) => ({ prospect, score: scoreProspect(prospect) }))
    .filter((item) => (options.tier ? item.score.tier === options.tier : true))
    .sort((a, b) => b.score.score - a.score.score)
    .slice(0, options.limit);

  const results: Array<{ prospectId: string; code: string; alreadyAssigned: boolean }> = [];
  for (const item of ranked) {
    const result = await assignCodeToProspect(item.prospect.id);
    results.push({ prospectId: item.prospect.id, ...result });
  }
  return results;
}

export async function markCodeSent(prospectId: string): Promise<{ code: string }> {
  const prospects = await readProspects();
  const codes = await readPromoCodes();
  const prospect = prospects.find((item) => item.id === prospectId);
  if (!prospect) {
    throw new Error(`Prospect not found: ${prospectId}`);
  }
  if (prospect.status === "do_not_contact") {
    throw new Error(`Prospect ${prospectId} is marked do_not_contact.`);
  }
  const code = codes.find((item) => item.assignedToProspectId === prospectId || item.code === prospect.promoCode);
  if (!code) {
    throw new Error(`No assigned promo code found for prospect ${prospectId}.`);
  }
  code.status = "sent";
  prospect.status = "code_sent";
  prospect.promoCode = code.code;
  prospect.lastContactedAt = nowIso();
  prospect.updatedAt = nowIso();
  await writePromoCodes(codes);
  await writeProspects(prospects);
  await appendOutreachLog({
    timestamp: nowIso(),
    prospectId,
    action: "code_sent",
    status: prospect.status,
    responseType: "",
    note: "Marked as sent after manual outreach.",
    template: "",
    language: prospect.language,
    codeMasked: maskPromoCode(code.code)
  });
  return { code: code.code };
}

export async function getAssignedCode(prospectId: string): Promise<string> {
  const codes = await readPromoCodes();
  const match = codes.find((code) => code.assignedToProspectId === prospectId && ["assigned", "sent", "redeemed"].includes(code.status));
  return match?.code ?? "";
}

function normalizePromoCode(record: CsvRecord): PromoCode {
  return {
    code: clean(record.code),
    status: clean(record.status) || "available",
    assignedToProspectId: clean(record.assignedToProspectId),
    assignedAt: clean(record.assignedAt),
    redeemed: clean(record.redeemed),
    notes: clean(record.notes)
  };
}

function mergeCodes(existing: PromoCode[], incoming: PromoCode[]): PromoCode[] {
  const byCode = new Map<string, PromoCode>(existing.map((code) => [code.code, code]));
  for (const code of incoming) {
    const current = byCode.get(code.code);
    if (current && current.assignedToProspectId && !code.assignedToProspectId) {
      continue;
    }
    if (!byCode.has(code.code)) {
      byCode.set(code.code, code);
      continue;
    }
    byCode.set(code.code, { ...current, ...code });
  }
  return [...byCode.values()];
}
