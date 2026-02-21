import React, { useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Modal,
  Pressable,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import { GestureDetector, Gesture } from "react-native-gesture-handler";
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  runOnJS,
} from "react-native-reanimated";
import { useMixerStore } from "../store/useMixerStore";
import { Save, Trash2, CheckCircle2 } from "lucide-react-native";
import { GlassView } from "expo-glass-effect";
import { LiquidButton } from "./LiquidButton";
import { CHANNEL_COLORS } from "../constants/colors";
import { useI18n } from "../i18n";

const hexToRgba = (hex: string, alpha: number) => {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

interface PresetsModalProps {
  visible: boolean;
  onClose: () => void;
}

export const PresetsModal: React.FC<PresetsModalProps> = ({
  visible,
  onClose,
}) => {
  const presets = useMixerStore((state) => state.presets);
  const currentPresetId = useMixerStore((state) => state.currentPresetId);
  const loadPreset = useMixerStore((state) => state.loadPreset);
  const saveUserPreset = useMixerStore((state) => state.saveUserPreset);
  const deleteUserPreset = useMixerStore((state) => state.deleteUserPreset);

  const t = useI18n();

  const [newPresetName, setNewPresetName] = useState("");

  const handleSave = () => {
    if (newPresetName.trim().length > 0) {
      saveUserPreset(newPresetName.trim());
      setNewPresetName("");
    }
  };

  const translateY = useSharedValue(0);
  const startY = useSharedValue(0);

  const panGesture = Gesture.Pan()
    .onStart(() => {
      startY.value = translateY.value;
    })
    .onUpdate((event) => {
      // Only allow pulling down
      if (event.translationY > 0) {
        translateY.value = startY.value + event.translationY;
      }
    })
    .onEnd((event) => {
      if (event.translationY > 150) {
        // Trigger close if pulled down enough
        runOnJS(onClose)();
      } else {
        // Snap back
        translateY.value = withSpring(0, { damping: 20, stiffness: 200 });
      }
    });

  // Reset translation when modal opens
  React.useEffect(() => {
    if (visible) {
      translateY.value = 0;
    }
  }, [visible, translateY]);

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ translateY: translateY.value }],
    };
  });

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={styles.overlay}
      >
        <Animated.View style={[styles.container, animatedStyle]}>
          <GlassView style={StyleSheet.absoluteFillObject} tintColor="dark" />
          <GestureDetector gesture={panGesture}>
            <Animated.View style={styles.dragArea}>
              <View style={styles.handlebarContainer}>
                <View style={styles.handlebar} />
              </View>
            </Animated.View>
          </GestureDetector>

          <Animated.View style={styles.content}>
            <Text style={styles.modalTitle}>{t.modal.title}</Text>

            <View style={styles.saveSection}>
              <TextInput
                style={styles.input}
                placeholder={t.modal.presetName}
                placeholderTextColor="rgba(255,255,255,0.4)"
                value={newPresetName}
                onChangeText={setNewPresetName}
                maxLength={30}
                cursorColor="#FFF"
                selectionColor="rgba(255, 255, 255, 0.3)"
              />
              <LiquidButton
                size={48}
                isRound
                isActive={newPresetName.trim().length > 0}
                onPress={
                  newPresetName.trim().length > 0 ? handleSave : undefined
                }
              >
                <Save
                  size={20}
                  color={
                    newPresetName.trim().length === 0
                      ? "rgba(255,255,255,0.3)"
                      : "#FFF"
                  }
                />
              </LiquidButton>
            </View>

            <ScrollView
              style={styles.presetList}
              contentContainerStyle={styles.presetListContent}
              showsVerticalScrollIndicator={false}
            >
              {presets.length === 0 && (
                <Text style={styles.noPresets}>{t.modal.noPresets}</Text>
              )}
              {presets.map((preset, index) => {
                const isActive = preset.id === currentPresetId;
                const colors = Object.values(CHANNEL_COLORS);
                const themeColor = colors[index % colors.length];

                // If it's a default preset, translate it, otherwise use its name
                let displayName = preset.name;
                if (preset.id === "preset_default_calm")
                  displayName = t.presets.default_calm;
                if (preset.id === "preset_default_storm")
                  displayName = t.presets.default_storm;

                return (
                  <Pressable
                    key={preset.id}
                    style={[
                      styles.presetItem,
                      isActive && {
                        backgroundColor: hexToRgba(themeColor, 0.1),
                      },
                    ]}
                    onPress={() => {
                      loadPreset(preset.id);
                      onClose();
                    }}
                  >
                    <View style={styles.presetItemLeft}>
                      {isActive ? (
                        <CheckCircle2 size={20} color={themeColor} />
                      ) : (
                        <View style={{ width: 20 }} /> // Spacer to align text
                      )}
                      <Text
                        style={[
                          styles.presetName,
                          isActive && { color: themeColor, fontWeight: "600" },
                        ]}
                      >
                        {displayName}
                      </Text>
                    </View>

                    <LiquidButton
                      style={{
                        transform: [{ scale: 0.85 }],
                        marginRight: -10,
                      }}
                      size={40}
                      isRound
                      isActive={false}
                      onPress={() => {
                        // Prevent deleting default presets if needed, but currently all presets can be deleted?
                        // Assuming delete is fine.
                        deleteUserPreset(preset.id);
                      }}
                    >
                      <Trash2 size={18} color={themeColor} />
                    </LiquidButton>
                  </Pressable>
                );
              })}
            </ScrollView>
          </Animated.View>
        </Animated.View>
      </KeyboardAvoidingView>
    </Modal>
  );
};

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: "transparent",
    justifyContent: "flex-end", // Optional: to snap to bottom if not flex 1
  },
  container: {
    flex: 1,
    marginTop: Platform.OS === "ios" ? 64 : 0,
    backgroundColor: "transparent",
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    overflow: "hidden",
  },
  dragArea: {
    width: "100%",
  },
  handlebarContainer: {
    width: "100%",
    alignItems: "center",
    paddingVertical: 12,
  },
  handlebar: {
    width: 36,
    height: 5,
    borderRadius: 3,
    backgroundColor: "rgba(255,255,255,0.2)",
  },
  content: {
    flex: 1,
    paddingHorizontal: 24,
    paddingTop: 8,
  },
  modalTitle: {
    color: "#FFF",
    fontSize: 28,
    fontWeight: "600",
    letterSpacing: -0.5,
    marginBottom: 24,
  },
  saveSection: {
    flexDirection: "row",
    gap: 12,
    marginBottom: 24,
  },
  input: {
    flex: 1,
    height: 48,
    backgroundColor: "rgba(255,255,255,0.06)",
    borderRadius: 24,
    paddingHorizontal: 20,
    color: "#FFF",
    fontSize: 16,
  },
  presetList: {
    flex: 1,
  },
  presetListContent: {
    gap: 8,
    paddingBottom: 40,
  },
  noPresets: {
    color: "rgba(255,255,255,0.4)",
    fontSize: 16,
    textAlign: "center",
    marginTop: 32,
    fontStyle: "italic",
  },
  presetItem: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "rgba(255,255,255,0.03)",
    paddingVertical: 16,
    paddingHorizontal: 16,
    borderRadius: 16,
  },
  presetItemActive: {
    backgroundColor: "rgba(186,226,196,0.1)",
  },
  presetItemLeft: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
  },
  presetName: {
    color: "rgba(255,255,255,0.7)",
    fontSize: 17,
    fontWeight: "400",
  },
});
