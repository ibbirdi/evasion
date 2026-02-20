import React from "react";
import { StyleSheet, Text, View, Pressable } from "react-native";
import Slider from "@react-native-community/slider";
import { Volume2, VolumeX, Activity } from "lucide-react-native";
import { ChannelId } from "../types/mixer";

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
  return (
    <View style={[styles.row, { opacity: isMuted ? 0.5 : 1 }]}>
      <View style={styles.labelContainer}>
        <Text style={styles.label}>{label}</Text>
      </View>

      <View style={styles.sliderContainer}>
        <Slider
          style={styles.slider}
          minimumValue={0}
          maximumValue={1}
          value={value}
          onValueChange={onChange}
          minimumTrackTintColor={color}
          maximumTrackTintColor="rgba(255,255,255,0.3)"
          thumbTintColor={color}
        />
      </View>

      {/* Controls */}
      <View style={styles.controls}>
        <Pressable
          onPress={onToggleAutoVariation}
          style={[styles.roundBtn, autoVariationEnabled && styles.btnActive]}
        >
          <Activity size={16} color={autoVariationEnabled ? "#FFF" : "#AAA"} />
        </Pressable>
        <Pressable
          onPress={onToggleMute}
          style={[
            styles.roundBtn,
            !isMuted ? styles.btnActive : styles.btnMutedLight,
          ]}
        >
          {!isMuted ? (
            <Volume2 size={16} color="#BAE2C4" /> // Greenish when active
          ) : (
            <VolumeX size={16} color="#666" /> // Gray when muted
          )}
        </Pressable>
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
  slider: {
    width: "100%",
    height: 40,
  },
  controls: {
    flexDirection: "row",
    gap: 8,
    width: 75,
    justifyContent: "flex-end",
  },
  roundBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.3)",
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "rgba(255,255,255,0.1)",
  },
  btnActive: {
    backgroundColor: "rgba(255,255,255,0.15)",
    borderColor: "rgba(255,255,255,0.3)",
  },
  btnMutedLight: {
    backgroundColor: "rgba(0,0,0,0.2)",
    borderColor: "rgba(255,255,255,0.1)",
  },
});
