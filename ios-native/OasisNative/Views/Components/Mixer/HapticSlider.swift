import Foundation
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
            sliderContent
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
            sliderContent
        }
    }

    private var sliderContent: some View {
        Slider(value: $value, in: 0...1)
            .tint(tint)
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

    @GestureState private var activeHandle: RangeSliderHandle?
    @State private var draftRange: AutoVariationRange?
    @State private var lastDragCommitTime: TimeInterval = 0
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
            let trackStart: CGFloat = 0
            let trackWidth = max(proxy.size.width, 1)
            let normalizedRange = displayedRange.clamped()
            let lowerX = trackStart + CGFloat(normalizedRange.lowerBound) * trackWidth
            let upperX = trackStart + CGFloat(normalizedRange.upperBound) * trackWidth
            let liveX = trackStart + CGFloat(min(max(liveValue, 0), 1)) * trackWidth
            let activeX = min(max(liveX, lowerX), upperX)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(activeHandle == nil ? 0.14 : 0.18))
                    .frame(width: trackWidth, height: OasisSliderChrome.trackHeight)
                    .offset(x: trackStart)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                tint.opacity(activeHandle == nil ? 0.78 : 0.92),
                                tint.opacity(activeHandle == nil ? 0.56 : 0.74)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(upperX - lowerX, 0), height: OasisSliderChrome.trackHeight)
                    .offset(x: lowerX)

                Circle()
                    .fill(Color.white.opacity(0.94))
                    .frame(width: OasisSliderChrome.liveIndicatorSize, height: OasisSliderChrome.liveIndicatorSize)
                    .shadow(color: Color.black.opacity(0.18), radius: 2, y: 1)
                    .offset(x: activeX - (OasisSliderChrome.liveIndicatorSize / 2))
                    .opacity(activeHandle == nil ? 0.82 : 1)
                    .allowsHitTesting(false)

                rangeHandle(isActive: activeHandle == .lower)
                    .frame(width: OasisSliderChrome.handleHitSize, height: OasisSliderChrome.controlHeight)
                    .contentShape(Rectangle())
                    .offset(x: lowerX - (OasisSliderChrome.handleHitSize / 2))
                    .gesture(handleDragGesture(
                        .lower,
                        trackStart: trackStart,
                        trackWidth: trackWidth
                    ))

                rangeHandle(isActive: activeHandle == .upper)
                    .frame(width: OasisSliderChrome.handleHitSize, height: OasisSliderChrome.controlHeight)
                    .contentShape(Rectangle())
                    .offset(x: upperX - (OasisSliderChrome.handleHitSize / 2))
                    .gesture(handleDragGesture(
                        .upper,
                        trackStart: trackStart,
                        trackWidth: trackWidth
                    ))
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            .coordinateSpace(name: "AutoVariationRangeSlider")
        }
        .frame(height: OasisSliderChrome.controlHeight)
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
        OasisSliderHandle(tint: tint, isActive: isActive)
    }

    private func handleDragGesture(
        _ handle: RangeSliderHandle,
        trackStart: CGFloat,
        trackWidth: CGFloat
    ) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("AutoVariationRangeSlider"))
            .updating($activeHandle) { _, state, _ in
                state = handle
            }
            .onChanged { gesture in
                updateRange(handle, with: gesture.location.x, trackStart: trackStart, trackWidth: trackWidth)
            }
            .onEnded { _ in
                if let draftRange {
                    commitRange(draftRange, force: true)
                }
                draftRange = nil
            }
    }

    private func updateRange(_ handle: RangeSliderHandle, with locationX: CGFloat, trackStart: CGFloat, trackWidth: CGFloat) {
        let value = min(max(Double((locationX - trackStart) / trackWidth), 0), 1)
        let currentRange = (draftRange ?? range).clamped()

        let updatedRange: AutoVariationRange
        switch handle {
        case .lower:
            updatedRange = AutoVariationRange(
                lowerBound: min(value, currentRange.upperBound - AutoVariationRange.minimumWidth),
                upperBound: currentRange.upperBound
            ).clamped()
        case .upper:
            updatedRange = AutoVariationRange(
                lowerBound: currentRange.lowerBound,
                upperBound: max(value, currentRange.lowerBound + AutoVariationRange.minimumWidth)
            ).clamped()
        }

        guard draftRange != updatedRange else { return }
        draftRange = updatedRange
        commitRange(updatedRange)
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

    private var displayedRange: AutoVariationRange {
        draftRange ?? range
    }

    private var accessibilityRangeValue: String {
        let normalized = range.clamped()
        let lower = Int((normalized.lowerBound * 100).rounded())
        let upper = Int((normalized.upperBound * 100).rounded())
        return "\(lower)% - \(upper)%"
    }

    private func adjust(_ handle: RangeSliderHandle, by delta: Double) {
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

    private func commitRange(_ newRange: AutoVariationRange, force: Bool = false) {
        let now = Date.timeIntervalSinceReferenceDate
        guard force || now - lastDragCommitTime >= OasisSliderChrome.dragCommitInterval else { return }
        lastDragCommitTime = now

        guard range != newRange else { return }
        range = newRange
    }
}

private enum RangeSliderHandle {
    case lower
    case upper
}

private enum OasisSliderChrome {
    static let controlHeight: CGFloat = 36
    static let trackHeight: CGFloat = 7
    static let rangeHandleWidth: CGFloat = 34
    static let rangeHandleHeight: CGFloat = 28
    static let handleHitSize: CGFloat = 44
    static let liveIndicatorSize: CGFloat = 5
    static let dragCommitInterval: TimeInterval = 1.0 / 24.0
}

private struct OasisSliderHandle: View {
    let tint: Color
    let isActive: Bool

    var body: some View {
        ZStack {
            handleBody
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
        }
        .frame(width: OasisSliderChrome.rangeHandleWidth, height: OasisSliderChrome.rangeHandleHeight)
        .scaleEffect(isActive ? 1.03 : 1)
        .shadow(color: Color.black.opacity(isActive ? 0.24 : 0.18), radius: isActive ? 6 : 4, y: isActive ? 3 : 2)
        .shadow(color: tint.opacity(isActive ? 0.18 : 0), radius: isActive ? 5 : 0)
    }

    @ViewBuilder
    private var handleBody: some View {
#if os(iOS)
        if isActive {
            glassHandle
        } else {
            solidHandle
        }
#else
        solidHandle
#endif
    }

    private var solidHandle: some View {
        RoundedRectangle(cornerRadius: OasisSliderChrome.rangeHandleHeight / 2, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(solidHandleStroke)
    }

    private var solidHandleStroke: some View {
        RoundedRectangle(cornerRadius: OasisSliderChrome.rangeHandleHeight / 2, style: .continuous)
            .strokeBorder(Color.white.opacity(0.64), lineWidth: 1)
    }

    @ViewBuilder
    private var glassHandle: some View {
#if os(iOS)
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: OasisSliderChrome.rangeHandleHeight / 2, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .glassEffect(
                    .regular.interactive(),
                    in: RoundedRectangle(cornerRadius: OasisSliderChrome.rangeHandleHeight / 2, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: OasisSliderChrome.rangeHandleHeight / 2, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.34),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: OasisSliderChrome.rangeHandleHeight / 2, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.56), lineWidth: 1)
                }
        } else {
            solidHandle
        }
#else
        EmptyView()
#endif
    }
}
