import { createContext, useContext } from "react";
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
const activeTranslations = translations[locale];

const I18nContext = createContext<Translations>(activeTranslations);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  return (
    <I18nContext.Provider value={activeTranslations}>
      {children}
    </I18nContext.Provider>
  );
}

/** Access all translated strings */
export function useI18n(): Translations {
  return useContext(I18nContext);
}
