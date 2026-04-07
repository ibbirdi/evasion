import SwiftUI
import UIKit

private let minimumAdaptivePanelHeight: CGFloat = 240

enum PanelTransitionSource: String, Hashable, Sendable {
    case headerPresets
    case bottomPresets
    case headerBinaural
    case bottomBinaural

    var transitionID: String { rawValue }

    var usesZoomTransition: Bool {
        switch self {
        case .bottomPresets, .bottomBinaural:
            true
        case .headerPresets, .headerBinaural:
            false
        }
    }
}

private enum ActiveHomePanel: String, Identifiable {
    case presets
    case binaural

    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var headerCompactProgress: CGFloat = 0
    @State private var activePanel: ActiveHomePanel?
    @State private var activePanelSource: PanelTransitionSource?
    @State private var activeSpatialChannel: SoundChannel?
    @State private var presetsPanelHeight: CGFloat = 360
    @State private var binauralPanelHeight: CGFloat = 360
    @Namespace private var panelTransitionNamespace

    private static let headerCollapseDistance: CGFloat = 140
    private static let headerProgressSteps: CGFloat = 48
    private func openPresets(from source: PanelTransitionSource) {
        presetsPanelHeight = measurePanelHeight(for: PresetsPanel().environment(model))
        activePanelSource = source.usesZoomTransition ? source : nil
        activePanel = .presets
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
        activeSpatialChannel = channel
    }

    @ViewBuilder
    private func presetsPanelView(source: PanelTransitionSource?) -> some View {
        if let source {
            PresetsPanel()
                .navigationTransition(.zoom(sourceID: source.transitionID, in: panelTransitionNamespace))
                .adaptiveSheetDetent($presetsPanelHeight)
                .presentationDetents([.height(presetsPanelHeight)])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        } else {
            PresetsPanel()
                .adaptiveSheetDetent($presetsPanelHeight)
                .presentationDetents([.height(presetsPanelHeight)])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func binauralPanelView(source: PanelTransitionSource?) -> some View {
        if let source {
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
                            MixerBoardSectionView(onOpenSpatial: openSpatial)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, proxy.safeAreaInsets.top + 156)
                        .padding(.bottom, 110)
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .accessibilityIdentifier("home.scroll")
                    .scrollIndicators(.hidden)
                    .scrollBounceBehavior(.basedOnSize)
                    .onScrollGeometryChange(
                        for: CGFloat.self,
                        of: { geometry in
                            let offset = max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
                            let rawProgress = min(max(offset / Self.headerCollapseDistance, 0), 1)
                            return (rawProgress * Self.headerProgressSteps).rounded() / Self.headerProgressSteps
                        },
                        action: { _, newValue in
                            headerCompactProgress = newValue
                        }
                    )

                    VStack(spacing: 0) {
                        HomeHeaderView(
                            compactProgress: headerCompactProgress,
                            onOpenPresets: openPresets,
                            onOpenBinaural: openBinaural
                        )
                        .padding(.top, proxy.safeAreaInsets.top + 4)
                        .padding(.horizontal, 8)

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color.clear)
                .ignoresSafeArea()
                .ignoresSafeArea(.keyboard)
                .safeAreaBar(edge: .bottom, spacing: 0) {
                    BottomBarView(
                        transitionNamespace: panelTransitionNamespace,
                        onOpenPresets: openPresets,
                        onOpenBinaural: openBinaural
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 2)
                    .padding(.bottom, -10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $activePanel, onDismiss: {
            activePanelSource = nil
        }) { panel in
            switch panel {
            case .presets:
                presetsPanelView(source: activePanelSource)
            case .binaural:
                binauralPanelView(source: activePanelSource)
            }
        }
        .sheet(item: $activeSpatialChannel, onDismiss: {
            model.showsSpatialPanel = false
        }) { channel in
            SpatialAudioPanel(channel: channel)
                .presentationDetents([.height(460)])
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $model.activePaywallContext, onDismiss: {
            model.dismissPaywall()
        }) { context in
            PaywallOverlay(context: context)
        }
        .onChange(of: activePanel) { _, panel in
            model.showsPresetsPanel = panel == .presets
            model.showsBinauralPanel = panel == .binaural
        }
        .onChange(of: activeSpatialChannel) { _, channel in
            model.showsSpatialPanel = channel != nil
        }
        .onChange(of: model.activePaywallContext?.id) { _, paywallID in
            guard paywallID != nil else { return }

            activePanel = nil
            activePanelSource = nil
            activeSpatialChannel = nil
        }
        .task {
            model.bootstrapIfNeeded()
        }
    }
}

private struct AdaptiveSheetDetentModifier: ViewModifier {
    @Binding var detentHeight: CGFloat

    func body(content: Content) -> some View {
        content.onGeometryChange(for: CGFloat.self, of: { proxy in
            proxy.size.height
        }) { _, newHeight in
            guard newHeight.isFinite, newHeight > 44 else { return }

            let targetHeight = max(minimumAdaptivePanelHeight, ceil(newHeight))
            guard abs(detentHeight - targetHeight) > 1 else { return }

            detentHeight = targetHeight
        }
    }
}

private extension View {
    func adaptiveSheetDetent(_ detentHeight: Binding<CGFloat>) -> some View {
        modifier(AdaptiveSheetDetentModifier(detentHeight: detentHeight))
    }
}
