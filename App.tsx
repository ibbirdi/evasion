import "react-native-gesture-handler";
import "react-native-reanimated";
import { StatusBar } from "expo-status-bar";
import { StyleSheet, View } from "react-native";
import { AnimatedBackground } from "./src/components/AnimatedBackground";
import { MixerBoard } from "./src/components/MixerBoard";
import { Header } from "./src/components/Header";
import { AudioEngine } from "./src/components/AudioEngine";
import { BinauralAudioEngine } from "./src/components/BinauralAudioEngine";
import { useState, useCallback, useEffect } from "react";
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

    if (isPlaying && isZenMode) {
      // If we are currently in Zen Mode, bring back controls instantly
      setIsZenMode(false);
    }

    if (isPlaying) {
      // Restart the countdown to go back to Zen
      inactivityTimeout.current = setTimeout(() => {
        setIsZenMode(true);
      }, 5000);
    }
  }, [isPlaying, isZenMode]);

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

  const gesture = Gesture.Tap()
    .onStart(() => {
      runOnJS(resetZenTimer)();
    })
    .runOnJS(true);

  // Also listen for pan to reset timer
  const panGesture = Gesture.Pan()
    .onStart(() => {
      runOnJS(resetZenTimer)();
    })
    .runOnJS(true);

  const composedGesture = Gesture.Exclusive(gesture, panGesture);

  if (!fontsLoaded) return null;
  return (
    <I18nProvider>
      <GestureHandlerRootView
        style={styles.container}
        onLayout={onLayoutRootView}
      >
        <GestureDetector gesture={composedGesture}>
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
