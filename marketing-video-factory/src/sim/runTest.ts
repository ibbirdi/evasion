import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import { execa } from "execa";

import { IOS_PROJECT_PATH } from "../config.js";
import { FactoryError, log } from "../logger.js";
import type { Lang, Scenario } from "../types.js";
import { ensureDir, pathExists } from "../utils/fs.js";
import type { DeviceInfo } from "./simulator.js";

const SCENARIO_TMP_PATH = "/tmp/oasis-marketing/scenario.json";
const START_MARKER_PATH = "/tmp/oasis-marketing/scenario-started.txt";

const LOCALES: Record<Lang, { locale: string; appleLanguages: string }> = {
  fr: { locale: "fr_FR", appleLanguages: "fr" },
  en: { locale: "en_US", appleLanguages: "en" },
  de: { locale: "de_DE", appleLanguages: "de" },
  es: { locale: "es_ES", appleLanguages: "es" },
  it: { locale: "it_IT", appleLanguages: "it" },
  ptbr: { locale: "pt_BR", appleLanguages: "pt-BR" },
};

export async function writeScenarioFile(
  scenario: Scenario,
  lang: Lang,
): Promise<string> {
  await ensureDir(path.dirname(SCENARIO_TMP_PATH));
  const enriched = { ...scenario, ...LOCALES[lang] };
  await writeFile(SCENARIO_TMP_PATH, JSON.stringify(enriched, null, 2), "utf-8");
  // Wipe any stale marker from a previous run.
  if (await pathExists(START_MARKER_PATH)) {
    await writeFile(START_MARKER_PATH, "");
  }
  return SCENARIO_TMP_PATH;
}

/**
 * Returns the Unix timestamp (seconds since epoch) at which the XCUITest
 * started replaying scenario actions. The Node driver subtracts this from
 * the moment it started the recording to know how many seconds to skip
 * forward in the raw mp4 (boot + xcodebuild + app launch overhead).
 */
export async function readStartMarker(): Promise<number | null> {
  if (!(await pathExists(START_MARKER_PATH))) return null;
  const raw = (await readFile(START_MARKER_PATH, "utf-8")).trim();
  if (!raw) return null;
  const n = Number.parseFloat(raw);
  return Number.isFinite(n) ? n : null;
}

export interface XCUITestOptions {
  device: DeviceInfo;
  scenarioPath: string;
  testIdentifier: string; // e.g. "OasisNativeUITests/MarketingScenarioRunner/testRunScenario"
  scheme: string;
  buildLogPath: string;
  debug: boolean;
}

export async function runXCUITest(opts: XCUITestOptions): Promise<void> {
  await ensureDir(path.dirname(opts.buildLogPath));
  const args = [
    "test-without-building",
    "-scheme",
    opts.scheme,
    "-project",
    IOS_PROJECT_PATH,
    "-destination",
    `platform=iOS Simulator,id=${opts.device.udid}`,
    "-only-testing",
    opts.testIdentifier,
    "OASIS_SCENARIO_PATH=" + opts.scenarioPath,
    "CODE_SIGNING_ALLOWED=NO",
  ];
  log.debug(`xcodebuild ${args.join(" ")}`);
  try {
    await execa("xcodebuild", args, {
      stdio: opts.debug ? "inherit" : "pipe",
      env: { ...process.env, OASIS_SCENARIO_PATH: opts.scenarioPath },
    });
  } catch (err: unknown) {
    const e = err as { stderr?: string; stdout?: string; message?: string };
    const tail = ((e.stdout ?? "") + "\n" + (e.stderr ?? ""))
      .split("\n")
      .slice(-30)
      .join("\n");
    await writeFile(opts.buildLogPath, tail, "utf-8").catch(() => undefined);
    throw new FactoryError(
      `xcodebuild test failed: ${e.message ?? "unknown error"}`,
      `Tail logs at ${opts.buildLogPath}. Re-run with --debug to see live output.`,
    );
  }
}

export async function ensureTestBuild(opts: {
  device: DeviceInfo;
  scheme: string;
  debug: boolean;
}): Promise<void> {
  // build-for-testing once so subsequent runs skip compilation. Cheap if up-to-date.
  const args = [
    "build-for-testing",
    "-scheme",
    opts.scheme,
    "-project",
    IOS_PROJECT_PATH,
    "-destination",
    `platform=iOS Simulator,id=${opts.device.udid}`,
    "CODE_SIGNING_ALLOWED=NO",
  ];
  log.info("Building UI test target (cached if unchanged)…");
  try {
    await execa("xcodebuild", args, {
      stdio: opts.debug ? "inherit" : "pipe",
    });
  } catch (err: unknown) {
    const e = err as { stderr?: string; message?: string };
    const tail = (e.stderr ?? "").split("\n").slice(-30).join("\n");
    throw new FactoryError(
      `xcodebuild build-for-testing failed: ${e.message ?? "unknown error"}`,
      tail || undefined,
    );
  }
}
