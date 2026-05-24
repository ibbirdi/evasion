import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { EXPORTS_DIR, TEMPLATES_DIR, loadAppConfig, loadMessageVariants, loadNiches, resolveLanguage } from "./config.js";
import { getAssignedCode } from "./codeAllocator.js";
import type { Prospect, SupportedLanguage } from "./types.js";
import { todayStamp } from "./utils/dates.js";
import { slugify } from "./utils/slug.js";
import { clean, firstName } from "./utils/text.js";

export interface RenderMessageOptions {
  prospect: Prospect;
  template?: string;
  lang?: string;
  writeFile?: boolean;
}

export interface RenderedMessage {
  language: SupportedLanguage;
  templateName: string;
  message: string;
  outputPath: string;
  promoCode: string;
  warning: string;
}

export async function renderMessage(options: RenderMessageOptions): Promise<RenderedMessage> {
  const variants = loadMessageVariants();
  const language = resolveLanguage(options.lang || options.prospect.language, variants.fallbackLanguage);
  const variant = variants.languages[language];
  const templateName = normalizeTemplateName(options.template || recommendedTemplate(options.prospect, language), language);
  const templatePath = join(TEMPLATES_DIR, `${templateName}.txt`);
  const template = await readFile(templatePath, "utf8");
  const assignedCode = options.prospect.promoCode || (await getAssignedCode(options.prospect.id));
  const warning = options.prospect.language === "unknown" && !options.lang ? variant.unknownLanguageWarning : "";
  const message = renderTemplate(template, buildVariables(options.prospect, language, assignedCode));
  let outputPath = "";
  if (options.writeFile) {
    const dir = join(EXPORTS_DIR, "messages", todayStamp());
    await mkdir(dir, { recursive: true });
    outputPath = join(dir, `${slugify(options.prospect.id)}-${slugify(templateName)}.txt`);
    await writeFile(outputPath, message, "utf8");
  }
  return { language, templateName, message, outputPath, promoCode: assignedCode, warning };
}

export function recommendedTemplate(prospect: Prospect, language: SupportedLanguage): string {
  const niches = loadNiches();
  const niche = niches[prospect.niche];
  const base =
    templateFromContact(prospect) ||
    niche?.recommendedTemplates[0] ||
    loadMessageVariants().languages[language].defaultTemplate.replace(`.${language}`, "");
  return normalizeTemplateName(base, language);
}

export function normalizeTemplateName(templateName: string, language: SupportedLanguage): string {
  const cleanName = clean(templateName).replace(/\.txt$/, "");
  if (cleanName.endsWith(`.${language}`)) {
    return cleanName;
  }
  if (/\.(fr|en|es|de|it|pt-BR)$/.test(cleanName)) {
    return cleanName;
  }
  return `${cleanName}.${language}`;
}

function templateFromContact(prospect: Prospect): string {
  if (prospect.platform === "reddit") {
    return "reddit-feedback";
  }
  if (prospect.platform === "blog" || prospect.platform === "newsletter") {
    return "email-reviewer";
  }
  if (prospect.contactMethod === "email") {
    return ["ios_apps", "apple", "indie_apps"].includes(prospect.niche) ? "email-reviewer" : "email-creator";
  }
  if (prospect.platform === "tiktok") {
    return "dm-tiktok";
  }
  if (prospect.platform === "instagram") {
    return "dm-instagram";
  }
  return "dm-creator";
}

function buildVariables(prospect: Prospect, language: SupportedLanguage, promoCode: string): Record<string, string> {
  const appConfig = loadAppConfig();
  const niches = loadNiches();
  const variants = loadMessageVariants();
  const variant = variants.languages[language];
  const localizedNiche = variant.angles[prospect.niche] ?? niches[prospect.niche]?.label ?? prospect.niche;
  return {
    appName: appConfig.appName,
    appStoreUrl: appConfig.appStoreUrl,
    senderName: appConfig.senderName,
    premiumDescription: appConfig.premiumDescription,
    name: greetingName(prospect.name) || prospect.handle || "there",
    fullName: prospect.name,
    handle: prospect.handle,
    platform: prospect.platform,
    niche: localizedNiche,
    nicheKey: prospect.niche,
    angle: variant.angles[prospect.niche] ?? variant.angles.default ?? "",
    promoCode: promoCode || variant.promoCodeMissingText,
    language
  };
}

function greetingName(name: string): string {
  const value = clean(name);
  if (!value) {
    return "";
  }
  const byMatch = value.match(/\bby\s+([A-Za-zÀ-ÿ]+)/i);
  if (byMatch?.[1]) {
    return byMatch[1];
  }
  const slashParts = value.split("/").map((part) => clean(part)).filter(Boolean);
  if (slashParts.length > 1) {
    return slashParts.at(-1) ?? slashParts[0] ?? value;
  }
  const words = value.split(/\s+/);
  const first = words[0] ?? value;
  const lowerFirst = first.toLowerCase();
  const genericFirstWords = new Set(["study", "lofi", "white", "whispering", "sleepful", "tiefer", "tff"]);
  if (genericFirstWords.has(lowerFirst)) {
    return value;
  }
  return firstName(value);
}

function renderTemplate(template: string, variables: Record<string, string>): string {
  return template.replace(/\{\{([a-zA-Z0-9_]+)\}\}/g, (_, key: string) => variables[key] ?? "");
}
