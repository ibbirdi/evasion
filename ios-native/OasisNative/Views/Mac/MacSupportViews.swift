import Observation
import SwiftUI

#if os(macOS)
import AppKit
import AVKit
#endif

enum MacPanelLayout {
    static let contentSize = CGSize(width: 560, height: 780)
    static let popoverArrowHeight: CGFloat = 12
    static let popoverArrowWidth: CGFloat = 24
    static let idealSize = CGSize(
        width: contentSize.width,
        height: contentSize.height + popoverArrowHeight
    )
    static let cornerRadius: CGFloat = 22
    static let screenMargin: CGFloat = 12
    static let statusItemGap: CGFloat = 4
    static let defaultArrowX: CGFloat = contentSize.width - 38
}

enum MacDesign {
    static let accent = Color(red: 0.64, green: 0.86, blue: 0.82)
}

@Observable
final class MacPanelChromeState {
    var arrowX: CGFloat = MacPanelLayout.defaultArrowX
}

enum MacPanelSection: String, CaseIterable, Identifiable {
    case mixer
    case presets
    case binaural

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .mixer:
            return L10n.Mac.mixer
        case .presets:
            return L10n.Presets.panelTitle
        case .binaural:
            return L10n.Binaural.title
        }
    }

    var systemImage: String {
        switch self {
        case .mixer:
            return "slider.horizontal.3"
        case .presets:
            return "bookmark.fill"
        case .binaural:
            return "waveform.path"
        }
    }
}

struct MacPanelPopoverShape: Shape {
    var arrowX: CGFloat

    var animatableData: CGFloat {
        get { arrowX }
        set { arrowX = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let arrowHeight = min(MacPanelLayout.popoverArrowHeight, rect.height * 0.20)
        let arrowHalfWidth = MacPanelLayout.popoverArrowWidth / 2
        let body = CGRect(
            x: rect.minX,
            y: rect.minY + arrowHeight,
            width: rect.width,
            height: rect.height - arrowHeight
        )
        let radius = min(MacPanelLayout.cornerRadius, body.width / 2, body.height / 2)
        let clampedArrowX = min(
            max(arrowX, body.minX + radius + arrowHalfWidth),
            body.maxX - radius - arrowHalfWidth
        )

        var path = Path()
        path.move(to: CGPoint(x: body.minX + radius, y: body.minY))
        path.addLine(to: CGPoint(x: clampedArrowX - arrowHalfWidth, y: body.minY))
        path.addLine(to: CGPoint(x: clampedArrowX, y: rect.minY))
        path.addLine(to: CGPoint(x: clampedArrowX + arrowHalfWidth, y: body.minY))
        path.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY))
        path.addQuadCurve(
            to: CGPoint(x: body.maxX, y: body.minY + radius),
            control: CGPoint(x: body.maxX, y: body.minY)
        )
        path.addLine(to: CGPoint(x: body.maxX, y: body.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: body.maxX - radius, y: body.maxY),
            control: CGPoint(x: body.maxX, y: body.maxY)
        )
        path.addLine(to: CGPoint(x: body.minX + radius, y: body.maxY))
        path.addQuadCurve(
            to: CGPoint(x: body.minX, y: body.maxY - radius),
            control: CGPoint(x: body.minX, y: body.maxY)
        )
        path.addLine(to: CGPoint(x: body.minX, y: body.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: body.minX + radius, y: body.minY),
            control: CGPoint(x: body.minX, y: body.minY)
        )
        path.closeSubpath()
        return path
    }
}

extension View {
    @ViewBuilder
    func macLiquidGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if interactive {
                glassEffect(.regular.interactive(), in: shape)
            } else {
                glassEffect(.regular, in: shape)
            }
        } else {
            background(.regularMaterial, in: shape)
        }
    }
}

struct MacPanelBackground: View {
    var arrowX: CGFloat?

    var body: some View {
        if let arrowX {
            background(shape: MacPanelPopoverShape(arrowX: arrowX))
        } else {
            background(shape: RoundedRectangle(cornerRadius: MacPanelLayout.cornerRadius, style: .continuous))
        }
    }

    private func background<S: Shape>(shape: S) -> some View {
        shape
            .fill(Color(red: 0.020, green: 0.024, blue: 0.032).opacity(0.30))
            .background(.ultraThinMaterial, in: shape)
            .overlay {
                LinearGradient(
                    colors: [
                        Color(red: 0.052, green: 0.061, blue: 0.075).opacity(0.24),
                        Color(red: 0.020, green: 0.024, blue: 0.034).opacity(0.36)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(shape)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                .clipShape(shape)
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
            .ignoresSafeArea()
    }
}

struct MacPanelSurface<Content: View>: View {
    let padding: EdgeInsets
    @ViewBuilder let content: Content

    init(
        padding: EdgeInsets = EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14),
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .macLiquidGlass(in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .background(Color.white.opacity(0.025), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct MacSectionTitle: View {
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource?

    init(_ title: LocalizedStringResource, subtitle: LocalizedStringResource? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MacStatusBadge: View {
    let text: LocalizedStringResource
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

struct MacIconButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringResource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.86))
        .macLiquidGlass(in: RoundedRectangle(cornerRadius: 7, style: .continuous), interactive: true)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

#if os(macOS)
struct MacRoutePickerButton: View {
    private let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)

    var body: some View {
        MacRoutePickerControl(
            normalColor: NSColor.white.withAlphaComponent(0.86),
            highlightedColor: NSColor.white.withAlphaComponent(0.95),
            activeColor: NSColor(
                calibratedRed: 0.64,
                green: 0.86,
                blue: 0.82,
                alpha: 1.0
            )
        )
        .frame(width: 28, height: 28)
        .contentShape(Rectangle())
        .macLiquidGlass(in: shape, interactive: true)
        .background(Color.white.opacity(0.045), in: shape)
        .accessibilityLabel(Text(L10n.HomeControls.routePicker))
        .help(L10n.string(L10n.HomeControls.routePicker))
    }
}

private struct MacRoutePickerControl: NSViewRepresentable {
    let normalColor: NSColor
    let highlightedColor: NSColor
    let activeColor: NSColor

    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView(frame: .zero)
        applyConfiguration(to: view)
        return view
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
        applyConfiguration(to: nsView)
    }

    private func applyConfiguration(to view: AVRoutePickerView) {
        view.isRoutePickerButtonBordered = false
        view.setRoutePickerButtonColor(normalColor, for: .normal)
        view.setRoutePickerButtonColor(highlightedColor, for: .normalHighlighted)
        view.setRoutePickerButtonColor(activeColor, for: .active)
        view.setRoutePickerButtonColor(activeColor.withAlphaComponent(0.95), for: .activeHighlighted)
    }
}
#endif

struct MacPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(red: 0.035, green: 0.045, blue: 0.060))
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.83, blue: 0.45),
                        Color(red: 0.95, green: 0.70, blue: 0.34)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .brightness(configuration.isPressed ? -0.05 : 0)
    }
}

extension SoundCategory {
    var macTitle: String {
        switch self {
        case .water:
            return "Water"
        case .weather:
            return "Weather"
        case .forest:
            return "Forest"
        case .wildlife:
            return "Wildlife"
        case .human:
            return "Places"
        case .fire:
            return "Fire"
        case .shelter:
            return "Shelter"
        }
    }
}

extension PremiumAccentToken {
    var macTint: Color {
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

#if os(macOS)
enum MacApplicationCommands {
    @MainActor
    static func quit() {
        NSApplication.shared.terminate(nil)
    }
}
#endif
