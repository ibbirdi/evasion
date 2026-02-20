import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { ChannelId, ChannelState, MixerStore, Preset } from "../types/mixer";
import { INITIAL_CHANNELS, DEFAULT_PRESETS } from "../constants/channels";

export const useMixerStore = create<MixerStore>()(
  persist(
    (set, get) => ({
      // Global States
      isPlaying: false,
      timerEndTime: null,
      timerDurationChosen: null,
      currentPresetId: null,

      // Channels
      channels: INITIAL_CHANNELS,

      // Custom Presets
      presets: [...DEFAULT_PRESETS],

      // Global Actions
      togglePlayPause: () => set((state) => ({ isPlaying: !state.isPlaying })),

      setTimer: (minutes: number | null) =>
        set({
          timerDurationChosen: minutes,
          timerEndTime: minutes ? Date.now() + minutes * 60 * 1000 : null,
        }),

      randomizeMix: () => {
        const channelIds = Object.keys(INITIAL_CHANNELS) as ChannelId[];
        const newChannels = { ...INITIAL_CHANNELS }; // Start with completely muted base

        // Pick 2 to 4 random channels to activate
        const numActive = Math.floor(Math.random() * 3) + 2;
        const shuffled = channelIds.sort(() => 0.5 - Math.random());
        const selected = shuffled.slice(0, numActive);

        selected.forEach((id) => {
          newChannels[id] = {
            ...INITIAL_CHANNELS[id],
            isMuted: false,
            volume: 0.3 + Math.random() * 0.5, // Volume between 0.3 and 0.8
            autoVariationEnabled: Math.random() > 0.5, // 50% chance to have auto variation
          };
        });

        set({
          channels: newChannels,
          currentPresetId: null, // Custom random mix
          isPlaying: true, // Auto play when randomized
        });
      },

      // Channel Actions
      setChannelVolume: (id: ChannelId, volume: number) =>
        set((state) => ({
          channels: {
            ...state.channels,
            [id]: { ...state.channels[id], volume },
          },
          currentPresetId: null, // Any manual change detaches from current preset
        })),

      setAutoChannelVolume: (id: ChannelId, volume: number) =>
        set((state) => ({
          channels: {
            ...state.channels,
            [id]: { ...state.channels[id], volume },
          },
          // Keep current preset intact for auto-variation adjustments
        })),

      toggleChannelMute: (id: ChannelId) =>
        set((state) => ({
          channels: {
            ...state.channels,
            [id]: {
              ...state.channels[id],
              isMuted: !state.channels[id].isMuted,
            },
          },
          currentPresetId: null,
        })),

      toggleChannelAutoVariation: (id: ChannelId) =>
        set((state) => ({
          channels: {
            ...state.channels,
            [id]: {
              ...state.channels[id],
              autoVariationEnabled: !state.channels[id].autoVariationEnabled,
            },
          },
          currentPresetId: null,
        })),

      // Preset Actions
      loadPreset: (presetId: string) => {
        const preset = get().presets.find((p) => p.id === presetId);
        if (preset) {
          set({
            channels: preset.channels,
            currentPresetId: presetId,
          });
        }
      },

      saveUserPreset: (name: string) => {
        const newPreset: Preset = {
          id: `preset_user_${Date.now()}`,
          name,
          channels: get().channels,
        };
        set((state) => ({
          presets: [...state.presets, newPreset],
          currentPresetId: newPreset.id,
        }));
      },

      deleteUserPreset: (presetId: string) =>
        set((state) => ({
          presets: state.presets.filter((p) => p.id !== presetId),
          currentPresetId:
            state.currentPresetId === presetId ? null : state.currentPresetId,
        })),
    }),
    {
      name: "evasion-mixer-storage",
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        channels: state.channels,
        presets: state.presets,
        currentPresetId: state.currentPresetId,
        // We do NOT persist `isPlaying`, `timerEndTime` or `timerDurationChosen`.
      }),
    },
  ),
);
