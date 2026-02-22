import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  Switch,
  Pressable,
  Platform,
  LayoutChangeEvent,
} from "react-native";
import { GlassView } from "expo-glass-effect";
import { Lock } from "lucide-react-native";
import Slider from "@react-native-community/slider";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  runOnJS,
  Easing,
} from "react-native-reanimated";
import { useMixerStore } from "../store/useMixerStore";
import { useI18n } from "../i18n";
import { BinauralTrackId } from "../types/mixer";
import { BINAURAL_TRACKS } from "../config/binauralAudio";
import * as Haptics from "expo-haptics";

const TRACKS: {
  id: BinauralTrackId;
  labelKey: "delta" | "theta" | "alpha" | "beta";
}[] = [
  { id: "delta", labelKey: "delta" },
  { id: "theta", labelKey: "theta" },
  { id: "alpha", labelKey: "alpha" },
  { id: "beta", labelKey: "beta" },
];

// Unique color per binaural track (harmonious pastels matching the app's palette)
const BINAURAL_COLORS: Record<BinauralTrackId, string> = {
  delta: "#A78BFA", // Violet — deep sleep
  theta: "#7DD3FC", // Sky blue — meditation
  alpha: "#86EFAC", // Mint green — focus
  beta: "#FCD34D", // Warm amber — alert
};

// Design tokens
const theme = {
  colors: {
    primary: "#8B9CF7",
    background: "#0D1117",
    text: "#FFFFFF",
    textSecondary: "rgba(255,255,255,0.5)",
    border: "rgba(255,255,255,0.12)",
  },
};

const CIRCLE_SIZE = 50;

const TrackSelector: React.FC<{
  track: (typeof TRACKS)[number];
  isActive: boolean;
  isLocked: boolean;
  onPress: () => void;
}> = ({ track, isActive, isLocked, onPress }) => {
  const t = useI18n();
  const trackColor = BINAURAL_COLORS[track.id];

  const circleStyle = useAnimatedStyle(() => ({
    transform: [
      {
        scale: withTiming(isActive ? 1.1 : 1, {
          duration: 250,
          easing: Easing.out(Easing.cubic),
        }),
      },
    ],
    borderColor: withTiming(isActive ? trackColor : theme.colors.border, {
      duration: 250,
    }),
    borderWidth: withTiming(isActive ? 2.5 : 1.5, { duration: 250 }),
    shadowOpacity: withTiming(isActive ? 0.6 : 0, { duration: 250 }),
  }));

  const dotStyle = useAnimatedStyle(() => ({
    opacity: withTiming(isActive ? 1 : 0, { duration: 200 }),
    transform: [
      {
        scale: withTiming(isActive ? 1 : 0.3, {
          duration: 250,
          easing: Easing.out(Easing.cubic),
        }),
      },
    ],
  }));

  return (
    <Pressable style={styles.trackItem} onPress={onPress}>
      <Animated.View
        style={[
          styles.circle,
          { shadowColor: trackColor },
          circleStyle,
          isLocked && !isActive && styles.circleLocked,
        ]}
      >
        <Animated.View
          style={[styles.circleDot, { backgroundColor: trackColor }, dotStyle]}
        />
        {isLocked && (
          <View style={styles.lockBadge}>
            <Lock size={12} color="rgba(255,255,255,0.4)" />
          </View>
        )}
      </Animated.View>
      <Text
        style={[
          styles.trackLabel,
          isActive && styles.trackLabelActive,
          isLocked && !isActive && styles.trackLabelLocked,
        ]}
      >
        {t.binaural[track.labelKey]}
      </Text>
    </Pressable>
  );
};

/** Glass slider matching the app's LiquidSlider style */
const BinauralVolumeSlider: React.FC<{
  value: number;
  color: string;
  disabled: boolean;
  onChange: (val: number) => void;
}> = ({ value, color, disabled, onChange }) => {
  return (
    <View style={sliderStyles.container}>
      <Slider
        style={sliderStyles.nativeSlider}
        value={value}
        onValueChange={onChange}
        minimumValue={0}
        maximumValue={1}
        disabled={disabled}
        minimumTrackTintColor={color}
        maximumTrackTintColor="rgba(255,255,255,0.1)"
        thumbTintColor="#FFFFFF"
      />
    </View>
  );
};

export const BinauralPanel: React.FC = () => {
  const t = useI18n();
  const isBinauralActive = useMixerStore((s) => s.isBinauralActive);
  const activeBinauralTrack = useMixerStore((s) => s.activeBinauralTrack);
  const binauralVolume = useMixerStore((s) => s.binauralVolume);
  const toggleBinaural = useMixerStore((s) => s.toggleBinaural);
  const setBinauralTrack = useMixerStore((s) => s.setBinauralTrack);
  const setBinauralVolume = useMixerStore((s) => s.setBinauralVolume);
  const isPremium = useMixerStore((s) => s.isPremium);
  const setPaywallVisible = useMixerStore((s) => s.setPaywallVisible);
  const isZenMode = useMixerStore((s) => s.isZenMode);

  const activeColor = BINAURAL_COLORS[activeBinauralTrack];

  const handleTrackPress = (trackId: BinauralTrackId) => {
    const trackConfig = BINAURAL_TRACKS[trackId];
    if (trackConfig.isPremium && !isPremium) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      setPaywallVisible(true);
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setBinauralTrack(trackId);
  };

  const contentHeight = useSharedValue(0);

  const containerAnimatedStyle = useAnimatedStyle(() => ({
    transform: [
      {
        translateY: withTiming(
          isBinauralActive ? 0 : contentHeight.value + 16,
          {
            duration: 400,
            easing: Easing.out(Easing.cubic),
          },
        ),
      },
    ],
  }));

  const contentAnimatedStyle = useAnimatedStyle(() => {
    let targetOpacity = isBinauralActive ? 1 : 0.4;
    if (isZenMode && !isBinauralActive) {
      targetOpacity = 0.05;
    }
    return {
      opacity: withTiming(targetOpacity, {
        duration: isZenMode ? 7000 : 300,
        easing: Easing.inOut(Easing.ease),
      }),
    };
  });

  const containerZenStyle = useAnimatedStyle(() => {
    let targetOpacity = 1;
    if (isZenMode && !isBinauralActive) {
      targetOpacity = 0.05;
    }
    return {
      opacity: withTiming(targetOpacity, {
        duration: isZenMode ? 7000 : 300,
      }),
    };
  });

  const handleContentLayout = (event: LayoutChangeEvent) => {
    const { height } = event.nativeEvent.layout;
    if (height > 0) {
      contentHeight.value = height;
    }
  };

  return (
    <Animated.View
      style={[styles.container, containerAnimatedStyle, containerZenStyle]}
    >
      <GlassView style={StyleSheet.absoluteFillObject} tintColor="dark" />

      <View style={styles.inner}>
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.title}>{t.binaural.title}</Text>
            <Text style={styles.headphonesHint}>
              {t.binaural.headphones_hint}
            </Text>
          </View>
          <Switch
            value={isBinauralActive}
            onValueChange={() => {
              Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
              toggleBinaural();
            }}
            trackColor={{
              false: "rgba(255,255,255,0.15)",
              true: activeColor,
            }}
            thumbColor={Platform.OS === "android" ? "#FFFFFF" : undefined}
            ios_backgroundColor="rgba(255,255,255,0.15)"
          />
        </View>

        {/* Selectors + Slider (dimmed when off) */}
        <Animated.View
          style={contentAnimatedStyle}
          onLayout={handleContentLayout}
        >
          {/* Track Selectors */}
          <View
            style={styles.trackRow}
            pointerEvents={isBinauralActive ? "auto" : "none"}
          >
            {TRACKS.map((track) => (
              <TrackSelector
                key={track.id}
                track={track}
                isActive={activeBinauralTrack === track.id}
                isLocked={!isPremium && BINAURAL_TRACKS[track.id].isPremium}
                onPress={() => handleTrackPress(track.id)}
              />
            ))}
          </View>

          {/* Volume Slider — same glass style as LiquidSlider */}
          <View
            style={styles.sliderContainer}
            pointerEvents={isBinauralActive ? "auto" : "none"}
          >
            <BinauralVolumeSlider
              value={binauralVolume}
              color={activeColor}
              disabled={!isBinauralActive}
              onChange={setBinauralVolume}
            />
          </View>
        </Animated.View>
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: "absolute",
    bottom: 0,
    width: "100%",
    zIndex: 10,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    overflow: "hidden",
  },
  inner: {
    paddingHorizontal: 24,
    paddingTop: 18,
    paddingBottom: Platform.OS === "ios" ? 36 : 24,
  },
  // Header
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  title: {
    fontSize: 11,
    fontWeight: "700",
    letterSpacing: 3,
    color: theme.colors.textSecondary,
    textTransform: "uppercase",
  },
  headphonesHint: {
    fontSize: 9,
    fontWeight: "400",
    color: "rgba(255,255,255,0.3)",
    marginTop: 3,
  },
  // Track selectors
  trackRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 16,
    paddingHorizontal: 8,
  },
  trackItem: {
    alignItems: "center",
    gap: 8,
  },
  circle: {
    width: CIRCLE_SIZE,
    height: CIRCLE_SIZE,
    borderRadius: CIRCLE_SIZE / 2,
    alignItems: "center",
    justifyContent: "center",
    shadowOffset: { width: 0, height: 0 },
    shadowRadius: 10,
    elevation: 6,
  },
  circleLocked: {
    opacity: 0.45,
  },
  circleDot: {
    width: 14,
    height: 14,
    borderRadius: 7,
  },
  lockBadge: {
    position: "absolute",
    bottom: -2,
    right: -2,
  },
  trackLabel: {
    fontSize: 12,
    fontWeight: "500",
    color: theme.colors.textSecondary,
  },
  trackLabelActive: {
    color: theme.colors.text,
    fontWeight: "600",
  },
  trackLabelLocked: {
    opacity: 0.45,
  },
  // Slider container
  sliderContainer: {
    marginTop: 4,
    paddingHorizontal: 4,
  },
});

const sliderStyles = StyleSheet.create({
  container: {
    width: "100%",
    height: 40,
    justifyContent: "center",
  },
  nativeSlider: {
    width: "100%",
    height: 40,
  },
});
