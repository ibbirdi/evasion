import React, { useEffect, useState } from "react";
import {
  View,
  Text,
  StyleSheet,
  Modal,
  Pressable,
  ActivityIndicator,
  Linking,
} from "react-native";
import { GlassView } from "expo-glass-effect";
import { CheckCircle2, X } from "lucide-react-native";
import { useI18n } from "../i18n";
import { useMixerStore } from "../store/useMixerStore";
import { RevenueCatService } from "../services/RevenueCatService";
import { PurchasesPackage } from "react-native-purchases";
import { CHANNEL_COLORS } from "../constants/colors";

export const PaywallScreen: React.FC = () => {
  const t = useI18n();
  const visible = useMixerStore((state) => state.isPaywallVisible);
  const setVisible = useMixerStore((state) => state.setPaywallVisible);

  const [currentPackage, setCurrentPackage] = useState<PurchasesPackage | null>(
    null,
  );
  const [isLoading, setIsLoading] = useState(false);
  const [isRestoring, setIsRestoring] = useState(false);

  useEffect(() => {
    if (visible) {
      loadOfferings();
    }
  }, [visible]);

  const loadOfferings = async () => {
    const pkg = await RevenueCatService.getOfferings();
    setCurrentPackage(pkg);
  };

  const handlePurchase = async () => {
    if (!currentPackage) return;
    setIsLoading(true);
    const success = await RevenueCatService.purchasePremium(currentPackage);
    setIsLoading(false);
    if (success) {
      setVisible(false);
    }
  };

  const handleRestore = async () => {
    setIsRestoring(true);
    const success = await RevenueCatService.restorePurchases();
    setIsRestoring(false);
    if (success) {
      setVisible(false);
    } else {
      // Optional: Show error alert "No purchases to restore"
    }
  };

  const openURL = (url: string) => {
    Linking.openURL(url).catch((err) =>
      console.error("Couldn't load page", err),
    );
  };

  if (!visible) return null;

  const benefits = [
    t.paywall.benefit_1,
    t.paywall.benefit_2,
    t.paywall.benefit_3,
    t.paywall.benefit_4,
  ];

  return (
    <Modal
      visible={visible}
      animationType="slide"
      transparent={true}
      onRequestClose={() => setVisible(false)}
    >
      <View style={styles.container}>
        <GlassView style={StyleSheet.absoluteFillObject} tintColor="dark" />

        {/* Close Button */}
        <Pressable style={styles.closeButton} onPress={() => setVisible(false)}>
          <X size={28} color="rgba(255,255,255,0.6)" />
        </Pressable>

        <View style={styles.content}>
          <Text style={styles.title}>{t.paywall.title}</Text>

          <View style={styles.benefitsContainer}>
            {benefits.map((benefit, index) => (
              <View key={index} style={styles.benefitRow}>
                <CheckCircle2 size={24} color={CHANNEL_COLORS.oiseaux} />
                <Text style={styles.benefitText}>{benefit}</Text>
              </View>
            ))}
          </View>

          <Text style={styles.noSubText}>{t.paywall.no_sub}</Text>

          {/* CTA */}
          <Pressable
            style={({ pressed }) => [
              styles.ctaButton,
              (!currentPackage || isLoading) && styles.ctaDisabled,
              pressed && { transform: [{ scale: 0.98 }] },
            ]}
            onPress={handlePurchase}
            disabled={!currentPackage || isLoading}
          >
            <View style={styles.ctaContent}>
              {isLoading ? (
                <ActivityIndicator color="#111827" />
              ) : (
                <Text style={styles.ctaText}>
                  {t.paywall.cta}
                  {currentPackage ? currentPackage.product.priceString : "..."}
                </Text>
              )}
            </View>
          </Pressable>

          {/* Footer Links */}
          <View style={styles.footer}>
            <Pressable onPress={handleRestore}>
              <Text style={styles.footerLink}>
                {isRestoring ? "..." : t.paywall.restore}
              </Text>
            </Pressable>
            <Text style={styles.footerSeparator}>{"  •  "}</Text>
            <Pressable onPress={() => openURL("https://your-terms-url.com")}>
              <Text style={styles.footerLink}>{t.paywall.terms}</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.8)", // Fallback behind GlassView
    justifyContent: "center",
  },
  closeButton: {
    position: "absolute",
    top: 60,
    right: 24,
    zIndex: 10,
    padding: 8,
  },
  content: {
    paddingHorizontal: 32,
    alignItems: "center",
    justifyContent: "center",
    marginTop: 60,
  },
  title: {
    fontSize: 34,
    fontWeight: "600",
    color: "#FFFFFF",
    textAlign: "center",
    letterSpacing: -0.5,
    marginBottom: 48,
  },
  benefitsContainer: {
    width: "100%",
    gap: 20,
    marginBottom: 48,
  },
  benefitRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 16,
  },
  benefitText: {
    fontSize: 18,
    color: "rgba(255,255,255,0.9)",
    flexShrink: 1,
    lineHeight: 24,
  },
  noSubText: {
    fontSize: 15,
    color: "rgba(255,255,255,0.6)",
    textAlign: "center",
    marginBottom: 24,
  },
  ctaButton: {
    backgroundColor: CHANNEL_COLORS.oiseaux, // "L'Ambre Premium"
    width: "100%",
    borderRadius: 30,
    shadowColor: CHANNEL_COLORS.oiseaux,
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.2,
    shadowRadius: 10,
    elevation: 8,
    marginBottom: 32,
  },
  ctaContent: {
    paddingVertical: 18,
    alignItems: "center",
    justifyContent: "center",
    width: "100%",
  },
  ctaDisabled: {
    opacity: 1,
  },
  ctaText: {
    color: "#111827",
    fontSize: 18,
    fontWeight: "700",
  },
  footer: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
  },
  footerLink: {
    fontSize: 13,
    color: "rgba(255,255,255,0.5)",
    textDecorationLine: "underline",
  },
  footerSeparator: {
    fontSize: 13,
    color: "rgba(255,255,255,0.3)",
  },
});
