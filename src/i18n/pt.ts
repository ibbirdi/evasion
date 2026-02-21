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
    noPresets: "Nenhum preset personalizado ainda.",
  },
  paywall: {
    title: "Desbloqueie a experiência completa",
    benefit_1: "Acesso ilimitado a todos os 9 sons premium",
    benefit_2: "Timer de sono e concentração",
    benefit_3: "Salve suas mixagens personalizadas",
    benefit_4: "Mixagem exclusiva de alta fidelidade",
    no_sub: "Pague uma vez. Seu para sempre. Sem assinaturas.",
    cta: "Desbloqueio vitalício - ",
    restore: "Restaurar compras",
    terms: "Termos de uso",
  },
} as const satisfies Translations;
