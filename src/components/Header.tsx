import MaskedView from "@react-native-masked-view/masked-view";
import { GlassView } from "expo-glass-effect";
import { LinearGradient } from "expo-linear-gradient";
import React from "react";
import { StyleSheet, Text, View, Image, TouchableOpacity } from "react-native";
import Animated, { LinearTransition } from "react-native-reanimated";
import { useI18n, SUPPORTED_LANGUAGES } from "../i18n";
import { StatusCapsules } from "./StatusCapsules";

export const Header: React.FC = () => {
  const { setLanguage, currentLanguage } = useI18n();
  const t = useI18n();

  const handleLogoPress = () => {
    const currentIndex = SUPPORTED_LANGUAGES.indexOf(currentLanguage);
    const nextIndex = (currentIndex + 1) % SUPPORTED_LANGUAGES.length;
    setLanguage(SUPPORTED_LANGUAGES[nextIndex]);
  };

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
          {/* <TouchableOpacity
            onPress={handleLogoPress}
            activeOpacity={0.7}
            testID="AppLogo"
          > */}
          <Image
            source={require("../../assets/oasisLogo.png")}
            style={styles.logo}
            resizeMode="contain"
          />
          {/* </TouchableOpacity> */}
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
    paddingBottom: 30, // Extended padding for a smoother blur fade
  },
  header: {
    paddingTop: 50,
    paddingHorizontal: 10,
  },
  titleContainer: {
    alignItems: "center",
  },
  logo: {
    width: 200,
    height: 50,
  },
  subtitle: {
    fontSize: 8,
    fontWeight: "500",
    letterSpacing: 4,
    color: "#F5F5F7",
    opacity: 0.5,
    marginTop: 4,
    textTransform: "uppercase",
  },
});
