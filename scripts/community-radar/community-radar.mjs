#!/usr/bin/env node

import fs from "node:fs/promises";
import path from "node:path";
import process from "node:process";

const DEFAULT_CONFIG_PATH = "scripts/community-radar/config.json";

const now = new Date();

function parseArgs(argv) {
  const args = {
    config: DEFAULT_CONFIG_PATH,
    format: "md",
    sources: null,
    out: null,
    minScore: null,
    maxItems: null,
    daysBack: null,
    manual: null,
    noNetwork: false
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    const next = argv[i + 1];
    if (arg === "--config") {
      args.config = next;
      i += 1;
    } else if (arg === "--format") {
      args.format = next;
      i += 1;
    } else if (arg === "--sources") {
      args.sources = next.split(",").map((s) => s.trim()).filter(Boolean);
      i += 1;
    } else if (arg === "--out") {
      args.out = next;
      i += 1;
    } else if (arg === "--min-score") {
      args.minScore = Number(next);
      i += 1;
    } else if (arg === "--max-items") {
      args.maxItems = Number(next);
      i += 1;
    } else if (arg === "--days-back") {
      args.daysBack = Number(next);
      i += 1;
    } else if (arg === "--manual") {
      args.manual = next;
      i += 1;
    } else if (arg === "--no-network") {
      args.noNetwork = true;
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!["md", "json"].includes(args.format)) {
    throw new Error("--format must be md or json");
  }

  return args;
}

function printHelp() {
  console.log(`Oasis Community Radar

Usage:
  node scripts/community-radar/community-radar.mjs [options]

Options:
  --config <path>       Config JSON path. Default: ${DEFAULT_CONFIG_PATH}
  --sources <list>      Comma-separated sources: reddit,hn,manual
  --format <md|json>    Output format. Default: md
  --out <path>          Write output to a file instead of stdout
  --min-score <n>       Minimum opportunity score
  --max-items <n>       Maximum opportunities in digest
  --days-back <n>       Source recency window
  --manual <path>       Manual items JSON file
  --no-network          Skip Reddit and HN fetches
`);
}

async function readJson(filePath) {
  const absolute = path.resolve(filePath);
  const raw = await fs.readFile(absolute, "utf8");
  return JSON.parse(raw);
}

function shouldUseSource(args, source) {
  if (args.noNetwork && source !== "manual") return false;
  if (!args.sources) return true;
  return args.sources.includes(source);
}

function cutoffEpoch(daysBack) {
  return Math.floor((Date.now() - daysBack * 24 * 60 * 60 * 1000) / 1000);
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function slugify(input) {
  return input
    .normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "")
    .slice(0, 80);
}

async function fetchJson(url, headers = {}) {
  const response = await fetch(url, { headers });
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  return response.json();
}

async function fetchReddit(config, daysBack, delayMs) {
  if (!config.reddit?.enabled) return [];

  const headers = {
    "User-Agent": config.reddit.userAgent || "OasisCommunityRadar/0.1"
  };
  const items = [];
  const queries = config.reddit.queries
    .filter((query) => query.enabled !== false)
    .slice(0, config.run.redditMaxQueries);

  for (const query of queries) {
    for (const subreddit of query.subreddits || []) {
      const url = new URL(`https://www.reddit.com/r/${subreddit}/search.json`);
      url.searchParams.set("q", query.terms);
      url.searchParams.set("restrict_sr", "1");
      url.searchParams.set("sort", "new");
      url.searchParams.set("t", "month");
      url.searchParams.set("limit", "25");

      try {
        const json = await fetchJson(url, headers);
        for (const child of json.data?.children || []) {
          const data = child.data;
          if (!data?.created_utc) continue;
          if (data.created_utc < cutoffEpoch(daysBack)) continue;
          items.push(normalizeRedditPost(data, query));
        }
      } catch (error) {
        items.push(errorItem("reddit", subreddit, query, error));
      }

      await sleep(delayMs);
    }
  }

  return items;
}

function normalizeRedditPost(data, query) {
  return {
    source: "reddit",
    sourceName: "Reddit",
    providerQueryId: query.id,
    segment: query.segment,
    campaign: query.campaign,
    title: decodeEntities(data.title || ""),
    body: decodeEntities(data.selftext || ""),
    url: `https://www.reddit.com${data.permalink}`,
    community: data.subreddit || "",
    author: data.author || "",
    createdAt: new Date(data.created_utc * 1000).toISOString(),
    comments: Number(data.num_comments || 0),
    points: Number(data.score || 0),
    intent: query.intent || ""
  };
}

function decodeEntities(input) {
  return input
    .replace(/&amp;/g, "&")
    .replace(/&gt;/g, ">")
    .replace(/&lt;/g, "<")
    .replace(/&quot;/g, "\"")
    .replace(/&#39;/g, "'");
}

async function fetchHackerNews(config, daysBack, delayMs) {
  if (!config.hackerNews?.enabled) return [];

  const items = [];
  const since = cutoffEpoch(daysBack);
  const queries = config.hackerNews.queries
    .filter((query) => query.enabled !== false)
    .slice(0, config.run.hnMaxQueries);

  for (const query of queries) {
    const url = new URL("https://hn.algolia.com/api/v1/search_by_date");
    url.searchParams.set("query", query.terms);
    url.searchParams.set("tags", "story");
    url.searchParams.set("numericFilters", `created_at_i>${since}`);
    url.searchParams.set("hitsPerPage", "25");

    try {
      const json = await fetchJson(url);
      for (const hit of json.hits || []) {
        items.push({
          source: "hn",
          sourceName: "Hacker News",
          providerQueryId: query.id,
          segment: query.segment,
          campaign: query.campaign,
          title: hit.title || hit.story_title || "",
          body: hit.story_text || "",
          url: hit.url || `https://news.ycombinator.com/item?id=${hit.objectID}`,
          discussionUrl: `https://news.ycombinator.com/item?id=${hit.objectID}`,
          community: "news.ycombinator.com",
          author: hit.author || "",
          createdAt: new Date((hit.created_at_i || since) * 1000).toISOString(),
          comments: Number(hit.num_comments || 0),
          points: Number(hit.points || 0),
          intent: "Find maker-friendly discussions for a human-written Show HN or founder comment."
        });
      }
    } catch (error) {
      items.push(errorItem("hn", "news.ycombinator.com", query, error));
    }

    await sleep(delayMs);
  }

  return items;
}

async function loadManualItems(config, args) {
  const manualRequested = Boolean(args.manual || args.sources?.includes("manual") || (!args.sources && config.manual?.enabled));
  if (!manualRequested) return [];

  const file = args.manual || config.manual.file;
  if (!file) return [];

  try {
    const rawItems = await readJson(file);
    return rawItems.map((item, index) => ({
      source: item.source || "manual",
      sourceName: item.sourceName || "Manual",
      providerQueryId: item.providerQueryId || `manual_${index + 1}`,
      segment: item.segment || inferSegment(`${item.title || ""} ${item.body || ""}`),
      campaign: item.campaign || `manual_${slugify(item.sourceName || "forum")}`,
      title: item.title || "",
      body: item.body || "",
      url: item.url || "",
      community: item.community || "",
      author: item.author || "",
      createdAt: item.createdAt || now.toISOString(),
      comments: Number(item.comments || 0),
      points: Number(item.points || 0),
      intent: item.intent || "Manual forum item imported for scoring."
    }));
  } catch (error) {
    return [errorItem("manual", "manual", { id: "manual", segment: "manual", campaign: "manual" }, error)];
  }
}

function errorItem(source, community, query, error) {
  return {
    source,
    sourceName: source,
    providerQueryId: query.id,
    segment: query.segment,
    campaign: query.campaign,
    title: `Fetch failed for ${query.id}`,
    body: error.message,
    url: "",
    community,
    author: "",
    createdAt: now.toISOString(),
    comments: 0,
    points: 0,
    error: true,
    intent: "Fetch error."
  };
}

async function fetchSubredditRules(config, opportunities) {
  const subreddits = [...new Set(
    opportunities
      .filter((item) => item.source === "reddit" && item.community)
      .map((item) => item.community)
  )];

  const headers = {
    "User-Agent": config.reddit?.userAgent || "OasisCommunityRadar/0.1"
  };
  const rulesBySubreddit = new Map();

  for (const subreddit of subreddits) {
    const url = `https://www.reddit.com/r/${subreddit}/about/rules.json`;
    try {
      const json = await fetchJson(url, headers);
      const rules = (json.rules || []).map((rule) => ({
        shortName: rule.short_name || "",
        description: rule.description || ""
      }));
      rulesBySubreddit.set(subreddit, rules);
    } catch {
      rulesBySubreddit.set(subreddit, []);
    }
    await sleep(config.run.delayMs);
  }

  return rulesBySubreddit;
}

function inferSegment(text) {
  const lower = text.toLowerCase();
  if (containsAny(lower, [/subscription/, /no sub/, /one[- ]time/, /lifetime/, /abonnement/, /achat unique/])) return "subscription";
  if (containsAny(lower, [/focus/, /studying/, /study/, /work/, /productivity/])) return "focus";
  if (containsAny(lower, [/travel/, /hotel/, /plane/, /offline/, /hors ligne/])) return "travel";
  if (containsAny(lower, [/show hn/, /built/, /founder/, /indie/, /side project/])) return "maker";
  return "sleep";
}

function scoreOpportunity(item, rulesBySubreddit, daysBack) {
  if (item.error) {
    return { ...item, score: -100, reasons: ["Fetch error"], risks: [item.body], ruleWarnings: [] };
  }

  const text = `${item.title}\n${item.body}`.toLowerCase();
  const reasons = [];
  const risks = [];
  let score = 0;
  const questionLike = containsAny(text, [/(\?|recommend|suggest|alternative|looking for|any app|what app|which app|what do you use|does anyone know|cherche|recommand)/]);
  const promoLike = containsAny(text, [/\[[^\]]+\]\s*\[[^\]]+\]/, /48\s?h(?:ou)?rs? only/, /\blifetime\b.*(\$|€|->|to)/, /\b(free|discount|sale|promo code)\b/, /app store:/, /play store:/]);

  score += addIf(text, [/recommend/, /suggest/, /alternative/, /looking for/, /any app/, /what app/, /which app/, /what do you use/, /does anyone know/, /cherche/, /recommand/], 30, "explicit recommendation intent", reasons);
  score += addIf(text, [/no subscription/, /without (a )?subscription/, /one[- ]time/, /lifetime/, /pay once/, /abonnement/, /sans abonnement/, /achat unique/, /paywall/, /too expensive/, /\$[0-9]+\/year/, /€[0-9]+\/year/], 25, "subscription fatigue", reasons);
  score += addIf(text, [/\bios\b/, /iphone/, /ipad/, /app store/], 20, "iOS fit", reasons);
  score += addIf(text, [/sleep/, /insomnia/, /white noise/, /brown noise/, /rain sounds?/, /sleep timer/, /bruit blanc/, /sommeil/, /dormir/], 15, "sleep or sound intent", reasons);
  score += addIf(text, [/focus/, /deep work/, /studying/, /study/, /reading/, /productivity/, /concentrat/], 12, "focus or reading use case", reasons);
  score += addIf(text, [/offline/, /no internet/, /plane/, /flight/, /hotel/, /travel/, /hors ligne/, /avion/], 15, "offline or travel moat", reasons);
  score += addIf(text, [/rain/, /wind/, /ocean/, /forest/, /nature sounds?/, /ambient/, /field recording/, /binaural/], 10, "Oasis sound catalog fit", reasons);

  const ageHours = Math.max(0, (Date.now() - new Date(item.createdAt).getTime()) / (60 * 60 * 1000));
  if (ageHours <= 48) {
    score += 10;
    reasons.push("fresh thread");
  } else if (ageHours <= daysBack * 24) {
    score += 4;
    reasons.push("recent enough");
  } else {
    score -= 20;
    risks.push("outside recency window");
  }

  if (item.comments > 0) {
    const engagement = Math.min(10, Math.round(Math.log2(item.comments + 1) * 3));
    score += engagement;
    reasons.push(`active discussion (+${engagement})`);
  }

  const ruleWarnings = ruleWarningsFor(item, rulesBySubreddit);
  if (ruleWarnings.length > 0) {
    score -= 30;
    risks.push("community rules may restrict promotion");
  }

  if (item.source === "hn") {
    risks.push("HN comments must be written manually; do not paste AI-generated wording");
  }

  if (item.source === "hn" && /^show hn:/i.test(item.title) && !/oasis/i.test(item.title)) {
    score -= 80;
    risks.push("other product Show HN, use as research only");
  }

  if (item.source === "reddit" && item.segment !== "maker" && !questionLike) {
    score -= 25;
    risks.push("not an obvious request thread");
  }

  if (item.source === "reddit" && item.segment !== "maker" && promoLike) {
    score -= 70;
    risks.push("looks like an app promotion, not a user need");
  }

  if (containsAny(text, [/suicid/, /self harm/, /panic attack/, /diagnos/, /treatment/, /medication/, /sleep apnea/, /medical advice/])) {
    score -= 25;
    risks.push("sensitive medical context, avoid product promotion");
  }

  if (containsAny(text, [/baby/, /newborn/, /infant/, /toddler/])) {
    score -= 20;
    risks.push("baby or child sleep context, avoid this persona");
  }

  return {
    ...item,
    score,
    reasons,
    risks,
    ruleWarnings
  };
}

function addIf(text, patterns, weight, reason, reasons) {
  if (!containsAny(text, patterns)) return 0;
  reasons.push(reason);
  return weight;
}

function containsAny(text, patterns) {
  return patterns.some((pattern) => pattern.test(text));
}

function ruleWarningsFor(item, rulesBySubreddit) {
  if (item.source !== "reddit") return [];
  const rules = rulesBySubreddit.get(item.community) || [];
  const warnings = [];
  for (const rule of rules) {
    const text = `${rule.shortName} ${rule.description}`.toLowerCase();
    if (containsAny(text, [/self.?promo/, /promotion/, /advertis/, /spam/, /solicit/, /survey/, /link shortener/, /no links/])) {
      warnings.push(rule.shortName || "Rule warning");
    }
  }
  return warnings;
}

function dedupe(items) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const key = item.url || `${item.source}:${slugify(item.title)}:${item.createdAt}`;
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }
  return result;
}

function buildCampaignLink(appConfig, campaign) {
  if (!appConfig?.appStoreBaseUrl) return "";
  const url = new URL(appConfig.appStoreBaseUrl);
  if (appConfig.campaignProviderToken) {
    url.searchParams.set("pt", appConfig.campaignProviderToken);
  }
  url.searchParams.set("ct", slugify(campaign || "community_radar"));
  url.searchParams.set("mt", "8");
  return url.toString();
}

function draftReply(item, appConfig) {
  const link = buildCampaignLink(appConfig, item.campaign);

  if (item.segment === "subscription") {
    return [
      "I am the developer of Oasis, so I am biased, but the no-subscription part is exactly why I built it.",
      "",
      "It is an iOS nature sound mixer with a few free sounds, background playback, a sleep timer, and offline audio. The premium unlock is a one-time purchase, not a subscription.",
      "",
      "If you compare options, I would look at three things first: whether it keeps playing when the phone is locked, whether the sounds feel natural over long sessions, and whether the pricing stays clear after day one.",
      "",
      `Optional tracked link, only if links are allowed: ${link}`
    ].join("\n");
  }

  if (item.segment === "focus") {
    return [
      "I am the developer of Oasis, so take this with the obvious bias. For focus, I would avoid anything that behaves like a playlist and look for something you can keep stable for long sessions.",
      "",
      "Oasis lets you mix field-recorded nature sounds, adjust each level, and place sounds around you. It also works offline, which is useful if you do not want streaming or a browser tab open while working.",
      "",
      `Optional tracked link, only if links are allowed: ${link}`
    ].join("\n");
  }

  if (item.segment === "travel") {
    return [
      "I am the developer of Oasis, so I am not neutral, but travel/offline use is one of the reasons I made it.",
      "",
      "The audio is bundled in the app, so it works in a hotel, on a plane, or anywhere with no connection. You can mix rain, wind, ocean, birds, and other nature sounds, then use the timer with the screen locked.",
      "",
      `Optional tracked link, only if links are allowed: ${link}`
    ].join("\n");
  }

  if (item.segment === "maker") {
    return [
      "Founder note: I am building Oasis as an offline iOS nature sound mixer with a one-time lifetime unlock.",
      "",
      "The product choice is deliberately anti-subscription: bundled field recordings, AVAudioEngine mixing, background playback, sound placement, and no account. The tradeoff is a larger download, but it means the app works without streaming.",
      "",
      "For this community I would frame it as a product/technical story, not as a sleep claim.",
      "",
      `Reference link, only if the thread allows product links: ${link}`
    ].join("\n");
  }

  return [
    "I am the developer of Oasis, so I am biased, but this is close to the use case I built for.",
    "",
    "It is an iOS nature sound mixer for sleep, focus, reading, and calm. It works offline, keeps playing with the screen locked, and uses a one-time premium unlock instead of a subscription.",
    "",
    `Optional tracked link, only if links are allowed: ${link}`
  ].join("\n");
}

function renderMarkdown(opportunities, config, args) {
  const generatedAt = now.toISOString();
  const guardrails = config.guardrails || {};
  const lines = [
    "# Oasis Community Radar",
    "",
    `Generated: ${generatedAt}`,
    `Sources: ${args.sources ? args.sources.join(", ") : args.noNetwork ? "manual" : "reddit, hn, manual"}`,
    `Threshold: ${config.run.minScore}`,
    "",
    "## Manual Rules",
    "",
    `- Daily reply cap: ${guardrails.dailyReplyCap || 5}`,
    `- Daily link cap: ${guardrails.dailyLinkCap || 1}`,
    "- Always disclose that you are the developer of Oasis.",
    "- Read the thread and community rules before posting.",
    "- Do not paste drafts blindly, especially on Hacker News.",
    "- Do not use unsolicited DMs, fake accounts, vote requests, or repeated replies.",
    "",
    "## Opportunities",
    ""
  ];

  if (opportunities.length === 0) {
    lines.push("No opportunities crossed the threshold.");
    return lines.join("\n");
  }

  opportunities.forEach((item, index) => {
    lines.push(`### ${index + 1}. ${item.title}`);
    lines.push("");
    lines.push(`- Score: ${item.score}`);
    lines.push(`- Source: ${item.sourceName}${item.community ? ` / ${item.community}` : ""}`);
    lines.push(`- Segment: ${item.segment}`);
    lines.push(`- Campaign: ${item.campaign}`);
    lines.push(`- URL: ${item.url || "(no URL)"}`);
    if (item.discussionUrl && item.discussionUrl !== item.url) lines.push(`- Discussion: ${item.discussionUrl}`);
    lines.push(`- Created: ${item.createdAt}`);
    lines.push(`- Reasons: ${item.reasons.length ? item.reasons.join(", ") : "none"}`);
    lines.push(`- Risks: ${item.risks.length ? item.risks.join(", ") : "none"}`);
    if (item.ruleWarnings.length) lines.push(`- Rule warnings: ${item.ruleWarnings.join(", ")}`);
    lines.push("");
    lines.push("Suggested reply draft:");
    lines.push("");
    lines.push("```text");
    lines.push(draftReply(item, config.app));
    lines.push("```");
    lines.push("");
  });

  return lines.join("\n");
}

function renderJson(opportunities) {
  return JSON.stringify({ generatedAt: now.toISOString(), opportunities }, null, 2);
}

async function writeOutput(content, outPath) {
  if (!outPath) {
    process.stdout.write(`${content}\n`);
    return;
  }
  const absolute = path.resolve(outPath);
  await fs.mkdir(path.dirname(absolute), { recursive: true });
  await fs.writeFile(absolute, `${content}\n`, "utf8");
  console.log(`Wrote ${absolute}`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  const config = await readJson(args.config);

  config.run.daysBack = args.daysBack ?? config.run.daysBack;
  config.run.minScore = args.minScore ?? config.run.minScore;
  config.run.maxItems = args.maxItems ?? config.run.maxItems;

  const fetched = [];
  if (shouldUseSource(args, "reddit")) {
    fetched.push(...await fetchReddit(config, config.run.daysBack, config.run.delayMs));
  }
  if (shouldUseSource(args, "hn")) {
    fetched.push(...await fetchHackerNews(config, config.run.daysBack, config.run.delayMs));
  }
  if (shouldUseSource(args, "manual")) {
    fetched.push(...await loadManualItems(config, args));
  }

  const raw = dedupe(fetched);
  const rulesBySubreddit = shouldUseSource(args, "reddit") && !args.noNetwork
    ? await fetchSubredditRules(config, raw)
    : new Map();

  const opportunities = raw
    .map((item) => scoreOpportunity(item, rulesBySubreddit, config.run.daysBack))
    .filter((item) => item.score >= config.run.minScore)
    .sort((a, b) => b.score - a.score)
    .slice(0, config.run.maxItems);

  const content = args.format === "json"
    ? renderJson(opportunities)
    : renderMarkdown(opportunities, config, args);

  await writeOutput(content, args.out);
}

main().catch((error) => {
  console.error(error.stack || error.message);
  process.exit(1);
});
