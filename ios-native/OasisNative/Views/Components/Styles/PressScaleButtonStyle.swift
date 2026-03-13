import SwiftUI

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if AppConfiguration.supportsSensoryFeedback {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.955 : 1)
                .brightness(configuration.isPressed ? 0.03 : 0)
                .animation(.snappy(duration: 0.09, extraBounce: 0.12), value: configuration.isPressed)
                .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: configuration.isPressed) { _, isPressed in
                    isPressed
                }
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.955 : 1)
                .brightness(configuration.isPressed ? 0.03 : 0)
                .animation(.snappy(duration: 0.09, extraBounce: 0.12), value: configuration.isPressed)
        }
    }
}
