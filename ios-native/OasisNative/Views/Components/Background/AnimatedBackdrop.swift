import SwiftUI

struct AnimatedBackdrop: View {
    @Environment(AppModel.self) private var model

    private var activePalette: [Color] {
        var colors = SoundChannel.allCases
            .filter(model.isAmbientChannelActive(_:))
            .map(\.tint)

        if model.isBinauralActive {
            colors.append(model.activeBinauralTrack.tint)
        }

        if colors.isEmpty {
            colors = [SoundChannel.oiseaux.tint, SoundChannel.vent.tint, SoundChannel.plage.tint]
        }

        return Array(colors.prefix(6))
    }

    private var primaryColor: Color { color(at: 0) }
    private var secondaryColor: Color { color(at: 1) }
    private var tertiaryColor: Color { color(at: 2) }
    private var quaternaryColor: Color { color(at: 3) }
    private var accentColor: Color { color(at: 4) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                baseGradient

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                primaryColor.opacity(0.44),
                                secondaryColor.opacity(0.30),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: proxy.size.width * 0.86, height: proxy.size.width * 0.62)
                    .blur(radius: 64)
                    .rotationEffect(.degrees(-12))
                    .offset(x: -proxy.size.width * 0.16, y: -proxy.size.height * 0.10)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                tertiaryColor.opacity(0.36),
                                quaternaryColor.opacity(0.24),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: proxy.size.width * 0.94, height: proxy.size.width * 0.74)
                    .blur(radius: 74)
                    .rotationEffect(.degrees(18))
                    .offset(x: proxy.size.width * 0.22, y: proxy.size.height * 0.34)

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.28),
                                secondaryColor.opacity(0.18),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * 0.70, height: proxy.size.width * 0.46)
                    .blur(radius: 52)
                    .rotationEffect(.degrees(8))
                    .offset(x: proxy.size.width * 0.08, y: proxy.size.height * 0.02)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.14),
                                Color.black.opacity(0.24),
                                Color.black.opacity(0.42)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.12),
                                Color.black.opacity(0.34)
                            ],
                            center: .center,
                            startRadius: 24,
                            endRadius: max(proxy.size.width, proxy.size.height) * 0.88
                        )
                    )
                    .blendMode(.multiply)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private var baseGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.03, blue: 0.06),
                mix(primaryColor, with: secondaryColor, opacity: 0.18),
                mix(tertiaryColor, with: quaternaryColor, opacity: 0.16),
                Color(red: 0.02, green: 0.03, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func color(at index: Int) -> Color {
        activePalette[index % activePalette.count]
    }

    private func mix(_ first: Color, with second: Color, opacity: Double) -> Color {
        let uiFirst = UIColor(first)
        let uiSecond = UIColor(second)

        var firstRed: CGFloat = 0
        var firstGreen: CGFloat = 0
        var firstBlue: CGFloat = 0
        var firstAlpha: CGFloat = 0
        uiFirst.getRed(&firstRed, green: &firstGreen, blue: &firstBlue, alpha: &firstAlpha)

        var secondRed: CGFloat = 0
        var secondGreen: CGFloat = 0
        var secondBlue: CGFloat = 0
        var secondAlpha: CGFloat = 0
        uiSecond.getRed(&secondRed, green: &secondGreen, blue: &secondBlue, alpha: &secondAlpha)

        return Color(
            red: (firstRed + secondRed) / 2,
            green: (firstGreen + secondGreen) / 2,
            blue: (firstBlue + secondBlue) / 2
        )
        .opacity(opacity)
    }
}
