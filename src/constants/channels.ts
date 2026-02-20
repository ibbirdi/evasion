import { ChannelId, ChannelState, Preset } from "../types/mixer";

export const INITIAL_CHANNELS: Record<ChannelId, ChannelState> = {
  oiseaux: {
    id: "oiseaux",
    label: "Oiseaux",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  vent: {
    id: "vent",
    label: "Vent",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  mer: {
    id: "mer",
    label: "Mer",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  riviere: {
    id: "riviere",
    label: "Rivière",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  foret: {
    id: "foret",
    label: "Forêt",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  pluie: {
    id: "pluie",
    label: "Pluie",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  tonnerre: {
    id: "tonnerre",
    label: "Tonnerre",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  insectes: {
    id: "insectes",
    label: "Insectes",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
  ville: {
    id: "ville",
    label: "Ville",
    volume: 0.5,
    isMuted: true,
    autoVariationEnabled: false,
  },
};

export const DEFAULT_PRESETS: Preset[] = [
  {
    id: "preset_default_calm",
    name: "Calme en forêt",
    channels: {
      ...INITIAL_CHANNELS,
      foret: { ...INITIAL_CHANNELS.foret, isMuted: false, volume: 0.6 },
      oiseaux: { ...INITIAL_CHANNELS.oiseaux, isMuted: false, volume: 0.4 },
      vent: {
        ...INITIAL_CHANNELS.vent,
        isMuted: false,
        volume: 0.3,
        autoVariationEnabled: true,
      },
    },
  },
  {
    id: "preset_default_storm",
    name: "Orage lointain",
    channels: {
      ...INITIAL_CHANNELS,
      pluie: { ...INITIAL_CHANNELS.pluie, isMuted: false, volume: 0.7 },
      tonnerre: {
        ...INITIAL_CHANNELS.tonnerre,
        isMuted: false,
        volume: 0.6,
        autoVariationEnabled: true,
      },
      vent: { ...INITIAL_CHANNELS.vent, isMuted: false, volume: 0.4 },
    },
  },
];
