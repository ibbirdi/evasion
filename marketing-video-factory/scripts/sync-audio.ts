// Symlinks the iOS audio bundle into marketing-video-factory/assets/audio/
// with short aliases used by the audio-mixes.json config. No file is copied.
//
// Run with: npm run sync

import { symlink, unlink } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { ASSET_DIRS } from "../src/config.js";
import { log, reportError } from "../src/logger.js";
import { ensureDir, pathExists } from "../src/utils/fs.js";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(HERE, "..", "..");
const IOS_AUDIO_DIR = path.join(
  REPO_ROOT,
  "ios-native/OasisNative/Resources/Audio",
);

const AUDIO_ALIASES: Record<string, string> = {
  "rain.m4a": "pluie1.m4a",
  "rain-tent.m4a": "tente1.m4a",
  "wind.m4a": "vent1.m4a",
  "forest.m4a": "foret1.m4a",
  "thunder.m4a": "orage1.m4a",
  "mountain-storm.m4a": "orageMontagne1.m4a",
  "sea.m4a": "mer1.m4a",
  "beach.m4a": "plage1.m4a",
  "river.m4a": "riviere1.m4a",
  "lake.m4a": "lac1.m4a",
  "birds.m4a": "oiseaux1.m4a",
  "campfire.m4a": "campfire1.m4a",
  "crickets.m4a": "grillons1.m4a",
  "cicadas.m4a": "cigales1.m4a",
  "cafe.m4a": "cafe1.m4a",
  "city.m4a": "ville1.m4a",
  "savanna.m4a": "savane1.m4a",
  "jungle-america.m4a": "jungleamerique1.m4a",
  "jungle-asia.m4a": "jungleasie1.m4a",
  "seagulls.m4a": "goelants1.m4a",
};

async function makeSymlink(src: string, dest: string): Promise<"created" | "missing"> {
  if (!(await pathExists(src))) return "missing";
  try { await unlink(dest); } catch { /* not present */ }
  await symlink(path.relative(path.dirname(dest), src), dest);
  return "created";
}

async function main(): Promise<void> {
  log.banner("Sync iOS audio → marketing assets (symlinks)");
  if (!(await pathExists(IOS_AUDIO_DIR))) {
    log.error(`iOS audio directory not found: ${IOS_AUDIO_DIR}`);
    process.exitCode = 1;
    return;
  }
  await ensureDir(ASSET_DIRS.audio);
  let ok = 0;
  let missing = 0;
  for (const [alias, real] of Object.entries(AUDIO_ALIASES)) {
    const r = await makeSymlink(
      path.join(IOS_AUDIO_DIR, real),
      path.join(ASSET_DIRS.audio, alias),
    );
    if (r === "created") {
      ok++;
      log.step(alias, `→ ${real}`);
    } else {
      missing++;
      log.warn(`Missing in iOS bundle: ${real}`);
    }
  }
  log.success(`Done — ${ok} linked, ${missing} missing.`);
  log.hint("Audio is layered on top of the simulator recording in post.");
}

main().catch((err) => {
  reportError(err);
  process.exit(1);
});
