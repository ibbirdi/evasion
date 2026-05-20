import SwiftUI

struct OasisScaledFontModifier: ViewModifier {
    let weight: Font.Weight
    let design: Font.Design

    @ScaledMetric private var scaledSize: CGFloat

    init(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design,
        relativeTo textStyle: Font.TextStyle
    ) {
        self.weight = weight
        self.design = design
        _scaledSize = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight, design: design))
    }
}

extension View {
    func oasisFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .rounded,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> some View {
        modifier(
            OasisScaledFontModifier(
                size: size,
                weight: weight,
                design: design,
                relativeTo: textStyle
            )
        )
    }

    func oasisMinimumHitTarget(_ size: CGFloat = 44) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        #if os(iOS)
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
        #else
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .animation(.snappy(duration: 0.09, extraBounce: 0.08), value: configuration.isPressed)
        #endif
    }
}
