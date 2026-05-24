export function nowIso(): string {
  return new Date().toISOString();
}

export function todayStamp(date = new Date()): string {
  return date.toISOString().slice(0, 10);
}

export function daysBetween(isoDate: string, reference = new Date()): number | null {
  if (!isoDate) {
    return null;
  }
  const parsed = new Date(isoDate);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  const deltaMs = reference.getTime() - parsed.getTime();
  return Math.floor(deltaMs / 86_400_000);
}
