import { useRouter } from "expo-router";
import { Bookmark, Clock } from "lucide-react-native";
import { SymbolView } from "expo-symbols";
import React, { useEffect, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import Animated, {
  FadeInUp,
  FadeOutUp,
  LinearTransition,
} from "react-native-reanimated";
import { useI18n } from "../i18n";
import { useMixerStore } from "../store/useMixerStore";
import { BINAURAL_COLORS } from "../constants/colors";

export const StatusCapsules: React.FC = () => {
  const router = useRouter();
  const t = useI18n();

  const isPlaying = useMixerStore((s) => s.isPlaying);
  const timerEndTime = useMixerStore((s) => s.timerEndTime);
  const timerDurationChosen = useMixerStore((s) => s.timerDurationChosen);
  const currentPresetId = useMixerStore((s) => s.currentPresetId);
  const presets = useMixerStore((s) => s.presets);
  const isBinauralActive = useMixerStore((s) => s.isBinauralActive);
  const activeBinauralTrack = useMixerStore((s) => s.activeBinauralTrack);

  const [timeRemaining, setTimeRemaining] = useState<number | null>(null);

  useEffect(() => {
    if (!timerEndTime || !isPlaying) {
      if (timerDurationChosen === null) {
        setTimeRemaining(null);
      } else {
        setTimeRemaining(timerDurationChosen * 60 * 1000);
      }
      return;
    }
    const interval = setInterval(() => {
      const remaining = timerEndTime - Date.now();
      if (remaining > 0) {
        setTimeRemaining(remaining);
      } else {
        setTimeRemaining(null);
      }
    }, 1000);
    const initialRemaining = timerEndTime - Date.now();
    setTimeRemaining(initialRemaining > 0 ? initialRemaining : null);
    return () => clearInterval(interval);
  }, [timerEndTime, isPlaying, timerDurationChosen]);

  const formatTime = (ms: number) => {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  };

  const activePreset = presets.find((p) => p.id === currentPresetId);

  return (
    <Animated.View layout={LinearTransition} style={styles.container}>
      {/* Binaural Capsule */}
      {isBinauralActive && (
        <Animated.View
          entering={FadeInUp}
          exiting={FadeOutUp}
          layout={LinearTransition}
        >
          <Pressable
            onPress={() => router.push("/binaural")}
            style={[
              styles.capsule,
              {
                backgroundColor: `${BINAURAL_COLORS[activeBinauralTrack]}20`,
                borderColor: `${BINAURAL_COLORS[activeBinauralTrack]}40`,
              },
            ]}
          >
            <SymbolView
              name="waveform.path"
              size={12}
              tintColor={BINAURAL_COLORS[activeBinauralTrack]}
            />
            <Text
              style={[
                styles.text,
                { color: BINAURAL_COLORS[activeBinauralTrack] },
              ]}
            >
              {t.binaural[activeBinauralTrack] || activeBinauralTrack}
            </Text>
          </Pressable>
        </Animated.View>
      )}

      {/* Timer Capsule */}
      {timerDurationChosen !== null && (
        <Animated.View
          entering={FadeInUp}
          exiting={FadeOutUp}
          layout={LinearTransition}
        >
          <View style={styles.capsule}>
            <Clock size={12} color="#FFF" opacity={0.8} />
            <Text style={styles.text}>
              {timeRemaining !== null
                ? formatTime(timeRemaining)
                : `${timerDurationChosen}m`}
            </Text>
          </View>
        </Animated.View>
      )}

      {/* Preset Capsule */}
      {activePreset && (
        <Animated.View
          entering={FadeInUp}
          exiting={FadeOutUp}
          layout={LinearTransition}
        >
          <Pressable
            onPress={() => router.push("/presets")}
            style={styles.capsule}
          >
            <Bookmark size={12} color="#FFF" opacity={0.8} />
            <Text style={styles.text}>{activePreset.name}</Text>
          </Pressable>
        </Animated.View>
      )}
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "center",
    gap: 8,
    marginTop: 8,
    paddingHorizontal: 20,
  },
  capsule: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "rgba(255, 255, 255, 0.1)",
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.15)",
    gap: 5,
  },
  text: {
    color: "#FFF",
    fontSize: 12,
    fontWeight: "600",
  },
});
