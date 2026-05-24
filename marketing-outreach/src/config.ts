import { readFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type {
  AppConfig,
  MessageVariantsConfig,
  NicheConfig,
  OutreachRules,
  ScoringConfig,
  SupportedLanguage
} from "./types.js";
import { SUPPORTED_LANGUAGES } from "./types.js";

export const PROJECT_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");
export const DATA_DIR = join(PROJECT_ROOT, "data");
export const EXPORTS_DIR = join(PROJECT_ROOT, "exports");
export const TEMPLATES_DIR = join(PROJECT_ROOT, "templates");
export const CONFIG_DIR = join(PROJECT_ROOT, "config");

export const PROSPECTS_PATH = join(DATA_DIR, "prospects.csv");
export const PROMO_CODES_PATH = join(DATA_DIR, "promo-codes.csv");
export const OUTREACH_LOG_PATH = join(DATA_DIR, "outreach-log.csv");
export const RESPONSES_PATH = join(DATA_DIR, "responses.csv");

function loadJson<T>(relativePath: string): T {
  const fullPath = join(PROJECT_ROOT, relativePath);
  return JSON.parse(readFileSync(fullPath, "utf8")) as T;
}

export function loadAppConfig(): AppConfig {
  return loadJson<AppConfig>("config/app.json");
}

export function loadOutreachRules(): OutreachRules {
  return loadJson<OutreachRules>("config/outreach-rules.json");
}

export function loadScoringConfig(): ScoringConfig {
  return loadJson<ScoringConfig>("config/scoring.json");
}

export function loadNiches(): Record<string, NicheConfig> {
  return loadJson<Record<string, NicheConfig>>("config/niches.json");
}

export function loadMessageVariants(): MessageVariantsConfig {
  return loadJson<MessageVariantsConfig>("config/message-variants.json");
}

export function isSupportedLanguage(value: string): value is SupportedLanguage {
  return SUPPORTED_LANGUAGES.includes(value as SupportedLanguage);
}

export function resolveLanguage(value: string | undefined, fallback?: SupportedLanguage): SupportedLanguage {
  if (value && isSupportedLanguage(value)) {
    return value;
  }
  const appConfig = loadAppConfig();
  return fallback ?? appConfig.fallbackLanguage;
}
