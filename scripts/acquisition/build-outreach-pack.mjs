#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_PLAN = "scripts/acquisition/outreach-plan.json";
const DEFAULT_OUT_DIR = "scripts/acquisition/outreach-pack";
const APP_STORE_BASE_URL = "https://apps.apple.com/app/apple-store/id6759493932";

const localizedSignoffs = {
  "fr-FR": "Jonathan\nDeveloppeur solo d'Oasis",
  "de-DE": "Jonathan\nSolo developer of Oasis",
  "es-ES": "Jonathan\nDesarrollador independiente de Oasis",
  multi: "Jonathan\nSolo developer of Oasis",
  "en-US": "Jonathan\nSolo developer of Oasis",
};

function parseArgs(argv) {
  const args = {
    plan: DEFAULT_PLAN,
    outDir: DEFAULT_OUT_DIR,
    date: new Date().toISOString().slice(0, 10),
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--plan") {
      args.plan = next;
      i += 1;
    } else if (arg === "--out-dir") {
      args.outDir = next;
      i += 1;
    } else if (arg === "--date") {
      args.date = next;
      i += 1;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(args.date)) throw new Error("--date must be YYYY-MM-DD");
  return args;
}

function printHelp() {
  console.log(`Oasis outreach pack

Usage:
  node scripts/acquisition/build-outreach-pack.mjs
  node scripts/acquisition/build-outreach-pack.mjs --date 2026-05-22

Options:
  --plan <path>       Outreach plan JSON. Default: ${DEFAULT_PLAN}
  --out-dir <path>    Output folder. Default: ${DEFAULT_OUT_DIR}
  --date <YYYY-MM-DD> Pack date. Default: today UTC
`);
}

async function readJson(relativePath) {
  const raw = await fs.readFile(path.resolve(REPO_ROOT, relativePath), "utf8");
  return JSON.parse(raw);
}

function appStoreLink(campaign) {
  const url = new URL(APP_STORE_BASE_URL);
  url.searchParams.set("ct", campaign);
  url.searchParams.set("mt", "8");
  return url.toString();
}

function csvEscape(value) {
  const text = String(value ?? "");
  return /[",\n]/u.test(text) ? `"${text.replace(/"/g, '""')}"` : text;
}

function renderCsv(rows) {
  const columns = Object.keys(rows[0] || {});
  return [
    columns.join(","),
    ...rows.map((row) => columns.map((column) => csvEscape(row[column])).join(",")),
  ].join("\n") + "\n";
}

function renderMessage(track) {
  const link = appStoreLink(track.campaign);
  if (track.locale === "fr-FR") {
    return [
      "Bonjour,",
      "",
      "Je suis Jonathan, le developpeur solo d'Oasis. Je vous contacte car votre veille autour des apps iPhone et des outils calmes semble proche du public pour lequel j'ai construit l'app.",
      "",
      `${track.angle} Oasis propose 35 sons de nature, 4 pistes binaurales, des presets, un timer, la lecture en arriere-plan, et fonctionne hors ligne. Le deblocage complet se fait avec un achat unique, sans abonnement.`,
      "",
      `Lien App Store suivi: ${link}`,
      "",
      "Si cela peut convenir a une selection, un test, ou une rubrique autour des apps utiles sans abonnement, je peux envoyer plus d'informations ou des visuels.",
      "",
      localizedSignoffs[track.locale],
    ].join("\n");
  }

  if (track.locale === "es-ES") {
    return [
      "Hola,",
      "",
      "Soy Jonathan, el desarrollador independiente de Oasis. Te escribo porque tu contenido sobre apps utiles, descanso o productividad parece encajar con la app.",
      "",
      `${track.angle} Oasis incluye 35 sonidos de naturaleza, 4 pistas binaurales, presets, temporizador, reproduccion en segundo plano y audio offline. El desbloqueo completo es una compra unica, sin suscripcion.`,
      "",
      `Tracked App Store link: ${link}`,
      "",
      "Si puede encajar en una seleccion, prueba o recomendacion, puedo enviar mas detalles y material visual.",
      "",
      localizedSignoffs[track.locale],
    ].join("\n");
  }

  return [
    "Hi,",
    "",
    "I am Jonathan, the solo developer of Oasis. I am reaching out because your work around useful apps, calm software, sleep, focus, or iPhone tools looks like a good fit for the app.",
    "",
    `${track.angle} Oasis includes 35 nature sounds, 4 binaural tracks, presets, a timer, background playback, and offline audio. The full unlock is a one-time purchase, not a subscription.`,
    "",
    `Tracked App Store link: ${link}`,
    "",
    "If it fits an app roundup, a short review, or a useful-tools mention, I can send more context, screenshots, or short videos.",
    "",
    localizedSignoffs[track.locale] || localizedSignoffs["en-US"],
  ].join("\n");
}

function renderReadme(plan, pack) {
  const lines = [
    "# Oasis Outreach Pack",
    "",
    `Generated: ${pack.generatedAt}`,
    `Date: ${pack.date}`,
    "",
    "Manual outreach only. This pack generates target categories, campaign links, and drafts; it does not send anything.",
    "",
    "## Rules",
    "",
    `- ${plan.policy.automation}`,
    `- ${plan.policy.personalization}`,
    `- ${plan.policy.disclosure}`,
    `- ${plan.policy.claims}`,
    "",
    "## Tracks",
    "",
    "| Track | Locale | Campaign | Expected downloads | Link |",
    "| --- | --- | --- | ---: | --- |",
  ];

  for (const row of pack.rows) {
    lines.push(`| ${row.label} | ${row.locale} | ${row.campaign} | ${row.expectedDownloads} | ${row.appStoreLink} |`);
  }

  lines.push(
    "",
    "## Workflow",
    "",
    "1. Pick 5-10 real outlets/creators from one track.",
    "2. Add names, contact URLs, and notes to `targets.csv`.",
    "3. Personalize the matching draft in `messages/`.",
    "4. Send manually from Jonathan's real account.",
    "5. Record live mentions or sent pitches with `record-publication.mjs` using the track campaign token.",
    "",
    "## Files",
    "",
    "- `targets.csv`: target categories and tracking links.",
    "- `messages/`: per-track message drafts.",
  );

  return `${lines.join("\n").trim()}\n`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const plan = await readJson(args.plan);
  const outputDir = path.resolve(REPO_ROOT, args.outDir, args.date);
  const messagesDir = path.join(outputDir, "messages");
  await fs.mkdir(messagesDir, { recursive: true });

  const rows = plan.tracks.map((track) => ({
    id: track.id,
    label: track.label,
    locale: track.locale,
    campaign: track.campaign,
    expectedDownloads: track.expectedDownloads,
    targetCategories: track.targets.join("|"),
    angle: track.angle,
    subject: track.subject,
    appStoreLink: appStoreLink(track.campaign),
    contactName: "",
    contactUrl: "",
    status: "research",
    sentAt: "",
    resultUrl: "",
    notes: "",
  }));

  const pack = {
    generatedAt: new Date().toISOString(),
    date: args.date,
    rows,
  };

  await fs.writeFile(path.join(outputDir, "targets.csv"), renderCsv(rows));
  await fs.writeFile(path.join(outputDir, "outreach-pack.json"), `${JSON.stringify({ ...pack, policy: plan.policy }, null, 2)}\n`);
  await fs.writeFile(path.join(outputDir, "README.md"), renderReadme(plan, pack));

  for (const track of plan.tracks) {
    await fs.writeFile(path.join(messagesDir, `${track.id}.txt`), renderMessage(track));
  }

  console.log(`Wrote ${outputDir}`);
  console.log(`Tracks: ${rows.length}`);
  console.log(`Expected downloads: ${rows.reduce((total, row) => total + Number(row.expectedDownloads || 0), 0)}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
