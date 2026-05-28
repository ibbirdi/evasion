import RevenueCat
import SwiftUI

struct PaywallOverlay: View {
    let context: PremiumPaywallContext

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var loadState: PaywallLoadState = .idle
    @State private var ctaPulse = false
    /// True only under UI/screenshot automation. Lets the CTA render its
    /// `.loaded` happy-path without a live RevenueCat offering and without
    /// surfacing any price (prices change, App Store auto-localises them on
    /// the live paywall anyway — no point baking one into a marketing asset).
    @State private var isScreenshotMockMode = false

    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.63, blue: 0.49),
            Color(red: 0.72, green: 0.85, blue: 0.87)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var presentation: PremiumPaywallPresentation {
        model.paywallPresentation(for: context.entryPoint)
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompactHeight = proxy.size.height < 820
            let topInset = proxy.safeAreaInsets.top

            ZStack {
                PaywallAtmosphericBackground()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Button {
                            model.dismissPaywall()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .oasisFont(size: 18, weight: .semibold, design: .default, relativeTo: .body)
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(width: 44, height: 44)
                                .background {
                                    Circle()
                                        .fill(Color.white.opacity(0.001))
                                        .oasisGlassEffect(in: Circle())
                                        .overlay {
                                            Circle()
                                                .fill(Color.white.opacity(0.028))
                                        }
                                }
                                .overlay {
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                                }
                        }
                        .buttonStyle(PressScaleButtonStyle())
                        .accessibilityIdentifier("premium.paywall.close")
                        .accessibilityLabel(Text(L10n.Presets.close))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, topInset + 8)

                    Spacer(minLength: isCompactHeight ? 12 : 24)

                    VStack(spacing: isCompactHeight ? 14 : 18) {
                        GlassSurface(
                            tint: Color(red: 0.91, green: 0.62, blue: 0.48).opacity(0.06),
                            cornerRadius: 34,
                            padding: EdgeInsets(
                                top: isCompactHeight ? 20 : 24,
                                leading: isCompactHeight ? 18 : 22,
                                bottom: isCompactHeight ? 18 : 22,
                                trailing: isCompactHeight ? 18 : 22
                            )
                        ) {
                            VStack(spacing: 0) {
                                PaywallLifetimeHero(
                                    title: presentation.title,
                                    subtitle: heroSubtitle,
                                    trustLine: L10n.string(L10n.Paywall.noSubscription),
                                    backdrop: heroBackdrop,
                                    isCompact: isCompactHeight
                                )
                                .padding(.bottom, isCompactHeight ? 18 : 22)

                                PaywallBenefitGrid(items: benefitItems, isCompact: isCompactHeight)
                                .padding(.bottom, isCompactHeight ? 18 : 24)

                                primaryActionButton(isCompactHeight: isCompactHeight)

                                if currentPackage?.localizedPriceString != nil {
                                    Text(L10n.Paywall.dailyPrice)
                                        .oasisFont(size: isCompactHeight ? 11 : 12, weight: .medium, relativeTo: .caption)
                                        .foregroundStyle(.white.opacity(0.50))
                                        .multilineTextAlignment(.center)
                                        .padding(.top, 4)
                                }
                            }
                        }

                        footerButtons(isCompactHeight: isCompactHeight)
                            .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, isCompactHeight ? 22 : 26)

                    Spacer(minLength: isCompactHeight ? 10 : 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            await loadCurrentPackage()
        }
        .onChange(of: model.isPremium) { _, isPremium in
            guard isPremium else { return }
            model.dismissPaywall()
            dismiss()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("premium.paywall.container")
    }

    @ViewBuilder
    private func primaryActionButton(isCompactHeight: Bool) -> some View {
        switch loadState {
        case .idle, .loading:
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Color(red: 0.06, green: 0.08, blue: 0.12))

                Text(L10n.Paywall.loading)
                    .oasisFont(size: 16, weight: .bold, relativeTo: .headline)
                    .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompactHeight ? 16 : 18)
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(ctaGradient.opacity(0.82))
            }
            .accessibilityIdentifier("premium.paywall.loading")

        case .loaded:
            Button {
                Task {
                    await purchaseCurrentPackage()
                }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(Color(red: 0.06, green: 0.08, blue: 0.12))
                    } else {
                        VStack(spacing: 2) {
                            Text(L10n.Paywall.primaryTitle)
                                .oasisFont(size: 17, weight: .bold, relativeTo: .headline)
                                .multilineTextAlignment(.center)

                            if let price = currentPackage?.localizedPriceString, !price.isEmpty {
                                Text(price)
                                    .oasisFont(size: 13, weight: .semibold, relativeTo: .subheadline)
                                    .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12).opacity(0.72))
                            }
                        }
                        .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompactHeight ? 16 : 18)
                .background {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(ctaGradient)
                        .shadow(color: Color(red: 0.91, green: 0.62, blue: 0.48).opacity(ctaPulse ? 0.28 : 0.13), radius: ctaPulse ? 22 : 12, y: 8)
                }
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                        ctaPulse = true
                    }
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled((currentPackage == nil && !isScreenshotMockMode) || isPurchasing)
            .accessibilityIdentifier("premium.paywall.primary")

        case .failed, .unavailable:
            VStack(spacing: 10) {
                Button {
                    Task {
                        await loadCurrentPackage(forceReload: true)
                    }
                } label: {
                    Text(L10n.Paywall.retry)
                        .oasisFont(size: 17, weight: .bold, relativeTo: .headline)
                        .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isCompactHeight ? 16 : 18)
                        .background {
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(ctaGradient)
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityIdentifier("premium.paywall.retry")

                Text(L10n.Paywall.unavailable)
                    .oasisFont(size: 12, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private func footerButtons(isCompactHeight: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text(isRestoring ? L10n.Paywall.restoring : L10n.Paywall.restore)
                    .oasisFont(size: isCompactHeight ? 12 : 13, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompactHeight ? 13 : 14)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.001))
                            .oasisGlassEffect(in: Capsule())
                            .overlay {
                                Capsule()
                                    .fill(Color.white.opacity(0.026))
                            }
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityIdentifier("premium.paywall.restore")

            Button {
                openURL(AppConfiguration.supportURL)
            } label: {
                Text(L10n.Paywall.support)
                    .oasisFont(size: isCompactHeight ? 12 : 13, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompactHeight ? 13 : 14)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.001))
                            .oasisGlassEffect(in: Capsule())
                            .overlay {
                                Capsule()
                                    .fill(Color.white.opacity(0.026))
                            }
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    }
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityIdentifier("premium.paywall.help")
        }
    }

    private var benefitItems: [PaywallBenefitItem] {
        presentation.benefitRows.map { benefit in
            PaywallBenefitItem(
                text: compactBenefitText(benefit.text),
                symbolName: benefitSymbol(for: benefit.kind),
                tint: benefitTint(for: benefit.kind)
            )
        }
    }

    private var heroSubtitle: String {
        guard let firstSentence = presentation.subtitle.split(whereSeparator: { ".!?".contains($0) }).first else {
            return presentation.subtitle
        }
        return String(firstSentence)
    }

    private func compactBenefitText(_ text: String) -> String {
        guard let colonIndex = text.firstIndex(of: ":") else { return text }
        return String(text[..<colonIndex])
    }

    private func benefitTint(for kind: PremiumBenefitKind) -> Color {
        switch kind {
        case .sounds:
            return Color(red: 0.60, green: 0.77, blue: 0.82)
        case .noise:
            return Color(red: 0.91, green: 0.68, blue: 0.54)
        case .presets:
            return Color(red: 0.86, green: 0.54, blue: 0.44)
        case .binaural:
            return Color(red: 0.72, green: 0.74, blue: 0.88)
        case .timer:
            return Color(red: 0.94, green: 0.75, blue: 0.52)
        case .updates:
            return Color(red: 0.93, green: 0.86, blue: 0.76)
        }
    }

    private func benefitSymbol(for kind: PremiumBenefitKind) -> String {
        switch kind {
        case .sounds:
            return "speaker.wave.2.fill"
        case .noise:
            return "waveform"
        case .presets:
            return "bookmark.fill"
        case .binaural:
            return "waveform.path.ecg"
        case .timer:
            return "timer"
        case .updates:
            return "sparkles"
        }
    }

    private var heroBackdrop: SoundBackdrop {
        SoundBackdrop(assetName: "paywall_beach_background", focus: .center)
    }

    private func loadCurrentPackage(forceReload: Bool = false) async {
        guard forceReload || loadState == .idle else { return }

        // Under UI/screenshot automation, RevenueCat offerings aren't reachable
        // (StoreKit sandbox isn't configured in CI and `premiumOverride=free`
        // intentionally disables the RC call path). Without this branch the
        // paywall would render its "Réessayer" error state and App Store
        // screenshots would miss the actual purchase CTA. Render the `.loaded`
        // happy path without a price — the App Store surfaces localised
        // pricing on the live paywall, so there's no value in baking one in.
        // No real purchase is triggered because `currentPackage` stays nil and
        // `purchaseCurrentPackage()` early-outs on that guard.
        if AppConfiguration.isRunningScreenshotAutomation {
            isScreenshotMockMode = true
            loadState = .loaded
            return
        }

        loadState = .loading
        currentPackage = nil

        do {
            let customerInfo = try await model.currentLifetimePackageCustomerInfo()
            model.applyRevenueCatCustomerInfo(customerInfo)

            if customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
                model.dismissPaywall()
                dismiss()
                return
            }

            currentPackage = try await model.currentLifetimePackage()
            loadState = currentPackage == nil ? .unavailable : .loaded
        } catch PremiumRevenueCatError.missingOffering, PremiumRevenueCatError.missingPackage {
            loadState = .unavailable
        } catch {
            print("RevenueCat offerings load failed: \(error)")
            loadState = .failed
        }
    }

    private func purchaseCurrentPackage() async {
        guard let currentPackage else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await model.purchaseLifetime(package: currentPackage)
            if !result.userCancelled,
               result.customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
                model.dismissPaywall()
                dismiss()
            }
        } catch {
            print("RevenueCat purchase failed: \(error)")
            loadState = .failed
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        await model.restorePurchases()

        if model.isPremium {
            model.dismissPaywall()
            dismiss()
        }
    }
}

private enum PaywallLoadState {
    case idle
    case loading
    case loaded
    case unavailable
    case failed
}

private struct PaywallAtmosphericBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.050, green: 0.058, blue: 0.064)

            OrganicBackdropImage(
                backdrop: SoundBackdrop(assetName: "paywall_beach_background", focus: .center),
                opacity: 0.34,
                bottomShadeOpacity: 0.80
            )
            .saturation(0.96)
            .contrast(1.04)
            .blur(radius: 8)
            .scaleEffect(1.08)

            LinearGradient(
                colors: [
                    Color(red: 0.47, green: 0.57, blue: 0.58).opacity(0.20),
                    Color(red: 0.13, green: 0.10, blue: 0.10).opacity(0.54),
                    Color.black.opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.91, green: 0.62, blue: 0.48).opacity(0.22),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 520
            )

            RadialGradient(
                colors: [
                    Color(red: 0.62, green: 0.78, blue: 0.82).opacity(0.16),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 70,
                endRadius: 540
            )
        }
        .ignoresSafeArea()
    }
}

private struct PaywallLifetimeHero: View {
    let title: String
    let subtitle: String
    let trustLine: String
    let backdrop: SoundBackdrop
    let isCompact: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "infinity")
                        .oasisFont(size: 12, weight: .bold, design: .default, relativeTo: .caption)
                        .accessibilityHidden(true)

                    Text(trustLine)
                        .oasisFont(size: isCompact ? 11 : 12, weight: .bold, relativeTo: .caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
                .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(Color.white.opacity(0.88))
                }
                .accessibilityLabel(Text(trustLine))
            }

            Spacer(minLength: isCompact ? 34 : 42)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .oasisFont(size: isCompact ? 27 : 31, weight: .semibold, relativeTo: .largeTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.82)

                Text(subtitle)
                    .oasisFont(size: isCompact ? 13 : 14, weight: .medium, relativeTo: .body)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, isCompact ? 16 : 18)
        .padding(.vertical, isCompact ? 16 : 18)
        .frame(maxWidth: .infinity)
        .frame(minHeight: isCompact ? 168 : 186, alignment: .bottomLeading)
        .background {
            shape
                .fill(Color(red: 0.10, green: 0.08, blue: 0.08))
                .overlay {
                    OrganicBackdropImage(backdrop: backdrop, opacity: 0.92, bottomShadeOpacity: 0.64)
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.06),
                            Color(red: 0.91, green: 0.62, blue: 0.48).opacity(0.08),
                            Color(red: 0.12, green: 0.10, blue: 0.10).opacity(0.80)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(shape)
        }
        .clipShape(shape)
        .overlay {
            shape.strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PaywallBenefitItem: Identifiable {
    let id = UUID()
    let text: String
    let symbolName: String
    let tint: Color
}

private struct PaywallBenefitGrid: View {
    let items: [PaywallBenefitItem]
    let isCompact: Bool

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: isCompact ? 8 : 10),
            GridItem(.flexible(), spacing: isCompact ? 8 : 10)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: isCompact ? 8 : 10) {
            ForEach(items) { item in
                PaywallBenefitTile(item: item, isCompact: isCompact)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PaywallBenefitTile: View {
    let item: PaywallBenefitItem
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 8 : 10) {
            Image(systemName: item.symbolName)
                .oasisFont(size: isCompact ? 15 : 16, weight: .semibold, design: .default, relativeTo: .headline)
                .foregroundStyle(item.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: isCompact ? 30 : 32, height: isCompact ? 30 : 32)
                .background {
                    Circle()
                        .fill(item.tint.opacity(0.15))
                }
                .accessibilityHidden(true)

            Text(item.text)
                .oasisFont(size: isCompact ? 13 : 14, weight: .semibold, relativeTo: .subheadline)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: isCompact ? 86 : 94, alignment: .topLeading)
        .padding(isCompact ? 12 : 14)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.070),
                            item.tint.opacity(0.075)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(item.tint.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
