import SwiftUI

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
