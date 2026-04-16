import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "waveform.path.ecg",
            titleKey: "onboarding.page1.title",
            titleDefault: "Your sound bed for sleep",
            subtitleKey: "onboarding.page1.subtitle",
            subtitleDefault: "Mix nature sounds, adjust each volume, and place them around you in 3D audio.",
            tint: Color(red: 0.45, green: 0.79, blue: 0.92)
        ),
        OnboardingPage(
            symbol: "timer",
            titleKey: "onboarding.page2.title",
            titleDefault: "Set a timer, drift off",
            subtitleKey: "onboarding.page2.subtitle",
            subtitleDefault: "Start a sleep timer, lock your phone, and let Oasis play in the background. Everything works offline.",
            tint: Color(red: 0.52, green: 0.91, blue: 0.64)
        ),
        OnboardingPage(
            symbol: "sparkles",
            titleKey: "onboarding.page3.title",
            titleDefault: "14 sounds, one purchase",
            subtitleKey: "onboarding.page3.subtitle",
            subtitleDefault: "Start free with 3 sounds and 3D audio. Unlock 11 more sounds, longer timers and binaural modes — no subscription, ever.",
            tint: Color(red: 0.97, green: 0.79, blue: 0.41)
        ),
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AnimatedBackdrop()

                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.60),
                        Color(red: 0.02, green: 0.03, blue: 0.09).opacity(0.80)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: proxy.safeAreaInsets.top + 40)

                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                            OnboardingPageView(page: page)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.smooth(duration: 0.3), value: currentPage)

                    Spacer(minLength: 16)

                    pageIndicator

                    Spacer(minLength: 20)

                    actionButtons(topInset: proxy.safeAreaInsets.top)

                    Spacer(minLength: max(proxy.safeAreaInsets.bottom, 16) + 12)
                }
            }
            .ignoresSafeArea()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? pages[currentPage].tint : Color.white.opacity(0.24))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.smooth(duration: 0.24), value: currentPage)
            }
        }
    }

    @ViewBuilder
    private func actionButtons(topInset: CGFloat) -> some View {
        let isLastPage = currentPage == pages.count - 1

        VStack(spacing: 12) {
            Button {
                if isLastPage {
                    withAnimation(.smooth(duration: 0.3)) {
                        model.completeOnboarding(fromPage: currentPage, skipped: false)
                    }
                } else {
                    withAnimation(.smooth(duration: 0.3)) {
                        currentPage += 1
                    }
                }
            } label: {
                Text(isLastPage
                    ? String(localized: "onboarding.cta.start", defaultValue: "Start listening")
                    : String(localized: "onboarding.cta.next", defaultValue: "Next")
                )
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.84, blue: 0.45),
                                    Color(red: 0.97, green: 0.72, blue: 0.33)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .buttonStyle(PressScaleButtonStyle())

            if !isLastPage {
                Button {
                    withAnimation(.smooth(duration: 0.3)) {
                        model.completeOnboarding(fromPage: currentPage, skipped: true)
                    }
                } label: {
                    Text(String(localized: "onboarding.cta.skip", defaultValue: "Skip"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(.horizontal, 30)
    }
}

private struct OnboardingPage {
    let symbol: String
    let titleKey: String
    let titleDefault: String
    let subtitleKey: String
    let subtitleDefault: String
    let tint: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 22) {
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.12))
                    .frame(width: 88, height: 88)

                Circle()
                    .strokeBorder(page.tint.opacity(0.28), lineWidth: 1.5)
                    .frame(width: 88, height: 88)

                Image(systemName: page.symbol)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(page.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 12) {
                Text(String(localized: String.LocalizationValue(page.titleKey), defaultValue: String.LocalizationValue(page.titleDefault)))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.80)

                Text(String(localized: String.LocalizationValue(page.subtitleKey), defaultValue: String.LocalizationValue(page.subtitleDefault)))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
