import React from "react";
import { Pressable, StyleSheet } from "react-native";
import { useI18n, SUPPORTED_LANGUAGES } from "../i18n";
import { DEBUG_CONFIG } from "../config/debug";

/**
 * An invisible button placed in the top-left corner
 * used to cycle through languages for screenshots.
 */
export const LanguageSwitcher: React.FC = () => {
  const { currentLanguage, setLanguage } = useI18n();

  if (!DEBUG_CONFIG.ENABLE_LANGUAGE_SWITCHER) {
    return null;
  }

  const cycleLanguage = () => {
    const currentIndex = SUPPORTED_LANGUAGES.indexOf(currentLanguage);
    const nextIndex = (currentIndex + 1) % SUPPORTED_LANGUAGES.length;
    setLanguage(SUPPORTED_LANGUAGES[nextIndex]);
  };

  return (
    <Pressable
      onPress={cycleLanguage}
      style={styles.container}
      testID="language-switcher-debug"
    />
  );
};

const styles = StyleSheet.create({
  container: {
    position: "absolute",
    top: 0,
    left: 0,
    width: 60,
    height: 60,
    zIndex: 9999,
    backgroundColor: "transparent", // Invisible but touchable
  },
});
