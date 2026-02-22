import { BinauralTrackId } from "../types/mixer";

export interface BinauralTrackConfig {
  id: BinauralTrackId;
  source: ReturnType<typeof require>;
  isPremium: boolean;
}

export const BINAURAL_TRACKS: Record<BinauralTrackId, BinauralTrackConfig> = {
  delta: {
    id: "delta",
    source: require("../../assets/audio/1_binaural_sleep_delta.m4a"),
    isPremium: false,
  },
  theta: {
    id: "theta",
    source: require("../../assets/audio/2_binaural_meditation_theta.m4a"),
    isPremium: true,
  },
  alpha: {
    id: "alpha",
    source: require("../../assets/audio/3_binaural_relax_alpha.m4a"),
    isPremium: true,
  },
  beta: {
    id: "beta",
    source: require("../../assets/audio/4_binaural_focus_beta.m4a"),
    isPremium: true,
  },
} as const;
