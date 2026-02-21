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
    grillons: "Grilli",
    ville: "Città",
    voiture: "Auto",
    train: "Treno",
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
    noPresets: "Nessun preset personalizzato ancora.",
  },
  paywall: {
    title: "Sblocca l'esperienza completa",
    benefit_1: "Accesso illimitato a tutti i 12 suoni premium",
    benefit_2: "Timer per il sonno e la concentrazione",
    benefit_3: "Salva i tuoi mix personalizzati",
    benefit_4: "Mixaggio esclusivo ad alta fedeltà",
    no_sub: "Paghi una volta. Tuo per sempre. Nessun abbonamento.",
    cta: "Sblocca a vita - ",
    restore: "Ripristina acquisti",
    terms: "Termini di utilizzo",
  },
} as const satisfies Translations;
