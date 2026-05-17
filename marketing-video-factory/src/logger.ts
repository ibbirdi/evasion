const COLORS = {
  reset: "\x1b[0m",
  dim: "\x1b[2m",
  bold: "\x1b[1m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
  gray: "\x1b[90m",
} as const;

const isTTY = process.stdout.isTTY;
const color = (c: keyof typeof COLORS, s: string) =>
  isTTY ? `${COLORS[c]}${s}${COLORS.reset}` : s;

let DEBUG = false;
export function setDebug(on: boolean): void {
  DEBUG = on;
}

export const log = {
  banner(title: string): void {
    const line = "━".repeat(Math.max(8, Math.min(60, title.length + 4)));
    process.stdout.write(`\n${color("cyan", line)}\n`);
    process.stdout.write(`${color("cyan", `  ${title}`)}\n`);
    process.stdout.write(`${color("cyan", line)}\n`);
  },
  info(msg: string): void {
    process.stdout.write(`${color("blue", "→")} ${msg}\n`);
  },
  step(label: string, value: string): void {
    process.stdout.write(
      `  ${color("gray", label.padEnd(16))} ${color("bold", value)}\n`,
    );
  },
  success(msg: string): void {
    process.stdout.write(`${color("green", "✓")} ${msg}\n`);
  },
  warn(msg: string): void {
    process.stdout.write(`${color("yellow", "!")} ${msg}\n`);
  },
  error(msg: string): void {
    process.stderr.write(`${color("red", "✗")} ${color("red", msg)}\n`);
  },
  hint(msg: string): void {
    process.stdout.write(`  ${color("dim", "↳ " + msg)}\n`);
  },
  debug(msg: string): void {
    if (DEBUG) process.stdout.write(`${color("magenta", "·")} ${color("dim", msg)}\n`);
  },
  plain(msg: string): void {
    process.stdout.write(`${msg}\n`);
  },
};

export class FactoryError extends Error {
  readonly hint?: string;
  constructor(message: string, hint?: string) {
    super(message);
    this.name = "FactoryError";
    if (hint) this.hint = hint;
  }
}

export function reportError(err: unknown): void {
  if (err instanceof FactoryError) {
    log.error(err.message);
    if (err.hint) log.hint(err.hint);
    if (DEBUG && err.stack) log.debug(err.stack);
    return;
  }
  if (err instanceof Error) {
    log.error(err.message);
    if (DEBUG && err.stack) log.debug(err.stack);
    return;
  }
  log.error(String(err));
}
