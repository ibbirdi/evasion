import "react-native-gesture-handler";
import "react-native-reanimated";
import { StatusBar } from "expo-status-bar";
import { StyleSheet, View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { AnimatedBackground } from "./src/components/AnimatedBackground";
import { MixerBoard } from "./src/components/MixerBoard";
import { Header } from "./src/components/Header";
import { AudioEngine } from "./src/components/AudioEngine";
import { useState } from "react";
import { PresetsModal } from "./src/components/PresetsModal";
import { I18nProvider } from "./src/i18n";

export default function App() {
  const [isPresetsVisible, setIsPresetsVisible] = useState(false);

  return (
    <I18nProvider>
      <GestureHandlerRootView style={styles.container}>
        <AudioEngine />
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
    </I18nProvider>
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
