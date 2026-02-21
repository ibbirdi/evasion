import type { Translations } from "./en";

export const de: Translations = {
  header: {
    title: "D R I F T",
    timer: "Timer",
  },
  channels: {
    oiseaux: "Vögel",
    vent: "Wind",
    plage: "Strand",
    goelands: "Möwen",
    foret: "Wald",
    pluie: "Regen",
    tonnerre: "Donner",
    cigales: "Zikaden",
    ville: "Stadt",
  },
  presets: {
    default_calm: "Ruhiger Wald",
    default_storm: "Fernes Gewitter",
  },
  modal: {
    title: "Presets",
    defaultPresets: "Standard Presets",
    yourPresets: "Deine Presets",
    saveNew: "Neues Preset speichern",
    presetName: "Name...",
    save: "Speichern",
    cancel: "Abbrechen",
    noPresets: "Noch keine eigenen Presets.",
  },
  paywall: {
    title: "Schalten Sie das volle Erlebnis frei",
    benefit_1: "Unbegrenzter Zugang zu allen 9 Premium-Klängen",
    benefit_2: "Schlaf- und Fokus-Timer",
    benefit_3: "Speichern Sie Ihre eigenen Mixe",
    benefit_4: "Exklusives High-Fidelity-Mixing",
    no_sub: "Einmalig zahlen. Für immer Ihnen. Kein Abo.",
    cta: "Lebenslang freischalten - ",
    restore: "Käufe wiederherstellen",
    terms: "Nutzungsbedingungen",
  },
} as const satisfies Translations;
