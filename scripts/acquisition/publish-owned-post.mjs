#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const REPO_ROOT = path.resolve(new URL("../..", import.meta.url).pathname);
const DEFAULT_QUEUE = "scripts/acquisition/global-publishing-queue.json";
const URL_PATTERN = /https?:\/\/[^\s]+/u;

function parseArgs(argv) {
  const args = {
    queue: DEFAULT_QUEUE,
    campaign: "",
    channel: "",
    date: "",
    language: "",
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
    } else if (arg === "--publish") {
      args.publish = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return args;
}

function printHelp() {
  console.log(`Oasis owned-post publisher

Dry-run by default. Use --publish only when the target account credentials are configured.

Usage:
  node scripts/acquisition/build-global-publishing-queue.mjs --format json --out scripts/acquisition/global-publishing-queue.json
  node scripts/acquisition/publish-owned-post.mjs --campaign shorts_sleep_cabin_fr_bluesky
  node scripts/acquisition/publish-owned-post.mjs --campaign shorts_sleep_cabin_fr_bluesky --publish

Selection options:
  --queue <path>       Queue JSON path. Default: ${DEFAULT_QUEUE}
  --campaign <id>      Exact queue campaign id
  --channel <name>     Channel label/id fragment, e.g. bluesky or mastodon
  --date <YYYY-MM-DD>  Queue date
  --language <locale>  Queue language id, e.g. en-US
  --publish            Actually publish via official API

Bluesky env:
  BSKY_HANDLE
  BSKY_APP_PASSWORD
  BSKY_SERVICE=https://bsky.social (optional)

Mastodon env:
  MASTODON_BASE_URL=https://mastodon.social
  MASTODON_ACCESS_TOKEN
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

function selectSlot(queue, args) {
  let slots = allSlots(queue);
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
    throw new Error("No queue slot matched the selection.");
  }
  if (slots.length > 1 && !args.campaign) {
    const options = slots.slice(0, 10).map((slot) => `- ${slot.date} ${slot.channel}: ${slot.campaign}`).join("\n");
    throw new Error(`Selection matched ${slots.length} slots. Narrow with --campaign.\n${options}`);
  }

  return slots[0];
}

function postText(slot) {
  return String(slot.copy || "")
    .replace(/<br\s*\/?>/gi, "\n")
    .trim();
}

function byteIndex(text, charIndex) {
  return Buffer.byteLength(text.slice(0, charIndex), "utf8");
}

function blueskyFacets(text) {
  const match = text.match(URL_PATTERN);
  if (!match || match.index == null) return [];
  const start = byteIndex(text, match.index);
  const end = start + Buffer.byteLength(match[0], "utf8");
  return [{
    index: { byteStart: start, byteEnd: end },
    features: [{ $type: "app.bsky.richtext.facet#link", uri: match[0] }],
  }];
}

async function postToBluesky(slot, text) {
  const identifier = process.env.BSKY_HANDLE;
  const password = process.env.BSKY_APP_PASSWORD;
  const service = process.env.BSKY_SERVICE || "https://bsky.social";
  if (!identifier || !password) {
    throw new Error("Missing BSKY_HANDLE or BSKY_APP_PASSWORD.");
  }

  const sessionResponse = await fetch(`${service}/xrpc/com.atproto.server.createSession`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ identifier, password }),
  });
  if (!sessionResponse.ok) {
    throw new Error(`Bluesky session failed: ${sessionResponse.status} ${await sessionResponse.text()}`);
  }
  const session = await sessionResponse.json();
  const recordResponse = await fetch(`${service}/xrpc/com.atproto.repo.createRecord`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${session.accessJwt}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      repo: session.did,
      collection: "app.bsky.feed.post",
      record: {
        $type: "app.bsky.feed.post",
        text,
        facets: blueskyFacets(text),
        createdAt: new Date().toISOString(),
      },
    }),
  });
  if (!recordResponse.ok) {
    throw new Error(`Bluesky post failed: ${recordResponse.status} ${await recordResponse.text()}`);
  }
  return recordResponse.json();
}

async function postToMastodon(slot, text) {
  const baseUrl = process.env.MASTODON_BASE_URL;
  const token = process.env.MASTODON_ACCESS_TOKEN;
  if (!baseUrl || !token) {
    throw new Error("Missing MASTODON_BASE_URL or MASTODON_ACCESS_TOKEN.");
  }

  const body = new URLSearchParams({
    status: text,
    visibility: "public",
    language: String(slot.language || "").slice(0, 2) || "en",
  });
  const response = await fetch(`${baseUrl.replace(/\/$/, "")}/api/v1/statuses`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/x-www-form-urlencoded",
    },
    body,
  });
  if (!response.ok) {
    throw new Error(`Mastodon post failed: ${response.status} ${await response.text()}`);
  }
  return response.json();
}

async function publish(slot, text) {
  const channel = normalize(slot.channel);
  if (channel.includes("bluesky")) return postToBluesky(slot, text);
  if (channel.includes("mastodon")) return postToMastodon(slot, text);
  throw new Error(`Publishing is not implemented for '${slot.channel}'. Use the official scheduler/API listed in the queue.`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const queue = await readQueue(args.queue);
  const slot = selectSlot(queue, args);
  const text = postText(slot);

  console.log(`Selected: ${slot.date} ${slot.channel} ${slot.campaign}`);
  console.log(`Mode: ${args.publish ? "publish" : "dry-run"}`);
  console.log("");
  console.log(text);
  console.log("");

  if (!args.publish) return;
  const result = await publish(slot, text);
  console.log(JSON.stringify(result, null, 2));
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
