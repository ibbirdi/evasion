import path from "node:path";

import { TMP_DIR } from "../config.js";
import { log } from "../logger.js";
import type { AudioMix, ResolvedOverlay } from "../types.js";
import { ensureDir, removeIfExists } from "../utils/fs.js";
import { probeMedia, runFfmpeg } from "../utils/ffmpeg.js";

import {
  audioFilterChain,
  audioMixChain,
  type ResolvedAudio,
} from "./renderAudioMix.js";
import { renderOverlayPng } from "./renderOverlay.js";
import { fadingOverlayChain } from "./concatIntro.js";

const FRAME_W = 1080;
const FRAME_H = 1920;

export interface PostProcessParams {
  rawRecording: string;
  duration: number;
  // Seconds to skip at the start of the raw recording (boot + xcodebuild
  // overhead before the XCUITest's `app.launch()` returned and the scenario
  // timeline began).
  startOffsetSec: number;
  overlays: ResolvedOverlay[];
  mix: AudioMix;
  tracks: ResolvedAudio[];
  output: string;
  debug: boolean;
  baseName: string;
}

export async function postProcess(p: PostProcessParams): Promise<void> {
  await ensureDir(TMP_DIR);

  // Pre-render the timed text PNGs once (1080x1920 transparent each).
  const overlayPngs: string[] = [];
  for (let i = 0; i < p.overlays.length; i++) {
    const ov = p.overlays[i]!;
    const png = path.join(TMP_DIR, `${p.baseName}_ov${i}.png`);
    await renderOverlayPng({
      text: ov.text,
      position: ov.position,
      ...(ov.size ? { size: ov.size } : {}),
      ...(ov.backdrop ? { backdrop: true } : {}),
      outPath: png,
    });
    overlayPngs.push(png);
  }

  try {
    await runFfmpegPipeline({ ...p, overlayPngs });
  } finally {
    for (const f of overlayPngs) {
      await removeIfExists(f);
      await removeIfExists(f.replace(/\.png$/, ".svg"));
    }
  }
}

async function runFfmpegPipeline(
  p: PostProcessParams & { overlayPngs: string[] },
): Promise<void> {
  // Probe the raw recording to know its native size — simctl writes the
  // device's native resolution (e.g. 1290x2796 for iPhone 17 Pro Max).
  const probe = await probeMedia(p.rawRecording);
  log.debug(
    `raw recording: ${probe.width}x${probe.height} duration=${probe.durationSec.toFixed(2)}s`,
  );

  const inputs: string[] = [];
  let nextIndex = 0;
  const addInput = (...args: string[]): number => {
    inputs.push(...args);
    return nextIndex++;
  };

  // [0] raw recording (video only — we discard its audio). Seek past boot
  // overhead so frame 0 of the output = first scenario action.
  const recIdx =
    p.startOffsetSec > 0
      ? addInput("-ss", p.startOffsetSec.toFixed(3), "-i", p.rawRecording)
      : addInput("-i", p.rawRecording);

  // [1..N] audio tracks (looped via aloop in the filter).
  const audioIndices: number[] = p.tracks.map((t) => addInput("-i", t.filePath));

  // [N+1..] overlay PNGs (each looped for the full duration).
  const overlayIndices: number[] = p.overlayPngs.map((png) =>
    addInput("-loop", "1", "-t", p.duration.toFixed(3), "-i", png),
  );

  const filterParts: string[] = [];

  // Recording → fit-to-height inside 1080×1920 with a blurred backdrop on the
  // sides. The device aspect (≈9:19.5) is taller than 9:16, so a fit-width
  // crop would clip the status bar at the top and the home indicator zone at
  // the bottom. Fit-to-height keeps the entire screen visible; the leftover
  // ~97 px on each side is filled with a heavily-blurred, slightly-darkened
  // copy of the same recording so the frame stays visually continuous.
  const trim = `trim=duration=${p.duration.toFixed(3)},setpts=PTS-STARTPTS`;
  filterParts.push(
    `[${recIdx}:v]split=2[recA][recB]`,
    `[recA]scale=${FRAME_W}:${FRAME_H}:force_original_aspect_ratio=increase,` +
      `crop=${FRAME_W}:${FRAME_H},boxblur=40:1,` +
      `eq=brightness=-0.22:saturation=0.85,setsar=1,fps=30,${trim},format=yuv420p[bgblur]`,
    `[recB]scale=-2:${FRAME_H}:flags=lanczos,setsar=1,fps=30,${trim},format=yuv420p[fg]`,
    `[bgblur][fg]overlay=(W-w)/2:0[bg]`,
  );

  // Timed text overlays with alpha fade in/out.
  let currentLabel = "bg";
  p.overlays.forEach((ov, i) => {
    const inputIdx = overlayIndices[i]!;
    const isLast = i === p.overlays.length - 1;
    const outLabel = isLast ? "vout" : `v${i + 1}`;
    const fadeLabel = `ovfade${i}`;
    filterParts.push(fadingOverlayChain(inputIdx, ov.start, ov.duration, fadeLabel));
    filterParts.push(`[${currentLabel}][${fadeLabel}]overlay=0:0[${outLabel}]`);
    currentLabel = outLabel;
  });
  if (p.overlays.length === 0) {
    filterParts.push(`[bg]null[vout]`);
    currentLabel = "vout";
  }

  // Audio mix.
  const audioLabels: string[] = [];
  p.tracks.forEach((t, i) => {
    const label = `a${i}`;
    audioLabels.push(label);
    filterParts.push(
      audioFilterChain(audioIndices[i]!, label, p.duration, t.volume, 0, 0),
    );
  });
  let combined: string;
  if (audioLabels.length === 1) {
    combined = audioLabels[0]!;
  } else {
    combined = "amixed";
    filterParts.push(audioMixChain(audioLabels, combined));
  }
  const fadeOutStart = Math.max(0, p.duration - p.mix.fadeOut);
  const fadeParts: string[] = [];
  if (p.mix.fadeIn > 0) fadeParts.push(`afade=t=in:st=0:d=${p.mix.fadeIn.toFixed(3)}`);
  if (p.mix.fadeOut > 0)
    fadeParts.push(`afade=t=out:st=${fadeOutStart.toFixed(3)}:d=${p.mix.fadeOut.toFixed(3)}`);
  let aoutLabel: string;
  if (fadeParts.length) {
    aoutLabel = "aout";
    filterParts.push(`[${combined}]${fadeParts.join(",")}[${aoutLabel}]`);
  } else {
    aoutLabel = combined;
  }

  const filterComplex = filterParts.join(";\n");

  const args: string[] = [
    "-y",
    "-hide_banner",
    "-loglevel",
    p.debug ? "info" : "error",
  ];
  args.push(...inputs);
  args.push("-filter_complex", filterComplex);
  args.push("-map", `[${currentLabel}]`);
  args.push("-map", `[${aoutLabel}]`);
  args.push(
    "-t",
    p.duration.toFixed(3),
    "-r",
    "30",
    "-c:v",
    "libx264",
    "-pix_fmt",
    "yuv420p",
    "-preset",
    "medium",
    "-crf",
    "20",
    "-profile:v",
    "high",
    "-level",
    "4.1",
    "-c:a",
    "aac",
    "-b:a",
    "192k",
    "-ar",
    "48000",
    "-movflags",
    "+faststart",
    p.output,
  );

  await runFfmpeg(args, p.debug);
}
