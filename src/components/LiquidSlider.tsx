import React, { useEffect } from "react";
import { StyleSheet, Text, View } from "react-native";
import { Volume2, VolumeX, Activity, Lock } from "lucide-react-native";
import Slider from "@react-native-community/slider";
import { ChannelId } from "../types/mixer";
import { LiquidButton } from "./LiquidButton";
import { useI18n } from "../i18n";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  Easing,
} from "react-native-reanimated";

interface Props {
  id: ChannelId;
  label: string;
  color: string;
  value: number; // 0 to 1
  isZenMode: boolean;
  isMuted: boolean;
  autoVariationEnabled: boolean;
  onChange: (val: number) => void;
  onToggleMute: () => void;
  onToggleAutoVariation: () => void;
  isLocked?: boolean;
  onRequirePremium?: () => void;
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
  isLocked = false,
  onRequirePremium,
  isZenMode,
}) => {
  const t = useI18n();
  const isVariationOn = autoVariationEnabled && !isLocked;

  const zenOpacity = useSharedValue(1);
  const isMutedOrZero = isMuted || value === 0;

  useEffect(() => {
    if (isZenMode) {
      zenOpacity.value = withTiming(isMutedOrZero ? 0.05 : 1, {
        duration: 7000,
        easing: Easing.inOut(Easing.ease),
      });
    } else {
      zenOpacity.value = withTiming(1, {
        duration: 300,
        easing: Easing.inOut(Easing.ease),
      });
    }
  }, [isZenMode, isMutedOrZero]);

  const animatedContainerStyle = useAnimatedStyle(() => ({
    opacity: zenOpacity.value,
  }));

  return (
    <Animated.View style={[styles.container, animatedContainerStyle]}>
      <View style={styles.content}>
        <View style={styles.labelContainer}>
          <Text style={styles.label}>{label}</Text>
          {isLocked && (
            <Lock
              size={12}
              color="rgba(255,255,255,0.4)"
              style={{ marginTop: 4 }}
            />
          )}
        </View>

        <View style={styles.sliderContainer}>
          <Slider
            style={styles.nativeSlider}
            value={value}
            onValueChange={onChange}
            minimumValue={0}
            maximumValue={1}
            disabled={autoVariationEnabled || isLocked}
            minimumTrackTintColor={color}
            maximumTrackTintColor="rgba(255,255,255,0.1)"
            thumbTintColor={isVariationOn ? "transparent" : "#FFFFFF"}
            thumbImage={
              isVariationOn
                ? {
                    uri: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=",
                  }
                : undefined
            }
          />

          {autoVariationEnabled && (
            <View style={styles.autoLabelContainer} pointerEvents="none">
              <Text style={styles.autoLabelText}>{t.mixer.auto_variation}</Text>
            </View>
          )}
        </View>

        {/* Controls */}
        <View style={styles.controls}>
          {isLocked ? (
            <LiquidButton onPress={onRequirePremium} isRound isActive={false}>
              <Lock size={18} color="#AAA" />
            </LiquidButton>
          ) : (
            <>
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
            </>
          )}
        </View>
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
  controls: {
    flexDirection: "row",
    gap: 8,
    width: 96,
    justifyContent: "flex-end",
  },
});
