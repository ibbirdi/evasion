import { writeFile } from "node:fs/promises";

import type { VideoMetadata } from "../types.js";

export async function writeMetadataJson(
  outPath: string,
  meta: VideoMetadata,
): Promise<void> {
  await writeFile(outPath, JSON.stringify(meta, null, 2) + "\n", "utf-8");
}

export function buildCaptionBlock(meta: VideoMetadata): string {
  return [meta.caption, "", meta.hashtags.join(" ")].join("\n");
}
