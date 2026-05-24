import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { parse } from "csv-parse/sync";
import { stringify } from "csv-stringify/sync";
import type { CsvRecord, OutreachLogEntry, ResponseEntry } from "./types.js";
import { OUTREACH_LOG_COLUMNS, RESPONSE_COLUMNS } from "./types.js";
import { OUTREACH_LOG_PATH, RESPONSES_PATH } from "./config.js";

export async function readCsvRecords<T extends CsvRecord>(filePath: string): Promise<T[]> {
  try {
    const input = await readFile(filePath, "utf8");
    if (!input.trim()) {
      return [];
    }
    const parsed = parse(input, {
      bom: true,
      columns: true,
      skip_empty_lines: true,
      relax_column_count: true,
      trim: true
    }) as CsvRecord[];
    return parsed.map((record) => normalizeRecord(record) as T);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return [];
    }
    throw error;
  }
}

export async function writeCsvRecords<T extends CsvRecord>(
  filePath: string,
  records: T[],
  columns: readonly string[]
): Promise<void> {
  await mkdir(dirname(filePath), { recursive: true });
  const normalized = records.map((record) => {
    const row: CsvRecord = {};
    for (const column of columns) {
      row[column] = String(record[column] ?? "");
    }
    return row;
  });
  const output = stringify(normalized, {
    header: true,
    columns: [...columns],
    quoted_empty: false
  });
  await writeFile(filePath, output, "utf8");
}

export async function appendCsvRecord<T extends CsvRecord>(
  filePath: string,
  record: T,
  columns: readonly string[]
): Promise<void> {
  const existing = await readCsvRecords<T>(filePath);
  existing.push(record);
  await writeCsvRecords(filePath, existing, columns);
}

export async function appendOutreachLog(entry: OutreachLogEntry): Promise<void> {
  await appendCsvRecord(OUTREACH_LOG_PATH, entry, OUTREACH_LOG_COLUMNS);
}

export async function appendResponse(entry: ResponseEntry): Promise<void> {
  await appendCsvRecord(RESPONSES_PATH, entry, RESPONSE_COLUMNS);
}

function normalizeRecord(record: CsvRecord): CsvRecord {
  const normalized: CsvRecord = {};
  for (const [key, value] of Object.entries(record)) {
    normalized[String(key).trim()] = String(value ?? "").trim();
  }
  return normalized;
}
