import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Platform } from "react-native";
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

  return (
    <View style={styles.header}>
      <View style={styles.titleContainer}>
        <Text style={styles.title}>{t.header.title}</Text>
        <Text style={styles.subtitle}>Binaural HD</Text>
      </View>
      <View style={styles.controls}>
        <LiquidButton isRound isActive={isPlaying} onPress={togglePlayPause}>
          {isPlaying ? (
            <Pause size={18} color="#FFF" />
          ) : (
            <Play size={18} fill="#EEE" color="#EEE" />
          )}
        </LiquidButton>
        <LiquidButton isRound testID="random-btn" onPress={randomizeMix}>
          <Shuffle size={18} color="#EEE" />
        </LiquidButton>
        <LiquidButton
          isActive={timerDurationChosen !== null}
          onPress={onTimerPress}
        >
          {timerDurationChosen !== null ? (
            <Timer size={18} color="#FFF" />
          ) : (
            <TimerOff size={18} color="#EEE" />
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
        {Platform.OS === "ios" && (
          <LiquidButton isRound>
            <Cast size={18} color="#EEE" />
            <View style={StyleSheet.absoluteFill}>
              <ExpoAvRoutePickerView
                activeTintColor="transparent"
                tintColor="transparent"
                style={{ width: "100%", height: "100%" }}
              />
            </View>
          </LiquidButton>
        )}
        <LiquidButton
          isRound
          testID="presets-btn"
          isActive={currentPresetId !== null}
          onPress={isPremium ? onOpenPresets : () => setPaywallVisible(true)}
        >
          {isPremium ? (
            <Bookmark
              size={18}
              color={currentPresetId !== null ? "#FFF" : "#EEE"}
            />
          ) : (
            <Lock size={18} color="#AAA" />
          )}
        </LiquidButton>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  header: {
    paddingTop: 60,
    paddingHorizontal: 20,
    alignItems: "center",
  },
  titleContainer: {
    alignItems: "center",
    marginBottom: 24,
  },
  title: {
    fontSize: 26,
    fontWeight: "300",
    letterSpacing: 6,
    color: "#E0E0E0",
    opacity: 0.9,
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
    gap: 8,
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
