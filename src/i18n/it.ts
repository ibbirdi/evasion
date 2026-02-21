import type { Translations } from "./en";

export const it: Translations = {
  header: {
    title: "O A S I",
    timer: "Timer",
  },
  channels: {
    oiseaux: "Uccelli",
    vent: "Vento",
    plage: "Spiaggia",
    goelands: "Gabbiani",
    foret: "Foresta",
    pluie: "Pioggia",
    tonnerre: "Tuono",
    cigales: "Cicale",
    ville: "Città",
  },
  presets: {
    default_calm: "Foresta Calma",
    default_storm: "Tempesta Lontana",
  },
  modal: {
    title: "Preset",
    defaultPresets: "Preset Predefiniti",
    yourPresets: "I tuoi Preset",
    saveNew: "Salva nuovo",
    presetName: "Nome...",
    save: "Salva",
    cancel: "Annulla",
    noPresets: "Nessun preset personalizzato.",
  },
} as const satisfies Translations;
