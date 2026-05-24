import { createHash } from "node:crypto";

export function clean(value: unknown): string {
  return String(value ?? "").trim();
}

export function normalizeToken(value: string): string {
  return clean(value).toLowerCase().replace(/^@/, "").replace(/\s+/g, "_");
}

export function firstName(name: string): string {
  const value = clean(name);
  if (!value) {
    return "";
  }
  return value.split(/\s+/)[0] ?? value;
}

export function numberFrom(value: string): number | null {
  const normalized = clean(value).replace(/\s/g, "").replace(",", ".");
  if (!normalized) {
    return null;
  }
  const match = normalized.match(/^([\d.]+)(k|m)?$/i);
  if (!match) {
    const direct = Number(normalized);
    return Number.isFinite(direct) ? direct : null;
  }
  const amount = Number(match[1]);
  if (!Number.isFinite(amount)) {
    return null;
  }
  const suffix = (match[2] ?? "").toLowerCase();
  if (suffix === "m") {
    return Math.round(amount * 1_000_000);
  }
  if (suffix === "k") {
    return Math.round(amount * 1_000);
  }
  return Math.round(amount);
}

export function containsAny(text: string, keywords: string[]): boolean {
  const haystack = clean(text).toLowerCase();
  return keywords.some((keyword) => haystack.includes(keyword.toLowerCase()));
}

export function maskPromoCode(code: string): string {
  const value = clean(code);
  if (value.length <= 6) {
    return value ? "***" : "";
  }
  return `${value.slice(0, 3)}...${value.slice(-4)}`;
}

export function shortHash(value: string): string {
  return createHash("sha1").update(value).digest("hex").slice(0, 8);
}

export function compactReason(parts: string[], maxParts = 4): string {
  return parts.filter(Boolean).slice(0, maxParts).join("; ");
}
