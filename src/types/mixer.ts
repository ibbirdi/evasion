import { AUDIO_CONFIG } from "../config/audio";

export type ChannelId = keyof typeof AUDIO_CONFIG;

export interface ChannelState {
  id: ChannelId;
  volume: number; // 0.0 to 1.0
  isMuted: boolean;
  autoVariationEnabled: boolean;
}

export interface Preset {
  id: string;
  name: string;
  channels: Record<ChannelId, ChannelState>;
}

export interface MixerState {
  // Global States
  isPlaying: boolean;
  timerEndTime: number | null; // Timestamp of timer end
  timerDurationChosen: number | null; // e.g 15, 30, 60
  currentPresetId: string | null;

  // Freemium States
  isPremium: boolean;
  isPaywallVisible: boolean;

  // Channels
  channels: Record<ChannelId, ChannelState>;

  // Custom Presets
  presets: Preset[];
}

export interface MixerActions {
  // Global Actions
  togglePlayPause: () => void;
  setTimer: (minutes: number | null) => void;
  randomizeMix: () => void;
  setIsPremium: (value: boolean) => void;
  setPaywallVisible: (value: boolean) => void;

  // Channel Actions
  setChannelVolume: (id: ChannelId, volume: number) => void;
  setAutoChannelVolume: (id: ChannelId, volume: number) => void;
  toggleChannelMute: (id: ChannelId) => void;
  toggleChannelAutoVariation: (id: ChannelId) => void;

  // Preset Actions
  loadPreset: (presetId: string) => void;
  saveUserPreset: (name: string) => void;
  deleteUserPreset: (presetId: string) => void;
}

export type MixerStore = MixerState & MixerActions;
