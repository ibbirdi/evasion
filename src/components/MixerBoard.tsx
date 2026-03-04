import React from "react";
import { Pressable, ScrollView, StyleSheet, View } from "react-native";
import Animated, { LinearTransition } from "react-native-reanimated";
import { AUDIO_CONFIG } from "../config/audio";
import { useI18n } from "../i18n";
import { useMixerStore } from "../store/useMixerStore";
import { ChannelId } from "../types/mixer";
import { LiquidSlider } from "./LiquidSlider";

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
    <Animated.View layout={LinearTransition} style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        {channelKeys.map((key) => {
          const channel = channels[key];
          const isLocked = !isPremium && !freeChannels.includes(key);
          const config = AUDIO_CONFIG[key as ChannelId];

          const slider = (
            <LiquidSlider
              key={key}
              id={key}
              label={t.channels[key as keyof typeof t.channels]}
              icon={config.icon}
              color={config.color}
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
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    paddingBottom: 140,
    paddingTop: 180, // Adds space for the absolute header so the first slider isn't hidden
  },
});
