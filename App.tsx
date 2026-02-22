import "react-native-gesture-handler";
import "react-native-reanimated";
import { StatusBar } from "expo-status-bar";
import { StyleSheet, View } from "react-native";
import { AnimatedBackground } from "./src/components/AnimatedBackground";
import { MixerBoard } from "./src/components/MixerBoard";
import { Header } from "./src/components/Header";
import { AudioEngine } from "./src/components/AudioEngine";
import { BinauralAudioEngine } from "./src/components/BinauralAudioEngine";
import { useState, useCallback, useEffect, useMemo } from "react";
import { PresetsModal } from "./src/components/PresetsModal";
import { I18nProvider } from "./src/i18n";
import { PaywallScreen } from "./src/components/PaywallScreen";
import { BinauralPanel } from "./src/components/BinauralPanel";
import { RevenueCatService } from "./src/services/RevenueCatService";
import { useMixerStore } from "./src/store/useMixerStore";
import {
  Gesture,
  GestureDetector,
  GestureHandlerRootView,
} from "react-native-gesture-handler";
import Animated, {
  useAnimatedStyle,
  withTiming,
  runOnJS,
} from "react-native-reanimated";
import { useRef } from "react";
import {
  useFonts,
  DancingScript_700Bold,
} from "@expo-google-fonts/dancing-script";
import * as SplashScreen from "expo-splash-screen";

SplashScreen.preventAutoHideAsync();

export default function App() {
  const isPlaying = useMixerStore((s) => s.isPlaying);
  const isZenMode = useMixerStore((s) => s.isZenMode);
  const setIsZenMode = useMixerStore((s) => s.setIsZenMode);

  const [isPresetsVisible, setIsPresetsVisible] = useState(false);
  const [fontsLoaded] = useFonts({ DancingScript_700Bold });

  useEffect(() => {
    RevenueCatService.initialize();
  }, []);

  const onLayoutRootView = useCallback(async () => {
    if (fontsLoaded) {
      await SplashScreen.hideAsync();
    }
  }, [fontsLoaded]);

  const inactivityTimeout = useRef<NodeJS.Timeout | null>(null);

  const resetZenTimer = useCallback(() => {
    if (inactivityTimeout.current) clearTimeout(inactivityTimeout.current);

    // Use getter for store to avoid dependency on isZenMode
    const { isZenMode, isPlaying } = useMixerStore.getState();

    if (isPlaying && isZenMode) {
      setIsZenMode(false);
    }

    if (isPlaying) {
      inactivityTimeout.current = setTimeout(() => {
        setIsZenMode(true);
      }, 5000);
    }
  }, [isPlaying]); // Only depends on isPlaying to know if we should restart the timer

  useEffect(() => {
    if (isPlaying) {
      resetZenTimer();
    } else {
      if (inactivityTimeout.current) clearTimeout(inactivityTimeout.current);
      setIsZenMode(false);
    }
    return () => {
      if (inactivityTimeout.current) clearTimeout(inactivityTimeout.current);
    };
  }, [isPlaying]);

  const activityGesture = useMemo(
    () =>
      Gesture.Pan()
        .runOnJS(true)
        .minDistance(0)
        .onBegin(() => {
          runOnJS(resetZenTimer)();
        }),
    [resetZenTimer],
  );

  if (!fontsLoaded) return null;
  return (
    <I18nProvider>
      <GestureHandlerRootView
        style={styles.container}
        onLayout={onLayoutRootView}
      >
        <GestureDetector gesture={activityGesture}>
          <View style={styles.container}>
            <AudioEngine />
            <BinauralAudioEngine />
            <AnimatedBackground />
            <View style={styles.overlay}>
              <Header onOpenPresets={() => setIsPresetsVisible(true)} />
              <MixerBoard />
              <BinauralPanel />
            </View>
            <PresetsModal
              visible={isPresetsVisible}
              onClose={() => setIsPresetsVisible(false)}
            />
            <PaywallScreen />
            <StatusBar style="light" />
          </View>
        </GestureDetector>
      </GestureHandlerRootView>
    </I18nProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    flex: 1,
    backgroundColor: "transparent",
  },
});
