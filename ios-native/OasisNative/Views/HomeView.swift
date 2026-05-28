import SwiftUI
import UIKit

private let minimumAdaptivePanelHeight: CGFloat = 240

enum PanelTransitionSource: String, Hashable, Sendable {
    case bottomCompose
    case headerBinaural
    case bottomBinaural

    var transitionID: String { rawValue }

    var usesZoomTransition: Bool {
        switch self {
        case .bottomCompose, .bottomBinaural:
            true
        case .headerBinaural:
            false
        }
    }
}

private enum ActiveHomePanel: String, Identifiable {
    case binaural

    var id: String { rawValue }
}

private struct HomeTopRitualIndicator: View {
    @Environment(AppModel.self) private var model
    let session: ActiveRitualSession
    let action: () -> Void

    private var tint: Color {
        session.intent.tint
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let progress = session.phaseProgress(at: timeline.date)
            let remainingMinutes = session.totalRemainingMinutes(at: timeline.date)

            Button(action: action) {
                VStack(spacing: 4) {
                    HStack(spacing: 10) {
                        OasisGlyphImage(glyph: session.intent.oasisGlyph)
                            .foregroundStyle(tint)
                            .frame(width: 12, height: 12)
                            .accessibilityHidden(true)

                        Text(session.phaseTitle)
                            .oasisFont(size: 11, weight: .semibold, relativeTo: .caption)
                            .foregroundStyle(.white.opacity(0.90))
                            .lineLimit(1)
                            .minimumScaleFactor(0.84)

                        Spacer(minLength: 4)

                        if model.isPlaying {
                            Text("\(remainingMinutes)m")
                                .oasisFont(size: 10, weight: .semibold, relativeTo: .caption2)
                                .foregroundStyle(.white.opacity(0.68))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        } else {
                            Text(L10n.HomeControls.pause)
                                .oasisFont(size: 9, weight: .bold, relativeTo: .caption2)
                                .foregroundStyle(tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule().fill(tint.opacity(0.13))
                                }
                                .overlay {
                                    Capsule().strokeBorder(tint.opacity(0.20), lineWidth: 1)
                                }
                                .layoutPriority(1)
                        }
                    }

                    HomeRitualPillProgress(progress: progress, tint: tint)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(width: 152)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.001))
                        .oasisGlassEffect(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(red: 0.04, green: 0.06, blue: 0.11).opacity(0.36))
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(tint.opacity(0.22), lineWidth: 1)
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityIdentifier("home.ritual.active")
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(accessibilityLabel(remainingMinutes: remainingMinutes)))
        }
    }

    private func accessibilityLabel(remainingMinutes: Int) -> String {
        let base = "\(L10n.string(L10n.Compose.activeRitual)), \(session.ritualTitle), \(session.phaseTitle)"
        if model.isPlaying {
            return "\(base), \(remainingMinutes) min"
        }
        return "\(base), \(L10n.string(L10n.Compose.pausedRitual)), \(remainingMinutes) min"
    }
}

private struct HomeRitualPillProgress: View {
    let progress: Double
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(tint.opacity(0.72))
                    .frame(width: max(proxy.size.width * progress, 5))
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var headerCompactProgress: CGFloat = 0
    @State private var activePanel: ActiveHomePanel?
    @State private var activePanelSource: PanelTransitionSource?
    @State private var showsComposeFullScreen = false
    @State private var activeSpatialChannel: SoundChannel?
    @State private var activeDetailChannel: SoundChannel?
    @State private var showsTimerUnlockPanel = false
    @State private var binauralPanelHeight: CGFloat = 360
    @Namespace private var panelTransitionNamespace

    fileprivate static let headerCollapseDistance: CGFloat = 140
    fileprivate static let headerProgressSteps: CGFloat = 48
    private func openCompose(from source: PanelTransitionSource) {
        showsComposeFullScreen = true
        activeSpatialChannel = nil
        activeDetailChannel = nil
        showsTimerUnlockPanel = false
        activePanelSource = nil
        activePanel = nil
    }

    private func openBinaural(from source: PanelTransitionSource) {
        model.prepareBinauralPanel()
        binauralPanelHeight = measurePanelHeight(for: BinauralPanel().environment(model))
        activePanelSource = source.usesZoomTransition ? source : nil
        activePanel = .binaural
    }

    private func openSpatial(for channel: SoundChannel) {
        activePanel = nil
        activePanelSource = nil
        activeDetailChannel = nil
        activeSpatialChannel = channel
    }

    private func openDetail(for channel: SoundChannel) {
        activePanel = nil
        activePanelSource = nil
        activeSpatialChannel = nil
        activeDetailChannel = channel
    }

    private func openTimerUnlock() {
        activePanel = nil
        activePanelSource = nil
        activeSpatialChannel = nil
        showsTimerUnlockPanel = true
    }

    @ViewBuilder
    private func binauralPanelView(source: PanelTransitionSource?) -> some View {
        if let source, #available(iOS 26.0, *) {
            BinauralPanel()
                .navigationTransition(.zoom(sourceID: source.transitionID, in: panelTransitionNamespace))
                .adaptiveSheetDetent($binauralPanelHeight)
                .presentationDetents([.height(binauralPanelHeight)])
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
        } else {
            BinauralPanel()
                .adaptiveSheetDetent($binauralPanelHeight)
                .presentationDetents([.height(binauralPanelHeight)])
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
        }
    }

    @MainActor
    private func measurePanelHeight<Content: View>(for content: Content) -> CGFloat {
        let width = currentWindowWidth()
        let host = UIHostingController(rootView: content)
        host.view.backgroundColor = .clear
        host.view.bounds = CGRect(x: 0, y: 0, width: width, height: 1)

        let fittedSize = host.sizeThatFits(
            in: CGSize(width: width, height: UIView.layoutFittingExpandedSize.height)
        )

        return detentHeight(for: fittedSize.height)
    }

    @MainActor
    private func currentWindowWidth() -> CGFloat {
        let activeScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }

        let keyWindow = activeScenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)

        let fallbackWindow = activeScenes
            .flatMap(\.windows)
            .first

        let window = keyWindow ?? fallbackWindow
        let width = window?.bounds.width ?? activeScenes.first?.screen.bounds.width ?? 390

        return max(width, 320)
    }

    private func detentHeight(for contentHeight: CGFloat) -> CGFloat {
        max(minimumAdaptivePanelHeight, ceil(contentHeight))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    AnimatedBackdrop()

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            MixerBoardSectionView(
                                onOpenSpatial: openSpatial,
                                onOpenDetail: openDetail
                            )
                        }
                        .padding(.horizontal, 0)
                        // Header has a generous visual box for the ring glow, but the
                        // scroll inset stays tight so the mixer does not feel pushed down.
                        .padding(.top, proxy.safeAreaInsets.top + 96)
                        .padding(.bottom, 110)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .accessibilityIdentifier("home.scroll")
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .headerCompactProgress($headerCompactProgress)

                    VStack(spacing: 0) {
                        HomeHeaderView(compactProgress: headerCompactProgress)
                        // Keep the ring above the first mixer card while preserving
                        // the tight scroll inset underneath it.
                        .padding(.top, max(0, proxy.safeAreaInsets.top - 34 - (headerCompactProgress * 14)))
                        .padding(.horizontal, 8)

                        Spacer(minLength: 0)

                        // Subtle dark gradient fading up from the bottom edge, used to make
                        // the floating toolbar readable on any backdrop colour. Non-interactive
                        // so scrolling and taps pass straight through to the content below.
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.48),
                                Color.black.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 180)
                        .allowsHitTesting(false)
                    }
                    .ignoresSafeArea(edges: .bottom)

                    // Passive timer feedback, centered horizontally at the nav-bar's
                    // vertical line while no ambience or ritual owns that space.
                    VStack(spacing: 0) {
                        if model.activeRitualSession == nil && model.activeComposerRecipeTitle == nil {
                            TimerCountdownIndicator()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: 44)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.top, max(0, proxy.safeAreaInsets.top - 52))
                    .allowsHitTesting(false)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.clear)
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)
                .oasisBottomBar(spacing: 0) {
                    BottomBarView(
                        transitionNamespace: panelTransitionNamespace,
                        onOpenCompose: openCompose,
                        onOpenBinaural: openBinaural
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 2)
                    .padding(.bottom, -10)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HomeToolbarImmersiveAudioToggle()
                }
                ToolbarItem(placement: .principal) {
                    if let session = model.activeRitualSession {
                        HomeTopRitualIndicator(session: session) {
                            openCompose(from: .bottomCompose)
                        }
                    } else if model.activeComposerRecipeTitle != nil {
                        HomeAmbienceStatusIndicator {
                            openCompose(from: .bottomCompose)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HomeToolbarTimerMenu(onRequestPremiumTimer: openTimerUnlock)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if model.activeComposerRecipeTitle == nil {
                        HomeToolbarActiveFilter()
                    }
                }
            }
        }
        .sheet(item: $activePanel, onDismiss: {
            activePanelSource = nil
        }) { panel in
            switch panel {
            case .binaural:
                binauralPanelView(source: activePanelSource)
            }
        }
        .fullScreenCover(isPresented: $showsComposeFullScreen, onDismiss: {
            model.showsComposePanel = false
        }) {
            ComposePanel()
        }
        .sheet(item: $activeSpatialChannel, onDismiss: {
            model.showsSpatialPanel = false
        }) { channel in
            SpatialAudioPanel(channel: channel)
                .presentationDetents([.height(520)])
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $activeDetailChannel) { channel in
            // In screenshot automation the sheet opens directly at `.large` so the full
            // detail content is visible in the App Store capture. Real users keep the
            // `.medium` default with `.large` as a drag-up option.
            let detents: Set<PresentationDetent> = AppConfiguration.isRunningScreenshotAutomation
                ? [.large]
                : [.medium, .large]
            SoundDetailSheet(channel: channel)
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showsTimerUnlockPanel) {
            TimerUnlockPanel()
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $model.activePaywallContext, onDismiss: {
            model.dismissPaywall()
        }) { context in
            PaywallOverlay(context: context)
        }
        .onChange(of: activePanel) { _, panel in
            model.showsBinauralPanel = panel == .binaural
        }
        .onChange(of: showsComposeFullScreen) { _, isPresented in
            model.showsComposePanel = isPresented
        }
        .onChange(of: activeSpatialChannel) { _, channel in
            model.showsSpatialPanel = channel != nil
        }
        .onChange(of: model.activePaywallContext?.id) { _, paywallID in
            guard paywallID != nil else { return }

            activePanel = nil
            activePanelSource = nil
            showsComposeFullScreen = false
            activeSpatialChannel = nil
            activeDetailChannel = nil
            showsTimerUnlockPanel = false
        }
        .task {
            model.bootstrapIfNeeded()
        }
    }
}

private struct AdaptiveSheetDetentModifier: ViewModifier {
    @Binding var detentHeight: CGFloat

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: AdaptiveSheetHeightPreferenceKey.self,
                        value: proxy.size.height
                    )
                }
            }
            .onPreferenceChange(AdaptiveSheetHeightPreferenceKey.self) { newHeight in
                guard newHeight.isFinite, newHeight > 44 else { return }

                let targetHeight = max(minimumAdaptivePanelHeight, ceil(newHeight))
                guard abs(detentHeight - targetHeight) > 1 else { return }

                detentHeight = targetHeight
            }
    }
}

private struct AdaptiveSheetHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct HeaderCompactProgressModifier: ViewModifier {
    @Binding var progress: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.onScrollGeometryChange(
                for: CGFloat.self,
                of: { geometry in
                    let offset = max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
                    let rawProgress = min(max(offset / HomeView.headerCollapseDistance, 0), 1)
                    return (rawProgress * HomeView.headerProgressSteps).rounded() / HomeView.headerProgressSteps
                },
                action: { _, newValue in
                    progress = newValue
                }
            )
        } else {
            content
        }
    }
}

private extension View {
    func adaptiveSheetDetent(_ detentHeight: Binding<CGFloat>) -> some View {
        modifier(AdaptiveSheetDetentModifier(detentHeight: detentHeight))
    }

    func headerCompactProgress(_ progress: Binding<CGFloat>) -> some View {
        modifier(HeaderCompactProgressModifier(progress: progress))
    }

    // `safeAreaInset` reserves bottom space without adding any implicit glass container.
    // On iOS 26+, `safeAreaBar` would add its own Liquid Glass layer beneath the toolbar,
    // which then double-stacks with the per-button `oasisGlassEffect` and flattens the
    // blur. Mirroring what the top header does (just a padded VStack, no container) keeps
    // the glass quality consistent across top and bottom toolbars.
    func oasisBottomBar<Content: View>(
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: spacing, content: content)
    }
}
