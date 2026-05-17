import { access, mkdir, readdir, rm, stat } from "node:fs/promises";
import path from "node:path";

export async function ensureDir(dir: string): Promise<void> {
  await mkdir(dir, { recursive: true });
}

export async function pathExists(p: string): Promise<boolean> {
  try {
    await access(p);
    return true;
  } catch {
    return false;
  }
}

export async function isFile(p: string): Promise<boolean> {
  try {
    const s = await stat(p);
    return s.isFile();
  } catch {
    return false;
  }
}

export async function listFiles(
  dir: string,
  extensions?: readonly string[],
): Promise<string[]> {
  if (!(await pathExists(dir))) return [];
  const entries = await readdir(dir, { withFileTypes: true });
  const files: string[] = [];
  for (const e of entries) {
    if (e.name.startsWith(".")) continue;
    if (
      extensions &&
      !extensions.some((ext) => e.name.toLowerCase().endsWith(ext.toLowerCase()))
    )
      continue;
    const full = path.join(dir, e.name);
    // Resolve symlinks: include the entry if the target is a regular file.
    if (e.isFile()) {
      files.push(full);
      continue;
    }
    if (e.isSymbolicLink()) {
      try {
        const s = await stat(full);
        if (s.isFile()) files.push(full);
      } catch {
        // dangling symlink — skip silently
      }
    }
  }
  return files.sort();
}

export async function removeIfExists(p: string): Promise<void> {
  if (await pathExists(p)) {
    await rm(p, { recursive: true, force: true });
  }
}
