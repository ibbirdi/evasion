import { readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import sharp from "sharp";

import { ASSET_DIRS } from "../config.js";
import { pathExists } from "../utils/fs.js";

const FRAME_W = 1080;
const FRAME_H = 1920;
const SAFE_MARGIN_X = 80;
// Texts overlay a full-bleed screen recording. "top" sits just below the
// social-app UI (TikTok/Reels reserve ~120 px) and above the in-app OASIS
// header. "bottom" sits just above the social-app bottom UI and over the top
// of the Oasis bottom bar — drop shadow keeps it readable on busy frames.
const TOP_TEXT_Y = 140;
const BOTTOM_TEXT_Y = 1640;

export type OverlayPosition = "top" | "center" | "bottom";

// SF Pro is Apple's system font and matches the in-app SwiftUI `.system()`
// face. It's a variable font containing every weight in a single .ttf —
// embedding it via @font-face in the SVG ensures sharp/librsvg uses it
// regardless of any other system font resolution oddities.
const SF_PRO_SYSTEM_PATHS = [
  "/System/Library/Fonts/SFNS.ttf",
  "/System/Library/Fonts/SFPro.ttf",
  "/System/Library/Fonts/SF-Pro.ttf",
];

let cachedFontFaceCss: string | null | undefined;

async function loadFontFaceCss(): Promise<string | null> {
  if (cachedFontFaceCss !== undefined) return cachedFontFaceCss;

  // 1. Optional user-supplied font overrides (drop a regular.ttf/bold.ttf in
  //    assets/fonts/ to swap to a custom brand typeface).
  const userOverrides: Array<{ name: string; weight: number; files: string[] }> = [
    { name: "OasisBody",    weight: 600, files: ["regular.ttf", "regular.otf"] },
    { name: "OasisDisplay", weight: 800, files: ["bold.ttf",    "bold.otf"] },
  ];

  const blocks: string[] = [];
  for (const candidate of userOverrides) {
    for (const f of candidate.files) {
      const fontPath = path.join(ASSET_DIRS.fonts, f);
      if (await pathExists(fontPath)) {
        const data = await readFile(fontPath);
        const ext = path.extname(f).slice(1).toLowerCase();
        const mime = ext === "otf" ? "font/otf" : "font/ttf";
        blocks.push(
          `@font-face { font-family: '${candidate.name}'; font-weight: ${candidate.weight}; src: url(data:${mime};base64,${data.toString("base64")}); }`,
        );
        break;
      }
    }
  }

  // 2. SF Pro (variable font). Loaded once, exposed as `SFPro` to the SVG.
  for (const sysPath of SF_PRO_SYSTEM_PATHS) {
    if (await pathExists(sysPath)) {
      const data = await readFile(sysPath);
      const b64 = data.toString("base64");
      // The variable axis covers all weights; we expose two named instances
      // (regular and bold) so the CSS `font-weight` picks the right glyphs.
      blocks.push(
        `@font-face { font-family: 'SFPro'; font-weight: 400 900; src: url(data:font/ttf;base64,${b64}); }`,
      );
      break;
    }
  }

  cachedFontFaceCss = blocks.length ? blocks.join("\n") : null;
  return cachedFontFaceCss;
}

function pickFontFamily(hasCustomFont: boolean, bold: boolean): string {
  if (hasCustomFont) {
    return bold
      ? "'OasisDisplay', 'OasisBody', 'SFPro', 'Helvetica Neue', sans-serif"
      : "'OasisBody', 'SFPro', 'Helvetica Neue', sans-serif";
  }
  return "'SFPro', 'SF Pro', '-apple-system', 'Helvetica Neue', sans-serif";
}

function escapeXml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

// Approximate char width per em, used for naive wrapping.
const CHAR_EM = 0.55;

function wrapText(text: string, fontSize: number, maxWidth: number): string[] {
  if (text.includes("\n")) return text.split("\n").map((l) => l.trim());
  const maxChars = Math.max(8, Math.floor(maxWidth / (fontSize * CHAR_EM)));
  if (text.length <= maxChars) return [text];

  const words = text.split(/\s+/);
  const lines: string[] = [];
  let current = "";
  for (const w of words) {
    const candidate = current ? `${current} ${w}` : w;
    if (candidate.length > maxChars && current) {
      lines.push(current);
      current = w;
    } else {
      current = candidate;
    }
  }
  if (current) lines.push(current);
  return lines;
}

export type OverlaySize = "sm" | "md" | "lg" | "xl" | "xxl";

// Absolute pixel sizes for the explicit `size` field on an overlay. When the
// scenario omits `size`, the renderer falls back to a position-based default.
const SIZE_PX: Record<OverlaySize, number> = {
  sm: 44,
  md: 68,
  lg: 100,
  xl: 150,
  xxl: 210,
};

function defaultFontSize(position: OverlayPosition): number {
  // Position-based defaults — tuned for body overlays sitting above/below
  // the simulator UI without clipping the OASIS header or bottom bar.
  if (position === "center") return 72;
  return 58;
}

export interface OverlayRenderOptions {
  text: string;
  position: OverlayPosition;
  size?: OverlaySize;
  bold?: boolean;
  /** Render a soft black gradient band behind the text for readability. */
  backdrop?: boolean;
  outPath: string;
}

export async function renderOverlayPng(opts: OverlayRenderOptions): Promise<void> {
  const fontFaceCss = await loadFontFaceCss();
  const hasCustomFont = fontFaceCss !== null;
  const bold = opts.bold ?? opts.position !== "bottom";
  const fontSize = opts.size ? SIZE_PX[opts.size] : defaultFontSize(opts.position);
  const fontFamily = pickFontFamily(hasCustomFont, bold);
  const lineHeight = Math.round(fontSize * 1.18);
  const maxWidth = FRAME_W - SAFE_MARGIN_X * 2;
  const lines = wrapText(opts.text, fontSize, maxWidth);

  const totalTextH = lines.length * lineHeight;
  let baselineY: number;
  switch (opts.position) {
    case "top":
      baselineY = TOP_TEXT_Y + fontSize;
      break;
    case "bottom":
      baselineY = BOTTOM_TEXT_Y + fontSize;
      break;
    default:
      baselineY = Math.round((FRAME_H - totalTextH) / 2) + fontSize;
  }

  const cx = FRAME_W / 2;

  const tspans = lines
    .map((line, idx) => {
      const dy = idx === 0 ? 0 : lineHeight;
      return `<tspan x="${cx}" dy="${dy}">${escapeXml(line)}</tspan>`;
    })
    .join("");

  // Optional gradient scrim — a tall band centred vertically on the text
  // that fades from transparent → soft black → transparent. Sits BEHIND the
  // text and provides reliable readability over busy app frames (mixer,
  // panels). Width spans the full frame; the vertical fade makes the band
  // dissolve into the recording rather than feel like a hard rectangle.
  const scrimPad = Math.round(fontSize * 1.4);
  const scrimTop = Math.max(0, baselineY - fontSize - scrimPad);
  const scrimHeight = Math.min(
    FRAME_H - scrimTop,
    totalTextH + scrimPad * 2,
  );
  const scrimSvg = opts.backdrop
    ? `<rect x="0" y="${scrimTop}" width="${FRAME_W}" height="${scrimHeight}" fill="url(#scrim)"/>`
    : "";

  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${FRAME_W}" height="${FRAME_H}" viewBox="0 0 ${FRAME_W} ${FRAME_H}">
  <defs>
    <style>
      ${fontFaceCss ?? ""}
      .t {
        font-family: ${fontFamily};
        font-weight: ${bold ? 800 : 600};
        font-size: ${fontSize}px;
        fill: #ffffff;
        letter-spacing: -0.5px;
        paint-order: stroke fill;
        stroke: rgba(0,0,0,0.18);
        stroke-width: 1.2px;
      }
    </style>
    <filter id="ds" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="14"/>
      <feOffset dx="0" dy="4" result="off"/>
      <feComponentTransfer><feFuncA type="linear" slope="0.9"/></feComponentTransfer>
      <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <linearGradient id="scrim" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%"   stop-color="#000000" stop-opacity="0"/>
      <stop offset="32%"  stop-color="#000000" stop-opacity="0.62"/>
      <stop offset="68%"  stop-color="#000000" stop-opacity="0.62"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </linearGradient>
  </defs>
  ${scrimSvg}
  <text class="t" text-anchor="middle" y="${baselineY}" filter="url(#ds)">${tspans}</text>
</svg>`;

  await writeFile(opts.outPath.replace(/\.png$/i, ".svg"), svg);
  await sharp(Buffer.from(svg, "utf-8"))
    .png({ compressionLevel: 9 })
    .toFile(opts.outPath);
}
