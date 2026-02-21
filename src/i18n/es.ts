import type { Translations } from "./en";

export const es: Translations = {
  header: {
    title: "O A S I S",
    timer: "Temp",
  },
  channels: {
    oiseaux: "Pájaros",
    vent: "Viento",
    plage: "Playa",
    goelands: "Gaviotas",
    foret: "Bosque",
    pluie: "Lluvia",
    tonnerre: "Truenos",
    cigales: "Cigarras",
    ville: "Ciudad",
  },
  presets: {
    default_calm: "Bosque Trancuilo",
    default_storm: "Tormenta Lejana",
  },
  modal: {
    title: "Presets",
    defaultPresets: "Presets por defecto",
    yourPresets: "Tus presets",
    saveNew: "Guardar nuevo",
    presetName: "Nombre...",
    save: "Guardar",
    cancel: "Cancelar",
    noPresets: "No hay presets personalizados.",
  },
} as const satisfies Translations;
