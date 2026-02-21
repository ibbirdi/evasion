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
    noPresets: "Aún no hay preajustes personalizados.",
  },
  paywall: {
    title: "Desbloquea la experiencia completa",
    benefit_1: "Acceso ilimitado a los 9 sonidos premium",
    benefit_2: "Temporizador de sueño y concentración",
    benefit_3: "Guarda tus mezclas personalizadas",
    benefit_4: "Mezcla exclusiva de alta fidelidad",
    no_sub: "Pago único. Tuyo para siempre. Sin suscripciones.",
    cta: "Desbloquear de por vida - ",
    restore: "Restaurar compras",
    terms: "Términos de uso",
  },
} as const satisfies Translations;
