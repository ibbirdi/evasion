import {
  Canvas,
  Fill,
  LinearGradient,
  vec,
  BlurMask,
  Circle,
} from "@shopify/react-native-skia";
import React, { useEffect } from "react";
import { StyleSheet, useWindowDimensions } from "react-native";
import {
  useSharedValue,
  withRepeat,
  withTiming,
  Easing,
} from "react-native-reanimated";

/**
 * Elegant Blue Gradient Background.
 * Uses a deep base gradient with animated light blooms for a premium feel.
 */
export function AnimatedBackground() {
  const { width, height } = useWindowDimensions();

  // Animation values for subtle motion of light blooms
  const blob1X = useSharedValue(width * 0.2);
  const blob1Y = useSharedValue(height * 0.3);
  const blob2X = useSharedValue(width * 0.8);
  const blob2Y = useSharedValue(height * 0.7);

  useEffect(() => {
    blob1X.value = withRepeat(
      withTiming(width * 0.6, {
        duration: 25000,
        easing: Easing.inOut(Easing.sin),
      }),
      -1,
      true,
    );
    blob1Y.value = withRepeat(
      withTiming(height * 0.5, {
        duration: 28000,
        easing: Easing.inOut(Easing.sin),
      }),
      -1,
      true,
    );
    blob2X.value = withRepeat(
      withTiming(width * 0.4, {
        duration: 32000,
        easing: Easing.inOut(Easing.sin),
      }),
      -1,
      true,
    );
    blob2Y.value = withRepeat(
      withTiming(height * 0.4, {
        duration: 22000,
        easing: Easing.inOut(Easing.sin),
      }),
      -1,
      true,
    );
  }, [width, height]);

  return (
    <Canvas style={StyleSheet.absoluteFill}>
      {/* 
        1. Base Master Gradient
        Creating a deep, elegant anchor for the UI.
      */}
      <Fill>
        <LinearGradient
          start={vec(0, 0)}
          end={vec(0, height)}
          colors={["#001a3d", "#080b1a", "#05060f"]}
          positions={[0, 0.4, 1]}
        />
      </Fill>

      {/* 
        2. Animated Light Bloom - Deep Royal Blue
      */}
      <Circle cx={blob1X} cy={blob1Y} r={width * 0.8}>
        <LinearGradient
          start={vec(width * 0.1, height * 0.25)}
          end={vec(width * 0.4, height * 0.5)}
          colors={["#1B3B8B44", "transparent"]}
        />
        <BlurMask blur={120} style="normal" />
      </Circle>

      {/* 
        3. Animated Light Bloom - Cyan/Sky accent for that 'pop'
      */}
      <Circle cx={blob2X} cy={blob2Y} r={width * 0.7}>
        <LinearGradient
          start={vec(width * 0.9, height * 0.75)}
          end={vec(width * 0.6, height * 0.5)}
          colors={["#00B2FF15", "transparent"]}
        />
        <BlurMask blur={150} style="normal" />
      </Circle>

      {/* 
        4. Finishing Polish
        Subtle diagonal sheen to unify the composition.
      */}
      <Fill opacity={0.1}>
        <LinearGradient
          start={vec(0, 0)}
          end={vec(width, height)}
          colors={[
            "rgba(255, 255, 255, 0.1)",
            "transparent",
            "rgba(0, 0, 0, 0.2)",
          ]}
        />
      </Fill>
    </Canvas>
  );
}
