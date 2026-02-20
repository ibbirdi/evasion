import React, { useEffect, useState } from "react";
import { View, Text, StyleSheet, Pressable, Platform } from "react-native";
import { useMixerStore } from "../store/useMixerStore";
import {
  Play,
  Pause,
  Shuffle,
  Timer,
  TimerOff,
  Bookmark,
  Cast,
} from "lucide-react-native";
import { ExpoAvRoutePickerView } from "@douglowder/expo-av-route-picker-view";

const TIMER_DURATIONS = [null, 15, 30, 60, 120];

interface HeaderProps {
  onOpenPresets: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onOpenPresets }) => {
  const isPlaying = useMixerStore((state) => state.isPlaying);
  const togglePlayPause = useMixerStore((state) => state.togglePlayPause);
  const randomizeMix = useMixerStore((state) => state.randomizeMix);
  const setTimer = useMixerStore((state) => state.setTimer);
  const timerEndTime = useMixerStore((state) => state.timerEndTime);
  const timerDurationChosen = useMixerStore(
    (state) => state.timerDurationChosen,
  );
  const currentPresetId = useMixerStore((state) => state.currentPresetId);

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
      <Text style={styles.title}>É V A S I O N</Text>
      <View style={styles.controls}>
        <Pressable
          style={[styles.btn, styles.iconBtn, isPlaying && styles.btnActive]}
          onPress={togglePlayPause}
        >
          {isPlaying ? (
            <Pause size={18} color="#FFF" />
          ) : (
            <Play size={18} fill="#EEE" color="#EEE" />
          )}
        </Pressable>
        <Pressable style={[styles.btn, styles.iconBtn]} onPress={randomizeMix}>
          <Shuffle size={18} color="#EEE" />
        </Pressable>
        <Pressable
          style={[styles.btn, timerDurationChosen !== null && styles.btnActive]}
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
                : "Timer"}
          </Text>
        </Pressable>
        {Platform.OS === "ios" && (
          <View style={[styles.btn, styles.iconBtn]}>
            <Cast size={18} color="#EEE" />
            <View style={StyleSheet.absoluteFill}>
              {/* Invisible native button on top of Cast icon */}
              <ExpoAvRoutePickerView
                activeTintColor="transparent"
                tintColor="transparent"
                style={{ width: "100%", height: "100%" }}
              />
            </View>
          </View>
        )}
        <Pressable
          style={[
            styles.btn,
            styles.iconBtn,
            currentPresetId !== null && styles.btnActive,
          ]}
          onPress={onOpenPresets}
        >
          <Bookmark
            size={18}
            color={currentPresetId !== null ? "#FFF" : "#EEE"}
          />
        </Pressable>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  header: {
    paddingTop: 60,
    paddingHorizontal: 20,
    paddingBottom: 20,
    alignItems: "center",
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(255,255,255,0.1)",
  },
  title: {
    fontSize: 26,
    fontWeight: "300",
    letterSpacing: 6,
    color: "#E0E0E0",
    marginBottom: 20,
    opacity: 0.9,
  },
  controls: {
    flexDirection: "row",
    gap: 8,
  },
  btn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingVertical: 10,
    paddingHorizontal: 14,
    borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.1)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.15)",
    overflow: "hidden",
  },
  iconBtn: {
    width: 42,
    height: 42,
    borderRadius: 21,
    paddingVertical: 0,
    paddingHorizontal: 0,
    justifyContent: "center",
  },
  btnActive: {
    backgroundColor: "rgba(255,255,255,0.2)",
    borderColor: "rgba(255,255,255,0.4)",
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
