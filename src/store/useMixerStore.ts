import AsyncStorage from "@react-native-async-storage/async-storage";
import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";
import { DEFAULT_PRESETS, INITIAL_CHANNELS } from "../constants/channels";
import { BinauralTrackId, ChannelId, MixerStore, Preset } from "../types/mixer";

export const useMixerStore = create<MixerStore>()(
  persist(
    (set, get) => ({
      // Global States
      isPlaying: false,
      timerEndTime: null,
      timerDurationChosen: null,
      currentPresetId: null,
      // Dev override for testing premium features
      isPremium: process.env.EXPO_PUBLIC_FORCE_PREMIUM === "true",
      isPaywallVisible: false,
      isBinauralPopupVisible: false,

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
        set((state) => ({
          isPlaying: !state.isPlaying,
        })),

      setIsPremium: (isPremium: boolean) =>
        set({
          isPremium:
            process.env.EXPO_PUBLIC_FORCE_PREMIUM === "true"
              ? true
              : process.env.EXPO_PUBLIC_FORCE_PREMIUM === "false"
                ? false
                : isPremium,
        }),
      setPaywallVisible: (isPaywallVisible: boolean) =>
        set({ isPaywallVisible }),
      setBinauralPopupVisible: (isBinauralPopupVisible: boolean) =>
        set({ isBinauralPopupVisible }),

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
        const isPremium =
          process.env.EXPO_PUBLIC_FORCE_PREMIUM === "true"
            ? true
            : process.env.EXPO_PUBLIC_FORCE_PREMIUM === "false"
              ? false
              : get().isPremium;
        const allChannelIds = Object.keys(INITIAL_CHANNELS) as ChannelId[];
        const freeChannels: ChannelId[] = ["oiseaux", "vent", "plage"];
        const channelIds = isPremium ? allChannelIds : freeChannels;

        const newChannels = { ...INITIAL_CHANNELS }; // Start with completely muted base

        // Pick 2 to 4 random channels to activate
        const maxActive = Math.min(8, channelIds.length);
        const minActive = Math.min(4, channelIds.length);
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

      reorderPresets: (fromIndex: number, toIndex: number) =>
        set((state) => {
          const newPresets = [...state.presets];
          const [moved] = newPresets.splice(fromIndex, 1);
          newPresets.splice(toIndex, 0, moved);
          return { presets: newPresets };
        }),
    }),
    {
      name: "evasion-mixer-storage",
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({
        channels: state.channels,
        presets: state.presets,
        currentPresetId: state.currentPresetId,
        isPremium:
          process.env.EXPO_PUBLIC_FORCE_PREMIUM === "true"
            ? true
            : process.env.EXPO_PUBLIC_FORCE_PREMIUM === "false"
              ? false
              : state.isPremium,
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
            ville: "village",
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
              ville: "village",
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
          isPremium:
            process.env.EXPO_PUBLIC_FORCE_PREMIUM === "true"
              ? true
              : process.env.EXPO_PUBLIC_FORCE_PREMIUM === "false"
                ? false
                : (state.isPremium ?? false),
        };
      },
    },
  ),
);
