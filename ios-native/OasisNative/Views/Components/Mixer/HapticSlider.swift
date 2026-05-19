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

struct AutoVariationRangeSlider: View {
    @Binding var range: AutoVariationRange
    let liveValue: Double
    let tint: Color
    let stepCount: Int

    @State private var activeHandle: RangeSliderHandle?
    @State private var lastQuantizedLower = 0
    @State private var lastQuantizedUpper = 0
    @State private var feedbackTrigger = 0

    init(
        range: Binding<AutoVariationRange>,
        liveValue: Double,
        tint: Color,
        stepCount: Int = 24
    ) {
        _range = range
        self.liveValue = liveValue
        self.tint = tint
        self.stepCount = stepCount
    }

    var body: some View {
        if AppConfiguration.supportsSensoryFeedback {
            sliderContent
                .onAppear(perform: updateQuantizedBounds)
                .onChange(of: range) { _, _ in
                    triggerFeedbackIfNeeded()
                }
                .sensoryFeedback(.impact(weight: .medium, intensity: 0.82), trigger: feedbackTrigger)
        } else {
            sliderContent
        }
    }

    private var sliderContent: some View {
        GeometryReader { proxy in
            let handleSize: CGFloat = 24
            let handleRadius = handleSize / 2
            let trackWidth = max(proxy.size.width - handleSize, 1)
            let normalizedRange = range.clamped()
            let lowerX = handleRadius + CGFloat(normalizedRange.lowerBound) * trackWidth
            let upperX = handleRadius + CGFloat(normalizedRange.upperBound) * trackWidth
            let liveX = handleRadius + CGFloat(min(max(liveValue, 0), 1)) * trackWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: trackWidth, height: 12)
                    .offset(x: handleRadius)

                Capsule()
                    .fill(tint.opacity(0.24))
                    .frame(width: max(upperX - lowerX, 0), height: 12)
                    .offset(x: lowerX)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(0.96),
                                tint.opacity(0.58)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(liveX - lowerX, 0), height: 8)
                    .offset(x: lowerX)

                Circle()
                    .fill(.white.opacity(0.94))
                    .frame(width: 7, height: 7)
                    .shadow(color: tint.opacity(0.55), radius: 5)
                    .offset(x: liveX - 3.5)

                rangeHandle(isActive: activeHandle == .lower)
                    .offset(x: lowerX - handleRadius)

                rangeHandle(isActive: activeHandle == .upper)
                    .offset(x: upperX - handleRadius)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateRange(
                            with: gesture.location.x,
                            trackStart: handleRadius,
                            trackWidth: trackWidth,
                            lowerX: lowerX,
                            upperX: upperX
                        )
                    }
                    .onEnded { _ in
                        activeHandle = nil
                    }
            )
        }
        .frame(height: 36)
        .animation(.linear(duration: 0.14), value: liveValue)
        .accessibilityElement(children: .ignore)
        .accessibilityAction(named: Text(L10n.Mixer.increaseMinimum)) {
            adjust(.lower, by: stepValue)
        }
        .accessibilityAction(named: Text(L10n.Mixer.decreaseMinimum)) {
            adjust(.lower, by: -stepValue)
        }
        .accessibilityAction(named: Text(L10n.Mixer.increaseMaximum)) {
            adjust(.upper, by: stepValue)
        }
        .accessibilityAction(named: Text(L10n.Mixer.decreaseMaximum)) {
            adjust(.upper, by: -stepValue)
        }
        .accessibilityValue(Text(verbatim: accessibilityRangeValue))
    }

    private func rangeHandle(isActive: Bool) -> some View {
        Circle()
            .fill(.ultraThinMaterial)
            .overlay {
                Circle()
                    .fill(isActive ? tint.opacity(0.32) : Color.white.opacity(0.08))
            }
            .overlay {
                Circle()
                    .strokeBorder(isActive ? tint.opacity(0.76) : Color.white.opacity(0.42), lineWidth: 1.1)
            }
            .frame(width: 24, height: 24)
    }

    private func updateRange(
        with locationX: CGFloat,
        trackStart: CGFloat,
        trackWidth: CGFloat,
        lowerX: CGFloat,
        upperX: CGFloat
    ) {
        let value = min(max(Double((locationX - trackStart) / trackWidth), 0), 1)
        let handle = activeHandle ?? nearestHandle(to: locationX, lowerX: lowerX, upperX: upperX)
        activeHandle = handle

        switch handle {
        case .lower:
            range = AutoVariationRange(
                lowerBound: min(value, range.upperBound - AutoVariationRange.minimumWidth),
                upperBound: range.upperBound
            ).clamped()
        case .upper:
            range = AutoVariationRange(
                lowerBound: range.lowerBound,
                upperBound: max(value, range.lowerBound + AutoVariationRange.minimumWidth)
            ).clamped()
        }
    }

    private func nearestHandle(to locationX: CGFloat, lowerX: CGFloat, upperX: CGFloat) -> RangeSliderHandle {
        abs(locationX - lowerX) <= abs(locationX - upperX) ? .lower : .upper
    }

    private func updateQuantizedBounds() {
        lastQuantizedLower = quantizedStep(for: range.lowerBound)
        lastQuantizedUpper = quantizedStep(for: range.upperBound)
    }

    private func triggerFeedbackIfNeeded() {
        let lower = quantizedStep(for: range.lowerBound)
        let upper = quantizedStep(for: range.upperBound)
        guard lower != lastQuantizedLower || upper != lastQuantizedUpper else { return }
        lastQuantizedLower = lower
        lastQuantizedUpper = upper
        feedbackTrigger += 1
    }

    private func quantizedStep(for value: Double) -> Int {
        Int((min(max(value, 0), 1) * Double(stepCount)).rounded())
    }

    private var stepValue: Double {
        1 / Double(max(stepCount, 1))
    }

    private var accessibilityRangeValue: String {
        let normalized = range.clamped()
        let lower = Int((normalized.lowerBound * 100).rounded())
        let upper = Int((normalized.upperBound * 100).rounded())
        return "\(lower)% - \(upper)%"
    }

    private func adjust(_ handle: RangeSliderHandle, by delta: Double) {
        activeHandle = handle
        switch handle {
        case .lower:
            range = AutoVariationRange(
                lowerBound: range.lowerBound + delta,
                upperBound: range.upperBound
            ).clamped()
        case .upper:
            range = AutoVariationRange(
                lowerBound: range.lowerBound,
                upperBound: range.upperBound + delta
            ).clamped()
        }
    }
}

private enum RangeSliderHandle {
    case lower
    case upper
}
