import SwiftUI

struct HapticSlider: View {
    @Binding var value: Double
    let tint: Color
    let stepCount: Int

    @State private var lastQuantizedValue = 0
    @State private var feedbackTrigger = 0

    init(
        value: Binding<Double>,
        tint: Color,
        stepCount: Int = 24
    ) {
        _value = value
        self.tint = tint
        self.stepCount = stepCount
    }

    var body: some View {
        if AppConfiguration.supportsSensoryFeedback {
            Slider(value: $value, in: 0...1)
                .tint(tint)
                .onAppear {
                    lastQuantizedValue = quantizedStep(for: value)
                }
                .onChange(of: value) { _, newValue in
                    let step = quantizedStep(for: newValue)
                    guard step != lastQuantizedValue else { return }
                    lastQuantizedValue = step
                    feedbackTrigger += 1
                }
                .sensoryFeedback(.impact(weight: .medium, intensity: 0.82), trigger: feedbackTrigger)
        } else {
            Slider(value: $value, in: 0...1)
                .tint(tint)
        }
    }

    private func quantizedStep(for value: Double) -> Int {
        Int((min(max(value, 0), 1) * Double(stepCount)).rounded())
    }
}
