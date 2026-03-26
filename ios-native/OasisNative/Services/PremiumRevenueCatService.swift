import Foundation
import RevenueCat

enum PremiumRevenueCatError: Error, Sendable {
    case missingOffering
    case missingPackage
}

struct PremiumPurchaseResult: Sendable {
    let customerInfo: CustomerInfo
    let userCancelled: Bool
}

struct PremiumRevenueCatService: Sendable {
    func customerInfo() async throws -> CustomerInfo {
        try await Purchases.shared.customerInfo()
    }

    func currentLifetimePackage() async throws -> Package {
        let offerings = try await Purchases.shared.offerings()
        guard let currentOffering = offerings.current else {
            throw PremiumRevenueCatError.missingOffering
        }

        if let lifetimePackage = currentOffering.availablePackages.first(where: { $0.packageType == .lifetime }) {
            return lifetimePackage
        }

        if let firstPackage = currentOffering.availablePackages.first {
            return firstPackage
        }

        throw PremiumRevenueCatError.missingPackage
    }

    func purchase(package: Package) async throws -> PremiumPurchaseResult {
        let result = try await Purchases.shared.purchase(package: package)
        return PremiumPurchaseResult(
            customerInfo: result.customerInfo,
            userCancelled: result.userCancelled
        )
    }

    func restorePurchases() async throws -> CustomerInfo {
        try await Purchases.shared.restorePurchases()
    }
}
