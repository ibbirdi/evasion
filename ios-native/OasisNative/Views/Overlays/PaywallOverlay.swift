import RevenueCat
import SwiftUI

struct PaywallOverlay: View {
    let context: PremiumPaywallContext

    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var currentPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var loadState: PaywallLoadState = .idle

    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.84, blue: 0.45),
            Color(red: 0.97, green: 0.72, blue: 0.33)
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
                AnimatedBackdrop()

                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.70),
                        Color(red: 0.02, green: 0.03, blue: 0.09).opacity(0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()

                Color(red: 0.01, green: 0.02, blue: 0.07)
                    .opacity(0.74)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Button {
                            model.dismissPaywall()
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.86))
                                .frame(width: 44, height: 44)
                                .background {
                                    Circle()
                                        .fill(Color.white.opacity(0.001))
                                        .glassEffect(.regular, in: Circle())
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, topInset + 8)

                    Spacer(minLength: isCompactHeight ? 12 : 24)

                    VStack(spacing: isCompactHeight ? 14 : 18) {
                        GlassSurface(
                            tint: presentation.accentToken.tint.opacity(0.08),
                            cornerRadius: 34,
                            padding: EdgeInsets(
                                top: isCompactHeight ? 20 : 24,
                                leading: isCompactHeight ? 18 : 22,
                                bottom: isCompactHeight ? 18 : 22,
                                trailing: isCompactHeight ? 18 : 22
                            )
                        ) {
                            VStack(spacing: 0) {
                                VStack(spacing: 10) {
                                    Image(systemName: presentation.symbolName)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(presentation.accentToken.tint)

                                    Text(presentation.title)
                                        .font(.system(size: isCompactHeight ? 29 : 33, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .minimumScaleFactor(0.85)

                                    Text(presentation.subtitle)
                                        .font(.system(size: isCompactHeight ? 14 : 15, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.64))
                                        .multilineTextAlignment(.center)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.bottom, isCompactHeight ? 18 : 24)

                                VStack(alignment: .leading, spacing: isCompactHeight ? 10 : 14) {
                                    ForEach(Array(presentation.benefitRows.enumerated()), id: \.offset) { index, benefit in
                                        BenefitRow(
                                            text: benefit,
                                            tint: benefitTint(for: index),
                                            isCompact: isCompactHeight
                                        )
                                    }
                                }
                                .padding(.bottom, isCompactHeight ? 18 : 24)

                                Text(L10n.Paywall.noSubscription)
                                    .font(.system(size: isCompactHeight ? 13 : 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.58))
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, isCompactHeight ? 18 : 22)

                                primaryActionButton(isCompactHeight: isCompactHeight)
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
                    .font(.system(size: 16, weight: .bold, design: .rounded))
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
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)

                            if let price = currentPackage?.localizedPriceString, !price.isEmpty {
                                Text(price)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
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
                        .shadow(color: Color(red: 0.97, green: 0.74, blue: 0.32).opacity(0.18), radius: 16, y: 8)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(currentPackage == nil || isPurchasing)
            .accessibilityIdentifier("premium.paywall.primary")

        case .failed, .unavailable:
            VStack(spacing: 10) {
                Button {
                    Task {
                        await loadCurrentPackage(forceReload: true)
                    }
                } label: {
                    Text(L10n.Paywall.retry)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
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
                    .font(.system(size: 12, weight: .medium, design: .rounded))
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
                    .font(.system(size: isCompactHeight ? 12 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompactHeight ? 13 : 14)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.001))
                            .glassEffect(.regular, in: Capsule())
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
                    .font(.system(size: isCompactHeight ? 12 : 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompactHeight ? 13 : 14)
                    .background {
                        Capsule()
                            .fill(Color.white.opacity(0.001))
                            .glassEffect(.regular, in: Capsule())
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

    private func benefitTint(for index: Int) -> Color {
        switch index {
        case 0:
            return presentation.accentToken.tint
        case 1:
            return SoundChannel.foret.tint
        case 2:
            return SoundChannel.pluie.tint
        default:
            return BinauralTrack.alpha.tint
        }
    }

    private func loadCurrentPackage(forceReload: Bool = false) async {
        guard forceReload || loadState == .idle else { return }

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

private struct BenefitRow: View {
    let text: String
    let tint: Color
    let isCompact: Bool

    var body: some View {
        HStack(alignment: .center, spacing: isCompact ? 12 : 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: isCompact ? 18 : 20, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: isCompact ? 22 : 24, height: isCompact ? 22 : 24)

            Text(text)
                .font(.system(size: isCompact ? 15 : 17, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.90))
                .lineSpacing(isCompact ? 2 : 3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, isCompact ? 6 : 8)
        .padding(.vertical, isCompact ? 8 : 10)
    }
}
