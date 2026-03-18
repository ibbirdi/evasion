import SwiftUI
import RevenueCat

struct PaywallOverlay: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var currentPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false

    private let accentGradient = LinearGradient(
        colors: [
            SoundChannel.pluie.tint.opacity(0.95),
            BinauralTrack.alpha.tint.opacity(0.85),
            SoundChannel.oiseaux.tint.opacity(0.95)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private let ctaGradient = LinearGradient(
        colors: [
            Color(red: 0.95, green: 0.84, blue: 0.45),
            Color(red: 0.97, green: 0.72, blue: 0.33)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

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
                            model.showsPaywall = false
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, topInset + 8)

                    Spacer(minLength: isCompactHeight ? 12 : 24)

                    VStack(spacing: isCompactHeight ? 14 : 20) {
                        GlassSurface(
                            tint: Color.white.opacity(0.045),
                            cornerRadius: 34,
                            padding: EdgeInsets(
                                top: isCompactHeight ? 20 : 24,
                                leading: isCompactHeight ? 18 : 22,
                                bottom: isCompactHeight ? 18 : 22,
                                trailing: isCompactHeight ? 18 : 22
                            )
                        ) {
                            VStack(spacing: 0) {
                                Text(model.copy.paywall.title)
                                    .font(.system(size: isCompactHeight ? 30 : 34, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.85)
                                    .padding(.bottom, isCompactHeight ? 12 : 16)

                                Text(model.copy.paywall.noSub)
                                    .font(.system(size: isCompactHeight ? 14 : 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.60))
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, isCompactHeight ? 20 : 28)

                                VStack(alignment: .leading, spacing: isCompactHeight ? 10 : 14) {
                                    BenefitRow(
                                        text: model.copy.paywall.benefit1,
                                        tint: SoundChannel.oiseaux.tint,
                                        isCompact: isCompactHeight
                                    )
                                    BenefitRow(
                                        text: model.copy.paywall.benefit2,
                                        tint: SoundChannel.foret.tint,
                                        isCompact: isCompactHeight
                                    )
                                    BenefitRow(
                                        text: model.copy.paywall.benefit3,
                                        tint: BinauralTrack.alpha.tint,
                                        isCompact: isCompactHeight
                                    )
                                    BenefitRow(
                                        text: model.copy.paywall.benefit4,
                                        tint: SoundChannel.pluie.tint,
                                        isCompact: isCompactHeight
                                    )
                                }
                                .padding(.bottom, isCompactHeight ? 18 : 24)

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
                                            Text(model.copy.paywall.cta + (currentPackage?.localizedPriceString ?? "..."))
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
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
                            }
                        }

                        HStack(spacing: 12) {
                            Button {
                                Task {
                                    await restorePurchases()
                                }
                            } label: {
                                Text(isRestoring ? "..." : model.copy.paywall.restore)
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

                            Button {
                                openURL(AppConfiguration.supportURL)
                            } label: {
                                Text(model.copy.paywall.terms)
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
                        }
                        .padding(.horizontal, 6)
                    }
                    .padding(.horizontal, isCompactHeight ? 22 : 26)

                    Spacer(minLength: isCompactHeight ? 10 : 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard currentPackage == nil, AppConfiguration.isRevenueCatConfigured else { return }

            do {
                let customerInfo = try await Purchases.shared.customerInfo()
                model.applyRevenueCatCustomerInfo(customerInfo)

                if customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
                    model.showsPaywall = false
                    dismiss()
                    return
                }

                let offerings = try await Purchases.shared.offerings()
                currentPackage = offerings.current?.availablePackages.first
            } catch {
                print("RevenueCat offerings load failed: \(error)")
            }
        }
        .onChange(of: model.isPremium) { _, isPremium in
            guard isPremium else { return }
            model.showsPaywall = false
            dismiss()
        }
        .preferredColorScheme(.dark)
    }

    private func purchaseCurrentPackage() async {
        guard let currentPackage else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await Purchases.shared.purchase(package: currentPackage)
            model.applyRevenueCatCustomerInfo(result.customerInfo)

            if !result.userCancelled,
               result.customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
                model.showsPaywall = false
                dismiss()
            }
        } catch {
            print("RevenueCat purchase failed: \(error)")
        }
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            model.applyRevenueCatCustomerInfo(customerInfo)

            if customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
                model.showsPaywall = false
                dismiss()
            }
        } catch {
            print("RevenueCat restore failed: \(error)")
        }
    }
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
