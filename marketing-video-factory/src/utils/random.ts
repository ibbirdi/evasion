// Mulberry32 — small deterministic PRNG. Seeded for reproducible runs.
export function createRng(seed: number): () => number {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function randomSeed(): number {
  return Math.floor(Math.random() * 2 ** 31);
}

export function makePicker(rng: () => number): (n: number) => number {
  return (n) => Math.floor(rng() * n);
}

export function pickOne<T>(rng: () => number, arr: readonly T[]): T {
  if (arr.length === 0) throw new Error("pickOne called on empty array.");
  const idx = Math.floor(rng() * arr.length);
  return arr[idx]!;
}
