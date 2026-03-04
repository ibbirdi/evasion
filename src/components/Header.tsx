import React from "react";
import { StyleSheet, Text, View } from "react-native";
import Animated, { LinearTransition } from "react-native-reanimated";
import { useI18n } from "../i18n";
import { StatusCapsules } from "./StatusCapsules";

export const Header: React.FC = () => {
  const t = useI18n();

  return (
    <Animated.View layout={LinearTransition} style={styles.header}>
      <View style={styles.titleContainer}>
        <Text style={styles.title}>{t.header.title}</Text>
        <Text style={styles.subtitle}>Binaural Nature</Text>
        <StatusCapsules />
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  header: {
    paddingTop: 40,
    paddingHorizontal: 10,
  },
  titleContainer: {
    alignItems: "center",
  },
  title: {
    fontSize: 50,
    fontFamily: "DancingScript_700Bold",
    fontWeight: "700",
    letterSpacing: 2,
    color: "#F5F5F7", // Apple-style off-white
    textShadowColor: "rgba(255, 255, 255, 1)",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 1,
  },
  subtitle: {
    fontSize: 10,
    fontWeight: "500",
    letterSpacing: 4,
    color: "#F5F5F7",
    opacity: 0.6,
    marginTop: -2,
    textTransform: "uppercase",
  },
});
