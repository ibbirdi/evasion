import React from "react";
import {
  StyleSheet,
  Pressable,
  View,
  ViewStyle,
  StyleProp,
} from "react-native";

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
  const borderRadius = isRound ? size / 2 : 20;

  return (
    <Pressable
      testID={testID}
      onPress={onPress}
      style={[
        {
          width: isRound ? size : undefined,
          height: isRound ? size : undefined,
          borderRadius,
          overflow: "hidden",
          backgroundColor: isActive
            ? "rgba(255,255,255,0.25)"
            : "rgba(255,255,255,0.06)",
        },
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
    </Pressable>
  );
};
