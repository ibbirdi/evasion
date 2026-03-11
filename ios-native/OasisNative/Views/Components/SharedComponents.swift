import SwiftUI
import UIKit

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
    @EnvironmentObject private var model: AppModel
    let scrollOffset: CGFloat
    let onOpenPresets: () -> Void
    let onOpenBinaural: () -> Void
    let presetSourceID: String
    let binauralSourceID: String
    let activeSourceID: String?
    let panelTransition: Namespace.ID

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
                onOpenBinaural: onOpenBinaural,
                presetSourceID: presetSourceID,
                binauralSourceID: binauralSourceID,
                activeSourceID: activeSourceID,
                panelTransition: panelTransition
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .animation(.smooth(duration: 0.22), value: compactProgress)
    }
}

private struct BrandLockupView: View {
    @EnvironmentObject private var model: AppModel
    let visibility: CGFloat

    private var bundleLogo: UIImage? {
        guard let url = Bundle.main.url(forResource: "oasisLogo", withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return image
    }

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
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
    @EnvironmentObject private var model: AppModel
    let onOpenPresets: () -> Void
    let onOpenBinaural: () -> Void
    let presetSourceID: String
    let binauralSourceID: String
    let activeSourceID: String?
    let panelTransition: Namespace.ID

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
        Button {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                onOpenPresets()
            }
        } label: {
            PanelTriggerChip(
                symbol: model.activePreset == nil ? "bookmark" : "bookmark.fill",
                title: model.activePreset.map(model.presetDisplayName) ?? model.copy.modal.title,
                tint: .white,
                sourceID: presetSourceID,
                activeSourceID: activeSourceID,
                panelTransition: panelTransition
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var binauralChip: some View {
        Button {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                onOpenBinaural()
            }
        } label: {
            PanelTriggerChip(
                symbol: model.isBinauralActive ? "waveform.path.ecg" : "waveform.path",
                title: model.copy.binaural[model.activeBinauralTrack],
                tint: model.isBinauralActive ? model.activeBinauralTrack.tint : .white.opacity(0.84),
                sourceID: binauralSourceID,
                activeSourceID: activeSourceID,
                panelTransition: panelTransition
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct TimerChip: View {
    @EnvironmentObject private var model: AppModel

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
    let sourceID: String
    let activeSourceID: String?
    let panelTransition: Namespace.ID

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
                .matchedGeometryEffect(
                    id: "panel-\(sourceID)",
                    in: panelTransition,
                    properties: .frame,
                    anchor: .center,
                    isSource: true
                )
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    Capsule()
                        .fill((activeSourceID == sourceID ? tint.opacity(0.10) : Color.white.opacity(0.02)))
                }
        }
        .overlay {
            Capsule()
                .strokeBorder((activeSourceID == sourceID ? tint.opacity(0.24) : Color.white.opacity(0.08)), lineWidth: 1)
        }
    }
}

struct MixerBoardSectionView: View {
    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(SoundChannel.allCases) { channel in
                SoundRowView(channel: channel)
            }
        }
    }
}

struct SoundRowView: View {
    @EnvironmentObject private var model: AppModel
    let channel: SoundChannel

    private var state: ChannelState {
        model.channelState(for: channel)
    }

    private var isLocked: Bool {
        model.isChannelLocked(channel)
    }

    private var isAutoAnimating: Bool {
        !isLocked && !state.isMuted && state.autoVariationEnabled && model.isPlaying
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
                        .fill(.thinMaterial)

                    Image(systemName: channel.systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.54 : 0.96))
                        .symbolRenderingMode(.hierarchical)
                }
                .frame(width: 38, height: 38)
            }
            .buttonStyle(PressScaleButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text(model.channelName(channel))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(state.isMuted && !isLocked ? 0.60 : 0.98))
                    .lineLimit(1)

                if let statusText {
                    Text(statusText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(secondaryTint)
                        .lineLimit(1)
                }
            }
            .frame(width: 94, alignment: .leading)

            Group {
                if isAutoAnimating {
                    AutoVariationLevelBar(
                        value: model.displayVolume(for: channel),
                        tint: channel.tint
                    )
                } else {
                    Slider(
                        value: Binding(
                            get: { model.displayVolume(for: channel) },
                            set: { model.setChannelVolume(channel, value: $0) }
                        ),
                        in: 0...1
                    )
                    .tint(channel.tint)
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
                HStack(spacing: 4) {
                    Image(systemName: isLocked ? "lock.fill" : (state.autoVariationEnabled ? "sparkles" : "dial.low"))
                        .font(.system(size: 10, weight: .semibold))

                    if !isLocked {
                        Text("AUTO")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                }
                .foregroundStyle(buttonForeground)
                .frame(width: isLocked ? 40 : 68, height: 36)
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
        isLocked ? .white.opacity(0.34) : channel.tint.opacity(0.90)
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
        state.autoVariationEnabled
            ? channel.tint.opacity(0.10)
            : Color.white.opacity(state.isMuted && !isLocked ? 0.015 : 0.03)
    }

    private var buttonForeground: Color {
        if isLocked {
            return .white.opacity(0.72)
        }
        return state.autoVariationEnabled ? .white : .white.opacity(0.82)
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

struct BottomBarView: View {
    @EnvironmentObject private var model: AppModel
    let onOpenPresets: () -> Void
    let onOpenBinaural: () -> Void
    let presetSourceID: String
    let binauralSourceID: String
    let activeSourceID: String?
    let panelTransition: Namespace.ID

    var body: some View {
        HStack(spacing: 10) {
            toolbarButton(
                systemImage: "shuffle",
                tint: .white,
                action: {
                    withAnimation(.smooth(duration: 0.24)) {
                        model.randomizeMix()
                    }
                }
            )

            Button {
                withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                    onOpenPresets()
                }
            } label: {
                PanelSourceIcon(
                    systemImage: model.currentPresetID == nil ? "bookmark" : "bookmark.fill",
                    tint: .white,
                    sourceID: presetSourceID,
                    panelTransition: panelTransition,
                    activeSourceID: activeSourceID
                )
            }
            .buttonStyle(PressScaleButtonStyle())

            playPauseButton()

            Button {
                withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                    onOpenBinaural()
                }
            } label: {
                PanelSourceIcon(
                    systemImage: "waveform.path",
                    tint: model.isBinauralActive ? model.activeBinauralTrack.tint : .white,
                    sourceID: binauralSourceID,
                    panelTransition: panelTransition,
                    activeSourceID: activeSourceID
                )
            }
            .buttonStyle(PressScaleButtonStyle())

            routePickerButton()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    Capsule()
                        .fill(Color.white.opacity(0.025))
                }
        }
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 20, y: 10)
    }

    private func toolbarButton(
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 42, height: 42)
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func playPauseButton() -> some View {
        Button {
            withAnimation(.smooth(duration: 0.24)) {
                model.togglePlayback()
            }
        } label: {
            Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, value: model.isPlaying)
                .frame(width: 50, height: 50)
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(
                                    model.isPlaying
                                        ? Color.white.opacity(0.10)
                                        : Color.white.opacity(0.04)
                                )
                        }
                }
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(model.isPlaying ? 0.18 : 0.08), lineWidth: 1)
                }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private func routePickerButton() -> some View {
        RoutePickerView()
            .frame(width: 18, height: 18)
            .foregroundStyle(.white)
            .padding(12)
    }
}

private struct PanelSourceIcon: View {
    let systemImage: String
    let tint: Color
    let sourceID: String
    let panelTransition: Namespace.ID
    let activeSourceID: String?

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(tint)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 42, height: 42)
            .background {
                Circle()
                    .fill(Color.white.opacity(0.001))
                    .matchedGeometryEffect(
                        id: "panel-\(sourceID)",
                        in: panelTransition,
                        properties: .frame,
                        anchor: .center,
                        isSource: true
                    )
                    .glassEffect(.regular, in: Circle())
                    .overlay {
                        Circle()
                            .fill(activeSourceID == sourceID ? tint.opacity(0.10) : Color.clear)
                    }
            }
    }
}

struct ContextPanelOverlay<Content: View>: View {
    let edge: Edge
    let topInset: CGFloat
    let bottomInset: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            if edge == .top {
                content
                    .padding(.top, topInset)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                content
                    .padding(.bottom, bottomInset)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
        .transition(
            .scale(scale: 0.92, anchor: edge == .top ? .top : .bottom)
                .combined(with: .opacity)
        )
    }
}

struct MorphingGlassPanel<Content: View>: View {
    let sourceID: String
    let panelTransition: Namespace.ID
    let maxWidth: CGFloat
    let contentPadding: EdgeInsets
    let reducesEffects: Bool
    @ViewBuilder let content: Content

    init(
        sourceID: String,
        panelTransition: Namespace.ID,
        maxWidth: CGFloat = 360,
        contentPadding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14),
        reducesEffects: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.sourceID = sourceID
        self.panelTransition = panelTransition
        self.maxWidth = maxWidth
        self.contentPadding = contentPadding
        self.reducesEffects = reducesEffects
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .padding(contentPadding)
        .frame(maxWidth: maxWidth)
        .background {
            if reducesEffects {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white.opacity(0.04))
                    }
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .matchedGeometryEffect(
                        id: "panel-\(sourceID)",
                        in: panelTransition,
                        properties: .frame,
                        anchor: .center,
                        isSource: false
                    )
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(reducesEffects ? 0.16 : 0.24), radius: reducesEffects ? 18 : 28, y: reducesEffects ? 8 : 14)
    }
}

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}
