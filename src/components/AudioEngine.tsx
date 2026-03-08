import {
  setAudioModeAsync,
  useAudioPlayer,
  useAudioPlayerStatus,
} from "expo-audio";
import React, { useEffect, useMemo, useRef, useState } from "react";
import { AppState, AppStateStatus } from "react-native";
import { AUDIO_CONFIG } from "../config/audio";
import { useLiveStore } from "../store/useLiveStore";
import { useMixerStore } from "../store/useMixerStore";
import { ChannelId } from "../types/mixer";

const pickRandom = <T,>(array: readonly T[]): T => {
  return array[Math.floor(Math.random() * array.length)];
};

const ChannelAudio: React.FC<{
  channelId: ChannelId;
  fadeMultiplier: number;
}> = ({ channelId, fadeMultiplier }) => {
  const isPlaying = useMixerStore((state) => state.isPlaying);
  const channelState = useMixerStore((state) => state.channels[channelId]);

  // Pick a random source on mount
  const source = useMemo(
    () => pickRandom(AUDIO_CONFIG[channelId].sources),
    [channelId],
  );
  const player = useAudioPlayer(source, { downloadFirst: true });

  const initializedOffset = useRef(false);

  const [variationVolume, setVariationVolume] = useState(channelState.volume);
  const variationRef = useRef(channelState.volume);

  // 1. Play/Pause and Looping
  useEffect(() => {
    player.loop = true;

    if (isPlaying) {
      if (!player.playing) {
        player.play();
      }

      // Apply random offset only once per player when it becomes loaded
      if (
        player.isLoaded &&
        !initializedOffset.current &&
        player.duration > 0
      ) {
        player.seekTo(Math.random() * player.duration);
        initializedOffset.current = true;
      }
    } else {
      if (player.playing) {
        player.pause();
      }
    }
  }, [isPlaying, player.isLoaded, player.duration]);

  // Periodic check for loaded offsets if they missed the immediate check
  useEffect(() => {
    let offsetCheckInterval: NodeJS.Timeout | null = null;
    if (isPlaying && !initializedOffset.current) {
      offsetCheckInterval = setInterval(() => {
        if (
          player.isLoaded &&
          !initializedOffset.current &&
          player.duration > 0
        ) {
          player.seekTo(Math.random() * player.duration);
          initializedOffset.current = true;
        }
      }, 500);
    }
    return () => {
      if (offsetCheckInterval) clearInterval(offsetCheckInterval);
    };
  }, [isPlaying]);

  // 2. Sync Manual Volume Changes + Local Variation
  useEffect(() => {
    const baseVolume = channelState.isMuted ? 0 : channelState.volume;
    // When auto-variation is on, we use the absolute variation value
    const finalVolume = channelState.autoVariationEnabled
      ? variationVolume
      : baseVolume;
    player.volume = finalVolume * fadeMultiplier;
  }, [
    channelState.isMuted,
    channelState.volume,
    channelState.autoVariationEnabled,
    fadeMultiplier,
    variationVolume,
  ]);

  // 3. Handle Audio Auto-Variation (Local updates ONLY to avoid store/persistence flooding)
  useEffect(() => {
    let variationTimeout: NodeJS.Timeout | null = null;
    let fadeInterval: NodeJS.Timeout | null = null;

    if (
      channelState.autoVariationEnabled &&
      !channelState.isMuted &&
      isPlaying
    ) {
      const triggerVariation = () => {
        // Start from current absolute volume
        const startVolume = variationRef.current;
        const targetVolume = Math.random(); // Full range 0.0 to 1.0

        const steps = 150; // Very smooth, slow transition
        let step = 0;
        const stepDelta = (targetVolume - startVolume) / steps;

        if (fadeInterval) clearInterval(fadeInterval);
        fadeInterval = setInterval(() => {
          step++;
          const nextVolume = startVolume + stepDelta * step;
          variationRef.current = nextVolume;
          setVariationVolume(nextVolume);
          // Sync with live store for visual feedback
          useLiveStore.getState().setVariation(channelId, nextVolume);

          if (step >= steps && fadeInterval) {
            clearInterval(fadeInterval);

            // Set delay before next variation
            const nextDelay = 3000 + Math.random() * 10000;
            variationTimeout = setTimeout(triggerVariation, nextDelay);
          }
        }, 100); // Consistent update rate for smoothness
      };

      triggerVariation();
    } else {
      // Return to manual volume when variation is disabled
      variationRef.current = channelState.volume;
      setVariationVolume(channelState.volume);
      useLiveStore.getState().setVariation(channelId, null); // Clear variation
    }

    return () => {
      if (variationTimeout) clearTimeout(variationTimeout);
      if (fadeInterval) clearInterval(fadeInterval);
    };
  }, [isPlaying, channelState.autoVariationEnabled, channelState.isMuted]);

  return null;
};

const ChannelWrapper: React.FC<{
  channelId: ChannelId;
  fadeMultiplier: number;
}> = ({ channelId, fadeMultiplier }) => {
  const isMuted = useMixerStore((state) => state.channels[channelId].isMuted);

  if (isMuted) return null;

  return <ChannelAudio channelId={channelId} fadeMultiplier={fadeMultiplier} />;
};

export const AudioEngine: React.FC = () => {
  const isPlaying = useMixerStore((state) => state.isPlaying);
  const timerEndTime = useMixerStore((state) => state.timerEndTime);
  const togglePlayPause = useMixerStore((state) => state.togglePlayPause);
  const setTimer = useMixerStore((state) => state.setTimer);

  const [fadeMultiplier, setFadeMultiplier] = useState(0);
  const fadeTarget = useRef(0);

  // Audio Fade Logic
  useEffect(() => {
    let fadeInterval: NodeJS.Timeout | null = null;

    if (isPlaying) {
      // Start Fade-In
      fadeTarget.current = 1;
      const FADE_IN_DURATION = 2000;
      const STEP_INTERVAL = 100;
      const steps = FADE_IN_DURATION / STEP_INTERVAL;
      const stepDelta = 1 / steps;

      fadeInterval = setInterval(() => {
        setFadeMultiplier((prev) => {
          const next = prev + stepDelta;
          if (next >= 1) {
            if (fadeInterval) clearInterval(fadeInterval);
            return 1;
          }
          return next;
        });
      }, STEP_INTERVAL);
    } else {
      // Fade-Out before pausing is handled by the component that triggers isPlaying logic
      // But here we need to ensure it's 0 if not playing and not fading out
      if (fadeMultiplier > 0) {
        const FADE_OUT_DURATION = 1000;
        const STEP_INTERVAL = 100;
        const steps = FADE_OUT_DURATION / STEP_INTERVAL;
        const stepDelta = 1 / steps;

        fadeInterval = setInterval(() => {
          setFadeMultiplier((prev) => {
            const next = prev - stepDelta;
            if (next <= 0) {
              if (fadeInterval) clearInterval(fadeInterval);
              return 0;
            }
            return next;
          });
        }, STEP_INTERVAL);
      }
    }

    return () => {
      if (fadeInterval) clearInterval(fadeInterval);
    };
  }, [isPlaying]);

  // Master Player for Lock Screen Controls
  // We use the first source of the first channel just to have a player to attach the lock screen to.
  // It will be silent (volume 0) because individual ChannelAudio components handle the actual sound.
  const firstChannelId = (Object.keys(AUDIO_CONFIG) as ChannelId[])[0];
  const masterSource = AUDIO_CONFIG[firstChannelId].sources[0];
  const masterPlayer = useAudioPlayer(masterSource);
  const masterStatus = useAudioPlayerStatus(masterPlayer);

  useEffect(() => {
    const syncLockScreen = async () => {
      if (isPlaying && masterPlayer.isLoaded) {
        masterPlayer.volume = 0;
        masterPlayer.loop = true;
        masterPlayer.play();
        masterPlayer.setActiveForLockScreen(true, {
          title: "Evasion",
          artist: "Soundscape",
        });
      } else {
        masterPlayer.pause();
        // We don't necessarily clear controls here to avoid flickering if it's just a pause
      }
    };
    syncLockScreen();
  }, [isPlaying, masterPlayer.isLoaded]);

  // Sync Remote Commands from Lock Screen back to Store
  useEffect(() => {
    let timeout: NodeJS.Timeout | null = null;

    if (masterStatus.isLoaded) {
      // Get the current true state without putting it in the dependency array
      // This prevents the effect from running right when the user clicks 'Play'
      const isPlayingCurrent = useMixerStore.getState().isPlaying;

      if (isPlayingCurrent && !masterStatus.playing) {
        // Paused via Lock Screen or loop gap.
        // Wait briefly to see if it's just the AVPlayer gap while looping
        timeout = setTimeout(() => {
          const stillPlaying = useMixerStore.getState().isPlaying;
          if (stillPlaying) {
            togglePlayPause();
          }
        }, 500); // 500ms to comfortably cover AVPlayer gap
      } else if (!isPlayingCurrent && masterStatus.playing) {
        // Played via Lock Screen
        togglePlayPause();
      }
    }

    return () => {
      if (timeout) clearTimeout(timeout);
    };
  }, [masterStatus.playing, masterStatus.isLoaded]);

  useEffect(() => {
    const applyAudioMode = async () => {
      try {
        await setAudioModeAsync({
          playsInSilentMode: true,
          shouldPlayInBackground: true,
          interruptionMode: "doNotMix", // Required for lock screen controls
        });
      } catch (e) {
        console.warn("Failed to set audio mode:", e);
      }
    };

    applyAudioMode();

    const subscription = AppState.addEventListener(
      "change",
      (nextStatus: AppStateStatus) => {
        if (nextStatus === "active") {
          applyAudioMode();
        }
      },
    );

    return () => {
      subscription.remove();
    };
  }, []);

  // Timer Logic
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

  return (
    <>
      {(Object.keys(AUDIO_CONFIG) as ChannelId[]).map((key) => (
        <ChannelWrapper
          key={key}
          channelId={key}
          fadeMultiplier={fadeMultiplier}
        />
      ))}
    </>
  );
};
