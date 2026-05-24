import { loadOutreachRules } from "./config.js";
import { readPromoCodes } from "./codeAllocator.js";
import { readProspects } from "./prospectImporter.js";
import { hasContactChannel } from "./scoring.js";
import type { PromoCode, Prospect, ValidationIssue } from "./types.js";
import {
  CONTACT_METHODS,
  PLATFORMS,
  PROMO_CODE_STATUSES,
  PROSPECT_LANGUAGES,
  PROSPECT_STATUSES
} from "./types.js";

export async function validateWorkspace(): Promise<ValidationIssue[]> {
  const prospects = await readProspects();
  const promoCodes = await readPromoCodes();
  return validateProspects(prospects).concat(validatePromoCodes(promoCodes), validateCrossReferences(prospects, promoCodes), complianceIssues());
}

export function validateProspects(prospects: Prospect[]): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  const seenEmail = new Map<string, string>();
  const seenProfile = new Map<string, string>();
  const seenHandlePlatform = new Map<string, string>();

  for (const prospect of prospects) {
    const id = prospect.id || "(missing id)";
    if (prospect.email && !isValidEmail(prospect.email)) {
      issues.push(issue("warning", "prospect", id, `Invalid email: ${prospect.email}`));
    }
    if (prospect.profileUrl && !isValidUrl(prospect.profileUrl)) {
      issues.push(issue("warning", "prospect", id, `Invalid profile URL: ${prospect.profileUrl}`));
    }
    if (!PLATFORMS.includes(prospect.platform as never)) {
      issues.push(issue("warning", "prospect", id, `Unknown platform: ${prospect.platform || "(empty)"}`));
    }
    if (!CONTACT_METHODS.includes(prospect.contactMethod as never)) {
      issues.push(issue("warning", "prospect", id, `Unknown contact method: ${prospect.contactMethod || "(empty)"}`));
    }
    if (!PROSPECT_STATUSES.includes(prospect.status as never)) {
      issues.push(issue("error", "prospect", id, `Unknown status: ${prospect.status || "(empty)"}`));
    }
    if (!PROSPECT_LANGUAGES.includes(prospect.language as never)) {
      issues.push(issue("warning", "prospect", id, `Unknown language: ${prospect.language || "(empty)"}`));
    }
    if (!hasContactChannel(prospect)) {
      issues.push(issue("warning", "prospect", id, "No usable public/manual contact channel."));
    }
    if (["tiktok", "instagram", "youtube"].includes(prospect.platform) && !prospect.handle && !prospect.profileUrl) {
      issues.push(issue("warning", "prospect", id, "Social prospect has no handle or profile URL."));
    }
    if (prospect.status === "do_not_contact" && prospect.lastContactedAt) {
      issues.push(issue("warning", "prospect", id, "do_not_contact prospect has a previous contact timestamp; verify no follow-up is planned."));
    }

    addDuplicateIssue(issues, seenEmail, prospect.email, id, "Duplicate email");
    addDuplicateIssue(issues, seenProfile, prospect.profileUrl, id, "Duplicate profile URL");
    addDuplicateIssue(
      issues,
      seenHandlePlatform,
      prospect.handle && prospect.platform ? `${prospect.platform}:${prospect.handle.toLowerCase()}` : "",
      id,
      "Duplicate platform/handle"
    );
  }

  return issues;
}

export function validatePromoCodes(codes: PromoCode[]): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  const seenCodes = new Map<string, string>();
  const assignedTo = new Map<string, string[]>();

  for (const code of codes) {
    const id = code.code ? maskForValidation(code.code) : "(missing code)";
    if (!code.code) {
      issues.push(issue("error", "promo-code", id, "Promo code row has no code."));
    }
    if (!PROMO_CODE_STATUSES.includes(code.status as never)) {
      issues.push(issue("error", "promo-code", id, `Unknown promo code status: ${code.status || "(empty)"}`));
    }
    addDuplicateIssue(issues, seenCodes, code.code, id, "Duplicate promo code");
    if (code.assignedToProspectId) {
      const current = assignedTo.get(code.assignedToProspectId) ?? [];
      current.push(code.code);
      assignedTo.set(code.assignedToProspectId, current);
    }
  }

  for (const [prospectId, assignedCodes] of assignedTo.entries()) {
    if (assignedCodes.length > 1) {
      issues.push(
        issue(
          "error",
          "promo-code",
          prospectId,
          `Prospect has multiple assigned promo codes: ${assignedCodes.map(maskForValidation).join(", ")}`
        )
      );
    }
  }
  return issues;
}

export function validateCrossReferences(prospects: Prospect[], codes: PromoCode[]): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  const prospectIds = new Set(prospects.map((prospect) => prospect.id));
  for (const code of codes) {
    if (code.assignedToProspectId && !prospectIds.has(code.assignedToProspectId)) {
      issues.push(
        issue("warning", "promo-code", maskForValidation(code.code), `Assigned prospect not found: ${code.assignedToProspectId}`)
      );
    }
  }
  for (const prospect of prospects) {
    if (prospect.status === "do_not_contact" && prospect.promoCode) {
      issues.push(issue("warning", "prospect", prospect.id, "do_not_contact prospect still has a promo code recorded."));
    }
    if (prospect.language === "unknown") {
      issues.push(issue("info", "prospect", prospect.id, "Language unknown: English fallback will be used only after manual review."));
    }
  }
  return issues;
}

export function complianceIssues(): ValidationIssue[] {
  const rules = loadOutreachRules();
  const issues: ValidationIssue[] = [];
  if (rules.allowAutoSend) {
    issues.push(issue("error", "compliance", "allowAutoSend", "allowAutoSend must remain false for this V1 workflow."));
  }
  if (rules.requireManualApproval) {
    issues.push(issue("info", "compliance", "manual-approval", "Manual review is required before every outreach message."));
  }
  if (rules.complianceWarnings) {
    issues.push(issue("info", "compliance", "email", rules.emailComplianceWarning));
  }
  return issues;
}

export function formatValidationReport(issues: ValidationIssue[]): string {
  const errors = issues.filter((item) => item.severity === "error");
  const warnings = issues.filter((item) => item.severity === "warning");
  const infos = issues.filter((item) => item.severity === "info");
  const lines = [
    "Validation report",
    "=================",
    "",
    `Errors: ${errors.length}`,
    `Warnings: ${warnings.length}`,
    `Info: ${infos.length}`,
    ""
  ];
  for (const severity of ["error", "warning", "info"] as const) {
    const group = issues.filter((item) => item.severity === severity);
    if (group.length === 0) {
      continue;
    }
    lines.push(severity.toUpperCase(), "-".repeat(severity.length));
    for (const item of group) {
      lines.push(`- [${item.scope}] ${item.id}: ${item.message}`);
    }
    lines.push("");
  }
  return lines.join("\n");
}

function issue(
  severity: ValidationIssue["severity"],
  scope: ValidationIssue["scope"],
  id: string,
  message: string
): ValidationIssue {
  return { severity, scope, id, message };
}

function addDuplicateIssue(
  issues: ValidationIssue[],
  seen: Map<string, string>,
  value: string,
  id: string,
  label: string
): void {
  if (!value) {
    return;
  }
  const normalized = value.toLowerCase();
  const existing = seen.get(normalized);
  if (existing) {
    issues.push(issue("warning", "prospect", id, `${label} with ${existing}: ${value}`));
    return;
  }
  seen.set(normalized, id);
}

function isValidEmail(value: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

function isValidUrl(value: string): boolean {
  try {
    const parsed = new URL(value);
    return ["http:", "https:"].includes(parsed.protocol);
  } catch {
    return false;
  }
}

function maskForValidation(code: string): string {
  if (code.length <= 6) {
    return "***";
  }
  return `${code.slice(0, 3)}...${code.slice(-4)}`;
}
