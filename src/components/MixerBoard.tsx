import React from "react";
import { View, StyleSheet, ScrollView } from "react-native";
import { useMixerStore } from "../store/useMixerStore";
import { LiquidSlider } from "./LiquidSlider";
import { CHANNEL_COLORS } from "../constants/colors";
import { ChannelId } from "../types/mixer";
import { useI18n } from "../i18n";
import { Pressable } from "react-native";

export const MixerBoard: React.FC = () => {
  const t = useI18n();
  const channels = useMixerStore((state) => state.channels);
  const setChannelVolume = useMixerStore((state) => state.setChannelVolume);
  const toggleChannelMute = useMixerStore((state) => state.toggleChannelMute);
  const toggleChannelAutoVariation = useMixerStore(
    (state) => state.toggleChannelAutoVariation,
  );
  const isPremium = useMixerStore((state) => state.isPremium);
  const setPaywallVisible = useMixerStore((state) => state.setPaywallVisible);

  const channelKeys = Object.keys(channels) as ChannelId[];
  const freeChannels: ChannelId[] = ["oiseaux", "vent", "plage"];

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {channelKeys.map((key) => {
        const channel = channels[key];
        const isLocked = !isPremium && !freeChannels.includes(key as ChannelId);

        const slider = (
          <LiquidSlider
            key={key}
            id={key}
            label={t.channels[key as ChannelId]}
            color={CHANNEL_COLORS[key]}
            value={channel.volume}
            isMuted={channel.isMuted}
            autoVariationEnabled={channel.autoVariationEnabled}
            isLocked={isLocked}
            onRequirePremium={() => setPaywallVisible(true)}
            onChange={(val) => setChannelVolume(key, val)}
            onToggleMute={() => toggleChannelMute(key)}
            onToggleAutoVariation={() => toggleChannelAutoVariation(key)}
          />
        );

        if (isLocked) {
          return (
            <Pressable key={key} onPress={() => setPaywallVisible(true)}>
              <View pointerEvents="box-only">{slider}</View>
            </Pressable>
          );
        }

        return slider;
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
    paddingBottom: 260,
    paddingTop: 10,
  },
});
