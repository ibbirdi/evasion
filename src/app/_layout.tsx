import {
  DancingScript_700Bold,
  useFonts,
} from "@expo-google-fonts/dancing-script";
import * as SplashScreen from "expo-splash-screen";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useCallback, useEffect } from "react";
import "react-native-gesture-handler";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import "react-native-reanimated";
import { I18nProvider } from "../i18n";
import { RevenueCatService } from "../services/RevenueCatService";

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
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
      <GestureHandlerRootView style={{ flex: 1 }} onLayout={onLayoutRootView}>
        <Stack
          screenOptions={{
            headerShown: false,
          }}
        >
          <Stack.Screen
            name="index"
            options={{
              contentStyle: { backgroundColor: "transparent" },
            }}
          />
          <Stack.Screen
            name="binaural"
            options={{
              presentation: "transparentModal",
              headerShown: false,
              contentStyle: { backgroundColor: "transparent" },
              animation: "fade",
            }}
          />
          <Stack.Screen
            name="presets"
            options={{
              presentation: "transparentModal",
              headerShown: false,
              contentStyle: { backgroundColor: "transparent" },
              animation: "fade",
            }}
          />
        </Stack>
        <StatusBar style="light" />
      </GestureHandlerRootView>
    </I18nProvider>
  );
}
