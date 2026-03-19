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
                Image(systemName: "scope")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(channel.tint.opacity(0.92))

                Text(model.channelName(channel))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(model.copy.spatial.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)

            SpatialPlacementStage(channel: channel)
                .frame(height: 252)

            Button {
                withAnimation(.smooth(duration: 0.24)) {
                    model.resetChannelSpatialPosition(channel)
                }
            } label: {
                Text(model.copy.spatial.reset)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .frame(height: 38)
                    .background {
                        Capsule()
                            .fill(.regularMaterial)
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
            .buttonStyle(PressScaleButtonStyle())
            .opacity(state.spatialPosition.isCentered ? 0.56 : 1)
            .disabled(state.spatialPosition.isCentered)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.spatial.container")
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
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(channel.tint.opacity(0.06))
                    }

                stageDecorations(in: stageSize)

                listenerMarker(at: CGPoint(x: stageSize.width / 2, y: stageSize.height / 2))

                sourceOrb(at: orbPoint)
            }
            .frame(width: stageSize.width, height: stageSize.height)
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        model.setChannelSpatialPosition(channel, value: normalizedPoint(from: value.location, in: stageSize))
                    }
            )
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

        label(model.copy.spatial.front)
            .position(x: center.x, y: 14)
        label(model.copy.spatial.back)
            .position(x: center.x, y: size.height - 14)
        label(model.copy.spatial.left)
            .position(x: 20, y: center.y)
        label(model.copy.spatial.right)
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
                .glassEffect(.regular, in: Circle())
                .overlay {
                    Circle()
                        .fill(channel.tint.opacity(0.22))
                }
                .overlay {
                    Circle()
                        .strokeBorder(channel.tint.opacity(0.42), lineWidth: 1.2)
                }
                .frame(width: 46, height: 46)

            Image(systemName: channel.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
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
            .font(.system(size: 10, weight: .semibold, design: .rounded))
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
}
