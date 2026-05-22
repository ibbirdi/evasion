import SwiftUI

struct MacMixerSection: View {
    @Environment(AppModel.self) private var model
    @State private var searchText = ""

    let onOpenDetail: (SoundChannel) -> Void

    private var visibleChannels: [SoundChannel] {
        SoundChannel.allCases.filter { channel in
            let matchesFilter = !model.showsOnlyActiveChannels || model.isAmbientChannelActive(channel)
            let matchesSearch = searchText.isEmpty
                || model.channelName(channel).localizedCaseInsensitiveContains(searchText)
                || channel.location.fullLabel.localizedCaseInsensitiveContains(searchText)
            return matchesFilter && matchesSearch
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            filterControls

            MacThinScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if visibleChannels.isEmpty {
                        MacPanelSurface {
                            Text(L10n.Mac.emptySearch)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.62))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 22)
                        }
                    } else {
                        ForEach(visibleChannels) { channel in
                            MacChannelRow(channel: channel) {
                                onOpenDetail(channel)
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var filterControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                searchField
                    .layoutPriority(1)

                activeFilterPicker
                    .frame(width: 236)
            }

            VStack(spacing: 8) {
                searchField
                activeFilterPicker
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.48))
                .accessibilityHidden(true)

            TextField(L10n.string(L10n.Mac.searchSounds), text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 11)
        .frame(height: 34)
        .frame(maxWidth: .infinity)
        .macLiquidGlass(in: RoundedRectangle(cornerRadius: 9, style: .continuous), interactive: true)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private var activeFilterPicker: some View {
        Picker("", selection: Binding(
            get: { model.showsOnlyActiveChannels },
            set: { model.showsOnlyActiveChannels = $0 }
        )) {
            Text(L10n.Mac.allSounds).tag(false)
            Text(L10n.Mac.activeOnly).tag(true)
        }
        .pickerStyle(.segmented)
        .controlSize(.regular)
    }
}

private struct MacChannelRow: View {
    @Environment(AppModel.self) private var model
    @State private var showsSpatialPopover = false

    let channel: SoundChannel
    let onOpenDetail: () -> Void

    private var state: ChannelState {
        model.channelState(for: channel)
    }

    private var isLocked: Bool {
        model.isChannelLocked(channel)
    }

    private var isActive: Bool {
        !isLocked && !state.isMuted
    }

    private var isSpatialized: Bool {
        !state.spatialPosition.isCentered
    }

    private var isAutoAnimating: Bool {
        !isLocked && state.autoVariationEnabled
    }

    private var displayVolumeBinding: Binding<Double> {
        Binding(
            get: { model.displayVolume(for: channel) },
            set: { model.setChannelVolume(channel, value: $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            identityRow
            controlsRow
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background {
            rowShape
                .fill(Color.white.opacity(0.001))
                .macLiquidGlass(in: rowShape)
                .overlay {
                    SoundBackdropImage(backdrop: channel.backdrop, opacity: backdropOpacity)
                        .clipShape(rowShape)
                }
                .overlay {
                    rowShape
                        .fill(channelBackgroundGradient)
                }
        }
        .overlay {
            rowShape
                .strokeBorder(Color.white.opacity(isActive ? 0.08 : 0.045), lineWidth: 0.8)
        }
        .opacity(isLocked ? 0.82 : (isActive ? 1 : 0.84))
        .animation(.easeInOut(duration: 0.18), value: state.isMuted)
        .animation(.easeInOut(duration: 0.18), value: state.autoVariationEnabled)
        .animation(.easeInOut(duration: 0.18), value: state.spatialPosition)
    }

    private var identityRow: some View {
        HStack(spacing: 6) {
            Text(channel.shortNameResource)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(identityForeground)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            if !channel.location.fullLabel.isEmpty {
                Text(verbatim: "·")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.30))

                Text(verbatim: channel.location.fullLabel)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(locationForeground)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer(minLength: 0)
            }

            Button(action: onOpenDetail) {
                Image(systemName: "info.circle")
                    .font(.system(size: 10, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(isLocked ? 0.30 : 0.42))
                    .frame(width: 18, height: 18)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help(L10n.string(L10n.Mixer.soundDetailsHint))
            .accessibilityLabel(Text(channel.shortNameResource))
            .accessibilityHint(Text(L10n.Mixer.soundDetailsHint))

            if isLocked {
                MacStatusBadge(text: L10n.Mixer.statusPremium, tint: Color(red: 0.96, green: 0.83, blue: 0.45))
            }
        }
    }

    private var controlsRow: some View {
        HStack(spacing: 10) {
            muteButton

            Group {
                if isAutoAnimating {
                    AutoVariationRangeSlider(
                        range: Binding(
                            get: { state.autoVariationRange },
                            set: { model.setChannelAutoVariationRange(channel, range: $0) }
                        ),
                        liveValue: model.displayVolume(for: channel),
                        tint: channel.tint
                    )
                    .disabled(state.isMuted)
                    .accessibilityLabel(Text(L10n.Mixer.autoRange))
                    .accessibilityHint(Text(L10n.Mixer.autoRangeHint))
                } else {
                    Slider(value: displayVolumeBinding, in: 0...1)
                        .tint(isLocked ? .white.opacity(0.22) : channel.tint)
                        .disabled(isLocked || state.isMuted || state.autoVariationEnabled)
                        .accessibilityLabel(Text(L10n.Mixer.volume))
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(sliderOpacity)

            spatialButton
            autoButton
        }
    }

    private var muteButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .sound(channel))
            } else {
                model.toggleMute(channel)
            }
        } label: {
            roundIcon(systemName: state.isMuted && !isLocked ? channel.systemImage : "speaker.wave.2.fill", isSelected: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(channel.shortNameResource))
        .accessibilityValue(Text(isLocked ? L10n.Mixer.locked : (state.isMuted ? L10n.Mixer.soundOff : L10n.Mixer.soundOn)))
    }

    private var spatialButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .spatial(channel))
            } else {
                showsSpatialPopover.toggle()
            }
        } label: {
            roundIcon(systemName: "scope", isSelected: isSpatialized)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showsSpatialPopover, arrowEdge: .trailing) {
            MacChannelSpatialPopover(channel: channel)
                .environment(model)
                .frame(width: 360)
        }
        .accessibilityLabel(Text(L10n.Mixer.soundPlacement))
        .accessibilityValue(Text(spatialAccessibilityValue))
        .accessibilityHint(Text(L10n.Mixer.soundPlacementHint))
    }

    private var autoButton: some View {
        Button {
            if isLocked {
                model.requestPremiumAccess(from: .sound(channel))
            } else {
                model.toggleAutoVariation(channel)
            }
        } label: {
            HStack(spacing: 0) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .accessibilityHidden(true)
                } else {
                    Text(L10n.Mixer.statusAuto)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(state.autoVariationEnabled ? .white : .white.opacity(0.82))
            .padding(.horizontal, isLocked ? 12 : 14)
            .frame(height: 34)
            .macLiquidGlass(in: Capsule(), interactive: true)
            .background(state.autoVariationEnabled ? channel.tint.opacity(0.22) : Color.white.opacity(0.035), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        state.autoVariationEnabled ? channel.tint.opacity(0.34) : Color.white.opacity(0.055),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.Mixer.autoVariation))
        .accessibilityValue(Text(state.autoVariationEnabled ? L10n.Mixer.enabled : L10n.Mixer.disabled))
    }

    private func roundIcon(systemName: String, isSelected: Bool) -> some View {
        Circle()
            .fill(Color.white.opacity(0.001))
            .macLiquidGlass(in: Circle(), interactive: true)
            .overlay {
                Circle()
                    .fill(isSelected ? channel.tint.opacity(0.22) : Color.white.opacity(0.018))
            }
            .overlay {
                Circle()
                    .strokeBorder(
                        isSelected ? channel.tint.opacity(0.36) : Color.white.opacity(0.075),
                        lineWidth: 1.1
                    )
            }
            .overlay {
                Image(systemName: systemName)
                    .font(.system(size: 14, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white.opacity(isLocked ? 0.54 : 0.95))
                    .accessibilityHidden(true)
            }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
    }

    private var rowShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 13, style: .continuous)
    }

    private var channelBackgroundGradient: LinearGradient {
        if isActive {
            let leadingOpacity = state.autoVariationEnabled ? 0.18 : 0.15
            return LinearGradient(
                colors: [
                    channel.tint.opacity(leadingOpacity),
                    channel.tint.opacity(leadingOpacity * 0.58),
                    Color.white.opacity(0.024)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [
                Color.white.opacity(state.isMuted && !isLocked ? 0.032 : 0.040),
                Color.white.opacity(0.014)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var identityForeground: Color {
        if isLocked { return .white.opacity(0.65) }
        return isActive ? .white.opacity(0.98) : .white.opacity(0.80)
    }

    private var locationForeground: Color {
        if isLocked { return .white.opacity(0.34) }
        return .white.opacity(0.52)
    }

    private var sliderOpacity: Double {
        if isLocked { return 0.30 }
        if state.isMuted { return 0.24 }
        if state.autoVariationEnabled { return 0.88 }
        return 1
    }

    private var backdropOpacity: Double {
        if isLocked { return 0.05 }
        if isActive { return state.autoVariationEnabled ? 0.18 : 0.15 }
        return 0.08
    }

    private var spatialAccessibilityValue: LocalizedStringResource {
        state.spatialPosition.isCentered ? L10n.Spatial.positionCentered : L10n.Mixer.enabled
    }
}

private struct MacThinScrollView<Content: View>: View {
    @State private var viewportHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var contentOffset: CGFloat = 0

    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            content
        }
        .onScrollGeometryChange(for: MacScrollMetrics.self) { geometry in
            MacScrollMetrics(
                contentHeight: geometry.contentSize.height,
                viewportHeight: geometry.containerSize.height,
                contentOffset: max(0, geometry.contentOffset.y + geometry.contentInsets.top)
            )
        } action: { _, metrics in
            contentHeight = metrics.contentHeight
            viewportHeight = metrics.viewportHeight
            contentOffset = min(metrics.contentOffset, max(metrics.contentHeight - metrics.viewportHeight, 0))
        }
        .compositingGroup()
        .mask(scrollEdgeMask)
        .overlay(alignment: .trailing) {
            thinScrollbar
        }
    }

    private var scrollEdgeMask: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(1 - topFadeOpacity), location: 0),
                    .init(color: .black.opacity(1 - topFadeOpacity * 0.62), location: 0.42),
                    .init(color: .black, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: edgeFadeHeight)

            Color.black

            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black.opacity(1 - bottomFadeOpacity * 0.62), location: 0.58),
                    .init(color: .black.opacity(1 - bottomFadeOpacity), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: edgeFadeHeight)
        }
    }

    private var thinScrollbar: some View {
        let canScroll = contentHeight > viewportHeight + 1
        let thumbHeight = max(34, viewportHeight * min(max(viewportHeight / max(contentHeight, 1), 0), 1))
        let maxOffset = max(contentHeight - viewportHeight, 1)
        let travel = max(viewportHeight - thumbHeight, 0)
        let yOffset = min(max((contentOffset / maxOffset) * travel, 0), travel)

        return Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 3, height: thumbHeight)
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            .offset(y: yOffset)
            .frame(width: 8, height: viewportHeight, alignment: .top)
            .padding(.trailing, 2)
            .opacity(canScroll ? 1 : 0)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.16), value: canScroll)
    }

    private var edgeFadeHeight: CGFloat {
        96
    }

    private var topFadeOpacity: Double {
        guard contentHeight > viewportHeight + 1 else { return 0 }
        return min(max(Double(contentOffset / edgeFadeHeight), 0), 1)
    }

    private var bottomFadeOpacity: Double {
        guard contentHeight > viewportHeight + 1 else { return 0 }
        let maxOffset = max(contentHeight - viewportHeight, 0)
        let remaining = max(maxOffset - contentOffset, 0)
        return min(max(Double(remaining / edgeFadeHeight), 0), 1)
    }
}

private struct MacScrollMetrics: Equatable, Sendable {
    var contentHeight: CGFloat = 0
    var viewportHeight: CGFloat = 0
    var contentOffset: CGFloat = 0
}

private struct MacChannelSpatialPopover: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel

    private var state: ChannelState {
        model.channelState(for: channel)
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(channel.shortNameResource)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.Spatial.subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }

            MacChannelSpatialPad(
                channel: channel,
                point: state.spatialPosition,
                onChange: { point in
                    model.setChannelSpatialPosition(channel, value: point)
                }
            )
            .frame(height: 230)

            HStack(spacing: 7) {
                MacPlacementChip(channel: channel, title: L10n.Spatial.left, systemImage: "arrow.left", point: SpatialPoint(x: -1, y: 0))
                MacPlacementChip(channel: channel, title: L10n.Spatial.front, systemImage: "arrow.up", point: SpatialPoint(x: 0, y: -1))
                MacPlacementChip(channel: channel, title: L10n.Spatial.center, systemImage: "scope", point: .center)
                MacPlacementChip(channel: channel, title: L10n.Spatial.back, systemImage: "arrow.down", point: SpatialPoint(x: 0, y: 1))
                MacPlacementChip(channel: channel, title: L10n.Spatial.right, systemImage: "arrow.right", point: SpatialPoint(x: 1, y: 0))
            }
        }
        .padding(16)
        .background(Color(red: 0.035, green: 0.040, blue: 0.052))
    }
}

private struct MacPlacementChip: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel
    let title: LocalizedStringResource
    let systemImage: String
    let point: SpatialPoint

    private var isSelected: Bool {
        let current = model.channelState(for: channel).spatialPosition.clamped()
        let target = point.clamped()
        return abs(current.x - target.x) < 0.02 && abs(current.y - target.y) < 0.02
    }

    var body: some View {
        Button {
            model.setChannelSpatialPosition(channel, value: point)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(isSelected ? channel.tint : .white.opacity(0.76))
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .macLiquidGlass(in: RoundedRectangle(cornerRadius: 10, style: .continuous), interactive: true)
            .background(isSelected ? channel.tint.opacity(0.16) : Color.white.opacity(0.030), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }
}

private struct MacChannelSpatialPad: View {
    let channel: SoundChannel
    let point: SpatialPoint
    let onChange: (SpatialPoint) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = CGSize(width: proxy.size.width, height: proxy.size.height)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .macLiquidGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(channel.tint.opacity(0.055))
                    }

                MacInlineSpatialGrid()
                    .stroke(Color.white.opacity(0.11), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))
                    .padding(18)

                Circle()
                    .stroke(channel.tint.opacity(0.25), lineWidth: 1)
                    .frame(width: min(size.width, size.height) * 0.54)

                Circle()
                    .fill(.white.opacity(0.84))
                    .frame(width: 8, height: 8)

                Circle()
                    .fill(channel.tint)
                    .frame(width: 18, height: 18)
                    .shadow(color: channel.tint.opacity(0.45), radius: 10, y: 4)
                    .position(position(in: size))

                directionalLabel(L10n.string(L10n.Spatial.front))
                    .position(x: size.width / 2, y: 14)
                directionalLabel(L10n.string(L10n.Spatial.back))
                    .position(x: size.width / 2, y: size.height - 14)
                directionalLabel(L10n.string(L10n.Spatial.left))
                    .position(x: 26, y: size.height / 2)
                directionalLabel(L10n.string(L10n.Spatial.right))
                    .position(x: size.width - 26, y: size.height / 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        onChange(spatialPoint(for: value.location, in: size))
                    }
            )
        }
        .accessibilityLabel(Text(L10n.Spatial.stageAccessibility))
        .accessibilityValue(Text(spatialValue))
    }

    private func directionalLabel(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.38))
    }

    private var spatialValue: String {
        if point.isCentered {
            return L10n.string(L10n.Spatial.positionCentered)
        }
        return "x \(String(format: "%.2f", point.x)), y \(String(format: "%.2f", point.y))"
    }

    private func position(in size: CGSize) -> CGPoint {
        let clamped = point.clamped()
        return CGPoint(
            x: ((clamped.x + 1) / 2) * size.width,
            y: ((clamped.y + 1) / 2) * size.height
        )
    }

    private func spatialPoint(for location: CGPoint, in size: CGSize) -> SpatialPoint {
        guard size.width > 0, size.height > 0 else { return .center }
        return SpatialPoint(
            x: ((location.x / size.width) * 2) - 1,
            y: ((location.y / size.height) * 2) - 1
        ).clamped()
    }
}

private struct MacInlineSpatialGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
