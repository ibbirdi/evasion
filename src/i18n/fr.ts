import type { Translations } from "./en";

export const fr: Translations = {
  header: {
    title: "Evasion",
    timer: "Timer",
  },
  channels: {
    oiseaux: "Oiseaux",
    vent: "Vent",
    plage: "Plage",
    goelands: "Goélands",
    foret: "Forêt",
    pluie: "Pluie",
    tonnerre: "Orage",
    cigales: "Cigales",
    grillons: "Grillons",
    ville: "Ville",
    voiture: "Voiture",
    train: "Train",
  },
  presets: {
    default_calm: "Calme en forêt",
    default_storm: "Orage lointain",
  },
  modal: {
    title: "Mes évasions",
    defaultPresets: "Presets par défaut",
    yourPresets: "Vos presets",
    saveNew: "Nouveau preset",
    presetName: "Nom...",
    save: "Enregistrer",
    cancel: "Annuler",
    noPresets: "Aucun preset personnalisé.",
  },
  paywall: {
    title: "Débloquez l'expérience complète",
    benefit_1: "Accès illimité aux 12 sons premium",
    benefit_2: "Minuteur de sommeil et concentration",
    benefit_3: "Sauvegardez vos mix personnalisés",
    benefit_4: "Mixage exclusif haute fidélité",
    no_sub: "Paiement unique. Zéro abonnement.",
    cta: "Débloquer à vie - ",
    restore: "Restaurer les achats",
    terms: "Conditions d'utilisation",
  },
  binaural: {
    title: "SONS BINAURAUX",
    delta: "Sommeil",
    theta: "Relaxation",
    alpha: "Concentration",
    beta: "Éveil",
    headphones_hint: "Casque stéréo recommandé",
  },
  mixer: {
    auto_variation: "VARIATION AUTO",
  },
} as const satisfies Translations;
