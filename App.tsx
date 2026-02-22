import "react-native-gesture-handler";
import "react-native-reanimated";
import { StatusBar } from "expo-status-bar";
import { StyleSheet, View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
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
import {
  useFonts,
  DancingScript_700Bold,
} from "@expo-google-fonts/dancing-script";
import * as SplashScreen from "expo-splash-screen";

SplashScreen.preventAutoHideAsync();

export default function App() {
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

  if (!fontsLoaded) return null;
  return (
    <I18nProvider>
      <GestureHandlerRootView
        style={styles.container}
        onLayout={onLayoutRootView}
      >
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
