import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            if model.hasCompletedOnboarding || AppConfiguration.isRunningScreenshotAutomation {
                HomeView()
            } else {
                OnboardingView()
            }

            // Overlaid at the root so the ritual can dim every other surface during its
            // brief choreography. Pointer-transparent — never blocks user input.
            EntryRitual()
        }
    }
}
