import SwiftUI

struct MacInlineUpsellSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let context: PremiumInlineUpsellContext

    private var presentation: PremiumInlineUpsellPresentation {
        switch context.entryPoint.category {
        case .preset:
            return model.presetsUpsellPresentation ?? model.paywallPresentation(for: .presetSave).inlineFallback
        case .binaural:
            return model.binauralUpsellPresentation ?? model.paywallPresentation(for: .binaural(.theta)).inlineFallback
        default:
            return model.paywallPresentation(for: context.entryPoint).inlineFallback
        }
    }

    var body: some View {
        ZStack {
            MacPanelBackground()

            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: presentation.symbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(presentation.accentToken.macTint)
                        .frame(width: 38, height: 38)
                        .background(presentation.accentToken.macTint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(verbatim: presentation.title)
                            .font(.system(size: 19, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(verbatim: presentation.message)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                if let footnote = presentation.footnote {
                    Text(verbatim: footnote)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.52))
                }

                HStack(spacing: 9) {
                    Button {
                        model.dismissInlineUpsell()
                        model.presentPaywall(from: context.entryPoint)
                        dismiss()
                    } label: {
                        Text(verbatim: presentation.primaryActionTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MacPrimaryButtonStyle())

                    if let secondaryTitle = presentation.secondaryActionTitle {
                        Button {
                            handleSecondaryAction()
                        } label: {
                            Text(verbatim: secondaryTitle)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.76))
                        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            .padding(18)
        }
    }

    private func handleSecondaryAction() {
        if context.entryPoint.category == .preset, model.isSignaturePreviewAvailable {
            model.startSignaturePreview()
        } else {
            model.dismissInlineUpsell()
        }
        dismiss()
    }
}

private extension PremiumPaywallPresentation {
    var inlineFallback: PremiumInlineUpsellPresentation {
        PremiumInlineUpsellPresentation(
            title: title,
            message: subtitle,
            primaryActionTitle: L10n.string(L10n.Premium.inlineUnlock),
            secondaryActionTitle: L10n.string(L10n.Premium.inlineNotNow),
            footnote: nil,
            symbolName: symbolName,
            accentToken: accentToken
        )
    }
}
