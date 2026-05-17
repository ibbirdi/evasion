import { execa } from "execa";

import { FactoryError, log } from "../logger.js";

let cachedFfmpeg: string | null = null;
let cachedFfprobe: string | null = null;

export async function resolveFfmpeg(): Promise<string> {
  if (cachedFfmpeg) return cachedFfmpeg;
  try {
    const { stdout } = await execa("which", ["ffmpeg"]);
    const p = stdout.trim();
    if (!p) throw new Error("empty");
    cachedFfmpeg = p;
    return p;
  } catch {
    throw new FactoryError(
      "FFmpeg not found on PATH.",
      "Install it on macOS with: brew install ffmpeg",
    );
  }
}

export async function resolveFfprobe(): Promise<string> {
  if (cachedFfprobe) return cachedFfprobe;
  try {
    const { stdout } = await execa("which", ["ffprobe"]);
    const p = stdout.trim();
    if (!p) throw new Error("empty");
    cachedFfprobe = p;
    return p;
  } catch {
    throw new FactoryError(
      "ffprobe not found on PATH (usually shipped with FFmpeg).",
      "Reinstall FFmpeg on macOS with: brew reinstall ffmpeg",
    );
  }
}

export interface MediaInfo {
  durationSec: number;
  width: number | null;
  height: number | null;
  hasAudio: boolean;
}

export async function probeMedia(file: string): Promise<MediaInfo> {
  const ffprobe = await resolveFfprobe();
  const { stdout } = await execa(ffprobe, [
    "-v",
    "error",
    "-show_entries",
    "stream=codec_type,width,height:format=duration",
    "-of",
    "json",
    file,
  ]);
  type ProbeOut = {
    streams?: Array<{ codec_type?: string; width?: number; height?: number }>;
    format?: { duration?: string };
  };
  const parsed: ProbeOut = JSON.parse(stdout);
  const videoStream = parsed.streams?.find((s) => s.codec_type === "video");
  const hasAudio = !!parsed.streams?.find((s) => s.codec_type === "audio");
  const duration = Number(parsed.format?.duration ?? "0");
  return {
    durationSec: Number.isFinite(duration) ? duration : 0,
    width: videoStream?.width ?? null,
    height: videoStream?.height ?? null,
    hasAudio,
  };
}

export async function runFfmpeg(args: string[], debug = false): Promise<void> {
  const ffmpeg = await resolveFfmpeg();
  log.debug(`ffmpeg ${args.map((a) => (a.includes(" ") ? `"${a}"` : a)).join(" ")}`);
  try {
    await execa(ffmpeg, args, {
      stdio: debug ? "inherit" : "pipe",
    });
  } catch (err: unknown) {
    const e = err as { stderr?: string; message?: string };
    const tail = (e.stderr ?? "").split("\n").slice(-12).join("\n");
    throw new FactoryError(
      `FFmpeg failed: ${e.message ?? "unknown error"}`,
      tail ? `Last lines:\n${tail}` : undefined,
    );
  }
}
