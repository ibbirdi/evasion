import "react-native-gesture-handler";
import "react-native-reanimated";
import { StatusBar } from "expo-status-bar";
import { StyleSheet, View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { AnimatedBackground } from "./src/components/AnimatedBackground";
import { MixerBoard } from "./src/components/MixerBoard";
import { Header } from "./src/components/Header";
import { useAudioEngine } from "./src/hooks/useAudioEngine";
import { useState } from "react";
import { PresetsModal } from "./src/components/PresetsModal";

export default function App() {
  // Initialize Background Audio Engine (Syncs Zustand with Expo Audio)
  useAudioEngine();

  const [isPresetsVisible, setIsPresetsVisible] = useState(false);

  return (
    <GestureHandlerRootView style={styles.container}>
      <AnimatedBackground />
      <View style={styles.overlay}>
        <Header onOpenPresets={() => setIsPresetsVisible(true)} />
        <MixerBoard />
      </View>
      <PresetsModal
        visible={isPresetsVisible}
        onClose={() => setIsPresetsVisible(false)}
      />
      <StatusBar style="light" />
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "transparent",
  },
});
