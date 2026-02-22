import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  ChannelId,
  ChannelState,
  MixerStore,
  Preset,
  BinauralTrackId,
} from "../types/mixer";
import { INITIAL_CHANNELS, DEFAULT_PRESETS } from "../constants/channels";

export const useMixerStore = create<MixerStore>()(
  persist(
    (set, get) => ({
      // Global States
      isPlaying: false,
      timerEndTime: null,
      timerDurationChosen: null,
      currentPresetId: null,
      isPremium: false,
      isPaywallVisible: false,
      isZenMode: false,

      // Binaural States
      isBinauralActive: false,
      activeBinauralTrack: "delta" as BinauralTrackId,
      binauralVolume: 0.5,

      // Channels
      channels: INITIAL_CHANNELS,

      // Custom Presets
      presets: [...DEFAULT_PRESETS],

      // Global Actions
      togglePlayPause: () =>
        set((state) => {
          const nextIsPlaying = !state.isPlaying;
          return {
            isPlaying: nextIsPlaying,
            isZenMode: false, // Always show controls when manually toggling
          };
        }),

      setIsPremium: (isPremium: boolean) => set({ isPremium }),
      setPaywallVisible: (isPaywallVisible: boolean) =>
        set({ isPaywallVisible }),

      setIsZenMode: (isZenMode: boolean) => set({ isZenMode }),

      // Binaural Actions
      toggleBinaural: () =>
        set((state) => ({ isBinauralActive: !state.isBinauralActive })),

      setBinauralTrack: (id: BinauralTrackId) =>
        set({ activeBinauralTrack: id }),

      setBinauralVolume: (volume: number) => set({ binauralVolume: volume }),

      setTimer: (minutes: number | null) =>
        set({
          timerDurationChosen: minutes,
          timerEndTime: minutes ? Date.now() + minutes * 60 * 1000 : null,
        }),

      randomizeMix: () => {
        const isPremium = get().isPremium;
        const allChannelIds = Object.keys(INITIAL_CHANNELS) as ChannelId[];
        const freeChannels: ChannelId[] = ["oiseaux", "vent", "plage"];
        const channelIds = isPremium ? allChannelIds : freeChannels;

        const newChannels = { ...INITIAL_CHANNELS }; // Start with completely muted base

        // Pick 2 to 4 random channels to activate
        const maxActive = Math.min(4, channelIds.length);
        const minActive = Math.min(2, channelIds.length);
        const numActive =
          Math.floor(Math.random() * (maxActive - minActive + 1)) + minActive;
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
          isZenMode: true,
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
        isPremium: state.isPremium,
        isBinauralActive: state.isBinauralActive,
        activeBinauralTrack: state.activeBinauralTrack,
        binauralVolume: state.binauralVolume,
        // We do NOT persist `isPlaying`, `timerEndTime` or `timerDurationChosen`, nor `isPaywallVisible`.
      }),
      merge: (persistedState: any, currentState) => {
        const state = persistedState as Partial<MixerStore>;
        const mergedChannels = { ...currentState.channels };

        if (state.channels) {
          // Mapping of old keys to new keys to preserve user settings during the update
          const migrations: Record<string, ChannelId> = {
            mer: "plage",
            riviere: "goelands",
            insectes: "cigales",
          };

          Object.keys(state.channels).forEach((key) => {
            const newKey = (migrations[key] || key) as ChannelId;
            // Only merge if the channel exists in the current INITIAL_CHANNELS configuration
            if (mergedChannels[newKey]) {
              mergedChannels[newKey] = {
                ...mergedChannels[newKey],
                volume: state.channels![key as ChannelId].volume ?? 0.5,
                isMuted: state.channels![key as ChannelId].isMuted ?? true,
                autoVariationEnabled:
                  state.channels![key as ChannelId].autoVariationEnabled ??
                  false,
              };
            }
          });
        }

        // Migrate custom presets
        const mergedPresets =
          state.presets?.map((preset) => {
            const newChannels = { ...currentState.channels };
            const migrations: Record<string, ChannelId> = {
              mer: "plage",
              riviere: "goelands",
              insectes: "cigales",
            };

            Object.keys(preset.channels).forEach((key) => {
              const newKey = (migrations[key] || key) as ChannelId;
              if (newChannels[newKey]) {
                newChannels[newKey] = {
                  ...newChannels[newKey],
                  volume: preset.channels[key as ChannelId].volume ?? 0.5,
                  isMuted: preset.channels[key as ChannelId].isMuted ?? true,
                  autoVariationEnabled:
                    preset.channels[key as ChannelId].autoVariationEnabled ??
                    false,
                };
              }
            });

            return { ...preset, channels: newChannels };
          }) || currentState.presets;

        return {
          ...currentState,
          ...state,
          channels: mergedChannels,
          presets: mergedPresets,
          isPremium: state.isPremium ?? false,
        };
      },
    },
  ),
);
