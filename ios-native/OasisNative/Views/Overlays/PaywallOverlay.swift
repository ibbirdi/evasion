import SwiftUI
import RevenueCat

struct PaywallOverlay: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @State private var currentPackage: Package?
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        ZStack {
            AnimatedBackdrop()

            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            Color.black.opacity(0.80)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button {
                        model.showsPaywall = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white.opacity(0.60))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 52)

                Spacer()

                VStack(spacing: 0) {
                    Text(model.copy.paywall.title)
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 48)

                    VStack(alignment: .leading, spacing: 20) {
                        BenefitRow(text: model.copy.paywall.benefit1)
                        BenefitRow(text: model.copy.paywall.benefit2)
                        BenefitRow(text: model.copy.paywall.benefit3)
                        BenefitRow(text: model.copy.paywall.benefit4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 48)

                    Text(model.copy.paywall.noSub)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)

                    Button {
                        Task {
                            await purchaseCurrentPackage()
                        }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(Color(red: 0.07, green: 0.09, blue: 0.13))
                            } else {
                                Text(model.copy.paywall.cta + (currentPackage?.localizedPriceString ?? "..."))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(red: 0.07, green: 0.09, blue: 0.13))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Color(red: 0.93, green: 0.78, blue: 0.31))
                                .shadow(color: Color(red: 0.93, green: 0.78, blue: 0.31).opacity(0.20), radius: 10, y: 6)
                        )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .disabled(currentPackage == nil || isPurchasing)
                    .padding(.bottom, 32)

                    HStack(spacing: 0) {
                        Button {
                            Task {
                                await restorePurchases()
                            }
                        } label: {
                            Text(isRestoring ? "..." : model.copy.paywall.restore)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.50))
                                .underline()
                        }
                        .buttonStyle(.plain)

                        Text("  •  ")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.30))

                        Button {
                            openURL(AppConfiguration.supportURL)
                        } label: {
                            Text(model.copy.paywall.terms)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.50))
                                .underline()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)

                Spacer()
            }
        }
        .task {
            guard currentPackage == nil, AppConfiguration.isRevenueCatConfigured else { return }

            do {
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

            if !result.userCancelled {
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

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(SoundChannel.oiseaux.tint)

            Text(text)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.90))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
