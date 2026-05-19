import SwiftUI

extension PremiumAccentToken {
    var tint: Color {
        switch self {
        case .ambient:
            return SoundChannel.pluie.tint
        case .preset:
            return LiquidActivityPalette.preset[0]
        case .binaural:
            return BinauralTrack.alpha.tint
        case .timer:
            return Color(red: 0.52, green: 0.91, blue: 0.64)
        case .preview:
            return Color(red: 0.97, green: 0.79, blue: 0.41)
        case .neutral:
            return SoundChannel.oiseaux.tint
        }
    }
}

struct PremiumInlineUpsellCard: View {
    let presentation: PremiumInlineUpsellPresentation
    let onPrimaryAction: () -> Void
    let onSecondaryAction: (() -> Void)?
    let onDismiss: () -> Void

    var body: some View {
        GlassSurface(
            tint: presentation.accentToken.tint.opacity(0.10),
            cornerRadius: 26,
            padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: presentation.symbolName)
                        .oasisFont(size: 16, weight: .semibold, design: .default, relativeTo: .headline)
                        .foregroundStyle(presentation.accentToken.tint)
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)
                        .background {
                            Circle()
                                .fill(presentation.accentToken.tint.opacity(0.16))
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(presentation.title)
                            .oasisFont(size: 16, weight: .semibold, relativeTo: .headline)
                            .foregroundStyle(.white)

                        Text(presentation.message)
                            .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .oasisFont(size: 12, weight: .bold, design: .default, relativeTo: .caption)
                            .foregroundStyle(.white.opacity(0.70))
                            .frame(width: 28, height: 28)
                            .background {
                                Circle()
                                    .fill(Color.white.opacity(0.06))
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityLabel(Text(L10n.Presets.close))
                    .accessibilityIdentifier("premium.inline.dismiss")
                }

                HStack(spacing: 10) {
                    Button(action: onPrimaryAction) {
                        Text(presentation.primaryActionTitle)
                            .oasisFont(size: 14, weight: .bold, relativeTo: .subheadline)
                            .foregroundStyle(Color(red: 0.05, green: 0.07, blue: 0.11))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.97, green: 0.83, blue: 0.47),
                                                Color(red: 0.97, green: 0.72, blue: 0.34)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityIdentifier("premium.inline.primary")

                    if let secondaryTitle = presentation.secondaryActionTitle,
                       let onSecondaryAction {
                        Button(action: onSecondaryAction) {
                            Text(secondaryTitle)
                                .oasisFont(size: 13, weight: .semibold, relativeTo: .subheadline)
                                .foregroundStyle(.white.opacity(0.86))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                }
                        }
                        .buttonStyle(PressScaleButtonStyle())
                        .accessibilityIdentifier("premium.inline.secondary")
                    }
                }

                if let footnote = presentation.footnote {
                    Text(footnote)
                        .oasisFont(size: 11, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(.white.opacity(0.56))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("premium.inline.\(presentation.accentToken.rawValue)")
    }
}

struct PremiumHomeBannerCard: View {
    let presentation: PremiumHomeBannerPresentation
    let onPrimaryAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        GlassSurface(
            tint: SoundChannel.oiseaux.tint.opacity(0.08),
            cornerRadius: 28,
            padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        ) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(presentation.title)
                        .oasisFont(size: 17, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(.white)

                    Text(presentation.message)
                        .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onPrimaryAction) {
                        Text(presentation.ctaTitle)
                            .oasisFont(size: 13, weight: .bold, relativeTo: .subheadline)
                            .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.97, green: 0.83, blue: 0.47),
                                                Color(red: 0.97, green: 0.72, blue: 0.34)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityIdentifier("premium.banner.primary")
                }

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .oasisFont(size: 12, weight: .bold, design: .default, relativeTo: .caption)
                        .foregroundStyle(.white.opacity(0.68))
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.05))
                        }
                }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(Text(L10n.Presets.close))
                .accessibilityIdentifier("premium.banner.dismiss")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("premium.banner")
    }
}

struct PremiumLibraryTeaserCard: View {
    let presentation: PremiumLibraryTeaserPresentation
    let isExpanded: Bool
    let onPrimaryAction: () -> Void
    let onToggleExpanded: () -> Void

    var body: some View {
        GlassSurface(
            tint: SoundChannel.pluie.tint.opacity(0.08),
            cornerRadius: 24,
            padding: EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "sparkles")
                        .oasisFont(size: 16, weight: .semibold, design: .default, relativeTo: .headline)
                        .foregroundStyle(SoundChannel.pluie.tint)
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)
                        .background {
                            Circle()
                                .fill(SoundChannel.pluie.tint.opacity(0.16))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(presentation.title)
                            .oasisFont(size: 16, weight: .semibold, relativeTo: .headline)
                            .foregroundStyle(.white)

                        Text(presentation.badgeTitle)
                            .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                            .foregroundStyle(SoundChannel.pluie.tint.opacity(0.92))
                    }

                    Spacer(minLength: 0)
                }

                Text(presentation.message)
                    .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button(action: onPrimaryAction) {
                        Text(presentation.ctaTitle)
                            .oasisFont(size: 13, weight: .bold, relativeTo: .subheadline)
                            .foregroundStyle(Color(red: 0.06, green: 0.08, blue: 0.12))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.97, green: 0.83, blue: 0.47),
                                                Color(red: 0.97, green: 0.72, blue: 0.34)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityIdentifier("premium.library.teaser.primary")

                    Button(action: onToggleExpanded) {
                        Text(isExpanded ? presentation.collapseTitle : presentation.expandTitle)
                            .oasisFont(size: 12, weight: .semibold, relativeTo: .caption)
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityIdentifier("premium.library.teaser.toggle")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("premium.library.teaser")
    }
}
