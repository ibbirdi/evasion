import { ChannelId, ChannelState, Preset } from "../types/mixer";
import { AUDIO_CONFIG } from "../config/audio";

export const INITIAL_CHANNELS = (
  Object.keys(AUDIO_CONFIG) as ChannelId[]
).reduce(
  (acc, key) => {
    acc[key] = {
      id: key,
      volume: 0.5,
      isMuted: true,
      autoVariationEnabled: false,
    };
    return acc;
  },
  {} as Record<ChannelId, ChannelState>,
);

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
