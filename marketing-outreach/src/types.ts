export const SUPPORTED_LANGUAGES = ["fr", "en", "es", "de", "it", "pt-BR"] as const;
export const PROSPECT_LANGUAGES = [...SUPPORTED_LANGUAGES, "unknown"] as const;
export const PLATFORMS = ["tiktok", "instagram", "youtube", "reddit", "blog", "newsletter", "other"] as const;
export const CONTACT_METHODS = ["dm", "email", "comment", "form", "manual"] as const;
export const PROSPECT_STATUSES = [
  "new",
  "shortlisted",
  "contacted",
  "replied",
  "code_sent",
  "posted",
  "reviewed",
  "rejected",
  "no_response",
  "do_not_contact"
] as const;
export const PROMO_CODE_STATUSES = ["available", "assigned", "sent", "redeemed", "expired", "reserved", "invalid"] as const;
export const RESPONSE_TYPES = ["positive", "neutral", "negative", "asked_question", "posted", "review_left", "no_interest"] as const;
export const SCORE_TIERS = ["A", "B", "C", "D"] as const;

export type SupportedLanguage = (typeof SUPPORTED_LANGUAGES)[number];
export type ProspectLanguage = (typeof PROSPECT_LANGUAGES)[number];
export type Platform = (typeof PLATFORMS)[number];
export type ContactMethod = (typeof CONTACT_METHODS)[number];
export type ProspectStatus = (typeof PROSPECT_STATUSES)[number];
export type PromoCodeStatus = (typeof PROMO_CODE_STATUSES)[number];
export type ResponseType = (typeof RESPONSE_TYPES)[number];
export type ScoreTier = (typeof SCORE_TIERS)[number];

export type CsvRecord = Record<string, string>;

export interface Prospect extends CsvRecord {
  id: string;
  name: string;
  handle: string;
  platform: string;
  profileUrl: string;
  email: string;
  niche: string;
  followers: string;
  engagementHint: string;
  country: string;
  language: string;
  contactMethod: string;
  notes: string;
  status: string;
  score: string;
  tier: string;
  scoreReason: string;
  priority: string;
  promoCode: string;
  lastContactedAt: string;
  lastFollowupAt: string;
  followupCount: string;
  createdAt: string;
  updatedAt: string;
}

export interface PromoCode extends CsvRecord {
  code: string;
  status: string;
  assignedToProspectId: string;
  assignedAt: string;
  redeemed: string;
  notes: string;
}

export interface OutreachLogEntry extends CsvRecord {
  timestamp: string;
  prospectId: string;
  action: string;
  status: string;
  responseType: string;
  note: string;
  template: string;
  language: string;
  codeMasked: string;
}

export interface ResponseEntry extends CsvRecord {
  timestamp: string;
  prospectId: string;
  type: string;
  note: string;
}

export interface AppConfig {
  appName: string;
  appStoreUrl: string;
  senderName: string;
  premiumDescription: string;
  defaultLanguage: SupportedLanguage;
  fallbackLanguage: SupportedLanguage;
  brandTone: string;
}

export interface OutreachRules {
  dailyContactLimit: number;
  maxFollowups: number;
  minDaysBeforeFollowup: number;
  requireManualApproval: boolean;
  allowAutoSend: boolean;
  complianceWarnings: boolean;
  supportedLanguages: SupportedLanguage[];
  emailComplianceWarning: string;
}

export interface ScoringConfig {
  tiers: Record<ScoreTier, number>;
  weights: Record<string, number>;
  highFitNiches: string[];
  mediumFitNiches: string[];
  positiveNoteKeywords: string[];
  negativeNoteKeywords: string[];
  targetCountries: string[];
}

export interface NicheConfig {
  label: string;
  description: string;
  recommendedAngles: string[];
  recommendedTemplates: string[];
  manualSearchKeywords: string[];
}

export interface MessageLanguageVariant {
  displayName: string;
  promoCodeMissingText: string;
  templateSuffix: string;
  defaultTemplate: string;
  unknownLanguageWarning: string;
  angles: Record<string, string>;
}

export interface MessageVariantsConfig {
  fallbackLanguage: SupportedLanguage;
  languages: Record<SupportedLanguage, MessageLanguageVariant>;
}

export interface ScoreResult {
  score: number;
  tier: ScoreTier;
  reason: string;
  priority: number;
}

export interface PlanItem {
  prospect: Prospect;
  score: ScoreResult;
  recommendedTemplate: string;
  promoCode: string;
  message: string;
  nextAction: string;
}

export interface ValidationIssue {
  severity: "error" | "warning" | "info";
  scope: "prospect" | "promo-code" | "compliance" | "system";
  id: string;
  message: string;
}

export const PROSPECT_COLUMNS = [
  "id",
  "name",
  "handle",
  "platform",
  "profileUrl",
  "email",
  "niche",
  "followers",
  "engagementHint",
  "country",
  "language",
  "contactMethod",
  "notes",
  "status",
  "score",
  "tier",
  "scoreReason",
  "priority",
  "promoCode",
  "lastContactedAt",
  "lastFollowupAt",
  "followupCount",
  "createdAt",
  "updatedAt"
] as const;

export const PROMO_CODE_COLUMNS = ["code", "status", "assignedToProspectId", "assignedAt", "redeemed", "notes"] as const;
export const OUTREACH_LOG_COLUMNS = [
  "timestamp",
  "prospectId",
  "action",
  "status",
  "responseType",
  "note",
  "template",
  "language",
  "codeMasked"
] as const;
export const RESPONSE_COLUMNS = ["timestamp", "prospectId", "type", "note"] as const;
