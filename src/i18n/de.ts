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
} as const satisfies Translations;
