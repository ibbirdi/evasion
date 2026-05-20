import Foundation
import RevenueCat

#if canImport(TelemetryDeck)
import TelemetryDeck
#endif

enum AppBootstrap {
    static func configure() {
        #if DEBUG
        Purchases.logLevel = AppConfiguration.shouldEnableRevenueCatDebugLogs ? .debug : .error
        #endif

        if AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured {
            Purchases.configure(withAPIKey: AppConfiguration.revenueCatAPIKey)
        }

        #if canImport(TelemetryDeck)
        if AppConfiguration.isTelemetryDeckConfigured {
            let config = TelemetryDeck.Config(appID: AppConfiguration.telemetryDeckAppID)
            TelemetryDeck.initialize(config: config)
        }
        #endif
    }
}
