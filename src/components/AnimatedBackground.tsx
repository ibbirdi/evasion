import React from "react";
import { StyleSheet, useWindowDimensions } from "react-native";
import { Canvas, Rect, LinearGradient, vec } from "@shopify/react-native-skia";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  Easing,
} from "react-native-reanimated";
import { useMixerStore } from "../store/useMixerStore";
import { useEffect } from "react";

export function AnimatedBackground() {
  const { width, height } = useWindowDimensions();
  const isZenMode = useMixerStore((state) => state.isZenMode);
  const zenOpacity = useSharedValue(0);

  useEffect(() => {
    zenOpacity.value = withTiming(isZenMode ? 0.8 : 0, {
      duration: isZenMode ? 7000 : 300,
      easing: Easing.inOut(Easing.ease),
    });
  }, [isZenMode]);

  const animatedOverlayStyle = useAnimatedStyle(() => ({
    opacity: zenOpacity.value,
    backgroundColor: "#000",
    ...StyleSheet.absoluteFillObject,
  }));

  return (
    <>
      <Canvas style={StyleSheet.absoluteFill}>
        <Rect x={0} y={0} width={width} height={height}>
          <LinearGradient
            start={vec(width / 2, 0)}
            end={vec(width / 2, height)}
            colors={["#0a0e17", "#0d1520", "#0a1018", "#060a10"]}
            positions={[0, 0.35, 0.7, 1]}
          />
        </Rect>
      </Canvas>
      <Animated.View pointerEvents="none" style={animatedOverlayStyle} />
    </>
  );
}
