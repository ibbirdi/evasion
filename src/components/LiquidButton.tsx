import React, { useCallback } from "react";
import {
  StyleSheet,
  Pressable,
  View,
  ViewStyle,
  StyleProp,
} from "react-native";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
} from "react-native-reanimated";
import * as Haptics from "expo-haptics";

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
      ? `rgba(255,255,255,${0.25 + brightness.value * 0.1})`
      : `rgba(255,255,255,${0.06 + brightness.value * 0.08})`,
  }));

  return (
    <AnimatedPressable
      testID={testID}
      onPress={handlePress}
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      style={[
        {
          width: isRound ? size : undefined,
          height: size,
          borderRadius,
          overflow: "hidden",
        },
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
