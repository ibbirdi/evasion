import React from "react";
import { StyleSheet, useWindowDimensions } from "react-native";
import { Canvas, Rect, LinearGradient, vec } from "@shopify/react-native-skia";

export function AnimatedBackground() {
  const { width, height } = useWindowDimensions();

  return (
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
  );
}
