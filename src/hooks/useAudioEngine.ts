import { useEffect, useRef } from "react";
import { useAudioPlayer, setAudioModeAsync, AudioPlayer } from "expo-audio";
import {
  useSharedValue,
  withTiming,
  Easing,
  runOnJS,
} from "react-native-reanimated";
import { useMixerStore } from "../store/useMixerStore";
import { ChannelId } from "../types/mixer";

export function useAudioEngine() {
  const {
    isPlaying,
    channels,
    timerEndTime,
    timerDurationChosen,
    setTimer,
    togglePlayPause,
  } = useMixerStore();

  // Load all audio tracks
  const players: Record<ChannelId, AudioPlayer> = {
    oiseaux: useAudioPlayer(require("../../assets/audio/oiseaux.m4a")),
    vent: useAudioPlayer(require("../../assets/audio/vent.m4a")),
    mer: useAudioPlayer(require("../../assets/audio/mer.m4a")),
    riviere: useAudioPlayer(require("../../assets/audio/riviere.m4a")),
    foret: useAudioPlayer(require("../../assets/audio/foret.m4a")),
    pluie: useAudioPlayer(require("../../assets/audio/pluie.m4a")),
    tonnerre: useAudioPlayer(require("../../assets/audio/tonnerre.m4a")),
    insectes: useAudioPlayer(require("../../assets/audio/insectes.m4a")),
    ville: useAudioPlayer(require("../../assets/audio/ville.m4a")),
  };

  const initializedOffsets = useRef<Record<string, boolean>>({});

  // 1. Initial configuration for Background Audio
  useEffect(() => {
    setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: "mixWithOthers", // Allow mixing with music or keep focus
    });
  }, []);

  // 2. Play/Pause and Looping Sync
  useEffect(() => {
    Object.keys(players).forEach((key) => {
      const channelId = key as ChannelId;
      const player = players[channelId];

      if (isPlaying) {
        player.loop = true;

        if (!player.playing) {
          player.play();
        }

        // Apply Random Offset only once per player when it becomes loaded
        if (
          player.isLoaded &&
          !initializedOffsets.current[channelId] &&
          player.duration > 0
        ) {
          player.seekTo(Math.random() * player.duration);
          initializedOffsets.current[channelId] = true;
        }
      } else {
        if (player.playing) {
          player.pause();
        }
      }
    });

    // Check periodically for loaded offsets if they missed the immediate check
    let offsetCheckInterval: NodeJS.Timeout | null = null;
    if (isPlaying) {
      offsetCheckInterval = setInterval(() => {
        Object.keys(players).forEach((key) => {
          const channelId = key as ChannelId;
          const player = players[channelId];
          if (
            player.isLoaded &&
            !initializedOffsets.current[channelId] &&
            player.duration > 0
          ) {
            player.seekTo(Math.random() * player.duration);
            initializedOffsets.current[channelId] = true;
          }
        });
      }, 500);
    }

    return () => {
      if (offsetCheckInterval) clearInterval(offsetCheckInterval);
    };
  }, [isPlaying]);

  // 3. Sync Manual Volume Changes
  useEffect(() => {
    (Object.keys(players) as ChannelId[]).forEach((id) => {
      const state = channels[id];
      const player = players[id];
      const targetVolume = state.isMuted ? 0 : state.volume;

      // Ensure manual volume changes or auto-variations are reflected in the player instantly
      player.volume = targetVolume;
    });
  }, [channels]);

  // 4. Handle Visual and Audio Auto-Variation
  // We decouple the dependency from `channels` object directly to prevent infinite re-render loops while animating
  const autoConfigStr = JSON.stringify(
    (Object.keys(players) as ChannelId[]).map((id) => ({
      a: channels[id].autoVariationEnabled,
      m: channels[id].isMuted,
    })),
  );

  useEffect(() => {
    const variationIntervals: NodeJS.Timeout[] = [];
    const fadeIntervals: NodeJS.Timeout[] = [];

    (Object.keys(players) as ChannelId[]).forEach((id) => {
      const isAuto = channels[id].autoVariationEnabled;
      const isMuted = channels[id].isMuted;

      if (isAuto && !isMuted && isPlaying) {
        const triggerVariation = () => {
          const currentVol = useMixerStore.getState().channels[id].volume;
          const randomDelta = Math.random() * 0.5 - 0.25; // +/- 25% change
          let nextVolume = currentVol + randomDelta;
          if (nextVolume < 0) nextVolume = 0;
          if (nextVolume > 1) nextVolume = 1;

          // Smooth JS Fade (30 steps of 100ms = 3.0 seconds animation)
          const steps = 30;
          let step = 0;
          const stepDelta = (nextVolume - currentVol) / steps;

          const fadeInterval = setInterval(() => {
            step++;
            const newVol = currentVol + stepDelta * step;
            // Update the state so the LiquidSlider UI thumb moves automatically and beautifully
            useMixerStore.getState().setAutoChannelVolume(id, newVol);

            if (step >= steps) {
              clearInterval(fadeInterval);
            }
          }, 100);

          fadeIntervals.push(fadeInterval);
        };

        const intervalId = setInterval(
          triggerVariation,
          8000 + Math.random() * 8000, // A new variation triggers every 8s - 16s
        );
        variationIntervals.push(intervalId);

        // Initial trigger right away
        triggerVariation();
      }
    });

    return () => {
      variationIntervals.forEach(clearInterval);
      fadeIntervals.forEach(clearInterval);
    };
  }, [isPlaying, autoConfigStr]);

  // 5. Timer Logic
  useEffect(() => {
    let timerInterval: NodeJS.Timeout | null = null;
    if (isPlaying && timerEndTime !== null) {
      timerInterval = setInterval(() => {
        if (Date.now() >= timerEndTime) {
          togglePlayPause(); // Stop playing
          setTimer(null); // Reset timer
        }
      }, 1000);
    }

    return () => {
      if (timerInterval) clearInterval(timerInterval);
    };
  }, [isPlaying, timerEndTime]);
}
