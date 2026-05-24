import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { EXPORTS_DIR, loadAppConfig, loadOutreachRules } from "./config.js";
import { readPromoCodes } from "./codeAllocator.js";
import { readCsvRecords, writeCsvRecords } from "./csv.js";
import { readProspects } from "./prospectImporter.js";
import type { CsvRecord, PlanItem, ResponseEntry } from "./types.js";
import { RESPONSES_PATH } from "./config.js";
import { todayStamp } from "./utils/dates.js";

export async function writePlanExports(items: PlanItem[], language: string): Promise<{ markdownPath: string; csvPath: string }> {
  await mkdir(EXPORTS_DIR, { recursive: true });
  const suffix = `${todayStamp()}${language ? `-${language}` : ""}`;
  const markdownPath = join(EXPORTS_DIR, `outreach-plan-${suffix}.md`);
  const csvPath = join(EXPORTS_DIR, `outreach-plan-${suffix}.csv`);
  await writeFile(markdownPath, renderPlanMarkdown(items, language), "utf8");
  await writeCsvRecords(csvPath, planRows(items), [
    "priority",
    "id",
    "name",
    "platform",
    "handle",
    "profileUrl",
    "language",
    "score",
    "tier",
    "niche",
    "contactMethod",
    "recommendedTemplate",
    "promoCode",
    "nextAction",
    "message"
  ]);
  return { markdownPath, csvPath };
}

export async function writeFollowupExports(items: PlanItem[], days: number): Promise<{ markdownPath: string; csvPath: string }> {
  const dir = join(EXPORTS_DIR, "followups");
  await mkdir(dir, { recursive: true });
  const suffix = todayStamp();
  const markdownPath = join(dir, `followups-${suffix}.md`);
  const csvPath = join(dir, `followups-${suffix}.csv`);
  await writeFile(markdownPath, renderFollowupMarkdown(items, days), "utf8");
  await writeCsvRecords(csvPath, planRows(items), [
    "priority",
    "id",
    "name",
    "platform",
    "handle",
    "profileUrl",
    "language",
    "score",
    "tier",
    "niche",
    "contactMethod",
    "recommendedTemplate",
    "promoCode",
    "nextAction",
    "message"
  ]);
  return { markdownPath, csvPath };
}

export async function writeReportExports(): Promise<{ markdownPath: string; csvPath: string; jsonPath: string }> {
  const report = await buildReport();
  const dir = join(EXPORTS_DIR, "reports");
  await mkdir(dir, { recursive: true });
  const suffix = todayStamp();
  const markdownPath = join(dir, `outreach-report-${suffix}.md`);
  const csvPath = join(dir, `outreach-report-${suffix}.csv`);
  const jsonPath = join(dir, `outreach-report-${suffix}.json`);
  await writeFile(markdownPath, renderReportMarkdown(report), "utf8");
  await writeCsvRecords(csvPath, Object.entries(report.metrics).map(([metric, value]) => ({ metric, value: String(value) })), [
    "metric",
    "value"
  ]);
  await writeFile(jsonPath, JSON.stringify(report, null, 2), "utf8");
  return { markdownPath, csvPath, jsonPath };
}

function renderPlanMarkdown(items: PlanItem[], language: string): string {
  const rules = loadOutreachRules();
  const app = loadAppConfig();
  const lines = [
    `# Oasis Outreach Plan - ${todayStamp()}${language ? ` - ${language}` : ""}`,
    "",
    `Manual approval required: ${rules.requireManualApproval ? "yes" : "no"}`,
    `Auto-send enabled: ${rules.allowAutoSend ? "yes" : "no"}`,
    "",
    `Compliance note: ${rules.emailComplianceWarning}`,
    "",
    `App Store URL: ${app.appStoreUrl}`,
    "",
    `Prospects: ${items.length}`,
    ""
  ];
  for (const item of items) {
    lines.push(
      `## ${item.prospect.name || item.prospect.handle || item.prospect.id}`,
      "",
      `- ID: ${item.prospect.id}`,
      `- Platform: ${item.prospect.platform}`,
      `- Handle: ${item.prospect.handle || "n/a"}`,
      `- URL: ${item.prospect.profileUrl || "n/a"}`,
      `- Language: ${item.prospect.language}`,
      `- Score: ${item.score.score} (${item.score.tier})`,
      `- Niche: ${item.prospect.niche}`,
      `- Contact method: ${item.prospect.contactMethod}`,
      `- Template: ${item.recommendedTemplate}`,
      `- Promo code: ${item.promoCode || "to assign"}`,
      `- Next action: ${item.nextAction}`,
      "",
      "```text",
      item.message,
      "```",
      ""
    );
  }
  return lines.join("\n");
}

function renderFollowupMarkdown(items: PlanItem[], days: number): string {
  const lines = [
    `# Oasis Follow-ups - ${todayStamp()}`,
    "",
    `Criteria: contacted at least ${days} days ago, no reply, not do_not_contact, under max follow-up limit.`,
    "",
    "Send manually only after checking the original thread and platform rules.",
    "",
    `Prospects: ${items.length}`,
    ""
  ];
  for (const item of items) {
    lines.push(
      `## ${item.prospect.name || item.prospect.handle || item.prospect.id}`,
      "",
      `- ID: ${item.prospect.id}`,
      `- Platform: ${item.prospect.platform}`,
      `- Follow-up count: ${item.prospect.followupCount || "0"}`,
      `- Last contacted: ${item.prospect.lastContactedAt || "n/a"}`,
      `- Template: ${item.recommendedTemplate}`,
      `- Next action: ${item.nextAction}`,
      "",
      "```text",
      item.message,
      "```",
      ""
    );
  }
  return lines.join("\n");
}

function planRows(items: PlanItem[]): CsvRecord[] {
  return items.map((item) => ({
    priority: String(item.score.priority),
    id: item.prospect.id,
    name: item.prospect.name,
    platform: item.prospect.platform,
    handle: item.prospect.handle,
    profileUrl: item.prospect.profileUrl,
    language: item.prospect.language,
    score: String(item.score.score),
    tier: item.score.tier,
    niche: item.prospect.niche,
    contactMethod: item.prospect.contactMethod,
    recommendedTemplate: item.recommendedTemplate,
    promoCode: item.promoCode || "to assign",
    nextAction: item.nextAction,
    message: item.message
  }));
}

async function buildReport(): Promise<{ generatedAt: string; metrics: Record<string, number | string> }> {
  const prospects = await readProspects();
  const codes = await readPromoCodes();
  const responses = await readCsvRecords<ResponseEntry>(RESPONSES_PATH);
  const byPlatform = countBy(prospects.map((item) => item.platform || "unknown"));
  const byNiche = countBy(prospects.map((item) => item.niche || "unknown"));
  const byTier = countBy(prospects.map((item) => item.tier || "unscored"));
  const contacted = prospects.filter((item) => ["contacted", "replied", "code_sent", "posted", "reviewed", "no_response"].includes(item.status));
  const codeSent = prospects.filter((item) => ["code_sent", "posted", "reviewed"].includes(item.status)).length;
  const replies = prospects.filter((item) => ["replied", "posted", "reviewed"].includes(item.status)).length;
  const positives = responses.filter((item) => ["positive", "asked_question", "posted", "review_left"].includes(item.type)).length;
  const posts = prospects.filter((item) => item.status === "posted").length + responses.filter((item) => item.type === "posted").length;
  const reviews = prospects.filter((item) => item.status === "reviewed").length + responses.filter((item) => item.type === "review_left").length;
  const metrics: Record<string, number | string> = {
    totalProspects: prospects.length,
    byPlatform: JSON.stringify(byPlatform),
    byNiche: JSON.stringify(byNiche),
    byTier: JSON.stringify(byTier),
    codesAvailable: codes.filter((item) => item.status === "available").length,
    codesAssigned: codes.filter((item) => item.status === "assigned").length,
    codesSent: codes.filter((item) => item.status === "sent").length,
    codesRedeemed: codes.filter((item) => item.status === "redeemed" || item.redeemed === "true").length,
    positiveResponses: positives,
    postsObtained: posts,
    appStoreReviewsObtained: reviews,
    responseRate: percent(replies, contacted.length),
    contactToCodeSentRate: percent(codeSent, contacted.length),
    codeSentToFeedbackRate: percent(positives + reviews + posts, codeSent)
  };
  return { generatedAt: new Date().toISOString(), metrics };
}

function renderReportMarkdown(report: { generatedAt: string; metrics: Record<string, number | string> }): string {
  const lines = ["# Oasis Outreach Report", "", `Generated at: ${report.generatedAt}`, ""];
  for (const [metric, value] of Object.entries(report.metrics)) {
    lines.push(`- ${metric}: ${value}`);
  }
  return lines.join("\n");
}

function countBy(values: string[]): Record<string, number> {
  return values.reduce<Record<string, number>>((acc, value) => {
    acc[value] = (acc[value] ?? 0) + 1;
    return acc;
  }, {});
}

function percent(numerator: number, denominator: number): string {
  if (denominator === 0) {
    return "0%";
  }
  return `${Math.round((numerator / denominator) * 1000) / 10}%`;
}
