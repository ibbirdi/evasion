import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Platform, Dimensions } from "react-native";
import { useMixerStore } from "../store/useMixerStore";
import {
  Play,
  Pause,
  Shuffle,
  Timer,
  TimerOff,
  Bookmark,
  Cast,
  Lock,
} from "lucide-react-native";
import { ExpoAvRoutePickerView } from "@douglowder/expo-av-route-picker-view";
import { LiquidButton } from "./LiquidButton";
import { useI18n } from "../i18n";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withRepeat,
  withTiming,
  Easing,
  cancelAnimation,
} from "react-native-reanimated";

const TIMER_DURATIONS = [null, 15, 30, 60, 120];

interface HeaderProps {
  onOpenPresets: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenPresets }) => {
  const t = useI18n();

  const isPlaying = useMixerStore((state) => state.isPlaying);
  const togglePlayPause = useMixerStore((state) => state.togglePlayPause);
  const randomizeMix = useMixerStore((state) => state.randomizeMix);
  const setTimer = useMixerStore((state) => state.setTimer);
  const timerEndTime = useMixerStore((state) => state.timerEndTime);
  const timerDurationChosen = useMixerStore(
    (state) => state.timerDurationChosen,
  );
  const currentPresetId = useMixerStore((state) => state.currentPresetId);
  const isZenMode = useMixerStore((state) => state.isZenMode);

  const isPremium = useMixerStore((state) => state.isPremium);
  const setPaywallVisible = useMixerStore((state) => state.setPaywallVisible);

  const [timeRemaining, setTimeRemaining] = useState<number | null>(null);

  // Countdown Logic (Local state to avoid triggering Zustand updates every second)
  useEffect(() => {
    if (!timerEndTime || !isPlaying) {
      setTimeRemaining(null);
      return;
    }

    const interval = setInterval(() => {
      const remaining = timerEndTime - Date.now();
      if (remaining > 0) {
        setTimeRemaining(remaining);
      } else {
        setTimeRemaining(null);
      }
    }, 1000);

    // Initial check
    const initialRemaining = timerEndTime - Date.now();
    setTimeRemaining(initialRemaining > 0 ? initialRemaining : null);

    return () => clearInterval(interval);
  }, [timerEndTime, isPlaying]);

  const onTimerPress = () => {
    if (!isPremium) {
      setPaywallVisible(true);
      return;
    }
    const currentIndex = TIMER_DURATIONS.indexOf(timerDurationChosen);
    const nextIndex = (currentIndex + 1) % TIMER_DURATIONS.length;
    setTimer(TIMER_DURATIONS[nextIndex]);
  };

  const formatTime = (ms: number) => {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const zenOpacity = useSharedValue(1);

  useEffect(() => {
    zenOpacity.value = withTiming(isZenMode ? 0.05 : 1, {
      duration: isZenMode ? 7000 : 300,
      easing: Easing.inOut(Easing.ease),
    });
  }, [isZenMode]);

  const animatedTitleStyle = useAnimatedStyle(() => ({
    opacity: zenOpacity.value,
  }));

  const animatedSecondaryControlsStyle = useAnimatedStyle(() => ({
    opacity: zenOpacity.value,
  }));

  return (
    <View style={styles.header}>
      <Animated.View style={[styles.titleContainer, animatedTitleStyle]}>
        <Text style={styles.title}>{t.header.title}</Text>
        <Text style={styles.subtitle}>Binaural HD</Text>
      </Animated.View>
      <View style={styles.controls}>
        {/* Play/Pause with rotating glow */}
        <View style={styles.playContainer}>
          <LiquidButton
            isRound
            isActive={isPlaying}
            size={52}
            onPress={togglePlayPause}
          >
            {isPlaying ? (
              <Pause size={20} color="#FFF" />
            ) : (
              <Play size={20} fill="#EEE" color="#EEE" />
            )}
          </LiquidButton>
          <PlayGlowRing isPlaying={isPlaying} size={52} />
        </View>

        {/* Shuffle */}
        <LiquidButton
          isRound
          testID="random-btn"
          size={52}
          onPress={randomizeMix}
          style={animatedSecondaryControlsStyle}
        >
          <Shuffle size={20} color="#EEE" />
        </LiquidButton>

        {/* Presets — between shuffle and timer */}
        <LiquidButton
          isRound
          testID="presets-btn"
          size={52}
          isActive={currentPresetId !== null}
          onPress={isPremium ? onOpenPresets : () => setPaywallVisible(true)}
          style={animatedSecondaryControlsStyle}
        >
          {isPremium ? (
            <Bookmark
              size={20}
              color={currentPresetId !== null ? "#FFF" : "#EEE"}
            />
          ) : (
            <Lock size={20} color="#AAA" />
          )}
        </LiquidButton>

        {/* Timer */}
        <LiquidButton
          isActive={timerDurationChosen !== null}
          size={52}
          onPress={onTimerPress}
          style={animatedSecondaryControlsStyle}
        >
          {timerDurationChosen !== null ? (
            <Timer size={20} color="#FFF" />
          ) : (
            <TimerOff size={20} color="#EEE" />
          )}
          <Text
            style={[
              styles.btnText,
              timerDurationChosen !== null && styles.btnTextActive,
            ]}
          >
            {timeRemaining !== null
              ? formatTime(timeRemaining)
              : timerDurationChosen
                ? `${timerDurationChosen}m`
                : t.header.timer}
          </Text>
          {!isPremium && (
            <Lock size={12} color="#AAA" style={{ marginLeft: 4 }} />
          )}
        </LiquidButton>
      </View>

      {/* AirPlay (iOS only) - Absolute top right */}
      {Platform.OS === "ios" && (
        <Animated.View
          style={[styles.airplayContainer, animatedSecondaryControlsStyle]}
        >
          <ExpoAvRoutePickerView
            activeTintColor="#FFF"
            tintColor="#EEE"
            style={{ width: 32, height: 32 }}
          />
        </Animated.View>
      )}
    </View>
  );
};

/** Rotating glow ring — pure RN Views with iOS shadows */
const RING_PADDING = 1;

const PlayGlowRing: React.FC<{ isPlaying: boolean; size: number }> = ({
  isPlaying,
  size,
}) => {
  const rotation = useSharedValue(0);
  const opacity = useSharedValue(0);

  useEffect(() => {
    if (isPlaying) {
      opacity.value = withTiming(1, { duration: 600 });
      rotation.value = 0;
      rotation.value = withRepeat(
        withTiming(360, {
          duration: 4000,
          easing: Easing.linear,
        }),
        -1,
        false,
      );
    } else {
      opacity.value = withTiming(0, { duration: 400 });
      cancelAnimation(rotation);
    }
  }, [isPlaying]);

  const ringAnimStyle = useAnimatedStyle(() => ({
    opacity: opacity.value,
    transform: [{ rotate: `${rotation.value}deg` }],
  }));

  const outerSize = size + RING_PADDING * 2;
  const arcBase = {
    position: "absolute" as const,
    width: outerSize,
    height: outerSize,
    borderRadius: outerSize / 2,
    borderColor: "transparent",
  };

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        {
          position: "absolute",
          width: outerSize,
          height: outerSize,
          top: -RING_PADDING,
          left: -RING_PADDING,
        },
        ringAnimStyle,
      ]}
    >
      {/* Layer 1 — wide soft glow halo */}
      <View
        style={[
          arcBase,
          {
            borderWidth: 3,
            borderTopColor: "rgba(255,255,255,0.5)",
            borderRightColor: "rgba(255,255,255,0.15)",
            shadowColor: "#FFFFFF",
            shadowOffset: { width: 0, height: 0 },
            shadowOpacity: 1,
            shadowRadius: 18,
          },
        ]}
      />
      {/* Layer 2 — medium glow */}
      <View
        style={[
          arcBase,
          {
            borderWidth: 2,
            borderTopColor: "rgba(255,255,255,0.7)",
            borderRightColor: "rgba(255,255,255,0.2)",
            shadowColor: "#FFFFFF",
            shadowOffset: { width: 0, height: 0 },
            shadowOpacity: 0.9,
            shadowRadius: 10,
          },
        ]}
      />
      {/* Layer 3 — sharp bright core */}
      <View
        style={[
          arcBase,
          {
            borderWidth: 1.5,
            borderTopColor: "rgba(255,255,255,1)",
            borderRightColor: "rgba(255,255,255,0.3)",
            shadowColor: "#FFFFFF",
            shadowOffset: { width: 0, height: 0 },
            shadowOpacity: 0.8,
            shadowRadius: 4,
          },
        ]}
      />
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  header: {
    paddingTop: 60,
    paddingHorizontal: 10,
  },
  titleContainer: {
    alignItems: "center",
    marginBottom: 24,
  },
  title: {
    fontSize: 40,
    fontFamily: "DancingScript_700Bold",
    fontWeight: "700",
    letterSpacing: 2,
    color: "#E0E0E0",
    opacity: 1,
    textShadowColor: "#E0E0E0",
    textShadowOffset: { width: 0.5, height: 0.5 },
    textShadowRadius: 1,
  },
  subtitle: {
    fontSize: 9,
    fontWeight: "500",
    letterSpacing: 5,
    color: "#E0E0E0",
    opacity: 0.5,
    marginTop: 4,
    textTransform: "uppercase",
  },
  controls: {
    flexDirection: "row",
    justifyContent: "space-between",
    width: "100%",
  },
  playContainer: {
    position: "relative",
  },
  airplayContainer: {
    position: "absolute",
    top: 66,
    right: 20,
    zIndex: 10,
  },
  btnText: {
    color: "#EEE",
    fontWeight: "500",
    fontSize: 13,
  },
  btnTextActive: {
    color: "#FFF",
    fontWeight: "600",
  },
});
