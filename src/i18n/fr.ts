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
    ville: "Ville",
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
} as const satisfies Translations;
