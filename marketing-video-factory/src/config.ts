import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { z } from "zod";

import {
  AudioMixesFileSchema,
  CaptionsFileSchema,
  type ConfigBundle,
  HashtagsFileSchema,
  HooksFileSchema,
  type Lang,
  type Scenario,
  ScenarioSchema,
} from "./types.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
export const ROOT_DIR = path.resolve(HERE, "..");
export const CONFIG_DIR = path.join(ROOT_DIR, "config");
export const SCENARIOS_DIR = path.join(ROOT_DIR, "scenarios");
export const ASSETS_DIR = path.join(ROOT_DIR, "assets");
export const OUTPUT_DIR = path.join(ROOT_DIR, "output");
export const TMP_DIR = path.join(ROOT_DIR, ".tmp");

export const ASSET_DIRS = {
  audio: path.join(ASSETS_DIR, "audio"),
  fonts: path.join(ASSETS_DIR, "fonts"),
  recordings: path.join(ASSETS_DIR, "recordings"),
} as const;

// Resolve the iOS Xcode project once — the CLI driver uses it to invoke
// xcodebuild test against the OasisNative scheme.
export const IOS_PROJECT_PATH = path.resolve(
  ROOT_DIR,
  "..",
  "ios-native/OasisNative.xcodeproj",
);

async function readJson<S extends z.ZodTypeAny>(
  filePath: string,
  schema: S,
): Promise<z.output<S>> {
  let raw: string;
  try {
    raw = await readFile(filePath, "utf-8");
  } catch (err) {
    throw new Error(`Cannot read config file: ${filePath} (${(err as Error).message})`);
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new Error(`Invalid JSON in ${filePath}: ${(err as Error).message}`);
  }
  const result = schema.safeParse(parsed);
  if (!result.success) {
    const issues = result.error.issues
      .map((i) => `  - ${i.path.join(".") || "<root>"}: ${i.message}`)
      .join("\n");
    throw new Error(`Schema validation failed for ${filePath}:\n${issues}`);
  }
  return result.data;
}

export async function loadConfig(): Promise<ConfigBundle> {
  const [mixes, hooksFr, hooksEn, captionsFr, captionsEn, hashtags] = await Promise.all([
    readJson(path.join(CONFIG_DIR, "audio-mixes.json"), AudioMixesFileSchema),
    readJson(path.join(CONFIG_DIR, "hooks.fr.json"), HooksFileSchema),
    readJson(path.join(CONFIG_DIR, "hooks.en.json"), HooksFileSchema),
    readJson(path.join(CONFIG_DIR, "captions.fr.json"), CaptionsFileSchema),
    readJson(path.join(CONFIG_DIR, "captions.en.json"), CaptionsFileSchema),
    readJson(path.join(CONFIG_DIR, "hashtags.json"), HashtagsFileSchema),
  ]);
  return {
    mixes: mixes.mixes,
    hooks: { fr: hooksFr, en: hooksEn },
    captions: { fr: captionsFr, en: captionsEn },
    hashtags,
  };
}

export async function listScenarios(): Promise<Scenario[]> {
  let names: string[];
  try {
    names = await readdir(SCENARIOS_DIR);
  } catch {
    return [];
  }
  const files = names.filter((n) => n.endsWith(".json"));
  const scenarios = await Promise.all(
    files.map((f) => readJson(path.join(SCENARIOS_DIR, f), ScenarioSchema)),
  );
  scenarios.sort((a, b) => a.id.localeCompare(b.id));
  return scenarios;
}

export async function loadScenario(id: string): Promise<Scenario> {
  const filePath = path.join(SCENARIOS_DIR, `${id}.json`);
  return readJson(filePath, ScenarioSchema);
}

export function findMix(bundle: ConfigBundle, id: string) {
  return bundle.mixes.find((m) => m.id === id);
}

export function pickHook(
  bundle: ConfigBundle,
  lang: Lang,
  category: string,
  pick: (n: number) => number,
): string {
  const pool = bundle.hooks[lang][category];
  if (!pool || pool.length === 0) {
    throw new Error(`No hooks for lang=${lang} category=${category}`);
  }
  return pool[pick(pool.length)]!;
}

export function pickCaption(
  bundle: ConfigBundle,
  lang: Lang,
  category: string,
  pick: (n: number) => number,
): string {
  const pool = bundle.captions[lang][category];
  if (!pool || pool.length === 0) {
    throw new Error(`No captions for lang=${lang} category=${category}`);
  }
  return pool[pick(pool.length)]!;
}

export function collectHashtags(
  bundle: ConfigBundle,
  lang: Lang,
  categories: string[],
): string[] {
  const dict = bundle.hashtags[lang];
  const out: string[] = [];
  for (const cat of categories) {
    const tags = dict[cat] ?? [];
    for (const tag of tags) {
      if (!out.includes(tag)) out.push(tag);
    }
  }
  return out;
}
