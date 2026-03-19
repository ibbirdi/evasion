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

    var id: String { rawValue }
}

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var scrollOffset: CGFloat = 0
    @State private var activePanel: ActiveHomePanel?
    @State private var activePanelSource: PanelTransitionSource?
    @State private var activeSpatialChannel: SoundChannel?
    @Namespace private var panelTransitionNamespace

    private func openPresets(from source: PanelTransitionSource) {
        if model.isPremium {
            activePanelSource = source.usesZoomTransition ? source : nil
            activePanel = .presets
        } else {
            withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                model.showsPaywall = true
            }
        }
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
                            max(geometry.contentOffset.y + geometry.contentInsets.top, 0)
                        },
                        action: { _, newValue in
                            scrollOffset = newValue
                        }
                    )

                    VStack(spacing: 0) {
                        HomeHeaderView(
                            scrollOffset: scrollOffset,
                            onOpenPresets: openPresets,
                            onOpenBinaural: openBinaural
                        )
                        .padding(.top, proxy.safeAreaInsets.top + 4)
                        .padding(.horizontal, 18)

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
                if let source = activePanelSource {
                    PresetsPanel()
                        .navigationTransition(.zoom(sourceID: source.transitionID, in: panelTransitionNamespace))
                        .presentationDetents([.medium, .large])
                        .presentationContentInteraction(.scrolls)
                        .presentationDragIndicator(.visible)
                } else {
                    PresetsPanel()
                        .presentationDetents([.medium, .large])
                        .presentationContentInteraction(.scrolls)
                        .presentationDragIndicator(.visible)
                }
            case .binaural:
                if let source = activePanelSource {
                    BinauralPanel()
                        .navigationTransition(.zoom(sourceID: source.transitionID, in: panelTransitionNamespace))
                        .presentationDetents([.height(396)])
                        .presentationContentInteraction(.resizes)
                        .presentationDragIndicator(.visible)
                } else {
                    BinauralPanel()
                        .presentationDetents([.height(396)])
                        .presentationContentInteraction(.resizes)
                        .presentationDragIndicator(.visible)
                }
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
        .fullScreenCover(isPresented: $model.showsPaywall) {
            PaywallOverlay()
        }
        .onChange(of: activePanel) { _, panel in
            model.showsPresetsPanel = panel == .presets
            model.showsBinauralPanel = panel == .binaural
        }
        .onChange(of: activeSpatialChannel) { _, channel in
            model.showsSpatialPanel = channel != nil
        }
        .preferredColorScheme(.dark)
        .task {
            model.bootstrapIfNeeded()
        }
    }
}
