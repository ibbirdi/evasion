import type { Translations } from "./en";

export const fr: Translations = {
  header: {
    title: "É V A S I O N",
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
    title: "Presets",
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
} as const satisfies Translations;
