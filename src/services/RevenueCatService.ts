import Purchases, { PurchasesPackage } from "react-native-purchases";
import { Platform } from "react-native";
import { useMixerStore } from "../store/useMixerStore";

// TODO: Replace with your actual RevenueCat API keys
const iosApiKey = "appl_KJQnGRCJPIZiOAWmEVXSnqKTMUU";
const androidApiKey = "test_CXlajEGbuuvuVzMmeoqONSRBAhV";

export const RevenueCatService = {
  initialize: async () => {
    if (Platform.OS === "ios") {
      Purchases.configure({ apiKey: iosApiKey });
    } else if (Platform.OS === "android") {
      Purchases.configure({ apiKey: androidApiKey });
    }
    // Check initial status
    await RevenueCatService.checkPremiumStatus();
  },

  checkPremiumStatus: async () => {
    const customerInfo = await Purchases.getCustomerInfo();
    // Assuming your entitlement identifier is "premium"
    if (typeof customerInfo.entitlements.active["premium"] !== "undefined") {
      useMixerStore.getState().setIsPremium(true);
    } else {
      // Optional: you can choose not to override to false if you want to trust the persisted state when offline
      useMixerStore.getState().setIsPremium(false);
    }
  },

  getOfferings: async (): Promise<PurchasesPackage | null> => {
    try {
      const offerings = await Purchases.getOfferings();
      if (
        offerings.current !== null &&
        offerings.current.availablePackages.length !== 0
      ) {
        // Return the first available package (Lifetime / One-Time)
        return offerings.current.availablePackages[0];
      }
      return null;
    } catch (e) {
      console.error("Error getting offerings:", e);
      return null;
    }
  },

  purchasePremium: async (pkg: PurchasesPackage) => {
    try {
      const { customerInfo } = await Purchases.purchasePackage(pkg);
      if (typeof customerInfo.entitlements.active["premium"] !== "undefined") {
        useMixerStore.getState().setIsPremium(true);
        return true;
      }
      return false;
    } catch (e: any) {
      if (!e.userCancelled) {
        console.error("Error purchasing premium:", e);
      }
      return false;
    }
  },

  restorePurchases: async () => {
    try {
      const customerInfo = await Purchases.restorePurchases();
      if (typeof customerInfo.entitlements.active["premium"] !== "undefined") {
        useMixerStore.getState().setIsPremium(true);
        return true;
      }
      return false;
    } catch (e) {
      console.error("Error restoring purchases:", e);
      return false;
    }
  },
};
