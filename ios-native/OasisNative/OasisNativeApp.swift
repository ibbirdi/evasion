import SwiftUI
import RevenueCat

@main
struct OasisNativeApp: App {
    @State private var model = AppModel()

    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else { return }
        Purchases.configure(withAPIKey: AppConfiguration.revenueCatAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(model)
        }
    }
}
