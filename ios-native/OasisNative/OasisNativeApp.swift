import SwiftUI
import RevenueCat
import TelemetryDeck

@main
struct OasisNativeApp: App {
    @State private var model = AppModel()

    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else { return }
        Purchases.configure(withAPIKey: AppConfiguration.revenueCatAPIKey)

        if AppConfiguration.isTelemetryDeckConfigured {
            let config = TelemetryDeck.Config(appID: AppConfiguration.telemetryDeckAppID)
            TelemetryDeck.initialize(config: config)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
