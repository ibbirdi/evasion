import type { Translations } from "./en";

export const pt: Translations = {
  header: {
    title: "R E F Ú G I O",
    timer: "Timer",
  },
  channels: {
    oiseaux: "Pássaros",
    vent: "Vento",
    plage: "Praia",
    goelands: "Gaivotas",
    foret: "Floresta",
    pluie: "Chuva",
    tonnerre: "Trovão",
    cigales: "Cigarras",
    ville: "Cidade",
  },
  presets: {
    default_calm: "Floresta Calma",
    default_storm: "Tempestade Distante",
  },
  modal: {
    title: "Presets",
    defaultPresets: "Padrão",
    yourPresets: "Seus Presets",
    saveNew: "Salvar novo",
    presetName: "Nome...",
    save: "Salvar",
    cancel: "Cancelar",
    noPresets: "Nenhum preset ainda.",
  },
} as const satisfies Translations;
