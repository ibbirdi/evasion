import { GlassView } from "expo-glass-effect";
import { useRouter } from "expo-router";
import React, { useCallback, useRef, useState } from "react";
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from "react-native";
import {
  Gesture,
  GestureDetector,
  GestureHandlerRootView,
} from "react-native-gesture-handler";
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from "react-native-reanimated";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { AUDIO_CONFIG } from "../config/audio";
import { useI18n } from "../i18n";
import { useMixerStore } from "../store/useMixerStore";

const hexToRgba = (hex: string, alpha: number) => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

const ROW_HEIGHT = 48;

const SPRING_CONFIG = {
  damping: 25,
  stiffness: 300,
  mass: 0.8,
};

// ─── Draggable Preset Row ──────────────────────────────────────────
interface DraggablePresetRowProps {
  preset: { id: string; name: string };
  index: number;
  isActive: boolean;
  themeColor: string;
  displayName: string;
  totalCount: number;
  onPress: () => void;
  onDelete: () => void;
  onDragStart: (index: number) => void;
  onDragMove: (index: number, translationY: number) => void;
  onDragEnd: (fromIndex: number, toIndex: number) => void;
  isDraggingOther: boolean;
}

function DraggablePresetRow({
  preset,
  index,
  isActive,
  themeColor,
  displayName,
  totalCount,
  onPress,
  onDelete,
  onDragStart,
  onDragMove,
  onDragEnd,
  isDraggingOther,
}: DraggablePresetRowProps) {
  const translateY = useSharedValue(0);
  const isDragging = useSharedValue(false);
  const zIdx = useSharedValue(0);
  const scale = useSharedValue(1);
  const opacity = useSharedValue(1);
  const startIndex = useRef(index);

  const panGesture = Gesture.Pan()
    .activateAfterLongPress(200)
    .onStart(() => {
      isDragging.value = true;
      zIdx.value = 100;
      scale.value = withSpring(1.04, SPRING_CONFIG);
      opacity.value = withTiming(0.9, { duration: 100 });
      startIndex.current = index;
      runOnJS(onDragStart)(index);
    })
    .onUpdate((e) => {
      translateY.value = e.translationY;
      runOnJS(onDragMove)(index, e.translationY);
    })
    .onEnd((e) => {
      const rawOffset = Math.round(e.translationY / ROW_HEIGHT);
      const clampedTo = Math.max(
        0,
        Math.min(totalCount - 1, index + rawOffset),
      );

      isDragging.value = false;
      translateY.value = withSpring(0, SPRING_CONFIG);
      scale.value = withSpring(1, SPRING_CONFIG);
      opacity.value = withTiming(1, { duration: 150 });
      zIdx.value = 0;

      runOnJS(onDragEnd)(startIndex.current, clampedTo);
    })
    .onFinalize(() => {
      isDragging.value = false;
      translateY.value = withSpring(0, SPRING_CONFIG);
      scale.value = withSpring(1, SPRING_CONFIG);
      opacity.value = withTiming(1, { duration: 150 });
      zIdx.value = 0;
    });

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }, { scale: scale.value }],
    zIndex: zIdx.value,
    opacity: opacity.value,
  }));

  return (
    <GestureDetector gesture={panGesture}>
      <Animated.View style={animatedStyle}>
        <Pressable
          style={({ pressed }) => [
            styles.presetRow,
            isActive && {
              backgroundColor: hexToRgba(themeColor, 0.1),
              borderColor: hexToRgba(themeColor, 0.25),
            },
            pressed && !isDraggingOther && styles.presetRowPressed,
          ]}
          onPress={isDraggingOther ? undefined : onPress}
        >
          {/* Drag handle */}
          <View style={styles.dragHandle}>
            <Text style={styles.dragIcon}>☰</Text>
          </View>

          {/* Active indicator dot */}
          <View style={styles.dotColumn}>
            {isActive && (
              <View
                style={[styles.activeDot, { backgroundColor: themeColor }]}
              />
            )}
          </View>

          <Text
            style={[
              styles.presetLabel,
              isActive && {
                color: themeColor,
                fontWeight: "600",
              },
            ]}
            numberOfLines={1}
          >
            {displayName}
          </Text>

          <Pressable
            onPress={onDelete}
            style={({ pressed }) => [
              styles.deleteBtn,
              pressed && styles.deleteBtnPressed,
            ]}
            hitSlop={8}
          >
            <Text style={styles.deleteX}>✕</Text>
          </Pressable>
        </Pressable>
      </Animated.View>
    </GestureDetector>
  );
}

// ─── Main Screen ───────────────────────────────────────────────────
export default function PresetsScreen() {
  const presets = useMixerStore((state) => state.presets) || [];
  const currentPresetId = useMixerStore((state) => state.currentPresetId);
  const loadPreset = useMixerStore((state) => state.loadPreset);
  const saveUserPreset = useMixerStore((state) => state.saveUserPreset);
  const deleteUserPreset = useMixerStore((state) => state.deleteUserPreset);
  const reorderPresets = useMixerStore((state) => state.reorderPresets);

  const t = useI18n();
  const router = useRouter();
  const insets = useSafeAreaInsets();

  const [newPresetName, setNewPresetName] = useState("");
  const [isDragging, setIsDragging] = useState(false);

  const handleSave = () => {
    if (newPresetName.trim().length > 0) {
      saveUserPreset(newPresetName.trim());
      setNewPresetName("");
    }
  };

  const colors: string[] = Object.values(AUDIO_CONFIG).map((c) => c.color);

  const handleDragStart = useCallback(() => {
    setIsDragging(true);
  }, []);

  const handleDragMove = useCallback(() => {
    // Reserved for potential haptic feedback or visual hints
  }, []);

  const handleDragEnd = useCallback(
    (fromIndex: number, toIndex: number) => {
      setIsDragging(false);
      if (fromIndex !== toIndex) {
        reorderPresets(fromIndex, toIndex);
      }
    },
    [reorderPresets],
  );

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <View style={styles.screenContainer}>
        {/* Tap backdrop to dismiss */}
        <Pressable
          style={StyleSheet.absoluteFill}
          onPress={() => router.back()}
        />

        <View
          style={[
            styles.container,
            { marginBottom: Math.max(insets.bottom, 20) + 70 },
          ]}
        >
          <GlassView
            style={[StyleSheet.absoluteFill, { borderRadius: 36 }]}
            tintColor="dark"
          />

          <View style={styles.inner}>
            {/* Title */}
            <Text style={styles.title}>{t.modal.title}</Text>

            {/* Save section — inline input + button */}
            <View style={styles.saveRow}>
              <View style={styles.inputWrapper}>
                <TextInput
                  style={styles.input}
                  placeholder={t.modal.presetName}
                  placeholderTextColor="rgba(255,255,255,0.28)"
                  value={newPresetName}
                  onChangeText={setNewPresetName}
                  maxLength={30}
                  cursorColor="rgba(255,255,255,0.6)"
                  selectionColor="rgba(255, 255, 255, 0.2)"
                  returnKeyType="done"
                  onSubmitEditing={handleSave}
                />
              </View>
              <Pressable
                onPress={
                  newPresetName.trim().length > 0 ? handleSave : undefined
                }
                style={({ pressed }) => [
                  styles.saveButton,
                  newPresetName.trim().length > 0 && styles.saveButtonActive,
                  pressed &&
                    newPresetName.trim().length > 0 &&
                    styles.saveButtonPressed,
                ]}
              >
                <Text
                  style={[
                    styles.saveIcon,
                    newPresetName.trim().length > 0 && styles.saveIconActive,
                  ]}
                >
                  ＋
                </Text>
              </Pressable>
            </View>

            {/* Divider */}
            <View style={styles.divider} />

            {/* Presets List */}
            <ScrollView
              style={styles.listScroll}
              contentContainerStyle={styles.listContent}
              showsVerticalScrollIndicator={false}
              bounces={presets.length > 4}
              scrollEnabled={!isDragging}
            >
              {presets.length === 0 ? (
                <Text style={styles.emptyText}>{t.modal.noPresets}</Text>
              ) : (
                presets.map((preset, index) => {
                  if (!preset) return null;
                  const isActive = preset.id === currentPresetId;
                  const themeColor = colors[index % colors.length];

                  let displayName = preset.name;
                  if (preset.id === "preset_default_calm")
                    displayName = t.presets.default_calm;
                  if (preset.id === "preset_default_storm")
                    displayName = t.presets.default_storm;

                  return (
                    <DraggablePresetRow
                      key={preset.id}
                      preset={preset}
                      index={index}
                      isActive={isActive}
                      themeColor={themeColor}
                      displayName={displayName}
                      totalCount={presets.length}
                      onPress={() => {
                        loadPreset(preset.id);
                        router.back();
                      }}
                      onDelete={() => deleteUserPreset(preset.id)}
                      onDragStart={handleDragStart}
                      onDragMove={handleDragMove}
                      onDragEnd={handleDragEnd}
                      isDraggingOther={isDragging}
                    />
                  );
                })
              )}
            </ScrollView>
          </View>
        </View>
      </View>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  screenContainer: {
    flex: 1,
    justifyContent: "flex-end",
    paddingHorizontal: 16,
  },
  container: {
    borderRadius: 36,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.3,
    shadowRadius: 24,
    elevation: 8,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(255,255,255,0.15)",
    maxHeight: "55%",
  },
  inner: {
    paddingTop: 22,
    paddingBottom: 20,
    borderRadius: 36,
    overflow: "hidden",
  },

  // ── Title ──
  title: {
    color: "#FFF",
    fontSize: 17,
    fontWeight: "600",
    letterSpacing: -0.2,
    marginBottom: 18,
    paddingHorizontal: 24,
  },

  // ── Save Row ──
  saveRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingHorizontal: 24,
    marginBottom: 16,
  },
  inputWrapper: {
    flex: 1,
    height: 38,
    borderRadius: 12,
    backgroundColor: "rgba(255,255,255,0.07)",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(255,255,255,0.1)",
    justifyContent: "center",
  },
  input: {
    height: 38,
    paddingHorizontal: 14,
    color: "#FFF",
    fontSize: 14,
    fontWeight: "400",
    letterSpacing: -0.1,
  },
  saveButton: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: "rgba(255,255,255,0.06)",
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "rgba(255,255,255,0.1)",
    alignItems: "center",
    justifyContent: "center",
  },
  saveButtonActive: {
    backgroundColor: "rgba(255,255,255,0.15)",
    borderColor: "rgba(255,255,255,0.25)",
  },
  saveButtonPressed: {
    opacity: 0.7,
  },
  saveIcon: {
    fontSize: 18,
    color: "rgba(255,255,255,0.2)",
    fontWeight: "300",
    marginTop: -1,
  },
  saveIconActive: {
    color: "rgba(255,255,255,0.9)",
  },

  // ── Divider ──
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: "rgba(255,255,255,0.08)",
    marginHorizontal: 24,
    marginBottom: 8,
  },

  // ── List ──
  listScroll: {
    maxHeight: 260,
  },
  listContent: {
    paddingHorizontal: 24,
    paddingTop: 8,
    paddingBottom: 4,
  },
  emptyText: {
    color: "rgba(255,255,255,0.3)",
    fontSize: 13,
    textAlign: "center",
    marginTop: 16,
    marginBottom: 8,
    fontWeight: "400",
    letterSpacing: -0.1,
  },

  // ── Preset Row ──
  presetRow: {
    flexDirection: "row",
    alignItems: "center",
    height: ROW_HEIGHT,
    paddingRight: 12,
    paddingLeft: 4,
    borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: "transparent",
    marginBottom: 4,
  },
  presetRowPressed: {
    backgroundColor: "rgba(255,255,255,0.06)",
  },

  // ── Drag Handle ──
  dragHandle: {
    width: 28,
    height: 28,
    alignItems: "center",
    justifyContent: "center",
  },
  dragIcon: {
    fontSize: 14,
    color: "rgba(255,255,255,0.2)",
    letterSpacing: 1,
  },

  dotColumn: {
    width: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  activeDot: {
    width: 7,
    height: 7,
    borderRadius: 3.5,
  },
  presetLabel: {
    flex: 1,
    color: "rgba(255,255,255,0.8)",
    fontSize: 15,
    fontWeight: "400",
    letterSpacing: -0.2,
    marginLeft: 4,
  },

  // ── Delete Button ──
  deleteBtn: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  deleteBtnPressed: {
    backgroundColor: "rgba(255,255,255,0.08)",
  },
  deleteX: {
    fontSize: 11,
    fontWeight: "500",
    color: "rgba(255,255,255,0.25)",
  },
});
