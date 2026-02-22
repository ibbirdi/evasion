import {
  DancingScript_700Bold,
  useFonts,
} from "@expo-google-fonts/dancing-script";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useCallback, useEffect, useRef, useState } from "react";
import { StyleSheet, View } from "react-native";
import "react-native-gesture-handler";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import "react-native-reanimated";
import { AnimatedBackground } from "./src/components/AnimatedBackground";
import { AudioEngine } from "./src/components/AudioEngine";
import { BinauralAudioEngine } from "./src/components/BinauralAudioEngine";
import { BinauralPanel } from "./src/components/BinauralPanel";
import { Header } from "./src/components/Header";
import { MixerBoard } from "./src/components/MixerBoard";
import { PaywallScreen } from "./src/components/PaywallScreen";
import { PresetsModal } from "./src/components/PresetsModal";
import { LanguageSwitcher } from "./src/components/LanguageSwitcher";
import { ZEN_CONFIG } from "./src/config/zen";
import { I18nProvider } from "./src/i18n";
import { RevenueCatService } from "./src/services/RevenueCatService";
import { useMixerStore } from "./src/store/useMixerStore";

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
      }, ZEN_CONFIG.INACTIVITY_DELAY);
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

  if (!fontsLoaded) return null;
  return (
    <I18nProvider>
      <GestureHandlerRootView
        style={styles.container}
        onLayout={onLayoutRootView}
      >
        <View style={styles.container} onTouchStart={resetZenTimer}>
          <LanguageSwitcher />
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
