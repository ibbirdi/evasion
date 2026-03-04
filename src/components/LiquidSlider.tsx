import Slider from "@react-native-community/slider";
import { SymbolView } from "expo-symbols";
import React, { ReactNode, useEffect } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import * as Haptics from "expo-haptics";
import Animated, {
  FadeIn,
  FadeOut,
  LinearTransition,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import { useI18n } from "../i18n";
import { useLiveStore } from "../store/useLiveStore";
import { ChannelId } from "../types/mixer";
import { LiquidButton } from "./LiquidButton";

interface Props {
  id: ChannelId;
  label: string;
  icon?: ReactNode;
  color: string;
  value: number; // 0 to 1
  isMuted: boolean;
  autoVariationEnabled: boolean;
  onChange: (val: number) => void;
  onToggleMute: () => void;
  onToggleAutoVariation: () => void;
  isLocked?: boolean;
  onRequirePremium?: () => void;
}

export const LiquidSlider: React.FC<Props> = ({
  id,
  label,
  icon,
  color,
  value,
  isMuted,
  autoVariationEnabled,
  onChange,
  onToggleMute,
  onToggleAutoVariation,
  isLocked = false,
  onRequirePremium,
}) => {
  const t = useI18n();
  const isVariationOn = autoVariationEnabled && !isLocked;

  const variation = useLiveStore((s) => s.variations[id]);
  const targetValue =
    variation !== undefined && variation !== null ? variation : value;

  const animatedValue = useSharedValue(targetValue);

  useEffect(() => {
    // Smoothly animate to the new value when it changes (e.g. shuffle)
    animatedValue.value = withTiming(targetValue, { duration: 500 });
  }, [targetValue]);

  // We still need a numeric value for the Slider component.
  // Since Slider is native, we'll use the targetValue for direct interaction,
  // but for "shuffle" transitions, the state update in the store might already be progressive if implemented there.
  // However, the user asked for "native transitions".
  // Let's use the targetValue directly for now as the layout transition already helps with the component feel.
  // To truly animate the thumb, we'd need a fully custom slider.
  // Given the constraints of the native Slider, I will focus on the layout and label animations which provide the most "smooth" feel.

  return (
    <Animated.View
      layout={LinearTransition}
      style={[styles.container, isMuted && { opacity: 0.5 }]}
    >
      <View style={styles.content}>
        <View style={styles.labelContainer}>
          <Pressable
            onPress={() => {
              if (isLocked) {
                onRequirePremium?.();
              } else {
                Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
                onToggleMute();
              }
            }}
            style={({ pressed }) => [
              styles.labelWithIcon,
              pressed && { opacity: 0.7 },
            ]}
          >
            {icon && (
              <View style={[styles.iconWrapper, !isMuted && styles.iconGlow]}>
                {icon}
              </View>
            )}
            <Text style={[styles.label, !isMuted && styles.labelActive]}>
              {label}
            </Text>
          </Pressable>
          {isLocked && (
            <SymbolView
              name="lock.fill"
              size={12}
              tintColor="rgba(255,255,255,0.4)"
              style={{ marginTop: 4 }}
            />
          )}
        </View>

        <Animated.View
          layout={LinearTransition}
          style={styles.sliderContainer}
          pointerEvents={
            isMuted || (autoVariationEnabled && !isLocked) ? "none" : "auto"
          }
        >
          <Slider
            key={`${id}-${isVariationOn && !isMuted}`}
            style={styles.nativeSlider}
            value={targetValue}
            onValueChange={onChange}
            minimumValue={0}
            maximumValue={1}
            disabled={isLocked || isMuted}
            minimumTrackTintColor={color}
            maximumTrackTintColor="rgba(255,255,255,0.1)"
            {...(isVariationOn && !isMuted
              ? {
                  thumbTintColor: "transparent",
                  thumbImage: {
                    uri: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
                  },
                }
              : {
                  thumbTintColor: "#FFFFFF",
                  thumbImage: undefined,
                })}
          />

          {autoVariationEnabled && (
            <Animated.View
              entering={FadeIn}
              exiting={FadeOut}
              style={styles.autoLabelContainer}
              pointerEvents="none"
            >
              <Text style={styles.autoLabelText}>{t.mixer.auto_variation}</Text>
            </Animated.View>
          )}
        </Animated.View>

        {/* Controls */}
        <Animated.View layout={LinearTransition} style={styles.controls}>
          {isLocked ? (
            <LiquidButton onPress={onRequirePremium} isRound isActive={false}>
              <SymbolView name="lock.fill" size={18} tintColor="#AAA" />
            </LiquidButton>
          ) : (
            <LiquidButton
              onPress={onToggleAutoVariation}
              isRound
              isActive={autoVariationEnabled}
            >
              <Text
                style={[
                  styles.autoButtonText,
                  { color: autoVariationEnabled ? "#FFF" : "#AAA" },
                ]}
              >
                AUTO
              </Text>
            </LiquidButton>
          )}
        </Animated.View>
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    marginBottom: 20,
    width: "100%",
  },
  content: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 16,
    width: "100%",
    justifyContent: "space-between",
  },
  labelContainer: {
    width: 100,
    overflow: "visible",
  },
  labelWithIcon: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    overflow: "visible",
  },
  iconWrapper: {
    width: 20,
    height: 20,
    alignItems: "center",
    justifyContent: "center",
    marginRight: 4,
    borderRadius: 10,
  },
  iconGlow: {
    shadowColor: "#ffe1fcff",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 10,
  },
  labelActive: {
    opacity: 1,
    textShadowColor: "rgba(198, 189, 255, 0.5)",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 3,
    padding: 10,
    margin: -10,
  },
  label: {
    color: "#ffffffff",
    fontWeight: "600",
    fontSize: 14,
    opacity: 0.9,
  },
  sliderContainer: {
    flex: 1,
    marginHorizontal: 10,
    justifyContent: "center",
    height: 40,
  },
  nativeSlider: {
    width: "100%",
    height: 40,
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
  autoButtonText: {
    fontSize: 8,
    fontWeight: "600",
    letterSpacing: 1,
  },
  controls: {
    flexDirection: "row",
    gap: 8,
    width: 48,
    justifyContent: "flex-end",
  },
});
