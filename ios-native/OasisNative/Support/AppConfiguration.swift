import Foundation
import CoreHaptics

enum DevelopmentPremiumOverride: String {
    case revenueCat
    case premium
    case free

    static func resolved() -> Self {
        #if DEBUG
        let processInfo = ProcessInfo.processInfo

        if let launchArgumentValue = processInfo.launchArgumentValue(after: "-OASISPremiumOverride"),
           let override = Self(rawValue: launchArgumentValue.lowercased()) {
            return override
        }

        if let environmentValue = processInfo.environment["OASIS_PREMIUM_OVERRIDE"],
           let override = Self(rawValue: environmentValue.lowercased()) {
            return override
        }

        return .revenueCat
        #else
        return .revenueCat
        #endif
    }

    var forcedPremiumAccess: Bool? {
        switch self {
        case .revenueCat:
            return nil
        case .premium:
            return true
        case .free:
            return false
        }
    }
}

enum AppConfiguration {
    static let persistenceKey = "evasion-mixer-storage"
    static let supportURL = URL(string: "https://bow-elephant-191.notion.site/ASSISTANCE-31084ba33afa801d872fc2aecc576f56?source=copy_link")!
    static let isRunningUITests = ProcessInfo.processInfo.arguments.contains("-ui_testing")
    static let isRunningFastlaneSnapshot = ProcessInfo.processInfo.arguments.contains("-FASTLANE_SNAPSHOT")
    static let isRunningScreenshotAutomation = isRunningUITests || isRunningFastlaneSnapshot
    static let shouldResetStateOnLaunch = isRunningScreenshotAutomation || ProcessInfo.processInfo.arguments.contains("-OASISResetState")
    static let shouldPersistState = !isRunningScreenshotAutomation
    static let revenueCatAPIKey = (
        ProcessInfo.processInfo.environment["OASIS_REVENUECAT_API_KEY"] ??
        (Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String)
    )?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    static let revenueCatEntitlementID = (Bundle.main.object(forInfoDictionaryKey: "RevenueCatEntitlementID") as? String)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? "premium"
    static let devPremiumOverride = DevelopmentPremiumOverride.resolved()
    static let forcedPremiumAccess = devPremiumOverride.forcedPremiumAccess
    static let shouldUseRevenueCatAccess = forcedPremiumAccess == nil
    static let isRevenueCatConfigured = !revenueCatAPIKey.isEmpty

    #if targetEnvironment(simulator)
    static let isSimulator = true
    static let supportsSensoryFeedback = false
    #else
    static let isSimulator = false
    static let supportsSensoryFeedback = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    #endif
}

private extension ProcessInfo {
    func launchArgumentValue(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let nextIndex = arguments.index(after: index)
        guard arguments.indices.contains(nextIndex) else { return nil }
        return arguments[nextIndex]
    }
}
