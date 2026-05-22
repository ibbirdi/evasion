#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_QUEUE = "scripts/acquisition/global-publishing-queue.json";
const TEXT_ASSETS = new Set(["text/link post", "community-radar opportunity only", "No ready video asset"]);

const TITLE_TEMPLATES = {
  "fr-FR": {
    sleep: "Oasis: pluie douce et sons de nature",
    premium: "Oasis: une app calme sans abonnement",
    spatial: "Oasis: place la pluie autour de toi",
  },
  "en-US": {
    sleep: "Oasis: soft rain and nature sounds",
    premium: "Oasis: calm sounds, no subscription",
    spatial: "Oasis: place rain around you",
  },
  "de-DE": {
    sleep: "Oasis: Regen und Naturklänge",
    premium: "Oasis: ruhige Sounds ohne Abo",
    spatial: "Oasis: Regen um dich herum platzieren",
  },
  "es-ES": {
    sleep: "Oasis: lluvia y sonidos de naturaleza",
    premium: "Oasis: sonidos tranquilos sin suscripción",
    spatial: "Oasis: coloca la lluvia a tu alrededor",
  },
  it: {
    sleep: "Oasis: pioggia e suoni della natura",
    premium: "Oasis: suoni calmi senza abbonamento",
    spatial: "Oasis: posiziona la pioggia intorno a te",
  },
  "pt-BR": {
    sleep: "Oasis: chuva e sons da natureza",
    premium: "Oasis: sons calmos sem assinatura",
    spatial: "Oasis: posicione a chuva ao seu redor",
  },
};

const TAGS = {
  "fr-FR": ["oasis", "sommeil", "pluie", "bruit blanc", "sons de nature", "sans abonnement", "app iOS"],
  "en-US": ["oasis", "sleep sounds", "rain sounds", "white noise", "nature sounds", "no subscription", "iOS app"],
  "de-DE": ["oasis", "schlaf", "regen", "naturklange", "weisses rauschen", "ohne abo", "iOS app"],
  "es-ES": ["oasis", "sonidos para dormir", "lluvia", "ruido blanco", "naturaleza", "sin suscripcion", "app iOS"],
  it: ["oasis", "suoni per dormire", "pioggia", "rumore bianco", "natura", "senza abbonamento", "app iOS"],
  "pt-BR": ["oasis", "sons para dormir", "chuva", "ruido branco", "natureza", "sem assinatura", "app iOS"],
};

const HASHTAGS = {
  "fr-FR": "#Shorts #sommeil #pluie #bruitblanc #iphone #appios #sansabonnement",
  "en-US": "#Shorts #sleep #rainsounds #whitenoise #iphone #iosapp #nosubscription",
  "de-DE": "#Shorts #schlaf #regen #naturklange #iphone #iosapp #ohneabo",
  "es-ES": "#Shorts #suenos #lluvia #ruidoblanco #iphone #appios #sinsuscripcion",
  it: "#Shorts #sonno #pioggia #rumorebianco #iphone #appios #senzaabbonamento",
  "pt-BR": "#Shorts #sono #chuva #ruidobranco #iphone #appios #semassinatura",
};

const CTAS = {
  "fr-FR": "Télécharger Oasis pour iPhone:",
  "en-US": "Download Oasis for iPhone:",
  "de-DE": "Oasis für iPhone laden:",
  "es-ES": "Descarga Oasis para iPhone:",
  it: "Scarica Oasis per iPhone:",
  "pt-BR": "Baixe Oasis para iPhone:",
};

function parseArgs(argv) {
  const args = {
    queue: DEFAULT_QUEUE,
    campaign: "",
    channel: "",
    date: "",
    language: "",
    privacy: "public",
    notifySubscribers: false,
    publishAt: "",
    publish: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--queue") {
      args.queue = next;
      i += 1;
    } else if (arg === "--campaign") {
      args.campaign = next;
      i += 1;
    } else if (arg === "--channel") {
      args.channel = next;
      i += 1;
    } else if (arg === "--date") {
      args.date = next;
      i += 1;
    } else if (arg === "--language") {
      args.language = next;
      i += 1;
    } else if (arg === "--privacy") {
      args.privacy = next;
      i += 1;
    } else if (arg === "--publish-at") {
      args.publishAt = next;
      i += 1;
    } else if (arg === "--notify-subscribers") {
      args.notifySubscribers = true;
    } else if (arg === "--publish") {
      args.publish = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!["public", "unlisted", "private"].includes(args.privacy)) {
    throw new Error("--privacy must be public, unlisted, or private");
  }
  if (args.publishAt && Number.isNaN(Date.parse(args.publishAt))) {
    throw new Error("--publish-at must be an ISO date/time");
  }

  return args;
}

function printHelp() {
  console.log(`Oasis video publisher

Dry-run by default. Use --publish only when the target account credentials are configured.

Usage:
  node scripts/acquisition/build-global-publishing-queue.mjs --format json --out scripts/acquisition/global-publishing-queue.json
  node scripts/acquisition/publish-video-post.mjs --campaign shorts_no_subscription_es --channel youtube
  node scripts/acquisition/publish-video-post.mjs --campaign shorts_no_subscription_es --channel youtube --publish

Selection options:
  --queue <path>       Queue JSON path. Default: ${DEFAULT_QUEUE}
  --campaign <id>      Exact queue campaign id
  --channel <name>     Channel label/id fragment, e.g. youtube
  --date <YYYY-MM-DD>  Queue date
  --language <locale>  Queue language id, e.g. en-US

Publishing options:
  --privacy <status>        public, unlisted, or private. Default: public
  --publish-at <ISO time>   Schedule on YouTube. Forces privacyStatus=private.
  --notify-subscribers      YouTube notification flag. Default: false
  --publish                 Actually publish via official API

YouTube env:
  YOUTUBE_ACCESS_TOKEN      OAuth token with youtube.upload scope
  or:
  YOUTUBE_CLIENT_ID
  YOUTUBE_CLIENT_SECRET
  YOUTUBE_REFRESH_TOKEN

Notes:
  TikTok and Meta video publishing still require their official account/audit/hosting flows.
`);
}

async function readQueue(relativePath) {
  const absolute = path.resolve(REPO_ROOT, relativePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function allSlots(queue) {
  if (Array.isArray(queue.slots)) return queue.slots;
  return (queue.days || []).flatMap((day) =>
    (day.slots || []).map((slot) => ({
      ...slot,
      date: day.date,
      language: slot.language || day.language?.id,
      market: slot.market || day.language?.market,
    })),
  );
}

function normalize(value) {
  return String(value || "").toLowerCase().replace(/[^a-z0-9]+/g, "_");
}

function isVideoSlot(slot) {
  return slot.asset && !TEXT_ASSETS.has(slot.asset);
}

function selectSlot(queue, args) {
  let slots = allSlots(queue).filter(isVideoSlot);
  if (args.campaign) {
    slots = slots.filter((slot) => slot.campaign === args.campaign);
  }
  if (args.channel) {
    const channel = normalize(args.channel);
    slots = slots.filter((slot) => normalize(slot.channel).includes(channel));
  }
  if (args.date) {
    slots = slots.filter((slot) => slot.date === args.date);
  }
  if (args.language) {
    slots = slots.filter((slot) => slot.language === args.language);
  }

  if (slots.length === 0) {
    throw new Error("No video queue slot matched the selection.");
  }
  if (slots.length > 1 && !args.campaign) {
    const options = slots.slice(0, 10).map((slot) => `- ${slot.date} ${slot.channel}: ${slot.campaign}`).join("\n");
    throw new Error(`Selection matched ${slots.length} video slots. Narrow with --campaign.\n${options}`);
  }

  return slots[0];
}

function inferAngle(slot) {
  const campaign = slot.campaign || "";
  if (campaign.includes("no_subscription")) return "premium";
  if (campaign.includes("spatial")) return "spatial";
  return "sleep";
}

function truncateTitle(title) {
  return title.length <= 100 ? title : `${title.slice(0, 97).trim()}...`;
}

function buildMetadata(slot, args) {
  const language = slot.language || "en-US";
  const angle = inferAngle(slot);
  const title = truncateTitle(TITLE_TEMPLATES[language]?.[angle] || TITLE_TEMPLATES["en-US"][angle]);
  const tags = TAGS[language] || TAGS["en-US"];
  const hashtags = HASHTAGS[language] || HASHTAGS["en-US"];
  const cta = CTAS[language] || CTAS["en-US"];
  const description = `${slot.copy}\n\n${cta}\n${slot.link}\n\n${hashtags}`.trim();
  const status = {
    privacyStatus: args.publishAt ? "private" : args.privacy,
    selfDeclaredMadeForKids: false,
    // The video includes generated intro footage plus real app footage; be conservative and declare it.
    containsSyntheticMedia: true,
  };
  if (args.publishAt) {
    status.publishAt = new Date(args.publishAt).toISOString();
  }

  return {
    asset: slot.asset,
    mimeType: "video/mp4",
    request: {
      snippet: {
        title,
        description,
        tags,
        categoryId: "22",
        defaultLanguage: language,
      },
      status,
    },
  };
}

async function assertAsset(asset) {
  const absolute = path.resolve(REPO_ROOT, asset);
  const stat = await fs.stat(absolute);
  if (!stat.isFile()) throw new Error(`Asset is not a file: ${asset}`);
  return { absolute, size: stat.size };
}

function multipartBody(metadata, videoBuffer) {
  const boundary = `oasis_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  const head = Buffer.from(
    `--${boundary}\r\n` +
      "Content-Type: application/json; charset=UTF-8\r\n\r\n" +
      `${JSON.stringify(metadata.request)}\r\n` +
      `--${boundary}\r\n` +
      `Content-Type: ${metadata.mimeType}\r\n\r\n`,
    "utf8",
  );
  const tail = Buffer.from(`\r\n--${boundary}--\r\n`, "utf8");
  return { boundary, body: Buffer.concat([head, videoBuffer, tail]) };
}

async function youtubeAccessToken() {
  if (process.env.YOUTUBE_ACCESS_TOKEN) return process.env.YOUTUBE_ACCESS_TOKEN;

  const clientId = process.env.YOUTUBE_CLIENT_ID;
  const clientSecret = process.env.YOUTUBE_CLIENT_SECRET;
  const refreshToken = process.env.YOUTUBE_REFRESH_TOKEN;
  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error("Missing YOUTUBE_ACCESS_TOKEN or YOUTUBE_CLIENT_ID/YOUTUBE_CLIENT_SECRET/YOUTUBE_REFRESH_TOKEN.");
  }

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });
  if (!response.ok) {
    throw new Error(`YouTube token refresh failed: ${response.status} ${await response.text()}`);
  }
  const payload = await response.json();
  if (!payload.access_token) throw new Error("YouTube token refresh did not return an access_token.");
  return payload.access_token;
}

async function publishToYouTube(slot, metadata, args) {
  const token = await youtubeAccessToken();
  const { absolute } = await assertAsset(metadata.asset);
  const videoBuffer = await fs.readFile(absolute);
  const { boundary, body } = multipartBody(metadata, videoBuffer);
  const url = new URL("https://www.googleapis.com/upload/youtube/v3/videos");
  url.searchParams.set("part", "snippet,status");
  url.searchParams.set("uploadType", "multipart");
  url.searchParams.set("notifySubscribers", args.notifySubscribers ? "true" : "false");

  const response = await fetch(url, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": `multipart/related; boundary=${boundary}`,
      "content-length": String(body.length),
    },
    body,
  });

  if (!response.ok) {
    throw new Error(`YouTube upload failed: ${response.status} ${await response.text()}`);
  }

  return response.json();
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const queue = await readQueue(args.queue);
  const slot = selectSlot(queue, args);
  const metadata = buildMetadata(slot, args);
  const { absolute, size } = await assertAsset(metadata.asset);
  const channel = normalize(slot.channel);

  console.log(`Selected: ${slot.date} ${slot.channel} ${slot.campaign}`);
  console.log(`Mode: ${args.publish ? "publish" : "dry-run"}`);
  console.log(`Asset: ${absolute} (${(size / 1024 / 1024).toFixed(1)} MB)`);
  console.log("");
  console.log(JSON.stringify(metadata.request, null, 2));

  if (!args.publish) return;

  if (channel.includes("youtube")) {
    const result = await publishToYouTube(slot, metadata, args);
    console.log(JSON.stringify(result, null, 2));
    return;
  }

  throw new Error(`Publishing is not implemented for '${slot.channel}'. Use the official scheduler/API listed in the queue.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
