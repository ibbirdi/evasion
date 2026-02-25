import { useAudioPlayer } from "expo-audio";
import React, { useEffect, useState } from "react";
import { BINAURAL_TRACKS } from "../config/binauralAudio";
import { useMixerStore } from "../store/useMixerStore";
import { BinauralTrackId } from "../types/mixer";

const TRACK_IDS: BinauralTrackId[] = ["delta", "theta", "alpha", "beta"];

/**
 * Headless component that manages binaural audio playback.
 * Renders one player per track but only unmutes the active one.
 */
const BinauralTrackPlayer: React.FC<{
  trackId: BinauralTrackId;
  fadeMultiplier: number;
}> = ({ trackId, fadeMultiplier }) => {
  const isBinauralActive = useMixerStore((s) => s.isBinauralActive);
  const activeBinauralTrack = useMixerStore((s) => s.activeBinauralTrack);
  const binauralVolume = useMixerStore((s) => s.binauralVolume);

  const isThisTrackActive = isBinauralActive && activeBinauralTrack === trackId;

  const player = useAudioPlayer(BINAURAL_TRACKS[trackId].source);

  // Looping
  useEffect(() => {
    player.loop = true;
  }, []);

  // Play/Pause
  useEffect(() => {
    if (isThisTrackActive) {
      if (!player.playing) {
        player.play();
      }
    } else {
      if (player.playing) {
        player.pause();
      }
    }
  }, [isThisTrackActive]);

  // Volume
  useEffect(() => {
    player.volume = isThisTrackActive ? binauralVolume * fadeMultiplier : 0;
  }, [isThisTrackActive, binauralVolume, fadeMultiplier]);

  return null;
};

const BinauralTrackWrapper: React.FC<{
  trackId: BinauralTrackId;
  fadeMultiplier: number;
}> = ({ trackId, fadeMultiplier }) => {
  const isBinauralActive = useMixerStore((s) => s.isBinauralActive);
  const activeBinauralTrack = useMixerStore((s) => s.activeBinauralTrack);
  const isThisTrackActive = isBinauralActive && activeBinauralTrack === trackId;

  if (!isThisTrackActive) return null;

  return (
    <BinauralTrackPlayer trackId={trackId} fadeMultiplier={fadeMultiplier} />
  );
};

export const BinauralAudioEngine: React.FC = () => {
  const isPlaying = useMixerStore((s) => s.isPlaying);
  const [fadeMultiplier, setFadeMultiplier] = useState(0);

  // Audio Fade Logic (Synchronized with AudioEngine)
  useEffect(() => {
    let fadeInterval: NodeJS.Timeout | null = null;

    if (isPlaying) {
      const FADE_IN_DURATION = 2000;
      const STEP_INTERVAL = 100;
      const steps = FADE_IN_DURATION / STEP_INTERVAL;
      const stepDelta = 1 / steps;

      fadeInterval = setInterval(() => {
        setFadeMultiplier((prev: number) => {
          const next = prev + stepDelta;
          if (next >= 1) {
            if (fadeInterval) clearInterval(fadeInterval);
            return 1;
          }
          return next;
        });
      }, STEP_INTERVAL);
    } else {
      if (fadeMultiplier > 0) {
        const FADE_OUT_DURATION = 1000;
        const STEP_INTERVAL = 100;
        const steps = FADE_OUT_DURATION / STEP_INTERVAL;
        const stepDelta = 1 / steps;

        fadeInterval = setInterval(() => {
          setFadeMultiplier((prev: number) => {
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

  return (
    <>
      {TRACK_IDS.map((id) => (
        <BinauralTrackWrapper
          key={id}
          trackId={id}
          fadeMultiplier={fadeMultiplier}
        />
      ))}
    </>
  );
};
