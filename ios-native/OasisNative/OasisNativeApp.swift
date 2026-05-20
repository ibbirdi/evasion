import SwiftUI

@main
struct OasisNativeApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        AppBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .onAppear {
                    model.handleScenePhase(scenePhase)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    model.handleScenePhase(newPhase)
                }
        }
    }
}
