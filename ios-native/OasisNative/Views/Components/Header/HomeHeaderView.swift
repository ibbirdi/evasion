import SwiftUI
import UIKit

struct HomeHeaderView: View {
    let scrollOffset: CGFloat
    let onOpenPresets: (PanelTransitionSource) -> Void
    let onOpenBinaural: (PanelTransitionSource) -> Void

    private var compactProgress: CGFloat {
        min(max(scrollOffset / 140, 0), 1)
    }

    private var logoVisibility: CGFloat {
        max(0, 1 - (compactProgress * 3.4))
    }

    var body: some View {
        VStack(spacing: max(6, 9 - (compactProgress * 4))) {
            BrandLockupView(visibility: logoVisibility)

            QuickControlsStrip(
                onOpenPresets: onOpenPresets,
                onOpenBinaural: onOpenBinaural
            )
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .animation(.smooth(duration: 0.22), value: compactProgress)
    }
}

private struct BrandLockupView: View {
    @Environment(AppModel.self) private var model
    let visibility: CGFloat

    private static let cachedLogo: UIImage? = {
        guard let url = Bundle.main.url(forResource: "oasisLogo", withExtension: "png"),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        return image
    }()

    private var bundleLogo: UIImage? {
        Self.cachedLogo
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            if let logo = bundleLogo {
                Image(uiImage: logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132)
                    .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
            } else {
                Text(model.copy.header.title)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74 * visibility, alignment: .top)
        .opacity(visibility)
        .scaleEffect(0.92 + (visibility * 0.08), anchor: .top)
        .clipped()
        .animation(.smooth(duration: 0.18), value: visibility)
    }
}

private struct QuickControlsStrip: View {
    @Environment(AppModel.self) private var model
    let onOpenPresets: (PanelTransitionSource) -> Void
    let onOpenBinaural: (PanelTransitionSource) -> Void

    var body: some View {
        HStack(spacing: 7) {
            presetChip
                .frame(maxWidth: .infinity)

            binauralChip
                .frame(maxWidth: .infinity)

            TimerChip()

            ActiveChannelsChip()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var presetChip: some View {
        let isPresetActive = model.activePreset != nil

        return Button {
            onOpenPresets(.headerPresets)
        } label: {
            PanelTriggerChip(
                symbol: model.activePreset == nil ? "bookmark" : "bookmark.fill",
                title: model.activePreset.map(model.presetDisplayName) ?? model.copy.modal.title,
                tint: isPresetActive ? LiquidActivityPalette.preset[0] : .white,
                isActivated: isPresetActive,
                palette: LiquidActivityPalette.preset
            )
        }
        .accessibilityIdentifier("home.header.presets")
        .buttonStyle(PressScaleButtonStyle())
    }

    private var binauralChip: some View {
        let isBinauralActive = model.isBinauralActive

        return Button {
            onOpenBinaural(.headerBinaural)
        } label: {
            PanelTriggerChip(
                symbol: model.isBinauralActive ? "waveform.path.ecg" : "waveform.path",
                title: model.copy.binaural[model.activeBinauralTrack],
                tint: isBinauralActive ? model.activeBinauralTrack.tint : .white.opacity(0.84),
                isActivated: isBinauralActive,
                palette: LiquidActivityPalette.binaural(for: model.activeBinauralTrack.tint)
            )
        }
        .accessibilityIdentifier("home.header.binaural")
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct TimerChip: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.isPremium {
            Menu {
                timerAction(model.copy.header.off, minutes: nil)
                timerAction("15 min", minutes: 15)
                timerAction("30 min", minutes: 30)
                timerAction("1h", minutes: 60)
                timerAction("2h", minutes: 120)
            } label: {
                HeaderChipLabel(
                    symbol: "timer",
                    title: model.timerToolbarTitle,
                    tint: model.timerDurationMinutes == nil
                        ? .white.opacity(0.82)
                        : Color(red: 0.52, green: 0.91, blue: 0.64),
                    expands: false
                )
            }
            .menuIndicator(.hidden)
            .accessibilityIdentifier("home.header.timer")
        } else {
            Button {
                withAnimation(.smooth(duration: 0.22)) {
                    model.showsPaywall = true
                }
            } label: {
                HeaderChipLabel(
                    symbol: "timer",
                    title: model.copy.header.timer,
                    tint: .white.opacity(0.82),
                    expands: false
                )
            }
            .accessibilityIdentifier("home.header.timer")
            .buttonStyle(PressScaleButtonStyle())
        }
    }

    private func timerAction(_ title: String, minutes: Int?) -> some View {
        Button(title) {
            withAnimation(.smooth(duration: 0.22)) {
                model.setTimer(minutes)
            }
        }
    }
}

private struct ActiveChannelsChip: View {
    @Environment(AppModel.self) private var model

    private var isActivated: Bool {
        model.showsOnlyActiveChannels
    }

    private var tint: Color {
        if isActivated {
            return Color(red: 0.54, green: 0.88, blue: 0.70)
        }

        return Color.white.opacity(0.82)
    }

    private var symbol: String {
        if isActivated {
            return "line.3.horizontal.decrease.circle.fill"
        }

        return "line.3.horizontal.circle"
    }

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.26, extraBounce: 0.02)) {
                model.showsOnlyActiveChannels.toggle()
            }
        } label: {
            HeaderChipLabel(
                symbol: symbol,
                title: "\(model.activeAmbientChannelsCount)",
                tint: tint,
                isActivated: isActivated,
                expands: false
            )
        }
        .accessibilityIdentifier("home.header.active-filter")
        .buttonStyle(PressScaleButtonStyle())
    }
}

private struct HeaderChipLabel: View {
    let symbol: String
    let title: String
    let tint: Color
    var isActivated = false
    var expands = true

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: expands ? .infinity : nil)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    Capsule()
                        .fill(isActivated ? tint.opacity(0.18) : Color.white.opacity(0.02))
                }
        }
        .overlay {
            Capsule()
                .strokeBorder(isActivated ? tint.opacity(0.30) : Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: isActivated ? tint.opacity(0.06) : .clear, radius: 8, y: 2)
        .fixedSize(horizontal: !expands, vertical: false)
        .animation(.smooth(duration: 0.22), value: isActivated)
    }
}

private struct PanelTriggerChip: View {
    let symbol: String
    let title: String
    let tint: Color
    let isActivated: Bool
    let palette: [Color]

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)

            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .contentTransition(.numericText(countsDown: true))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.001))
                .glassEffect(.regular, in: Capsule())
                .overlay {
                    Capsule()
                        .fill(
                            isActivated ? tint.opacity(0.18) : Color.white.opacity(0.018)
                        )
                }
        }
        .overlay {
            Capsule()
                .strokeBorder(activeBorderStyle, lineWidth: 1.15)
        }
        .shadow(color: isActivated ? tint.opacity(0.04) : .clear, radius: 8, y: 2)
        .animation(.smooth(duration: 0.22), value: isActivated)
    }

    private var activeBorderStyle: AnyShapeStyle {
        if isActivated {
            AnyShapeStyle(tint.opacity(0.34))
        } else {
            AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
}
