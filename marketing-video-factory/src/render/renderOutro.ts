import { readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import path from "node:path";

import sharp from "sharp";

import { ASSETS_DIR, ROOT_DIR } from "../config.js";
import { FactoryError } from "../logger.js";
import { pathExists } from "../utils/fs.js";

const FRAME_W = 1080;
const FRAME_H = 1920;
const DEFAULT_SVG = path.join(ASSETS_DIR, "branding", "oasis-end-card.svg");

const SF_PRO_SYSTEM_PATHS = [
  "/System/Library/Fonts/SFNS.ttf",
  "/System/Library/Fonts/SFPro.ttf",
  "/System/Library/Fonts/SF-Pro.ttf",
];

let cachedSfProDataUri: string | null | undefined;

async function loadSfProDataUri(): Promise<string | null> {
  if (cachedSfProDataUri !== undefined) return cachedSfProDataUri;
  for (const sysPath of SF_PRO_SYSTEM_PATHS) {
    if (await pathExists(sysPath)) {
      const data = await readFile(sysPath);
      cachedSfProDataUri = `data:font/ttf;base64,${data.toString("base64")}`;
      return cachedSfProDataUri;
    }
  }
  cachedSfProDataUri = null;
  return null;
}

export function resolveOutroSvgPath(raw: string | undefined): string {
  if (!raw) return DEFAULT_SVG;
  if (raw.startsWith("~")) return path.join(homedir(), raw.slice(1));
  if (path.isAbsolute(raw)) return raw;
  return path.resolve(ROOT_DIR, raw);
}

/**
 * Builds the SVG `d` attribute for a true sinusoid wave. Cubic-bezier
 * approximations look peaky at this scale; sampling sin() at ~3 px granularity
 * yields a curve that's visually indistinguishable from the in-app render.
 */
function buildWavePath(opts: {
  xStart: number;
  width: number;
  yBase: number;
  amplitude: number;
  cycles: number;
  samples: number;
}): string {
  const { xStart, width, yBase, amplitude, cycles, samples } = opts;
  const points: string[] = [];
  for (let i = 0; i <= samples; i++) {
    const t = i / samples;
    const x = xStart + t * width;
    // Y axis is inverted in SVG (downward positive), so subtract for a wave
    // that swings upward at its first peak.
    const y = yBase - Math.sin(t * Math.PI * 2 * cycles) * amplitude;
    points.push(`${x.toFixed(2)},${y.toFixed(2)}`);
  }
  return `M ${points[0]} L ${points.slice(1).join(" ")}`;
}

/**
 * Renders the outro SVG to a 1080×1920 PNG that FFmpeg can loop. Before
 * rasterising:
 *   1. injects an `@font-face` for SFPro so the bundled font resolves
 *      regardless of librsvg's system-font discovery quirks
 *   2. replaces the `__WAVE_PATH__` placeholder with a true sin() polyline
 *      (cubic-bezier approximations were too peaky compared to the in-app
 *      `WaveformSignatureLine`).
 */
export async function renderOutroPng(svgPath: string, outPath: string): Promise<void> {
  if (!(await pathExists(svgPath))) {
    throw new FactoryError(
      `Outro SVG not found: ${svgPath}`,
      `Check the scenario's outro.svg path. Relative paths resolve against the marketing-video-factory root.`,
    );
  }
  const raw = await readFile(svgPath, "utf-8");
  const fontUri = await loadSfProDataUri();

  let prepared = raw;

  // 1. SF Pro @font-face.
  if (fontUri) {
    const fontFaceBlock = `<style>@font-face { font-family: 'SFPro'; font-weight: 400 900; src: url(${fontUri}); }</style>`;
    if (prepared.includes("<defs>")) {
      prepared = prepared.replace("<defs>", `<defs>${fontFaceBlock}`);
    } else {
      prepared = prepared.replace(/<svg[^>]*>/, (m) => `${m}<defs>${fontFaceBlock}</defs>`);
    }
  }

  // 2. Wave path. Centred horizontally on the OASIS text (≈ 700 px wide,
  // x ∈ [190, 890]); 5 cycles, amplitude tuned to feel proportionate to the
  // 190 px wordmark above; baseline at y=1020 (just below the text baseline).
  const wavePath = buildWavePath({
    xStart: 190,
    width: 700,
    yBase: 1020,
    amplitude: 26,
    cycles: 3,
    samples: 240,
  });
  prepared = prepared.replace("__WAVE_PATH__", wavePath);

  await writeFile(outPath.replace(/\.png$/i, ".svg"), prepared);
  await sharp(Buffer.from(prepared, "utf-8"))
    .resize(FRAME_W, FRAME_H, { fit: "cover" })
    .png({ compressionLevel: 9 })
    .toFile(outPath);
}

export const DEFAULT_OUTRO_DURATION = 2.6;
