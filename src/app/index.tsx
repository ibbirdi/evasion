import { ExpoAvRoutePickerView } from "@douglowder/expo-av-route-picker-view";
import { Stack, useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { Platform, StyleSheet, View } from "react-native";
import { AnimatedBackground } from "../components/AnimatedBackground";
import { AudioEngine } from "../components/AudioEngine";
import { BinauralAudioEngine } from "../components/BinauralAudioEngine";
import { Header } from "../components/Header";
import { LanguageSwitcher } from "../components/LanguageSwitcher";
import { MixerBoard } from "../components/MixerBoard";
import { PaywallScreen } from "../components/PaywallScreen";
import { BINAURAL_COLORS } from "../constants/colors";
import { useI18n } from "../i18n";
import { useMixerStore } from "../store/useMixerStore";

export default function HomeScreen() {
  const router = useRouter();
  const t = useI18n();

  const isPlaying = useMixerStore((s) => s.isPlaying);
  const togglePlayPause = useMixerStore((s) => s.togglePlayPause);
  const randomizeMix = useMixerStore((s) => s.randomizeMix);
  const setTimer = useMixerStore((s) => s.setTimer);
  const timerEndTime = useMixerStore((s) => s.timerEndTime);
  const timerDurationChosen = useMixerStore((s) => s.timerDurationChosen);
  const currentPresetId = useMixerStore((s) => s.currentPresetId);
  const isBinauralActive = useMixerStore((s) => s.isBinauralActive);
  const activeBinauralTrack = useMixerStore((s) => s.activeBinauralTrack);
  const isPremium = useMixerStore((s) => s.isPremium);
  const setPaywallVisible = useMixerStore((s) => s.setPaywallVisible);

  // Timer countdown for toolbar label
  const [timeRemaining, setTimeRemaining] = useState<number | null>(null);

  useEffect(() => {
    if (!timerEndTime || !isPlaying) {
      if (timerDurationChosen === null) {
        setTimeRemaining(null);
      } else {
        setTimeRemaining(timerDurationChosen * 60 * 1000);
      }
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
    const initialRemaining = timerEndTime - Date.now();
    setTimeRemaining(initialRemaining > 0 ? initialRemaining : null);
    return () => clearInterval(interval);
  }, [timerEndTime, isPlaying, timerDurationChosen]);

  const formatTimerLabel = () => {
    if (timeRemaining === null) return "";
    const m = Math.floor(timeRemaining / 1000 / 60);
    const s = Math.floor((timeRemaining / 1000) % 60);
    return `${m}:${s.toString().padStart(2, "0")}`;
  };

  // Timer handlers
  const handleTimerSelect = (minutes: number | null) => {
    if (!isPremium) {
      setPaywallVisible(true);
      return;
    }
    setTimer(minutes);
  };

  const handlePresetsDisabledPress = () => {
    if (!isPremium) {
      setPaywallVisible(true);
    }
  };

  // Format timer for display
  const formatTime = (ms: number) => {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  // Timer label for the menu title
  const timerLabel =
    timeRemaining !== null
      ? formatTime(timeRemaining)
      : timerDurationChosen
        ? `${timerDurationChosen}m`
        : t.header.timer;

  return (
    <>
      {/* Bottom Toolbar with all action buttons */}
      <Stack.Toolbar>
        {/* Play / Pause */}
        <Stack.Toolbar.Button
          icon={isPlaying ? "pause.fill" : "play.fill"}
          onPress={togglePlayPause}
          selected={isPlaying}
          accessibilityLabel={isPlaying ? "Pause" : "Play"}
          key={isPlaying ? "pauseButton" : "playButton"}
        />

        {/* Shuffle */}
        <Stack.Toolbar.Button
          icon="shuffle"
          onPress={randomizeMix}
          accessibilityLabel="Shuffle"
          key="shuffleButton"
        />

        {/* Binaural — opens as fullScreenModal */}
        <Stack.Toolbar.Button
          icon="waveform.path"
          selected={isBinauralActive}
          onPress={() => router.push("/binaural")}
          accessibilityLabel={t.binaural.title}
          {...(isBinauralActive && {
            tintColor: BINAURAL_COLORS[activeBinauralTrack],
          })}
          key="binauralButton"
        />

        <Stack.Toolbar.Spacer />

        {/* Timer — Menu with duration options */}
        <Stack.Toolbar.Menu
          icon="timer"
          title={timerLabel}
          {...(timerDurationChosen !== null && {
            tintColor: "#34C759",
          })}
        >
          <Stack.Toolbar.MenuAction
            onPress={() => handleTimerSelect(null)}
            icon="xmark.circle"
            isOn={timerDurationChosen === null}
          >
            Off
          </Stack.Toolbar.MenuAction>
          <Stack.Toolbar.MenuAction
            onPress={() => handleTimerSelect(15)}
            icon="clock"
            isOn={timerDurationChosen === 15}
          >
            15 min
          </Stack.Toolbar.MenuAction>
          <Stack.Toolbar.MenuAction
            onPress={() => handleTimerSelect(30)}
            icon="clock.fill"
            isOn={timerDurationChosen === 30}
          >
            30 min
          </Stack.Toolbar.MenuAction>
          <Stack.Toolbar.MenuAction
            onPress={() => handleTimerSelect(60)}
            icon="clock.badge"
            isOn={timerDurationChosen === 60}
          >
            1h
          </Stack.Toolbar.MenuAction>
          <Stack.Toolbar.MenuAction
            onPress={() => handleTimerSelect(120)}
            icon="clock.badge.checkmark"
            isOn={timerDurationChosen === 120}
          >
            2h
          </Stack.Toolbar.MenuAction>
        </Stack.Toolbar.Menu>
        {/* Presets / Favorites */}
        <Stack.Toolbar.Button
          icon={
            isPremium
              ? currentPresetId !== null
                ? "bookmark.fill"
                : "bookmark"
              : "lock.fill"
          }
          selected={isPremium ? currentPresetId !== null : false}
          onPress={() =>
            isPremium ? router.push("/presets") : handlePresetsDisabledPress()
          }
          accessibilityLabel={t.modal.title}
          key="presetsButton"
        />

        {/* <Stack.Toolbar.Spacer /> */}

        {/* AirPlay (via custom view) */}
        {/* {Platform.OS === "ios" && (
          <Stack.Toolbar.View>
            <ExpoAvRoutePickerView
              activeTintColor="#FFF"
              tintColor="#999"
              style={{ width: 28, height: 28 }}
            />
          </Stack.Toolbar.View>
        )} */}
      </Stack.Toolbar>

      {/* Main content */}
      <View style={styles.container}>
        <LanguageSwitcher />
        <AudioEngine />
        <BinauralAudioEngine />
        <AnimatedBackground />
        <View style={styles.overlay}>
          <Header />
          <MixerBoard />
        </View>

        <PaywallScreen />
      </View>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFill,
    flex: 1,
    backgroundColor: "transparent",
  },
});
