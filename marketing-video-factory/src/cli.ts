import { rm } from "node:fs/promises";
import path from "node:path";

import { Command } from "commander";

import { listScenarios, loadConfig, OUTPUT_DIR, TMP_DIR } from "./config.js";
import { FactoryError, log, reportError, setDebug } from "./logger.js";
import { recordScenario } from "./sim/record.js";
import { resolveFfmpeg } from "./utils/ffmpeg.js";
import { LangSchema } from "./types.js";
import { pathExists } from "./utils/fs.js";

const DEFAULT_DEVICE = "iPhone 17 Pro Max";

function parsePositiveInt(value: string, name: string): number {
  const n = Number.parseInt(value, 10);
  if (!Number.isFinite(n) || n < 1) {
    throw new FactoryError(`Invalid value for --${name}: "${value}".`);
  }
  return n;
}

const program = new Command();
program
  .name("oasis-video-factory")
  .description("Scenario-driven marketing video factory for Oasis.")
  .option("--debug", "verbose output (xcodebuild + FFmpeg streamed inline)")
  .hook("preAction", (cmd) => {
    setDebug(Boolean(cmd.opts().debug));
  });

program
  .command("validate")
  .description("Check FFmpeg, configs and scenarios.")
  .action(async () => {
    try {
      log.banner("Validation");
      log.info("Checking FFmpeg…");
      await resolveFfmpeg();
      log.success("FFmpeg available.");

      log.info("Loading configs…");
      const bundle = await loadConfig();
      log.success(`Loaded ${bundle.mixes.length} audio mixes.`);

      log.info("Loading scenarios…");
      const scenarios = await listScenarios();
      if (scenarios.length === 0) {
        log.warn("No scenarios in scenarios/. Add a JSON file there.");
      } else {
        log.success(`Loaded ${scenarios.length} scenario(s).`);
        const mixIds = new Set(bundle.mixes.map((m) => m.id));
        let issues = 0;
        for (const s of scenarios) {
          if (!mixIds.has(s.audioMix)) {
            log.error(`Scenario "${s.id}" references unknown audio mix "${s.audioMix}".`);
            issues++;
          }
          if (!bundle.hooks[s.lang][s.hookCategory]) {
            log.error(`Scenario "${s.id}" hookCategory "${s.hookCategory}" missing for lang=${s.lang}.`);
            issues++;
          }
          if (!bundle.captions[s.lang][s.captionCategory]) {
            log.error(`Scenario "${s.id}" captionCategory "${s.captionCategory}" missing for lang=${s.lang}.`);
            issues++;
          }
        }
        if (issues > 0) {
          process.exitCode = 1;
          log.warn(`Validation found ${issues} issue(s).`);
        } else {
          log.success("All scenarios cross-reference cleanly.");
        }
      }
    } catch (err) {
      reportError(err);
      process.exitCode = 1;
    }
  });

program
  .command("list")
  .description("List scenarios and audio mixes.")
  .action(async () => {
    try {
      const bundle = await loadConfig();
      const scenarios = await listScenarios();
      log.banner("Scenarios");
      for (const s of scenarios) {
        log.plain(
          `  ${s.id.padEnd(24)} ${s.mood.padEnd(12)} ${String(s.duration).padStart(3)}s  ${s.audioMix}`,
        );
      }
      log.banner("Audio mixes");
      for (const m of bundle.mixes) {
        log.plain(`  ${m.id.padEnd(24)} ${m.tracks.map((t) => t.file).join(" + ")}`);
      }
    } catch (err) {
      reportError(err);
      process.exitCode = 1;
    }
  });

program
  .command("record")
  .description("Record a scenario from the simulator and render the final social video.")
  .option("-s, --scenario <id>", "scenario id (file under scenarios/)", "sleep-rain-demo")
  .option("-l, --lang <lang>", "fr | en | de | es | it | ptbr (overrides scenario lang)")
  .option("--device <name>", "simulator device name", DEFAULT_DEVICE)
  .option("--seed <n>", "deterministic hook/caption pick")
  .option("--dry-run", "skip simulator + FFmpeg, write metadata only")
  .option("--keep-raw", "keep the raw simulator recording alongside the final mp4")
  .action(async (rawOpts) => {
    try {
      const debug = Boolean(program.opts().debug);
      const lang = rawOpts.lang ? LangSchema.parse(rawOpts.lang) : undefined;
      await recordScenario({
        scenarioId: String(rawOpts.scenario),
        ...(lang !== undefined ? { lang } : {}),
        outputDir: OUTPUT_DIR,
        ...(rawOpts.seed ? { seed: parsePositiveInt(rawOpts.seed, "seed") } : {}),
        dryRun: Boolean(rawOpts.dryRun),
        debug,
        device: String(rawOpts.device ?? DEFAULT_DEVICE),
        keepRaw: Boolean(rawOpts.keepRaw),
      });
    } catch (err) {
      reportError(err);
      process.exitCode = 1;
    }
  });

program
  .command("clean")
  .description("Remove temporary files (and output with --all).")
  .option("--all", "also delete generated videos in output/")
  .action(async (rawOpts) => {
    try {
      if (await pathExists(TMP_DIR)) {
        await rm(TMP_DIR, { recursive: true, force: true });
        log.success(`Removed ${path.relative(process.cwd(), TMP_DIR)}/`);
      } else {
        log.info("No tmp directory to clean.");
      }
      if (rawOpts.all && (await pathExists(OUTPUT_DIR))) {
        const fs = await import("node:fs/promises");
        const entries = await fs.readdir(OUTPUT_DIR);
        for (const e of entries) {
          if (e === ".gitkeep") continue;
          await rm(path.join(OUTPUT_DIR, e), { recursive: true, force: true });
        }
        log.warn(`Cleared output/ (kept .gitkeep).`);
      } else if (!rawOpts.all) {
        log.hint("Pass --all to also wipe output/.");
      }
    } catch (err) {
      reportError(err);
      process.exitCode = 1;
    }
  });

program.parseAsync(process.argv).catch((err) => {
  reportError(err);
  process.exit(1);
});
