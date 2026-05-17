import path from "node:path";

import { ASSET_DIRS } from "../config.js";
import { FactoryError } from "../logger.js";
import type { AudioMix, AudioTrack } from "../types.js";
import { pathExists } from "../utils/fs.js";

export interface ResolvedAudio {
  filePath: string;
  fileName: string;
  volume: number;
}

export async function resolveTracks(mix: AudioMix): Promise<ResolvedAudio[]> {
  const resolved: ResolvedAudio[] = [];
  const missing: AudioTrack[] = [];
  for (const t of mix.tracks) {
    const full = path.join(ASSET_DIRS.audio, t.file);
    if (await pathExists(full)) {
      resolved.push({ filePath: full, fileName: t.file, volume: t.volume });
    } else {
      missing.push(t);
    }
  }
  if (missing.length) {
    const list = missing.map((m) => `  - ${m.file}`).join("\n");
    throw new FactoryError(
      `Audio mix "${mix.id}" references files that are missing in assets/audio/:\n${list}`,
      "Run `npm run sync:audio` to symlink Oasis bundle sounds into assets/audio/, " +
        "or drop the missing .m4a files there manually.",
    );
  }
  return resolved;
}

// Produces a filter_complex chain entry for a single audio track:
// loops it, trims to duration, applies volume, applies fade in/out.
export function audioFilterChain(
  inputIndex: number,
  outLabel: string,
  durationSec: number,
  volume: number,
  fadeIn: number,
  fadeOut: number,
): string {
  const fadeOutStart = Math.max(0, durationSec - fadeOut);
  const parts: string[] = [];
  parts.push(`aloop=loop=-1:size=2147483647`);
  parts.push(`atrim=duration=${durationSec.toFixed(3)}`);
  parts.push(`asetpts=N/SR/TB`);
  parts.push(`volume=${volume.toFixed(3)}`);
  if (fadeIn > 0) {
    parts.push(`afade=t=in:st=0:d=${fadeIn.toFixed(3)}`);
  }
  if (fadeOut > 0) {
    parts.push(`afade=t=out:st=${fadeOutStart.toFixed(3)}:d=${fadeOut.toFixed(3)}`);
  }
  return `[${inputIndex}:a]${parts.join(",")}[${outLabel}]`;
}

export function audioMixChain(inputs: string[], outLabel: string): string {
  const labels = inputs.map((l) => `[${l}]`).join("");
  return `${labels}amix=inputs=${inputs.length}:duration=first:normalize=0[${outLabel}]`;
}
