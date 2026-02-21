export const AUDIO_CONFIG = {
  oiseaux: {
    id: "oiseaux",
    sources: [require("../../assets/audio/oiseaux1.m4a")],
  },
  vent: {
    id: "vent",
    sources: [require("../../assets/audio/vent1.m4a")], // NOTE: Check if it was vent.m4a or vent1.m4a
  },
  plage: {
    id: "plage",
    sources: [require("../../assets/audio/plage1.m4a")],
  },
  goelands: {
    id: "goelands",
    sources: [require("../../assets/audio/goelants1.m4a")], // Notice typo in filename goelants1.m4a vs goelands
  },
  foret: {
    id: "foret",
    sources: [require("../../assets/audio/foret1.m4a")],
  },
  pluie: {
    id: "pluie",
    sources: [require("../../assets/audio/pluie1.m4a")],
  },
  tonnerre: {
    id: "tonnerre",
    sources: [require("../../assets/audio/orage1.m4a")],
  },
  cigales: {
    id: "cigales",
    sources: [require("../../assets/audio/cigales1.m4a")],
  },
  grillons: {
    id: "grillons",
    sources: [require("../../assets/audio/grillons1.m4a")],
  },
  ville: {
    id: "ville",
    sources: [require("../../assets/audio/ville1.m4a")],
  },
  voiture: {
    id: "voiture",
    sources: [require("../../assets/audio/voiture1.m4a")],
  },
  train: {
    id: "train",
    sources: [require("../../assets/audio/train1.m4a")],
  },
} as const;

export type ChannelId = keyof typeof AUDIO_CONFIG;
