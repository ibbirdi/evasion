import SwiftUI

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
    case timerUnlock

    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var headerCompactProgress: CGFloat = 0
    @State private var activePanel: ActiveHomePanel?
    @State private var activePanelSource: PanelTransitionSource?
    @State private var activeSpatialChannel: SoundChannel?
    @Namespace private var panelTransitionNamespace

    private static let headerCollapseDistance: CGFloat = 140
    private static let headerProgressSteps: CGFloat = 48

    private func openPresets(from source: PanelTransitionSource) {
        activePanelSource = source.usesZoomTransition ? source : nil
        activePanel = .presets
    }

    private func openBinaural(from source: PanelTransitionSource) {
        model.prepareBinauralPanel()
        activePanelSource = source.usesZoomTransition ? source : nil
        activePanel = .binaural
    }

    private func openSpatial(for channel: SoundChannel) {
        activePanel = nil
        activePanelSource = nil
        activeSpatialChannel = channel
    }

    private func openTimerUnlock() {
        activePanelSource = nil
        activePanel = .timerUnlock
    }

    @ViewBuilder
    private func presetsPanelView(source: PanelTransitionSource?) -> some View {
        if let source {
            PresetsPanel()
                .navigationTransition(.zoom(sourceID: source.transitionID, in: panelTransitionNamespace))
                .presentationSizing(.fitted.fitted(horizontal: false, vertical: true))
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        } else {
            PresetsPanel()
                .presentationSizing(.fitted.fitted(horizontal: false, vertical: true))
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func binauralPanelView(source: PanelTransitionSource?) -> some View {
        if let source {
            BinauralPanel()
                .navigationTransition(.zoom(sourceID: source.transitionID, in: panelTransitionNamespace))
                .presentationSizing(.fitted.fitted(horizontal: false, vertical: true))
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
        } else {
            BinauralPanel()
                .presentationSizing(.fitted.fitted(horizontal: false, vertical: true))
                .presentationContentInteraction(.resizes)
                .presentationDragIndicator(.visible)
        }
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
                            onOpenBinaural: openBinaural,
                            onOpenTimerUnlock: openTimerUnlock
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
            case .timerUnlock:
                TimerUnlockPanel()
                    .presentationDetents([.height(318)])
                    .presentationContentInteraction(.resizes)
                    .presentationDragIndicator(.visible)
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
