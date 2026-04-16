import SwiftUI
import RevenueCat

#if canImport(TelemetryDeck)
import TelemetryDeck
#endif

@main
struct OasisNativeApp: App {
    @State private var model = AppModel()

    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else { return }
        Purchases.configure(withAPIKey: AppConfiguration.revenueCatAPIKey)

        #if canImport(TelemetryDeck)
        if AppConfiguration.isTelemetryDeckConfigured {
            let config = TelemetryDeck.Config(appID: AppConfiguration.telemetryDeckAppID)
            TelemetryDeck.initialize(config: config)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
