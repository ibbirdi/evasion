import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.hasCompletedOnboarding || AppConfiguration.isRunningScreenshotAutomation {
            HomeView()
        } else {
            OnboardingView()
        }
    }
}
