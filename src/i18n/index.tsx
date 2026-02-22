import { createContext, useContext, useState } from "react";
import { getLocales } from "expo-localization";
import { en } from "./en";
import { fr } from "./fr";
import { es } from "./es";
import { de } from "./de";
import { it } from "./it";
import { pt } from "./pt";
import type { Translations } from "./en";

export type { Translations };

type SupportedLanguage = "en" | "fr" | "es" | "de" | "it" | "pt";

/** Detect device language once at startup. Fallback to en. */
function resolveLocale(): SupportedLanguage {
  try {
    const locales = getLocales();
    const lang = locales[0]?.languageCode ?? "en";
    if (["fr", "es", "de", "it", "pt"].includes(lang)) {
      return lang as SupportedLanguage;
    }
    return "en";
  } catch {
    return "en";
  }
}

const translations: Record<SupportedLanguage, Translations> = {
  en,
  fr,
  es,
  de,
  it,
  pt,
};

const locale = resolveLocale();

type I18nContextType = Translations & {
  setLanguage: (lang: SupportedLanguage) => void;
  currentLanguage: SupportedLanguage;
};

const I18nContext = createContext<I18nContextType | null>(null);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [currentLang, setCurrentLang] = useState<SupportedLanguage>(locale);

  const value = {
    ...translations[currentLang],
    setLanguage: setCurrentLang,
    currentLanguage: currentLang,
  };

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

/** Access all translated strings */
export function useI18n(): I18nContextType {
  const context = useContext(I18nContext);
  if (!context) {
    throw new Error("useI18n must be used within an I18nProvider");
  }
  return context;
}

export const SUPPORTED_LANGUAGES: SupportedLanguage[] = [
  "fr",
  "en",
  "es",
  "de",
  "it",
  "pt",
];
