import React from "react";
import { View, StyleSheet, ScrollView } from "react-native";
import { useMixerStore } from "../store/useMixerStore";
import { LiquidSlider } from "./LiquidSlider";
import { CHANNEL_COLORS } from "../constants/colors";
import { ChannelId } from "../types/mixer";

export const MixerBoard: React.FC = () => {
  const channels = useMixerStore((state) => state.channels);
  const setChannelVolume = useMixerStore((state) => state.setChannelVolume);
  const toggleChannelMute = useMixerStore((state) => state.toggleChannelMute);
  const toggleChannelAutoVariation = useMixerStore(
    (state) => state.toggleChannelAutoVariation,
  );

  const channelKeys = Object.keys(channels) as ChannelId[];

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {channelKeys.map((key) => {
        const channel = channels[key];
        return (
          <LiquidSlider
            key={key}
            id={key}
            label={channel.label}
            color={CHANNEL_COLORS[key]}
            value={channel.volume}
            isMuted={channel.isMuted}
            autoVariationEnabled={channel.autoVariationEnabled}
            onChange={(val) => setChannelVolume(key, val)}
            onToggleMute={() => toggleChannelMute(key)}
            onToggleAutoVariation={() => toggleChannelAutoVariation(key)}
          />
        );
      })}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    marginTop: 20,
  },
  content: {
    paddingBottom: 80,
    paddingTop: 10,
  },
});
