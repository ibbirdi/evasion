import React, { useEffect } from "react";
import { StyleSheet, useWindowDimensions, View } from "react-native";
import { Canvas, Fill, Shader, Skia } from "@shopify/react-native-skia";
import {
  useSharedValue,
  withRepeat,
  withTiming,
  Easing,
  useDerivedValue,
} from "react-native-reanimated";

const sksl = `
uniform float2 resolution;
uniform float time;

// Fonction de base pour l'aléatoire (dithering)
float random(float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898,78.233))) * 43758.5453123);
}

// Bruit 2D basique (Value Noise)
float noise (float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    float2 u = f*f*(3.0-2.0*f);

    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

// FBM (Fractional Brownian Motion) pour la fluidité
float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

half4 main(float2 pos) {
    float2 uv = pos / resolution;
    
    // Ajustement de la vitesse d'évolution des vagues
    float t = time * 0.3;
    
    // TECHNIQUE DE DOMAIN WARPING (Déformation d'espace)
    // C'est ce qui crée cet aspect "Fluide", "Fumée", ou "Vagues" extrêmement doux.
    // L'espace (uv) est distordu par du bruit, qui est lui-même distordu par un bruit en mouvement.
    
    float2 q = float2(0.0);
    q.x = fbm(uv * 2.5 + float2(t * 0.5, t * 1.2));
    q.y = fbm(uv * 2.5 + float2(-t * 0.8, t * 0.4));
    
    float2 r = float2(0.0);
    r.x = fbm(uv * 2.5 + 4.0 * q + float2(t * 1.5, t * 0.8));
    r.y = fbm(uv * 2.5 + 4.0 * q + float2(-t * 1.1, -t * 1.6));
    
    float f = fbm(uv * 2.5 + 4.0 * r);
    
    // Palette Zenith/Nuit douce (Ultra harmonieux)
    float3 col1 = float3(0.02, 0.04, 0.07); // Bleu nuit abyssal (fond)
    float3 col2 = float3(0.06, 0.11, 0.18); // Bleu brume (vagues médianes)
    float3 col3 = float3(0.12, 0.17, 0.25); // Bleu lagon très doux (crêtes des vagues)
    
    float3 finalColor = mix(col1, col2, f);
    finalColor = mix(finalColor, col3, r.x * r.y * 0.8);
    
    // Dithering ultra-subtil (imperceptible) juste pour éviter les "bandes de couleur" (color banding) 
    // sur les écrans OLED avec des dégradés sombres. Ce n'est plus du tout du "grain visuel".
    float dither = (random(pos + time * 0.1) - 0.5) * 0.02;
    finalColor += dither;
    
    return half4(finalColor.r, finalColor.g, finalColor.b, 1.0);
}
`;

const source = Skia.RuntimeEffect.Make(sksl);

export function AnimatedBackground() {
  const { width, height } = useWindowDimensions();
  const time = useSharedValue(0);

  useEffect(() => {
    time.value = withRepeat(
      withTiming(100, { duration: 150000, easing: Easing.linear }),
      -1,
      false,
    );
  }, [time]);

  const uniforms = useDerivedValue(() => {
    return {
      resolution: [width, height],
      time: time.value,
    };
  }, [width, height]);

  if (!source) {
    <View style={[StyleSheet.absoluteFill, { backgroundColor: "#070B14" }]} />;
  }

  return (
    <Canvas style={StyleSheet.absoluteFill}>
      <Fill>
        <Shader source={source!} uniforms={uniforms} />
      </Fill>
    </Canvas>
  );
}
