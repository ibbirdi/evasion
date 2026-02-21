import React, { useState, useEffect } from "react";
import { StyleSheet, Text, View, LayoutChangeEvent } from "react-native";
import { Volume2, VolumeX, Activity } from "lucide-react-native";
import { ChannelId } from "../types/mixer";
import { LiquidButton } from "./LiquidButton";
import { Gesture, GestureDetector } from "react-native-gesture-handler";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  runOnJS,
  withTiming,
} from "react-native-reanimated";

interface Props {
  id: ChannelId;
  label: string;
  color: string;
  value: number; // 0 to 1
  isMuted: boolean;
  autoVariationEnabled: boolean;
  onChange: (val: number) => void;
  onToggleMute: () => void;
  onToggleAutoVariation: () => void;
}

export const LiquidSlider: React.FC<Props> = ({
  label,
  color,
  value,
  isMuted,
  autoVariationEnabled,
  onChange,
  onToggleMute,
  onToggleAutoVariation,
}) => {
  const [trackWidth, setTrackWidth] = useState(0);
  const progress = useSharedValue(value);
  const isInteracting = useSharedValue(false);

  // Sync prop -> sharedValue (for AutoVariation external updates)
  useEffect(() => {
    if (!isInteracting.value) {
      progress.value = withTiming(value, { duration: 150 });
    }
  }, [value, isInteracting, progress]);

  const pan = Gesture.Pan()
    .enabled(!autoVariationEnabled)
    .onBegin((e) => {
      isInteracting.value = true;
      if (trackWidth > 0) {
        let newProgress = e.x / trackWidth;
        newProgress = Math.max(0, Math.min(1, newProgress));
        progress.value = newProgress;
        runOnJS(onChange)(newProgress);
      }
    })
    .onUpdate((e) => {
      if (trackWidth > 0) {
        let newProgress = e.x / trackWidth;
        newProgress = Math.max(0, Math.min(1, newProgress));
        progress.value = newProgress;
        runOnJS(onChange)(newProgress);
      }
    })
    .onEnd(() => {
      isInteracting.value = false;
    })
    .onFinalize(() => {
      isInteracting.value = false;
    });

  const fillStyle = useAnimatedStyle(() => ({
    width: `${progress.value * 100}%`,
  }));

  const thumbStyle = useAnimatedStyle(() => {
    const translation = progress.value * trackWidth - 12; // 12 = half of thumb width

    const isActive = progress.value > 0 && !isMuted;
    const shadowOpacity = isActive ? withTiming(0.8) : withTiming(0);

    // Prevent thumb from glitching to left (-12) when width is not yet calculated
    if (trackWidth === 0) {
      return { transform: [{ translateX: 0 }], shadowOpacity };
    }

    return {
      transform: [{ translateX: translation }],
      shadowOpacity,
    };
  });

  return (
    <View style={[styles.row, { opacity: isMuted ? 0.5 : 1 }]}>
      <View style={styles.labelContainer}>
        <Text style={styles.label}>{label}</Text>
      </View>

      <View style={styles.sliderContainer}>
        <GestureDetector gesture={pan}>
          <Animated.View
            style={styles.touchArea}
            onLayout={(e: LayoutChangeEvent) =>
              setTrackWidth(e.nativeEvent.layout.width)
            }
          >
            {/* The Glass Track */}
            <View style={styles.glassTrack}>
              {/* The Fill */}
              <Animated.View
                style={[
                  styles.glassFill,
                  { backgroundColor: color },
                  fillStyle,
                ]}
              />
            </View>

            {/* The Thumb */}
            <Animated.View
              style={[styles.glassThumb, { shadowColor: color }, thumbStyle]}
            >
              {/* <View style={[styles.thumbInner, { backgroundColor: color }]} /> */}
            </Animated.View>
          </Animated.View>
        </GestureDetector>

        {autoVariationEnabled && (
          <View style={styles.autoLabelContainer} pointerEvents="none">
            <Text style={styles.autoLabelText}>AUTO</Text>
          </View>
        )}
      </View>

      {/* Controls */}
      <View style={styles.controls}>
        <LiquidButton
          onPress={onToggleAutoVariation}
          isRound
          isActive={autoVariationEnabled}
        >
          <Activity
            strokeWidth={3}
            size={18}
            color={autoVariationEnabled ? "#FFF" : "#AAA"}
          />
        </LiquidButton>
        <LiquidButton onPress={onToggleMute} isRound isActive={!isMuted}>
          {!isMuted ? (
            <Volume2 strokeWidth={3} size={18} color="#ffffffff" />
          ) : (
            <VolumeX size={18} color="#666" />
          )}
        </LiquidButton>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    marginVertical: 12,
    paddingHorizontal: 16,
    width: "100%",
    justifyContent: "space-between",
  },
  labelContainer: {
    width: 70,
  },
  label: {
    color: "#F0F0F0",
    fontWeight: "600",
    fontSize: 14,
    opacity: 0.9,
  },
  sliderContainer: {
    flex: 1,
    marginHorizontal: 10,
    justifyContent: "center",
  },
  touchArea: {
    width: "100%",
    height: 40,
    justifyContent: "center",
  },
  glassTrack: {
    width: "100%",
    height: 6,
    borderRadius: 3,
    backgroundColor: "rgba(255,255,255,0.06)", // Fond givré très subtil
    overflow: "hidden",
  },
  glassFill: {
    height: "100%",
    opacity: 0.85,
    borderRadius: 5,
  },
  glassThumb: {
    position: "absolute",
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: "rgba(20, 25, 35, 0.95)", // Coeur sombre comme du verre teinté
    borderWidth: 1.5,
    borderColor: "rgba(255,255,255,0.9)", // Bordure étincelante
    shadowOffset: { width: 0, height: 0 },
    shadowRadius: 10,
    justifyContent: "center",
    alignItems: "center",
  },
  thumbInner: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  autoLabelContainer: {
    position: "absolute",
    bottom: -2,
    width: "100%",
    alignItems: "center",
  },
  autoLabelText: {
    color: "rgba(255, 255, 255, 0.4)",
    fontSize: 9,
    letterSpacing: 2,
    fontWeight: "500",
  },
  controls: {
    flexDirection: "row",
    gap: 8,
    width: 96,
    justifyContent: "flex-end",
  },
  roundBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
  },
});
