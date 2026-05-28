import RevenueCat
import SwiftUI

struct MacPaywallSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let context: PremiumPaywallContext

    @State private var currentPackage: Package?
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var loadFailed = false

    private var presentation: PremiumPaywallPresentation {
        model.paywallPresentation(for: context.entryPoint)
    }

    var body: some View {
        ZStack {
            MacPanelBackground()

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: presentation.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(presentation.accentToken.macTint)
                        .frame(width: 38, height: 38)
                        .background(presentation.accentToken.macTint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: presentation.title)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(verbatim: presentation.subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button {
                        model.dismissPaywall()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.58))
                    .accessibilityLabel(Text(L10n.Presets.close))
                }

                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(presentation.benefitRows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 9) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(presentation.accentToken.macTint)
                            Text(verbatim: row.text)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.84))
                        }
                    }
                }
                .padding(.vertical, 2)

                Text(L10n.Paywall.noSubscription)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))

                Button {
                    Task {
                        await purchase()
                    }
                } label: {
                    HStack {
                        if isLoading || isPurchasing {
                            ProgressView()
                                .controlSize(.small)
                        }

                        VStack(spacing: 2) {
                            Text(primaryTitle)
                                .font(.system(size: 14, weight: .bold, design: .rounded))

                            if let price = currentPackage?.localizedPriceString {
                                Text(verbatim: price)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .opacity(0.72)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                }
                .buttonStyle(MacPrimaryButtonStyle())
                .disabled(currentPackage == nil || isLoading || isPurchasing)

                if loadFailed {
                    Button {
                        Task {
                            await loadPackage(force: true)
                        }
                    } label: {
                        Text(L10n.Paywall.retry)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 30)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.82))
                    .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await restore()
                        }
                    } label: {
                        Text(isRestoring ? L10n.Paywall.restoring : L10n.Paywall.restore)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isRestoring)

                    Button {
                        openURL(AppConfiguration.supportURL)
                    } label: {
                        Text(L10n.Paywall.support)
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .buttonStyle(.borderless)
                .foregroundStyle(.white.opacity(0.70))
            }
            .padding(20)
        }
        .task {
            await loadPackage(force: false)
        }
        .onChange(of: model.isPremium) { _, isPremium in
            guard isPremium else { return }
            model.dismissPaywall()
            dismiss()
        }
    }

    private var primaryTitle: String {
        if isLoading {
            return L10n.string(L10n.Paywall.loading)
        }
        if loadFailed || currentPackage == nil {
            return L10n.string(L10n.Paywall.unavailable)
        }
        return L10n.string(L10n.Paywall.primaryTitle)
    }

    private func loadPackage(force: Bool) async {
        guard force || currentPackage == nil else { return }
        isLoading = true
        loadFailed = false
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
        } catch {
            print("RevenueCat offerings load failed: \(error)")
            loadFailed = true
        }

        isLoading = false
    }

    private func purchase() async {
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
            loadFailed = true
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        await model.restorePurchases()

        if model.isPremium {
            model.dismissPaywall()
            dismiss()
        }
    }
}
