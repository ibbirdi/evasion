import SwiftUI

struct SpatialAudioPanel: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel

    private var state: ChannelState {
        model.channelState(for: channel)
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                OasisGlyphImage(glyph: .target)
                    .foregroundStyle(channel.tint.opacity(0.92))
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)

                Text(model.channelName(channel))
                    .oasisFont(size: 24, weight: .semibold, relativeTo: .title2)
                    .foregroundStyle(.white)

                Text(L10n.Spatial.subtitle)
                    .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)

            SpatialPlacementStage(channel: channel)
                .frame(height: 252)

            spatialPresetControls
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.spatial.container")
    }

    private var spatialPresetControls: some View {
        HStack(spacing: 7) {
            ForEach(SpatialPreset.allCases) { preset in
                Button {
                    withAnimation(.smooth(duration: 0.22)) {
                        model.setChannelSpatialPosition(channel, value: preset.point)
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: preset.systemImage)
                            .oasisFont(size: 13, weight: .semibold, design: .default, relativeTo: .caption)
                            .accessibilityHidden(true)

                        Text(preset.title)
                            .oasisFont(size: 10, weight: .semibold, relativeTo: .caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundStyle(isPresetSelected(preset) ? channel.tint : .white.opacity(0.72))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background {
                        Capsule()
                            .fill(isPresetSelected(preset) ? channel.tint.opacity(0.17) : Color.white.opacity(0.045))
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                isPresetSelected(preset) ? channel.tint.opacity(0.36) : Color.white.opacity(0.07),
                                lineWidth: 1
                            )
                    }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(Text(preset.title))
                .accessibilityAddTraits(isPresetSelected(preset) ? .isSelected : [])
            }
        }
    }

    private func isPresetSelected(_ preset: SpatialPreset) -> Bool {
        let current = state.spatialPosition.clamped()
        let target = preset.point.clamped()
        return abs(current.x - target.x) < 0.02 && abs(current.y - target.y) < 0.02
    }
}

private enum SpatialPreset: CaseIterable, Identifiable {
    case left
    case front
    case center
    case back
    case right

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .left:
            return L10n.Spatial.left
        case .front:
            return L10n.Spatial.front
        case .center:
            return L10n.Spatial.center
        case .back:
            return L10n.Spatial.back
        case .right:
            return L10n.Spatial.right
        }
    }

    var systemImage: String {
        switch self {
        case .left:
            return "arrow.left"
        case .front:
            return "arrow.up"
        case .center:
            return "scope"
        case .back:
            return "arrow.down"
        case .right:
            return "arrow.right"
        }
    }

    var point: SpatialPoint {
        switch self {
        case .left:
            return SpatialPoint(x: -1, y: 0)
        case .front:
            return SpatialPoint(x: 0, y: -1)
        case .center:
            return .center
        case .back:
            return SpatialPoint(x: 0, y: 1)
        case .right:
            return SpatialPoint(x: 1, y: 0)
        }
    }
}

private struct SpatialPlacementStage: View {
    @Environment(AppModel.self) private var model
    let channel: SoundChannel

    private var position: SpatialPoint {
        model.channelState(for: channel).spatialPosition
    }

    var body: some View {
        GeometryReader { proxy in
            let length = min(proxy.size.width, proxy.size.height)
            let stageSize = CGSize(width: length, height: length)
            let orbPoint = point(for: position, in: stageSize)

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white.opacity(0.001))
                    .oasisGlassEffect(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(channel.tint.opacity(0.06))
                    }

                stageDecorations(in: stageSize)

                listenerMarker(at: CGPoint(x: stageSize.width / 2, y: stageSize.height / 2))

                sourceOrb(at: orbPoint)
            }
            .frame(width: stageSize.width, height: stageSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        model.setChannelSpatialPosition(channel, value: normalizedPoint(from: value.location, in: stageSize))
                    }
            )
            // Force the stage to expose itself as a single accessibility leaf
            // so XCUITest can target it for synthetic drag gestures used by
            // the marketing video factory.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(L10n.Spatial.stageAccessibility))
            .accessibilityHint(Text(L10n.Spatial.stageHint))
            .accessibilityValue(accessibilityValue(for: position))
            .accessibilityIdentifier("spatial.stage")
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private func stageDecorations(in size: CGSize) -> some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        shape
            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)

        Path { path in
            path.move(to: CGPoint(x: center.x, y: 24))
            path.addLine(to: CGPoint(x: center.x, y: size.height - 24))
            path.move(to: CGPoint(x: 24, y: center.y))
            path.addLine(to: CGPoint(x: size.width - 24, y: center.y))
        }
        .stroke(Color.white.opacity(0.10), style: StrokeStyle(lineWidth: 1, dash: [5, 7]))

        ForEach([0.26, 0.46, 0.68], id: \.self) { scale in
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
                .frame(width: size.width * scale, height: size.width * scale)
                .position(center)
        }

        label(L10n.string(L10n.Spatial.front))
            .position(x: center.x, y: 14)
        label(L10n.string(L10n.Spatial.back))
            .position(x: center.x, y: size.height - 14)
        label(L10n.string(L10n.Spatial.left))
            .position(x: 20, y: center.y)
        label(L10n.string(L10n.Spatial.right))
            .position(x: size.width - 20, y: center.y)
    }

    private func sourceOrb(at point: CGPoint) -> some View {
        ZStack {
            Circle()
                .fill(channel.tint.opacity(0.18))
                .frame(width: 56, height: 56)
                .blur(radius: 10)

            Circle()
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: Circle())
                .overlay {
                    Circle()
                        .fill(channel.tint.opacity(0.22))
                }
                .overlay {
                    Circle()
                        .strokeBorder(channel.tint.opacity(0.42), lineWidth: 1.2)
                }
                .frame(width: 46, height: 46)

            OasisGlyphImage(glyph: channel.oasisGlyph)
                .foregroundStyle(.white)
                .frame(width: 19, height: 19)
                .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
        .position(point)
        .animation(.smooth(duration: 0.16), value: point)
    }

    private func listenerMarker(at point: CGPoint) -> some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                .frame(width: 22, height: 22)

            Circle()
                .fill(Color.white.opacity(0.72))
                .frame(width: 6, height: 6)
        }
        .position(point)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .oasisFont(size: 10, weight: .semibold, relativeTo: .caption2)
            .foregroundStyle(.white.opacity(0.42))
    }

    private func normalizedPoint(from location: CGPoint, in size: CGSize) -> SpatialPoint {
        let inset: CGFloat = 28
        let minX = inset
        let maxX = size.width - inset
        let minY = inset
        let maxY = size.height - inset

        let clampedX = min(max(location.x, minX), maxX)
        let clampedY = min(max(location.y, minY), maxY)

        let normalizedX = ((clampedX - minX) / max(maxX - minX, 1)) * 2 - 1
        let normalizedY = ((clampedY - minY) / max(maxY - minY, 1)) * 2 - 1

        return SpatialPoint(x: Double(normalizedX), y: Double(normalizedY)).clamped()
    }

    private func point(for position: SpatialPoint, in size: CGSize) -> CGPoint {
        let inset: CGFloat = 28
        let clamped = position.clamped()
        let x = inset + ((CGFloat(clamped.x) + 1) * 0.5 * (size.width - (inset * 2)))
        let y = inset + ((CGFloat(clamped.y) + 1) * 0.5 * (size.height - (inset * 2)))
        return CGPoint(x: x, y: y)
    }

    private func accessibilityValue(for position: SpatialPoint) -> Text {
        if position.isCentered {
            return Text(L10n.Spatial.positionCentered)
        }

        let horizontal: LocalizedStringResource? = {
            if position.x < -0.25 { return L10n.Spatial.left }
            if position.x > 0.25 { return L10n.Spatial.right }
            return nil
        }()

        let vertical: LocalizedStringResource? = {
            if position.y < -0.25 { return L10n.Spatial.front }
            if position.y > 0.25 { return L10n.Spatial.back }
            return nil
        }()

        let parts = [vertical, horizontal].compactMap { $0 }.map(L10n.string)
        guard !parts.isEmpty else { return Text(L10n.Spatial.positionCentered) }
        return Text(parts.joined(separator: ", "))
    }
}
