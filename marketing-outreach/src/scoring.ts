import { loadScoringConfig } from "./config.js";
import type { Prospect, ScoreResult, ScoreTier, ScoringConfig } from "./types.js";
import { CONTACT_METHODS, PROSPECT_STATUSES, SUPPORTED_LANGUAGES } from "./types.js";
import { compactReason, containsAny, numberFrom } from "./utils/text.js";

export function scoreProspect(prospect: Prospect, config: ScoringConfig = loadScoringConfig()): ScoreResult {
  const weights = config.weights;
  const reasons: string[] = [];
  let score = 20;

  const niche = prospect.niche.toLowerCase();
  if (config.highFitNiches.includes(niche)) {
    score += weights.highFitNiche ?? 0;
    reasons.push(`high-fit niche: ${niche}`);
  } else if (config.mediumFitNiches.includes(niche)) {
    score += weights.mediumFitNiche ?? 0;
    reasons.push(`medium-fit niche: ${niche}`);
  } else if (niche) {
    reasons.push(`niche needs review: ${niche}`);
  } else {
    score -= 8;
    reasons.push("missing niche");
  }

  const followers = numberFrom(prospect.followers);
  if (followers !== null) {
    if (followers >= 1_000 && followers <= 50_000) {
      score += weights.microCreator ?? 0;
      reasons.push("micro-creator range");
    } else if (followers > 50_000 && followers <= 150_000) {
      score += weights.smallCreator ?? 0;
      reasons.push("larger but still reachable");
    } else if (followers > 150_000) {
      score += weights.largeCreatorPenalty ?? 0;
      reasons.push("large account penalty");
    } else {
      score += 3;
      reasons.push("small audience");
    }
  } else {
    reasons.push("followers unknown");
  }

  if (SUPPORTED_LANGUAGES.includes(prospect.language as never)) {
    score += weights.supportedLanguage ?? 0;
    reasons.push(`localized language: ${prospect.language}`);
  } else if (prospect.language === "unknown" || !prospect.language) {
    score += weights.unknownLanguagePenalty ?? 0;
    reasons.push("language unknown");
  } else {
    score += weights.unsupportedLanguagePenalty ?? 0;
    reasons.push(`unsupported language: ${prospect.language}`);
  }

  if (hasContactChannel(prospect)) {
    score += weights.publicContact ?? 0;
    reasons.push("public contact path");
  } else {
    score -= 18;
    reasons.push("no contact path");
  }

  const noteText = `${prospect.notes} ${prospect.engagementHint}`;
  if (containsAny(noteText, config.positiveNoteKeywords)) {
    score += weights.manualPositiveNote ?? 0;
    reasons.push("positive manual signals");
  }
  if (containsAny(noteText, config.negativeNoteKeywords)) {
    score += weights.manualNegativeNote ?? 0;
    reasons.push("negative manual signals");
  }
  if (containsAny(noteText, ["high engagement", "active comments", "engaged", "responds", "responsive"])) {
    score += weights.engagementPositive ?? 0;
    reasons.push("engagement looks healthy");
  }
  if (containsAny(noteText, ["low engagement", "inactive", "dead account"])) {
    score += weights.engagementNegative ?? 0;
    reasons.push("engagement concern");
  }
  if (containsAny(noteText, ["spammy", "bot", "mass giveaway", "fake followers"])) {
    score += weights.spammyPenalty ?? 0;
    reasons.push("spam risk");
  }
  if (containsAny(noteText, ["brand only", "agency", "store account"]) && !["ios_apps", "indie_apps"].includes(niche)) {
    score += weights.irrelevantBrandPenalty ?? 0;
    reasons.push("brand account may be irrelevant");
  }

  if (prospect.country && !config.targetCountries.includes(prospect.country.toUpperCase())) {
    score -= 5;
    reasons.push(`country outside priority list: ${prospect.country}`);
  }

  if (prospect.status === "do_not_contact") {
    score += weights.doNotContactPenalty ?? 0;
    reasons.push("do not contact");
  } else if (!PROSPECT_STATUSES.includes(prospect.status as never)) {
    score -= 8;
    reasons.push("unknown status");
  }

  const boundedScore = Math.max(0, Math.min(100, Math.round(score)));
  const tier = tierForScore(boundedScore, config);
  return {
    score: boundedScore,
    tier,
    reason: compactReason(reasons),
    priority: priorityForTier(tier, boundedScore)
  };
}

export function applyScores(prospects: Prospect[]): Prospect[] {
  return prospects.map((prospect) => {
    const result = scoreProspect(prospect);
    return {
      ...prospect,
      score: String(result.score),
      tier: result.tier,
      scoreReason: result.reason,
      priority: String(result.priority),
      updatedAt: new Date().toISOString()
    };
  });
}

export function hasContactChannel(prospect: Prospect): boolean {
  const method = prospect.contactMethod;
  if (!CONTACT_METHODS.includes(method as never)) {
    return false;
  }
  if (method === "email") {
    return Boolean(prospect.email);
  }
  if (method === "dm") {
    return Boolean(prospect.handle || prospect.profileUrl);
  }
  if (method === "comment" || method === "form") {
    return Boolean(prospect.profileUrl);
  }
  return Boolean(prospect.handle || prospect.profileUrl || prospect.email || prospect.notes);
}

export function isContactableStatus(status: string): boolean {
  return ["new", "shortlisted"].includes(status);
}

export function canAssignCodeStatus(status: string): boolean {
  return ["new", "shortlisted", "contacted", "replied"].includes(status);
}

function tierForScore(score: number, config: ScoringConfig): ScoreTier {
  if (score >= config.tiers.A) {
    return "A";
  }
  if (score >= config.tiers.B) {
    return "B";
  }
  if (score >= config.tiers.C) {
    return "C";
  }
  return "D";
}

function priorityForTier(tier: ScoreTier, score: number): number {
  const base = { A: 1000, B: 2000, C: 3000, D: 4000 }[tier];
  return base - score;
}
