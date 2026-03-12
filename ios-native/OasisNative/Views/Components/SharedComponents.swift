import SwiftUI
import UIKit

enum LiquidActivityPalette {
    static let preset = [
        Color(red: 0.48, green: 0.80, blue: 1.00),
        Color(red: 0.96, green: 0.58, blue: 0.92),
        Color(red: 1.00, green: 0.79, blue: 0.56)
    ]

    static func binaural(for tint: Color) -> [Color] {
        [
            tint,
            Color(red: 0.52, green: 0.74, blue: 0.99),
            Color(red: 0.95, green: 0.62, blue: 0.98)
        ]
    }

    static func channel(for tint: Color) -> [Color] {
        [
            tint,
            tint.opacity(0.78),
            Color.white.opacity(0.68)
        ]
    }

    static let playback = [
        Color(red: 0.74, green: 0.96, blue: 0.28),
        Color(red: 0.99, green: 0.82, blue: 0.25),
        Color(red: 0.97, green: 0.60, blue: 0.18)
    ]
}

struct AnimatedBackdrop: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.06, blue: 0.16),
                        Color(red: 0.03, green: 0.10, blue: 0.24),
                        Color(red: 0.02, green: 0.05, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.14, green: 0.42, blue: 0.90).opacity(0.32),
                                Color(red: 0.05, green: 0.19, blue: 0.48).opacity(0.14),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: proxy.size.width * 0.42
                        )
                    )
                    .frame(width: proxy.size.width * 0.78, height: proxy.size.width * 0.78)
                    .blur(radius: 42)
                    .offset(
                        x: animate ? proxy.size.width * 0.18 : proxy.size.width * 0.06,
                        y: animate ? -proxy.size.height * 0.08 : -proxy.size.height * 0.02
                    )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.00, green: 0.64, blue: 0.92).opacity(0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: proxy.size.width * 0.30
                        )
                    )
                    .frame(width: proxy.size.width * 0.58, height: proxy.size.width * 0.58)
                    .blur(radius: 30)
                    .offset(
                        x: animate ? proxy.size.width * 0.28 : proxy.size.width * 0.36,
                        y: animate ? proxy.size.height * 0.38 : proxy.size.height * 0.48
                    )

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.02),
                                Color.black.opacity(0.14),
                                Color.black.opacity(0.28)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct GlassSurface<Content: View>: View {
    let tint: Color
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    @ViewBuilder let content: Content

    init(
        tint: Color = .white.opacity(0.04),
        cornerRadius: CGFloat = 28,
        padding: EdgeInsets = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.14), radius: 16, y: 8)
    }
}

struct CompactGlassPanel<Content: View>: View {
    let maxWidth: CGFloat
    let contentPadding: EdgeInsets
    @ViewBuilder let content: Content

    init(
        maxWidth: CGFloat = 368,
        contentPadding: EdgeInsets = EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18),
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(contentPadding)
        .frame(maxWidth: maxWidth)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.03))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 28, y: 14)
    }
}

struct HomeHeaderView: View {
    let scrollOffset: CGFloat
    let onOpenPresets: () -> Void
    let onOpenBinaural: () -> Void

    private var compactProgress: CGFloat {
        min(max(scrollOffset / 140, 0), 1)
    }

    private var logoVisibility: CGFloat {
        max(0, 1 - (compactProgress * 3.4))
    }

    var body: some View {
        VStack(spacing: max(6, 9 - (compactProgress * 4))) {
            BrandLockupView(visibility: logoVisibility)

            QuickControlsStrip(
                onOpenPresets: onOpenPresets,
                onOpenBinaural: onOpenBinaural
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .animation(.smooth(duration: 0.22), value: compactProgress)
    }
}

private struct BrandLockupView: View {
    @Environment(AppModel.self) private var model
    let visibility: CGFloat

    private static let cachedLogo: UIImage? = {
        guard let url = Bundle.main.url(forResource: "oasisLogo", withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return image
    }()

    private var bundleLogo: UIImage? {
        Self.cachedLogo
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if let logo = bundleLogo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132)
                    .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
            } else {
                Text(model.copy.header.title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("BINAURAL NATURE")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(2.6)
                .foregroundStyle(.white.opacity(0.54))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74 * visibility, alignment: .top)
        .opacity(visibility)
        .scaleEffect(0.92 + (visibility * 0.08), anchor: .top)
        .clipped()
        .animation(.smooth(duration: 0.18), value: visibility)
    }
}

private struct QuickControlsStrip: View {
    @Environment(AppModel.self) private var model
    let onOpenPresets: () -> Void
    let onOpenBinaural: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                presetChip
                binauralChip
                TimerChip()
            }
            .frame(maxWidth: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    presetChip
                    binauralChip
                    TimerChip()
                }
                .padding(.horizontal, 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var presetChip: some View {
        let isPresetActive = model.activePreset != nil

        return Button {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                onOpenPresets()
            }
        } label: {
            PanelTriggerChip(
                symbol: model.activePreset == nil ? "bookmark" : "bookmark.fill",
                title: model.activePreset.map(model.presetDisplayName) ?? model.copy.modal.title,
                tint: isPresetActive ? LiquidActivityPalette.preset[0] : .white,
                isActivated: isPresetActive,
                palette: LiquidActivityPalette.preset
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var binauralChip: some View {
        let isBinauralActive = model.isBinauralActive

        return Button {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                onOpenBinaural()
            }
        } label: {
            PanelTriggerChip(
                symbol: model.isBinauralActive ? "waveform.path.ecg" : "waveform.path",
                title: model.copy.binaural[model.activeBinauralTrack],
                tint: isBinauralActive ? model.activeBinauralTrack.tint : .white.opacity(0.84),
                isActivated: isBinauralActive,
                palette: LiquidActivityPalette.binaural(for: model.activeBinauralTrack.tint)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct TimerChip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.isPremium {
            Menu {
                timerAction("Off", minutes: nil)
                timerAction("15 min", minutes: 15)
                timerAction("30 min", minutes: 30)
                timerAction("1h", minutes: 60)
                timerAction("2h", minutes: 120)
            } label: {
                HeaderChipLabel(
                    symbol: "timer",
                    title: model.timerToolbarTitle,
                    tint: model.timerDurationMinutes == nil
                        ? .white.opacity(0.82)
                        : Color(red: 0.52, green: 0.91, blue: 0.64)
                )
            }
            .menuIndicator(.hidden)
        } else {
            Button {
                withAnimation(.smooth(duration: 0.22)) {
                    model.showsPaywall = true
                }
            } label: {
                HeaderChipLabel(
                    symbol: "timer",
                    title: model.copy.header.timer,
                    tint: .white.opacity(0.82)
                )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    private func timerAction(_ title: String, minutes: Int?) -> some View {
        Button(title) {
            withAnimation(.smooth(duration: 0.22)) {
                model.setTimer(minutes)
            }
        }
    }
}

private struct HeaderChipLabel: View {
    let symbol: String
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    Capsule()
                        .fill(Color.white.opacity(0.02))
                }
        }
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct PanelTriggerChip: View {
    let symbol: String
    let title: String
    let tint: Color
    let isActivated: Bool
    let palette: [Color]

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    ZStack {
                        if isActivated {
                            AnimatedLiquidAura(
                                palette: palette,
                                shape: Capsule(),
                                intensity: 0.64,
                                blurRadius: 4.5,
                                baseBlendOpacity: 0.20,
                                speedMultiplier: 2.25,
                                frameRate: 24,
                                isAnimated: true
                            )
                                .padding(1)
                        }

                        Capsule()
                            .fill(
                                isActivated ? tint.opacity(0.05) : Color.white.opacity(0.02)
                            )
                    }
                }
        }
        .overlay {
            Capsule().strokeBorder(activeBorderStyle, lineWidth: 1.15)
        }
        .shadow(color: isActivated ? tint.opacity(0.08) : .clear, radius: 10, y: 3)
        .animation(.smooth(duration: 0.22), value: isActivated)
    }

    private var activeBorderStyle: AnyShapeStyle {
        if isActivated {
            AnyShapeStyle(LinearGradient(
                colors: palette.map { $0.opacity(0.34) },
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
}

struct MixerBoardSectionView: View {
    @State private var labelColumnWidth: CGFloat = 0

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(SoundChannel.allCases) { channel in
                SoundRowView(
                    channel: channel,
                    labelColumnWidth: labelColumnWidth
                )
            }
        }
        .onPreferenceChange(ChannelLabelWidthKey.self) { width in
            guard width > 0 else { return }
            labelColumnWidth = width
        }
    }
}

struct SoundRowView: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel
    let labelColumnWidth: CGFloat

    private var state: ChannelState {
        model.channelState(for: channel)
    }

    private var isLocked: Bool {
        model.isChannelLocked(channel)
    }

    private var isAutoAnimating: Bool {
        !isLocked && state.autoVariationEnabled
    }

    private var isActive: Bool {
        !isLocked && !state.isMuted
    }

    private var statusText: String? {
        if isLocked {
            return "PREMIUM"
        }
        if state.isMuted {
            return "MUTE"
        }
        if state.autoVariationEnabled {
            return "AUTO"
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if isLocked {
                    withAnimation(.smooth(duration: 0.22)) {
                        model.showsPaywall = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        model.toggleMute(channel)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            ZStack {
                                if isActive {
                                    AnimatedLiquidAura(
                                        palette: LiquidActivityPalette.channel(for: channel.tint),
                                        shape: Circle(),
                                        intensity: 0.42,
                                        blurRadius: 4.5,
                                        baseBlendOpacity: 0.08,
                                        speedMultiplier: 1.22,
                                        isAnimated: false
                                    )
                                    .padding(1)
                                }

                                Circle()
                                    .fill(isActive ? channel.tint.opacity(0.06) : Color.white.opacity(0.012))
                            }
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    isActive
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: LiquidActivityPalette.channel(for: channel.tint).map { $0.opacity(0.28) },
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        : AnyShapeStyle(Color.white.opacity(0.08)),
                                    lineWidth: 1.1
                                )
                        }

                    Image(systemName: channel.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.54 : 1))
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(PressScaleButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(model.channelName(channel))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.60 : 0.98))
                    .lineLimit(1)

                if let statusText {
                    Text(statusText)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(secondaryTint)
                        .lineLimit(1)
                }
            }
            .frame(width: labelColumnWidth == 0 ? nil : labelColumnWidth, alignment: .leading)
            .layoutPriority(1)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: ChannelLabelWidthKey.self, value: proxy.size.width)
                }
            }

            Group {
                if isAutoAnimating {
                    AutoVariationLevelBar(
                        value: model.displayVolume(for: channel),
                        tint: channel.tint
                    )
                } else {
                    HapticSlider(
                        value: Binding(
                            get: { model.displayVolume(for: channel) },
                            set: { model.setChannelVolume(channel, value: $0) }
                        ),
                        tint: channel.tint
                    )
                    .disabled(isLocked || state.isMuted || state.autoVariationEnabled)
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(sliderOpacity)

            Button {
                if isLocked {
                    withAnimation(.smooth(duration: 0.22)) {
                        model.showsPaywall = true
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        model.toggleAutoVariation(channel)
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .semibold))
                    } else {
                        Text("AUTO")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(buttonForeground)
                .padding(.horizontal, isLocked ? 12 : 14)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(state.autoVariationEnabled ? channel.tint.opacity(0.22) : Color.white.opacity(0.04))
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            state.autoVariationEnabled ? channel.tint.opacity(0.36) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(channelTint)
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        }
        .opacity(isLocked ? 0.90 : 1)
        .animation(.easeInOut(duration: 0.16), value: state.isMuted)
        .animation(.easeInOut(duration: 0.16), value: state.autoVariationEnabled)
    }

    private var secondaryTint: Color {
        if isLocked {
            return .white.opacity(0.34)
        }
        return isActive ? channel.tint.opacity(0.90) : .white.opacity(0.34)
    }

    private var sliderOpacity: Double {
        if isLocked {
            return 0.28
        }
        if state.isMuted {
            return 0.24
        }
        if isAutoAnimating {
            return 1
        }
        if state.autoVariationEnabled {
            return 0.80
        }
        return 1
    }

    private var channelTint: Color {
        if isActive {
            return channel.tint.opacity(state.autoVariationEnabled ? 0.10 : 0.07)
        }
        return Color.white.opacity(state.isMuted && !isLocked ? 0.010 : 0.018)
    }

    private var buttonForeground: Color {
        if isLocked {
            return .white.opacity(0.72)
        }
        return state.autoVariationEnabled ? .white : .white.opacity(0.82)
    }
}

private struct ChannelLabelWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct AutoVariationLevelBar: View {
    let value: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let clamped = min(max(value, 0), 1)
            let width = max(proxy.size.width * clamped, 12)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))

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
                    .frame(width: width)
            }
        }
        .frame(height: 12)
        .animation(.easeInOut(duration: 0.65), value: value)
    }
}

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

struct BottomToolbarItemLabel: View {
    let systemImage: String
    let tint: Color
    let isActivated: Bool
    let palette: [Color]

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 48, height: 48)
            .background {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(isActivated ? 0.040 : 0.022))
                        }

                    if isActivated {
                        AnimatedLiquidAura(
                            palette: palette,
                            shape: Circle(),
                            intensity: 0.58,
                            blurRadius: 4.5,
                            baseBlendOpacity: 0.10,
                            speedMultiplier: 1.24,
                            isAnimated: false
                        )
                            .padding(1)
                    }

                    Circle()
                        .fill(isActivated ? tint.opacity(0.06) : Color.clear)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(activeBorderStyle, lineWidth: 1.25)
            }
            .contentShape(Circle())
            .animation(.smooth(duration: 0.22), value: isActivated)
    }

    private var activeBorderStyle: AnyShapeStyle {
        if isActivated {
            AnyShapeStyle(LinearGradient(
                colors: palette.map { $0.opacity(0.36) },
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        } else {
            AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
}

struct PlaybackToolbarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .symbolEffect(.bounce, value: model.isPlaying)
            .frame(width: 58, height: 58)
            .background {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(model.isPlaying ? 0.04 : 0.022))
                        }

                    if model.isPlaying {
                        AnimatedLiquidAura(
                            palette: LiquidActivityPalette.playback,
                            shape: Circle(),
                            intensity: 0.70,
                            blurRadius: 5,
                            baseBlendOpacity: 0.14,
                            speedMultiplier: 2.1,
                            frameRate: 24,
                            isAnimated: true
                        )
                        .padding(1)
                    }

                    Circle()
                        .fill(model.isPlaying ? Color.white.opacity(0.08) : Color.clear)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(playbackBorderStyle, lineWidth: 1.3)
            }
            .animation(.smooth(duration: 0.22), value: model.isPlaying)
    }

    private var playbackBorderStyle: AnyShapeStyle {
        if model.isPlaying {
            AnyShapeStyle(
                LinearGradient(
                    colors: LiquidActivityPalette.playback.map { $0.opacity(0.42) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
}

struct BottomBarView: View {
    @Environment(AppModel.self) private var model
    let onOpenPresets: () -> Void
    let onOpenBinaural: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.24)) {
                    model.randomizeMix()
                }
            } label: {
                BottomToolbarItemLabel(
                    systemImage: "shuffle",
                    tint: .white,
                    isActivated: false,
                    palette: []
                )
            }
            .buttonStyle(PressScaleButtonStyle())

            Button {
                withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                    onOpenPresets()
                }
            } label: {
                BottomToolbarItemLabel(
                    systemImage: model.currentPresetID == nil ? "bookmark" : "bookmark.fill",
                    tint: LiquidActivityPalette.preset[0],
                    isActivated: model.activePreset != nil,
                    palette: LiquidActivityPalette.preset
                )
            }
            .buttonStyle(PressScaleButtonStyle())

            Button {
                model.togglePlayback()
            } label: {
                PlaybackToolbarLabel()
            }
            .buttonStyle(PressScaleButtonStyle())

            Button {
                withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                    onOpenBinaural()
                }
            } label: {
                BottomToolbarItemLabel(
                    systemImage: "waveform.path",
                    tint: model.activeBinauralTrack.tint,
                    isActivated: model.isBinauralActive,
                    palette: LiquidActivityPalette.binaural(for: model.activeBinauralTrack.tint)
                )
            }
            .buttonStyle(PressScaleButtonStyle())

            RoutePickerView()
                .frame(width: 22, height: 22)
                .foregroundStyle(.white)
                .padding(13)
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(0.022))
                        }
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1.25)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 412)
        .frame(maxWidth: .infinity)
    }
}

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

private struct AnimatedLiquidAura<ShapeType: Shape>: View {
    let palette: [Color]
    let shape: ShapeType
    let intensity: Double
    let blurRadius: CGFloat
    let baseBlendOpacity: Double
    let speedMultiplier: Double
    let frameRate: Double
    let isAnimated: Bool

    @State private var mesh = OrganicMeshSeed.make()
    @State private var animationStart = Date()
    init(
        palette: [Color],
        shape: ShapeType,
        intensity: Double,
        blurRadius: CGFloat = 5,
        baseBlendOpacity: Double = 0,
        speedMultiplier: Double = 1,
        frameRate: Double = 24,
        isAnimated: Bool = false
    ) {
        self.palette = palette
        self.shape = shape
        self.intensity = intensity
        self.blurRadius = blurRadius
        self.baseBlendOpacity = baseBlendOpacity
        self.speedMultiplier = speedMultiplier
        self.frameRate = frameRate
        self.isAnimated = isAnimated
    }

    var body: some View {
        Group {
            if isAnimated {
                ZStack {
                    auraBody(time: 0)

                    TimelineView(.animation(minimumInterval: 1.0 / frameRate, paused: false)) { context in
                        smokeBody(time: context.date.timeIntervalSince(animationStart))
                    }
                }
            } else {
                auraBody(time: 0)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func auraBody(time: Double) -> some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: mesh.points(at: time, speedMultiplier: speedMultiplier),
            colors: mesh.colors(using: palette, smokeOpacity: baseBlendOpacity),
            background: .clear,
            smoothsColors: true
        )
        .compositingGroup()
        .blur(radius: blurRadius)
        .saturation(1.12)
        .opacity(intensity)
        .mask(shape.fill(style: FillStyle(eoFill: false, antialiased: true)))
    }

    private func smokeBody(time: Double) -> some View {
        shape
            .fill(.white)
            .visualEffect { content, proxy in
                content.colorEffect(
                    ShaderLibrary.liquidSmoke(
                        .float2(proxy.size),
                        .float(Float(time * speedMultiplier)),
                        .color(palette[safe: 0] ?? .white),
                        .color(palette[safe: 1] ?? palette[safe: 0] ?? .white),
                        .color(palette[safe: 2] ?? palette[safe: 1] ?? palette[safe: 0] ?? .white),
                        .float(Float(intensity))
                    )
                )
            }
            .opacity(0.94)
    }
}

private struct OrganicMeshSeed {
    struct Motion {
        let amplitudeX: Float
        let amplitudeY: Float
        let speedX: Double
        let speedY: Double
        let phaseX: Double
        let phaseY: Double
    }

    let top: Motion
    let leading: Motion
    let center: Motion
    let trailing: Motion
    let bottom: Motion

    static func make() -> OrganicMeshSeed {
        OrganicMeshSeed(
            top: .random(amplitudeX: 0.10, amplitudeY: 0.06, speed: 1.55...2.10),
            leading: .random(amplitudeX: 0.06, amplitudeY: 0.12, speed: 1.38...1.92),
            center: .random(amplitudeX: 0.16, amplitudeY: 0.16, speed: 1.72...2.36),
            trailing: .random(amplitudeX: 0.06, amplitudeY: 0.12, speed: 1.34...1.88),
            bottom: .random(amplitudeX: 0.10, amplitudeY: 0.06, speed: 1.48...2.02)
        )
    }

    func points(at time: Double, speedMultiplier: Double) -> [SIMD2<Float>] {
        [
            SIMD2(0.0, 0.0),
            offsetPoint(baseX: 0.5, baseY: 0.0, motion: top, time: time, speedMultiplier: speedMultiplier),
            SIMD2(1.0, 0.0),
            offsetPoint(baseX: 0.0, baseY: 0.5, motion: leading, time: time, speedMultiplier: speedMultiplier),
            offsetPoint(baseX: 0.5, baseY: 0.5, motion: center, time: time, speedMultiplier: speedMultiplier),
            offsetPoint(baseX: 1.0, baseY: 0.5, motion: trailing, time: time, speedMultiplier: speedMultiplier),
            SIMD2(0.0, 1.0),
            offsetPoint(baseX: 0.5, baseY: 1.0, motion: bottom, time: time, speedMultiplier: speedMultiplier),
            SIMD2(1.0, 1.0)
        ]
    }

    func colors(using palette: [Color], smokeOpacity: Double) -> [Color] {
        let a = palette[safe: 0] ?? .white
        let b = palette[safe: 1] ?? a
        let c = palette[safe: 2] ?? b
        let smoke = Color.black.opacity(max(0.08, smokeOpacity * 0.9))
        let haze = Color.black.opacity(max(0.04, smokeOpacity * 0.55))

        return [
            a.opacity(0.74), smoke, c.opacity(0.72),
            b.opacity(0.62), .white.opacity(0.16), haze,
            c.opacity(0.68), a.opacity(0.64), b.opacity(0.70)
        ]
    }

    private func offsetPoint(baseX: Float, baseY: Float, motion: Motion, time: Double, speedMultiplier: Double) -> SIMD2<Float> {
        let x = baseX + (motion.amplitudeX * Float(organicWave(time: time, speed: motion.speedX * speedMultiplier, phase: motion.phaseX)))
        let y = baseY + (motion.amplitudeY * Float(organicWave(time: time, speed: motion.speedY * speedMultiplier, phase: motion.phaseY)))
        return SIMD2(clamp(x, min: 0, max: 1), clamp(y, min: 0, max: 1))
    }
}


private extension OrganicMeshSeed.Motion {
    static func random(amplitudeX: Float, amplitudeY: Float, speed: ClosedRange<Double>) -> Self {
        Self(
            amplitudeX: amplitudeX,
            amplitudeY: amplitudeY,
            speedX: Double.random(in: speed),
            speedY: Double.random(in: speed),
            phaseX: Double.random(in: 0...(Double.pi * 2)),
            phaseY: Double.random(in: 0...(Double.pi * 2))
        )
    }
}

private func organicWave(time: Double, speed: Double, phase: Double) -> Double {
    let primary = sin(time * speed + phase)
    let secondary = cos(time * (speed * 0.63) + (phase * 1.37))
    return (primary * 0.7) + (secondary * 0.3)
}

private func clamp<T: Comparable>(_ value: T, min lowerBound: T, max upperBound: T) -> T {
    Swift.min(Swift.max(value, lowerBound), upperBound)
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
