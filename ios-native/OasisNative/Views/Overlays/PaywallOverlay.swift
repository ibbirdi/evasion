import SwiftUI

struct PaywallOverlay: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackdrop()

                ScrollView(showsIndicators: false) {
                    GlassSurface(
                        tint: SoundChannel.oiseaux.tint.opacity(0.12),
                        cornerRadius: 34,
                        padding: EdgeInsets(top: 28, leading: 24, bottom: 24, trailing: 24)
                    ) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text(model.copy.paywall.title)
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 18) {
                                BenefitRow(text: model.copy.paywall.benefit1)
                                BenefitRow(text: model.copy.paywall.benefit2)
                                BenefitRow(text: model.copy.paywall.benefit3)
                                BenefitRow(text: model.copy.paywall.benefit4)
                            }

                            Text(model.copy.paywall.noSub)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.62))
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let purchaseErrorMessage = model.purchaseErrorMessage {
                                Text(purchaseErrorMessage)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.red.opacity(0.82))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            HStack(spacing: 10) {
                                Button {
                                    Task {
                                        await model.restorePurchases()
                                    }
                                } label: {
                                    Text(model.isRestoringPurchases ? "..." : model.copy.paywall.restore)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                                .buttonStyle(.plain)

                                Text("•")
                                    .foregroundStyle(.white.opacity(0.28))

                                Button {
                                    openURL(AppConfiguration.supportURL)
                                } label: {
                                    Text(model.copy.paywall.terms)
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Button {
                    Task {
                        await model.purchasePremium()
                    }
                } label: {
                    HStack {
                        if model.isPurchasingPremium {
                            ProgressView()
                                .tint(Color.black.opacity(0.8))
                        } else {
                            Text(model.copy.paywall.cta + model.premiumPriceText)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .foregroundStyle(Color.black.opacity(0.82))
                    .background(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color(red: 0.93, green: 0.78, blue: 0.31))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                .buttonStyle(.plain)
                .disabled(model.isPurchasingPremium)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(model.copy.modal.cancel) {
                        model.showsPaywall = false
                        model.purchaseErrorMessage = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct BenefitRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(SoundChannel.oiseaux.tint)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
