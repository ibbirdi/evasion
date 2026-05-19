import SwiftUI

struct AnimatedBackdrop: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                baseGradient

                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.23, blue: 0.29).opacity(0.34),
                                Color(red: 0.11, green: 0.16, blue: 0.22).opacity(0.24),
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
                                Color(red: 0.14, green: 0.19, blue: 0.26).opacity(0.28),
                                Color(red: 0.09, green: 0.13, blue: 0.19).opacity(0.18),
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
                                Color(red: 0.17, green: 0.22, blue: 0.28).opacity(0.20),
                                Color(red: 0.10, green: 0.15, blue: 0.21).opacity(0.14),
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
                                Color.black.opacity(0.06),
                                Color.black.opacity(0.14),
                                Color.black.opacity(0.26)
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
                                Color.black.opacity(0.04),
                                Color.black.opacity(0.18)
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
                Color(red: 0.028, green: 0.042, blue: 0.065),
                Color(red: 0.075, green: 0.100, blue: 0.130),
                Color(red: 0.052, green: 0.076, blue: 0.105),
                Color(red: 0.024, green: 0.036, blue: 0.060)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
