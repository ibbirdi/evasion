import { homedir } from "node:os";
import path from "node:path";

import { ROOT_DIR } from "../config.js";
import { FactoryError, log } from "../logger.js";
import { pathExists } from "../utils/fs.js";
import { probeMedia, runFfmpeg } from "../utils/ffmpeg.js";

const FRAME_W = 1080;
const FRAME_H = 1920;

/**
 * Resolves an intro path from a scenario:
 * - absolute paths are used as-is
 * - paths starting with `~` are expanded against `$HOME`
 * - relative paths are resolved against the marketing-video-factory root
 */
export function resolveIntroPath(raw: string): string {
  if (raw.startsWith("~")) return path.join(homedir(), raw.slice(1));
  if (path.isAbsolute(raw)) return raw;
  return path.resolve(ROOT_DIR, raw);
}

export interface IntroOverlay {
  /** Absolute path to the pre-rendered 1080×1920 transparent PNG. */
  pngPath: string;
  /** Visible window, in seconds from intro start. */
  start: number;
  duration: number;
}

export interface ConcatParams {
  introPath: string;
  introMaxDuration?: number;
  /** Optional overlays composited onto the intro segment only. */
  introOverlays?: IntroOverlay[];
  bodyPath: string;
  /** Optional end-card PNG appended via a second xfade. */
  outroPngPath?: string;
  outroDuration?: number;
  output: string;
  debug: boolean;
}

const XFADE_DURATION = 0.8;
const OVERLAY_FADE_DURATION = 0.35;

/**
 * Filter chain that fades an overlay PNG's alpha in and out around its
 * visible window. Output label is `outLabel`; the resulting stream is fed
 * straight into an `overlay` filter — no need for `enable=` on the overlay
 * itself because the alpha curve handles visibility cleanly.
 */
export function fadingOverlayChain(
  inputIdx: number,
  start: number,
  duration: number,
  outLabel: string,
): string {
  const fadeIn = Math.min(OVERLAY_FADE_DURATION, duration * 0.3);
  const fadeOut = Math.min(OVERLAY_FADE_DURATION, duration * 0.3);
  const end = start + duration;
  return (
    `[${inputIdx}:v]format=yuva420p,` +
    `fade=t=in:st=${start.toFixed(3)}:d=${fadeIn.toFixed(3)}:alpha=1,` +
    `fade=t=out:st=${(end - fadeOut).toFixed(3)}:d=${fadeOut.toFixed(3)}:alpha=1` +
    `[${outLabel}]`
  );
}

/**
 * Concatenates `intro + body` into `output`. The intro is scaled to fill the
 * 1080×1920 canvas and centre-cropped (same chain used on the scenario body's
 * raw simulator recording), so a 16:9 source fills the frame edge-to-edge and
 * loses its horizontal margins rather than leaving black bars.
 *
 * The body is re-encoded through identical scale/fps/format filters so the
 * concat filter sees matching stream params on both sides.
 */
export async function concatIntroAndBody(p: ConcatParams): Promise<void> {
  if (!(await pathExists(p.introPath))) {
    throw new FactoryError(
      `Intro video not found: ${p.introPath}`,
      "Check the `intro.path` in your scenario JSON. Relative paths resolve against marketing-video-factory/.",
    );
  }
  const intro = await probeMedia(p.introPath);
  const introTrim = Math.min(
    p.introMaxDuration ?? intro.durationSec,
    intro.durationSec,
  );
  log.debug(
    `intro: ${intro.width}x${intro.height} duration=${intro.durationSec.toFixed(2)}s hasAudio=${intro.hasAudio} trim=${introTrim.toFixed(2)}s`,
  );

  const trimClauseV = `,trim=duration=${introTrim.toFixed(3)},setpts=PTS-STARTPTS`;
  const trimClauseA = `,atrim=duration=${introTrim.toFixed(3)},asetpts=PTS-STARTPTS`;

  // Inputs:  [0] intro, [1] body, optionally [2] anullsrc when intro has no
  // audio, then one looped image input per intro overlay PNG.
  const inputs: string[] = ["-i", p.introPath, "-i", p.bodyPath];
  let introAudioInputLabel = "0:a";
  if (!intro.hasAudio) {
    inputs.push(
      "-f", "lavfi",
      "-t", introTrim.toFixed(3),
      "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
    );
    introAudioInputLabel = "2:a";
  }

  // Overlay PNG inputs — looped to span the intro's full duration. Their
  // alpha channel is faded in/out around each overlay's visible window.
  const overlays = p.introOverlays ?? [];
  const baseInputCount = intro.hasAudio ? 2 : 3;
  for (const ov of overlays) {
    inputs.push(
      "-loop", "1",
      "-t", introTrim.toFixed(3),
      "-i", ov.pngPath,
    );
  }
  const overlayIndices = overlays.map((_, i) => baseInputCount + i);

  // Outro inputs (optional): PNG looped for outroDuration + silent audio.
  const hasOutro = Boolean(p.outroPngPath && p.outroDuration);
  const outroDuration = p.outroDuration ?? 0;
  let outroVideoIdx: number | null = null;
  let outroAudioIdx: number | null = null;
  if (hasOutro && p.outroPngPath && outroDuration > 0) {
    outroVideoIdx = baseInputCount + overlays.length;
    outroAudioIdx = outroVideoIdx + 1;
    inputs.push(
      "-loop", "1",
      "-t", outroDuration.toFixed(3),
      "-i", p.outroPngPath,
      "-f", "lavfi",
      "-t", outroDuration.toFixed(3),
      "-i", "anullsrc=channel_layout=stereo:sample_rate=48000",
    );
  }

  const filterParts: string[] = [];

  // Intro video — scale to fill 1080×1920, centre-crop. The 16:9 source ends
  // up with its left and right edges cropped out; what remains fills the
  // vertical frame edge-to-edge with no letterboxing.
  const introBaseLabel = overlays.length > 0 ? "introbase" : "introv";
  filterParts.push(
    `[0:v]scale=${FRAME_W}:${FRAME_H}:force_original_aspect_ratio=increase,` +
      `crop=${FRAME_W}:${FRAME_H},setsar=1,fps=30${trimClauseV},format=yuv420p[${introBaseLabel}]`,
  );

  // Chain timed text overlays on the intro base, each with alpha fade in/out.
  let currentIntroLabel = introBaseLabel;
  overlays.forEach((ov, i) => {
    const inputIdx = overlayIndices[i]!;
    const isLast = i === overlays.length - 1;
    const outLabel = isLast ? "introv" : `iov${i + 1}`;
    const fadeLabel = `iofade${i}`;
    filterParts.push(fadingOverlayChain(inputIdx, ov.start, ov.duration, fadeLabel));
    filterParts.push(`[${currentIntroLabel}][${fadeLabel}]overlay=0:0[${outLabel}]`);
    currentIntroLabel = outLabel;
  });

  // Cross-fade between intro and body.
  const xfadeIntroBody = Math.min(XFADE_DURATION, Math.max(0.2, introTrim / 2));
  const xfadeIntroBodyOffset = Math.max(0, introTrim - xfadeIntroBody);

  filterParts.push(
    // Intro audio — resample to a fixed format so the crossfade sees matching params.
    `[${introAudioInputLabel}]aresample=48000:async=1,aformat=channel_layouts=stereo:sample_fmts=fltp${trimClauseA}[introa]`,
    // Body — already 1080×1920 / 30fps / yuv420p (post-processed by
    // postProcess.ts). Normalize stream params just in case so xfade sees
    // identical inputs on both sides.
    `[1:v]scale=${FRAME_W}:${FRAME_H},setsar=1,fps=30,format=yuv420p[bodyv]`,
    `[1:a]aresample=48000:async=1,aformat=channel_layouts=stereo:sample_fmts=fltp[bodya]`,
  );

  if (!hasOutro) {
    // Two-segment chain (intro → body).
    filterParts.push(
      `[introv][bodyv]xfade=transition=fade:duration=${xfadeIntroBody.toFixed(3)}:offset=${xfadeIntroBodyOffset.toFixed(3)}[outv]`,
      `[introa][bodya]acrossfade=d=${xfadeIntroBody.toFixed(3)}:c1=tri:c2=tri[outa]`,
    );
  } else {
    // Three-segment chain (intro → body → outro). The body's frame 0 lands at
    // output time `xfadeIntroBodyOffset`. The body ends on the output timeline
    // at `xfadeIntroBodyOffset + bodyDuration`. We crossfade the outro into
    // the body at `bodyEnd - xfadeBodyOutro`, where `xfadeBodyOutro` is also
    // clamped to half the outro length to stay valid.
    const xfadeBodyOutro = Math.min(XFADE_DURATION, Math.max(0.2, outroDuration / 2));

    filterParts.push(
      // Outro: PNG already 1080×1920. Normalize params before the second xfade.
      `[${outroVideoIdx}:v]scale=${FRAME_W}:${FRAME_H},setsar=1,fps=30,format=yuv420p[outrov]`,
      `[${outroAudioIdx}:a]aresample=48000:async=1,aformat=channel_layouts=stereo:sample_fmts=fltp[outroa]`,

      // First xfade: intro → body. Intermediate stream is `[ibv]/[iba]`.
      `[introv][bodyv]xfade=transition=fade:duration=${xfadeIntroBody.toFixed(3)}:offset=${xfadeIntroBodyOffset.toFixed(3)}[ibv]`,
      `[introa][bodya]acrossfade=d=${xfadeIntroBody.toFixed(3)}:c1=tri:c2=tri[iba]`,
    );

    // Total length of intro+body after first xfade = xfadeIntroBodyOffset + bodyDuration.
    // But we don't know bodyDuration here — it'll be probed at runtime. Approximate:
    // we can use ffprobe synchronously. Cleaner: probe body and compute offset.
    const bodyProbe = await probeMedia(p.bodyPath);
    const bodyDuration = bodyProbe.durationSec;
    const ibLength = xfadeIntroBodyOffset + bodyDuration;
    const xfadeBodyOutroOffset = Math.max(0, ibLength - xfadeBodyOutro);

    filterParts.push(
      // Second xfade: (intro+body) → outro.
      `[ibv][outrov]xfade=transition=fade:duration=${xfadeBodyOutro.toFixed(3)}:offset=${xfadeBodyOutroOffset.toFixed(3)}[outv]`,
      `[iba][outroa]acrossfade=d=${xfadeBodyOutro.toFixed(3)}:c1=tri:c2=tri[outa]`,
    );
  }

  const args: string[] = [
    "-y", "-hide_banner",
    "-loglevel", p.debug ? "info" : "error",
  ];
  args.push(...inputs);
  args.push("-filter_complex", filterParts.join(";\n"));
  args.push("-map", "[outv]", "-map", "[outa]");
  args.push(
    "-r", "30",
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    "-preset", "medium",
    "-crf", "20",
    "-profile:v", "high",
    "-level", "4.1",
    "-c:a", "aac",
    "-b:a", "192k",
    "-ar", "48000",
    "-movflags", "+faststart",
    p.output,
  );

  log.info(
    `Concatenating intro (${introTrim.toFixed(1)}s) + scenario (${path.basename(p.bodyPath)}) → ${path.basename(p.output)}`,
  );
  await runFfmpeg(args, p.debug);
}
