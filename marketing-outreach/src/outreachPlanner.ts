import { loadOutreachRules, resolveLanguage } from "./config.js";
import { getAssignedCode } from "./codeAllocator.js";
import { readProspects, writeProspects } from "./prospectImporter.js";
import { isContactableStatus, scoreProspect } from "./scoring.js";
import { renderMessage, recommendedTemplate } from "./messageRenderer.js";
import type { PlanItem, Prospect, SupportedLanguage } from "./types.js";
import { daysBetween, nowIso } from "./utils/dates.js";

export async function buildDailyPlan(options: { limit: number; lang?: string }): Promise<PlanItem[]> {
  const rules = loadOutreachRules();
  const requestedLimit = Math.max(1, options.limit);
  const limit = Math.min(requestedLimit, rules.dailyContactLimit);
  const prospects = await readProspects();
  const eligible = prospects
    .filter((prospect) => prospect.status !== "do_not_contact")
    .filter((prospect) => isContactableStatus(prospect.status))
    .filter((prospect) => (options.lang ? prospect.language === options.lang : prospect.language !== "unknown"))
    .map((prospect) => ({ prospect, score: scoreProspect(prospect) }))
    .filter((item) => item.score.tier !== "D")
    .sort((a, b) => b.score.score - a.score.score)
    .slice(0, limit);

  const items: PlanItem[] = [];
  for (const item of eligible) {
    const lang = resolveLanguage(options.lang || item.prospect.language);
    const template = recommendedTemplate(item.prospect, lang);
    const rendered = await renderMessage({ prospect: item.prospect, template, lang, writeFile: false });
    items.push({
      prospect: item.prospect,
      score: item.score,
      recommendedTemplate: rendered.templateName,
      promoCode: rendered.promoCode || (await getAssignedCode(item.prospect.id)),
      message: rendered.message,
      nextAction: nextActionForProspect(item.prospect)
    });
  }
  return items;
}

export async function buildFollowupPlan(options: { days: number; limit?: number; record?: boolean }): Promise<PlanItem[]> {
  const rules = loadOutreachRules();
  const prospects = await readProspects();
  const eligible = prospects
    .filter((prospect) => ["contacted", "code_sent", "no_response"].includes(prospect.status))
    .filter((prospect) => prospect.status !== "do_not_contact")
    .filter((prospect) => Number(prospect.followupCount || "0") < rules.maxFollowups)
    .filter((prospect) => {
      const lastContact = prospect.lastFollowupAt || prospect.lastContactedAt;
      const elapsed = daysBetween(lastContact);
      return elapsed !== null && elapsed >= options.days;
    })
    .map((prospect) => ({ prospect, score: scoreProspect(prospect) }))
    .sort((a, b) => b.score.score - a.score.score)
    .slice(0, options.limit ?? rules.dailyContactLimit);

  const items: PlanItem[] = [];
  for (const item of eligible) {
    const lang = resolveLanguage(item.prospect.language);
    const count = Number(item.prospect.followupCount || "0");
    const template = `followup-${Math.min(count + 1, 2)}.${lang}`;
    const rendered = await renderMessage({ prospect: item.prospect, template, lang, writeFile: false });
    items.push({
      prospect: item.prospect,
      score: item.score,
      recommendedTemplate: rendered.templateName,
      promoCode: rendered.promoCode,
      message: rendered.message,
      nextAction: "Review context, then send manually only if still appropriate."
    });
  }

  if (options.record && items.length > 0) {
    const now = nowIso();
    const ids = new Set(items.map((item) => item.prospect.id));
    const updated = prospects.map((prospect) => {
      if (!ids.has(prospect.id)) {
        return prospect;
      }
      return {
        ...prospect,
        lastFollowupAt: now,
        followupCount: String(Number(prospect.followupCount || "0") + 1),
        updatedAt: now
      };
    });
    await writeProspects(updated);
  }

  return items;
}

function nextActionForProspect(prospect: Prospect): string {
  if (!prospect.promoCode) {
    return "Assign a promo code, review the message, then contact manually.";
  }
  if (prospect.contactMethod === "email") {
    return "Check consent/professional context before sending manually.";
  }
  return "Review profile context, personalize if needed, then contact manually.";
}
