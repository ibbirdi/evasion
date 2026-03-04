import { GlassView } from "expo-glass-effect";
import * as Haptics from "expo-haptics";
import React, { useCallback } from "react";
import {
  Pressable,
  StyleProp,
  StyleSheet,
  View,
  ViewStyle,
} from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from "react-native-reanimated";

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

interface LiquidButtonProps {
  onPress?: () => void;
  children: React.ReactNode;
  /** Dimensions et forme du bouton */
  size?: number;
  /** true = bouton rond (icon only) */
  isRound?: boolean;
  /** Met en avant le bouton (bordure + légère surbrillance) */
  isActive?: boolean;
  /** Custom active color */
  activeColor?: string;
  /** Style supplémentaire pour le wrapper extérieur */
  style?: StyleProp<ViewStyle>;
  /** ID for testing with Maestro etc */
  testID?: string;
}

export const LiquidButton: React.FC<LiquidButtonProps> = ({
  onPress,
  children,
  size = 42,
  isRound = false,
  isActive = false,
  activeColor,
  style,
  testID,
}) => {
  const scale = useSharedValue(1);
  const brightness = useSharedValue(0);
  const borderRadius = isRound ? size / 2 : 20;

  const handlePressIn = useCallback(() => {
    scale.value = withSpring(0.9, {
      damping: 15,
      stiffness: 400,
      mass: 0.4,
    });
    brightness.value = withTiming(1, { duration: 80 });
  }, []);

  const handlePressOut = useCallback(() => {
    scale.value = withSpring(1, {
      damping: 12,
      stiffness: 300,
      mass: 0.5,
    });
    brightness.value = withTiming(0, { duration: 200 });
  }, []);

  const handlePress = useCallback(() => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    onPress?.();
  }, [onPress]);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
    backgroundColor: isActive
      ? activeColor || `rgba(255,255,255,${0.2 + brightness.value * 0.1})`
      : `rgba(255,255,255,${0.05 + brightness.value * 0.05})`,
  }));

  return (
    <AnimatedPressable
      testID={testID}
      onPress={handlePress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[
        styles.container,
        {
          width: isRound ? size : undefined,
          height: size,
          borderRadius,
          overflow: "hidden",
        },
        isActive && styles.active,
        isActive && activeColor ? { borderColor: activeColor } : {},
        animatedStyle,
        style,
      ]}
    >
      <View
        style={{
          flex: 1,
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "center",
          gap: 6,
          paddingVertical: isRound ? 0 : 10,
          paddingHorizontal: isRound ? 0 : 14,
        }}
      >
        {children}
      </View>
    </AnimatedPressable>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: "rgba(255, 255, 255, 0.05)",
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.15)",
  },
  active: {
    backgroundColor: "rgba(255, 255, 255, 0.12)",
    borderColor: "rgba(255, 255, 255, 0.3)",
  },
});
