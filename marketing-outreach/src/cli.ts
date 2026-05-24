import { Command } from "commander";
import { loadOutreachRules } from "./config.js";
import { appendOutreachLog, appendResponse } from "./csv.js";
import { assignBatch, assignCodeToProspect, importPromoCodes, markCodeSent } from "./codeAllocator.js";
import { writeFollowupExports, writePlanExports, writeReportExports } from "./exports.js";
import { renderMessage } from "./messageRenderer.js";
import { buildDailyPlan, buildFollowupPlan } from "./outreachPlanner.js";
import { applyScores } from "./scoring.js";
import { importProspects, readProspects, writeProspects } from "./prospectImporter.js";
import { formatValidationReport, validateWorkspace } from "./validation.js";
import * as log from "./logger.js";
import type { ProspectStatus, ResponseType, ScoreTier } from "./types.js";
import { PROSPECT_STATUSES, RESPONSE_TYPES, SCORE_TIERS } from "./types.js";
import { nowIso } from "./utils/dates.js";
import { maskPromoCode } from "./utils/text.js";

const program = new Command();

program
  .name("oasis-outreach")
  .description("Human-in-the-loop outreach CRM for Oasis Premium promo codes.")
  .showHelpAfterError()
  .showSuggestionAfterError();

program
  .command("import")
  .description("Import or normalize prospects into data/prospects.csv")
  .requiredOption("--file <file>", "CSV file to import")
  .action((options: { file: string }) =>
    run(async () => {
      const result = await importProspects(options.file);
      log.success(`Imported ${result.imported} prospects from ${result.path}. Canonical total: ${result.total}.`);
    })
  );

program
  .command("validate")
  .description("Validate prospects, promo codes, statuses, languages, and compliance guardrails")
  .action(() =>
    run(async () => {
      const issues = await validateWorkspace();
      console.log(formatValidationReport(issues));
      if (issues.some((issue) => issue.severity === "error")) {
        process.exitCode = 1;
      }
    })
  );

program
  .command("score")
  .description("Score prospects and write score/tier/reason fields")
  .action(() =>
    run(async () => {
      const prospects = await readProspects();
      const scored = applyScores(prospects);
      await writeProspects(scored);
      log.success(`Scored ${scored.length} prospects.`);
    })
  );

program
  .command("codes:import")
  .description("Import promo codes into data/promo-codes.csv")
  .requiredOption("--file <file>", "CSV file containing promo codes")
  .action((options: { file: string }) =>
    run(async () => {
      const result = await importPromoCodes(options.file);
      log.success(`Imported ${result.imported} code rows. Unique canonical codes: ${result.total}.`);
      log.warn("Promo codes are sensitive. They are ignored by git and are not printed in bulk.");
    })
  );

program
  .command("codes:assign")
  .description("Assign one available promo code to a prospect")
  .requiredOption("--prospect-id <id>", "Prospect id")
  .action((options: { prospectId: string }) =>
    run(async () => {
      const result = await assignCodeToProspect(options.prospectId);
      log.success(
        result.alreadyAssigned
          ? `Prospect already had code ${result.code}.`
          : `Assigned code ${result.code} to ${options.prospectId}.`
      );
    })
  );

program
  .command("codes:assign-batch")
  .description("Assign codes to the best eligible prospects")
  .option("--tier <tier>", "Score tier to target: A, B, C, D")
  .option("--limit <number>", "Maximum codes to assign", parseInteger, 20)
  .action((options: { tier?: ScoreTier; limit: number }) =>
    run(async () => {
      if (options.tier && !SCORE_TIERS.includes(options.tier)) {
        throw new Error(`Unknown tier: ${options.tier}`);
      }
      const results = await assignBatch({ tier: options.tier, limit: options.limit });
      log.success(`Assigned ${results.filter((item) => !item.alreadyAssigned).length} new codes.`);
      for (const result of results) {
        console.log(`- ${result.prospectId}: ${result.code}`);
      }
    })
  );

program
  .command("message")
  .description("Render a localized, copyable message for one prospect. Does not send anything.")
  .requiredOption("--prospect-id <id>", "Prospect id")
  .option("--template <template>", "Template name, for example dm-instagram.fr")
  .option("--lang <lang>", "Force message language")
  .action((options: { prospectId: string; template?: string; lang?: string }) =>
    run(async () => {
      const prospects = await readProspects();
      const prospect = prospects.find((item) => item.id === options.prospectId);
      if (!prospect) {
        throw new Error(`Prospect not found: ${options.prospectId}`);
      }
      const rendered = await renderMessage({ prospect, template: options.template, lang: options.lang, writeFile: true });
      if (rendered.warning) {
        log.warn(rendered.warning);
      }
      log.info(`Template: ${rendered.templateName}`);
      log.info(`Language: ${rendered.language}`);
      if (rendered.outputPath) {
        log.success(`Message written to ${rendered.outputPath}`);
      }
      console.log("\n--- MESSAGE ---\n");
      console.log(rendered.message);
    })
  );

program
  .command("plan")
  .description("Generate a daily human-reviewed contact plan")
  .option("--limit <number>", "Maximum prospects to include", parseInteger, 20)
  .option("--lang <lang>", "Filter by prospect language")
  .action((options: { limit: number; lang?: string }) =>
    run(async () => {
      const rules = loadOutreachRules();
      if (options.limit > rules.dailyContactLimit) {
        log.warn(`Configured dailyContactLimit is ${rules.dailyContactLimit}; plan will be capped.`);
      }
      const items = await buildDailyPlan({ limit: options.limit, lang: options.lang });
      const paths = await writePlanExports(items, options.lang ?? "");
      log.success(`Generated ${items.length} plan items.`);
      log.info(`Markdown: ${paths.markdownPath}`);
      log.info(`CSV: ${paths.csvPath}`);
      log.warn("No messages were sent. Review and send manually only where appropriate.");
    })
  );

program
  .command("update")
  .description("Update one prospect status")
  .requiredOption("--prospect-id <id>", "Prospect id")
  .requiredOption("--status <status>", "New status")
  .action((options: { prospectId: string; status: ProspectStatus }) =>
    run(async () => {
      if (!PROSPECT_STATUSES.includes(options.status)) {
        throw new Error(`Unknown status: ${options.status}`);
      }
      const prospects = await readProspects();
      const prospect = prospects.find((item) => item.id === options.prospectId);
      if (!prospect) {
        throw new Error(`Prospect not found: ${options.prospectId}`);
      }
      prospect.status = options.status;
      if (options.status === "contacted") {
        prospect.lastContactedAt = nowIso();
      }
      prospect.updatedAt = nowIso();
      await writeProspects(prospects);
      await appendOutreachLog({
        timestamp: nowIso(),
        prospectId: prospect.id,
        action: "status_update",
        status: prospect.status,
        responseType: "",
        note: "",
        template: "",
        language: prospect.language,
        codeMasked: prospect.promoCode ? maskPromoCode(prospect.promoCode) : ""
      });
      log.success(`Updated ${prospect.id} to status ${prospect.status}.`);
    })
  );

program
  .command("note")
  .description("Append a manual note to a prospect")
  .requiredOption("--prospect-id <id>", "Prospect id")
  .requiredOption("--note <note>", "Note text")
  .action((options: { prospectId: string; note: string }) =>
    run(async () => {
      const prospects = await readProspects();
      const prospect = prospects.find((item) => item.id === options.prospectId);
      if (!prospect) {
        throw new Error(`Prospect not found: ${options.prospectId}`);
      }
      const stamp = nowIso();
      prospect.notes = prospect.notes ? `${prospect.notes} | ${stamp}: ${options.note}` : `${stamp}: ${options.note}`;
      prospect.updatedAt = stamp;
      await writeProspects(prospects);
      await appendOutreachLog({
        timestamp: stamp,
        prospectId: prospect.id,
        action: "note",
        status: prospect.status,
        responseType: "",
        note: options.note,
        template: "",
        language: prospect.language,
        codeMasked: prospect.promoCode ? maskPromoCode(prospect.promoCode) : ""
      });
      log.success(`Added note to ${prospect.id}.`);
    })
  );

program
  .command("sent")
  .description("Mark the assigned promo code as manually sent")
  .requiredOption("--prospect-id <id>", "Prospect id")
  .action((options: { prospectId: string }) =>
    run(async () => {
      const result = await markCodeSent(options.prospectId);
      log.success(`Marked code ${result.code} as sent to ${options.prospectId}.`);
    })
  );

program
  .command("reply")
  .description("Record a prospect response")
  .requiredOption("--prospect-id <id>", "Prospect id")
  .requiredOption("--type <type>", "positive, neutral, negative, asked_question, posted, review_left, no_interest")
  .option("--note <note>", "Optional response note", "")
  .action((options: { prospectId: string; type: ResponseType; note: string }) =>
    run(async () => {
      if (!RESPONSE_TYPES.includes(options.type)) {
        throw new Error(`Unknown response type: ${options.type}`);
      }
      const prospects = await readProspects();
      const prospect = prospects.find((item) => item.id === options.prospectId);
      if (!prospect) {
        throw new Error(`Prospect not found: ${options.prospectId}`);
      }
      prospect.status = statusForResponse(options.type);
      prospect.updatedAt = nowIso();
      await writeProspects(prospects);
      await appendResponse({ timestamp: nowIso(), prospectId: prospect.id, type: options.type, note: options.note });
      await appendOutreachLog({
        timestamp: nowIso(),
        prospectId: prospect.id,
        action: "reply",
        status: prospect.status,
        responseType: options.type,
        note: options.note,
        template: "",
        language: prospect.language,
        codeMasked: prospect.promoCode ? maskPromoCode(prospect.promoCode) : ""
      });
      log.success(`Recorded ${options.type} response for ${prospect.id}.`);
    })
  );

program
  .command("followups")
  .description("Generate short follow-up drafts for eligible prospects")
  .option("--days <number>", "Minimum days since last contact/follow-up", parseInteger, 5)
  .option("--limit <number>", "Maximum follow-ups to include", parseInteger)
  .option("--record", "After manual review/sending, increment followupCount for generated prospects", false)
  .action((options: { days: number; limit?: number; record: boolean }) =>
    run(async () => {
      const rules = loadOutreachRules();
      const days = Math.max(options.days, rules.minDaysBeforeFollowup);
      if (days !== options.days) {
        log.warn(`Configured minDaysBeforeFollowup is ${rules.minDaysBeforeFollowup}; using ${days} days.`);
      }
      const items = await buildFollowupPlan({ days, limit: options.limit, record: options.record });
      const paths = await writeFollowupExports(items, days);
      log.success(`Generated ${items.length} follow-up drafts.`);
      log.info(`Markdown: ${paths.markdownPath}`);
      log.info(`CSV: ${paths.csvPath}`);
      if (options.record) {
        log.warn("Follow-up counters were incremented because --record was provided. Messages still were not sent by this tool.");
      }
    })
  );

program
  .command("report")
  .description("Export outreach tracking summary")
  .action(() =>
    run(async () => {
      const paths = await writeReportExports();
      log.success("Report generated.");
      log.info(`Markdown: ${paths.markdownPath}`);
      log.info(`CSV: ${paths.csvPath}`);
      log.info(`JSON: ${paths.jsonPath}`);
    })
  );

program.parseAsync(process.argv);

async function run(fn: () => Promise<void>): Promise<void> {
  try {
    await fn();
  } catch (err) {
    log.error(err instanceof Error ? err.message : String(err));
    process.exitCode = 1;
  }
}

function parseInteger(value: string): number {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new Error(`Expected a positive integer, got '${value}'.`);
  }
  return parsed;
}

function statusForResponse(type: ResponseType): ProspectStatus {
  switch (type) {
    case "positive":
    case "neutral":
    case "asked_question":
      return "replied";
    case "posted":
      return "posted";
    case "review_left":
      return "reviewed";
    case "negative":
    case "no_interest":
      return "rejected";
  }
}
