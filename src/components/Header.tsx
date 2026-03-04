import MaskedView from "@react-native-masked-view/masked-view";
import { GlassView } from "expo-glass-effect";
import { LinearGradient } from "expo-linear-gradient";
import React from "react";
import { StyleSheet, Text, View } from "react-native";
import Animated, { LinearTransition } from "react-native-reanimated";
import { useI18n } from "../i18n";
import { StatusCapsules } from "./StatusCapsules";

export const Header: React.FC = () => {
  const t = useI18n();

  return (
    <Animated.View
      layout={LinearTransition}
      style={styles.headerContainer}
      pointerEvents="box-none"
    >
      <MaskedView
        style={StyleSheet.absoluteFill}
        pointerEvents="none"
        maskElement={
          <LinearGradient
            colors={["rgba(0,0,0,1)", "rgba(0,0,0,0)"]}
            locations={[0.7, 1]}
            style={StyleSheet.absoluteFill}
          />
        }
      >
        <GlassView style={StyleSheet.absoluteFill} tintColor="dark" />
      </MaskedView>

      <View style={styles.header} pointerEvents="box-none">
        <View style={styles.titleContainer} pointerEvents="box-none">
          <Text style={styles.title}>{t.header.title}</Text>
          <Text style={styles.subtitle}>Binaural Nature</Text>
          <StatusCapsules />
        </View>
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  headerContainer: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    zIndex: 10,
    paddingBottom: 40, // Extended padding for a smoother blur fade
  },
  header: {
    paddingTop: 50,
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
    fontSize: 8,
    fontWeight: "500",
    letterSpacing: 4,
    color: "#F5F5F7",
    opacity: 0.5,
    marginTop: -2,
    textTransform: "uppercase",
  },
});
