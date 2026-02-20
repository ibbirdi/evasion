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
import { useMixerStore } from "../store/useMixerStore";
import { X, Save, Trash2, CheckCircle2 } from "lucide-react-native";

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

  const [newPresetName, setNewPresetName] = useState("");

  const handleSave = () => {
    if (newPresetName.trim().length > 0) {
      saveUserPreset(newPresetName.trim());
      setNewPresetName("");
    }
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={onClose}
    >
      <KeyboardAvoidingView
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        style={styles.modalOverlay}
      >
        <View style={styles.modalContent}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Mes Environnements</Text>
            <Pressable onPress={onClose} style={styles.closeBtn}>
              <X color="#EEE" size={24} />
            </Pressable>
          </View>

          <View style={styles.saveSection}>
            <TextInput
              style={styles.input}
              placeholder="Nom du mix actuel..."
              placeholderTextColor="#888"
              value={newPresetName}
              onChangeText={setNewPresetName}
              maxLength={30}
            />
            <Pressable
              style={[
                styles.saveBtn,
                newPresetName.trim().length === 0 && styles.saveBtnDisabled,
              ]}
              onPress={handleSave}
              disabled={newPresetName.trim().length === 0}
            >
              <Save
                size={18}
                color={newPresetName.trim().length === 0 ? "#888" : "#BAE2C4"}
              />
            </Pressable>
          </View>

          <ScrollView
            style={styles.presetList}
            contentContainerStyle={styles.presetListContent}
          >
            {presets.map((preset) => {
              const isActive = preset.id === currentPresetId;
              const isDefault = preset.id.startsWith("preset_default");

              return (
                <Pressable
                  key={preset.id}
                  style={[
                    styles.presetItem,
                    isActive && styles.presetItemActive,
                  ]}
                  onPress={() => {
                    loadPreset(preset.id);
                    onClose();
                  }}
                >
                  <View style={styles.presetItemLeft}>
                    {isActive ? (
                      <CheckCircle2 size={20} color="#BAE2C4" />
                    ) : (
                      <View style={{ width: 20 }} /> // Spacer to align text
                    )}
                    <Text
                      style={[
                        styles.presetName,
                        isActive && styles.presetNameActive,
                      ]}
                    >
                      {preset.name}
                    </Text>
                  </View>

                  {!isDefault && (
                    <Pressable
                      style={styles.deleteBtn}
                      onPress={() => deleteUserPreset(preset.id)}
                    >
                      <Trash2 size={18} color="#FF6B6B" />
                    </Pressable>
                  )}
                </Pressable>
              );
            })}
          </ScrollView>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
};

const styles = StyleSheet.create({
  modalOverlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.7)",
    justifyContent: "flex-end",
  },
  modalContent: {
    backgroundColor: "#161b22",
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    height: "75%",
    padding: 20,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
  },
  modalHeader: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  modalTitle: {
    color: "#FFF",
    fontSize: 20,
    fontWeight: "600",
  },
  closeBtn: {
    padding: 5,
  },
  saveSection: {
    flexDirection: "row",
    gap: 10,
    marginBottom: 20,
  },
  input: {
    flex: 1,
    height: 44,
    backgroundColor: "rgba(255,255,255,0.05)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
    borderRadius: 12,
    paddingHorizontal: 15,
    color: "#FFF",
    fontSize: 16,
  },
  saveBtn: {
    width: 44,
    height: 44,
    backgroundColor: "rgba(255,255,255,0.08)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.15)",
    borderRadius: 12,
    justifyContent: "center",
    alignItems: "center",
  },
  saveBtnDisabled: {
    opacity: 0.5,
  },
  presetList: {
    flex: 1,
  },
  presetListContent: {
    gap: 10,
    paddingBottom: 40,
  },
  presetItem: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    backgroundColor: "rgba(255,255,255,0.03)",
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.05)",
  },
  presetItemActive: {
    backgroundColor: "rgba(186,226,196,0.1)",
    borderColor: "rgba(186,226,196,0.3)",
  },
  presetItemLeft: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
  },
  presetName: {
    color: "#CCC",
    fontSize: 16,
  },
  presetNameActive: {
    color: "#BAE2C4",
    fontWeight: "600",
  },
  deleteBtn: {
    padding: 5,
  },
});
