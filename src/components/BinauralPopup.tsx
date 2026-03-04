import Slider from "@react-native-community/slider";
import { GlassView } from "expo-glass-effect";
import * as Haptics from "expo-haptics";
import { Lock, X } from "lucide-react-native";
import React, { useEffect, useState } from "react";
import {
  Platform,
  Pressable,
  StyleSheet,
  Switch,
  Text,
  View,
} from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
  interpolate,
  Extrapolation,
  runOnJS,
} from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { BINAURAL_TRACKS } from "../config/binauralAudio";
import { BINAURAL_COLORS } from "../constants/colors";
import { useI18n } from "../i18n";
import { useMixerStore } from "../store/useMixerStore";
import { BinauralTrackId } from "../types/mixer";
import { LiquidButton } from "./LiquidButton";

const TRACKS: {
  id: BinauralTrackId;
  labelKey: "delta" | "theta" | "alpha" | "beta";
  freqKey: "delta_freq" | "theta_freq" | "alpha_freq" | "beta_freq";
}[] = [
  { id: "delta", labelKey: "delta", freqKey: "delta_freq" },
  { id: "theta", labelKey: "theta", freqKey: "theta_freq" },
  { id: "alpha", labelKey: "alpha", freqKey: "alpha_freq" },
  { id: "beta", labelKey: "beta", freqKey: "beta_freq" },
];

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
        scale: withSpring(isActive ? 1.1 : 1, {
          damping: 15,
          stiffness: 300,
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
        scale: withSpring(isActive ? 1 : 0.3, {
          damping: 15,
          stiffness: 300,
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
      <View style={styles.labelContainer}>
        <Text
          style={[
            styles.trackLabel,
            isActive && styles.trackLabelActive,
            isLocked && !isActive && styles.trackLabelLocked,
          ]}
        >
          {t.binaural[track.labelKey]}
        </Text>
        <Text
          style={[
            styles.trackFreq,
            isActive && styles.trackFreqActive,
            isLocked && !isActive && styles.trackFreqLocked,
          ]}
        >
          {t.binaural[track.freqKey]}
        </Text>
      </View>
    </Pressable>
  );
};

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

interface BinauralPopupProps {
  isVisible: boolean;
  onClose: () => void;
}

export const BinauralPopup: React.FC<BinauralPopupProps> = ({
  isVisible,
  onClose,
}) => {
  const t = useI18n();
  const insets = useSafeAreaInsets();
  const isBinauralActive = useMixerStore((s) => s.isBinauralActive);
  const activeBinauralTrack = useMixerStore((s) => s.activeBinauralTrack);
  const binauralVolume = useMixerStore((s) => s.binauralVolume);
  const toggleBinaural = useMixerStore((s) => s.toggleBinaural);
  const setBinauralTrack = useMixerStore((s) => s.setBinauralTrack);
  const setBinauralVolume = useMixerStore((s) => s.setBinauralVolume);
  const isPremium = useMixerStore((s) => s.isPremium);
  const setPaywallVisible = useMixerStore((s) => s.setPaywallVisible);

  const activeColor = BINAURAL_COLORS[activeBinauralTrack];

  // State to unmount component when animation finishes
  const [shouldRender, setShouldRender] = useState(isVisible);

  // Animation value: 0 = hidden, 1 = fully visible
  const visibility = useSharedValue(isVisible ? 1 : 0);

  useEffect(() => {
    if (isVisible) {
      setShouldRender(true);
      visibility.value = withSpring(1, {
        damping: 24,
        stiffness: 300,
        mass: 0.8,
      });
    } else {
      visibility.value = withSpring(
        0,
        {
          damping: 24,
          stiffness: 300,
          mass: 0.8,
        },
        (finished) => {
          if (finished) {
            runOnJS(setShouldRender)(false);
          }
        },
      );
    }
  }, [isVisible]);

  const handleTrackPress = (trackId: BinauralTrackId) => {
    const trackConfig = BINAURAL_TRACKS[trackId];
    if (trackConfig.isPremium && !isPremium) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
      setPaywallVisible(true);
      onClose(); // Close popup to show paywall
      return;
    }
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setBinauralTrack(trackId);
  };

  const popupStyle = useAnimatedStyle(() => {
    // Popup expands from the bottom simulating the context menu origin
    const scale = interpolate(
      visibility.value,
      [0, 1],
      [0.05, 1], // Start very small
      Extrapolation.CLAMP,
    );
    const translateY = interpolate(
      visibility.value,
      [0, 1],
      [100, 0], // Move heavily from the bottom as it expands
      Extrapolation.CLAMP,
    );

    return {
      opacity: interpolate(
        visibility.value,
        [0, 1],
        [0.4, 1], // Fade in while scaling
        Extrapolation.CLAMP,
      ),
      transform: [{ translateY }, { scale }],
    };
  });

  const backdropStyle = useAnimatedStyle(() => {
    return {
      opacity: interpolate(
        visibility.value,
        [0, 1],
        [0, 1],
        Extrapolation.CLAMP,
      ),
    };
  });

  if (!shouldRender) return null;

  return (
    <>
      <Animated.View style={[styles.backdrop, backdropStyle]}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onClose} />
      </Animated.View>

      {/* We add safe area padding (insets.bottom) plus standard 60px for the toolbar so it floats right above it */}
      <Animated.View
        style={[
          styles.container,
          popupStyle,
          { bottom: Math.max(insets.bottom, 20) + 70 },
        ]}
      >
        <GlassView style={StyleSheet.absoluteFill} tintColor="dark" />

        <View style={styles.inner}>
          {/* Header */}
          <View style={styles.header}>
            <View>
              <Text style={styles.title}>{t.binaural.title}</Text>
              <Text style={styles.headphonesHint}>
                {t.binaural.headphones_hint}
              </Text>
            </View>
            <View style={styles.headerActions}>
              <Switch
                value={isBinauralActive}
                onValueChange={() => {
                  Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                  toggleBinaural();
                }}
                trackColor={{ false: "#3E3E3E", true: activeColor }}
                thumbColor={isBinauralActive ? "#FFFFFF" : "#F4F3F4"}
                ios_backgroundColor="#3E3E3E"
              />
            </View>
          </View>

          {/* Content */}
          <View>
            <View style={styles.trackRow}>
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

            <View style={styles.sliderContainer}>
              <BinauralVolumeSlider
                value={binauralVolume}
                color={activeColor}
                disabled={!isBinauralActive}
                onChange={setBinauralVolume}
              />
            </View>
          </View>
        </View>
      </Animated.View>
    </>
  );
};

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFill,
    backgroundColor: "transparent",
    zIndex: 99,
  },
  container: {
    position: "absolute",
    left: 16,
    right: 16,
    zIndex: 100,
    borderRadius: 18,
    overflow: "hidden",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.35,
    shadowRadius: 20,
    elevation: 8,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(255,255,255,0.2)",
  },
  inner: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 24,
  },
  header: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 24,
    paddingHorizontal: 20,
  },
  title: {
    fontSize: 18,
    fontWeight: "600",
    letterSpacing: -0.3,
    color: theme.colors.text,
  },
  headphonesHint: {
    fontSize: 12,
    fontWeight: "400",
    color: "rgba(255,255,255,0.4)",
    marginTop: 4,
  },
  headerActions: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  powerText: {
    fontSize: 13,
    fontWeight: "600",
  },
  trackRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginBottom: 24,
    paddingHorizontal: 20,
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
  labelContainer: {
    alignItems: "center",
    gap: 2,
  },
  trackFreq: {
    fontSize: 10,
    fontWeight: "500",
    color: "rgba(255,255,255,0.25)",
    letterSpacing: 0.2,
  },
  trackFreqActive: {
    color: "rgba(255,255,255,0.5)",
  },
  trackFreqLocked: {
    opacity: 0.45,
  },
  sliderContainer: {
    marginTop: 0,
    paddingHorizontal: 20,
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
