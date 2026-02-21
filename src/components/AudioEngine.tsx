import React, { useEffect, useRef, useMemo, useState } from "react";
import { useAudioPlayer, setAudioModeAsync } from "expo-audio";
import { useMixerStore } from "../store/useMixerStore";
import { ChannelId } from "../types/mixer";
import { AUDIO_CONFIG } from "../config/audio";

const pickRandom = <T,>(array: readonly T[]): T => {
  return array[Math.floor(Math.random() * array.length)];
};

const ChannelAudio: React.FC<{ channelId: ChannelId }> = ({ channelId }) => {
  const isPlaying = useMixerStore((state) => state.isPlaying);
  const channelState = useMixerStore((state) => state.channels[channelId]);

  // Pick a random source on mount
  const source = useMemo(
    () => pickRandom(AUDIO_CONFIG[channelId].sources),
    [channelId],
  );
  const player = useAudioPlayer(source);

  const initializedOffset = useRef(false);

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

  // 2. Sync Manual Volume Changes
  useEffect(() => {
    const targetVolume = channelState.isMuted ? 0 : channelState.volume;
    player.volume = targetVolume;
  }, [channelState.isMuted, channelState.volume]);

  // 3. Handle Audio Auto-Variation
  useEffect(() => {
    let variationInterval: NodeJS.Timeout | null = null;
    let fadeInterval: NodeJS.Timeout | null = null;

    if (
      channelState.autoVariationEnabled &&
      !channelState.isMuted &&
      isPlaying
    ) {
      const triggerVariation = () => {
        const currentVol = useMixerStore.getState().channels[channelId].volume;
        const randomDelta = Math.random() * 0.5 - 0.25; // +/- 25% change
        let nextVolume = currentVol + randomDelta;
        if (nextVolume < 0) nextVolume = 0;
        if (nextVolume > 1) nextVolume = 1;

        const steps = 30;
        let step = 0;
        const stepDelta = (nextVolume - currentVol) / steps;

        fadeInterval = setInterval(() => {
          step++;
          const newVol = currentVol + stepDelta * step;
          useMixerStore.getState().setAutoChannelVolume(channelId, newVol);

          if (step >= steps && fadeInterval) {
            clearInterval(fadeInterval);
          }
        }, 100);
      };

      variationInterval = setInterval(
        triggerVariation,
        8000 + Math.random() * 8000,
      );

      triggerVariation();
    }

    return () => {
      if (variationInterval) clearInterval(variationInterval);
      if (fadeInterval) clearInterval(fadeInterval);
    };
  }, [isPlaying, channelState.autoVariationEnabled, channelState.isMuted]);

  return null;
};

export const AudioEngine: React.FC = () => {
  const isPlaying = useMixerStore((state) => state.isPlaying);
  const timerEndTime = useMixerStore((state) => state.timerEndTime);
  const togglePlayPause = useMixerStore((state) => state.togglePlayPause);
  const setTimer = useMixerStore((state) => state.setTimer);

  // Initial config for Background Audio
  useEffect(() => {
    setAudioModeAsync({
      playsInSilentMode: true,
      shouldPlayInBackground: true,
      interruptionMode: "mixWithOthers",
    });
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
        <ChannelAudio key={key} channelId={key} />
      ))}
    </>
  );
};
