import React, { useEffect, useRef } from "react";
import { useAudioPlayer } from "expo-audio";
import { useMixerStore } from "../store/useMixerStore";
import { BINAURAL_TRACKS } from "../config/binauralAudio";
import { BinauralTrackId } from "../types/mixer";

const TRACK_IDS: BinauralTrackId[] = ["delta", "theta", "alpha", "beta"];

/**
 * Headless component that manages binaural audio playback.
 * Renders one player per track but only unmutes the active one.
 */
const BinauralTrackPlayer: React.FC<{ trackId: BinauralTrackId }> = ({
  trackId,
}) => {
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
    player.volume = isThisTrackActive ? binauralVolume : 0;
  }, [isThisTrackActive, binauralVolume]);

  return null;
};

export const BinauralAudioEngine: React.FC = () => {
  return (
    <>
      {TRACK_IDS.map((id) => (
        <BinauralTrackPlayer key={id} trackId={id} />
      ))}
    </>
  );
};
