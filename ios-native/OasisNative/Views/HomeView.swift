import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var scrollOffset: CGFloat = 0
    @Namespace private var panelTransition
    @State private var activePanelSource: PanelSource?

    private enum PanelSource: String {
        case headerPresets
        case headerBinaural
        case dockPresets
        case dockBinaural

        var edge: Edge {
            switch self {
            case .headerPresets, .headerBinaural:
                return .top
            case .dockPresets, .dockBinaural:
                return .bottom
            }
        }

        var transitionID: String { rawValue }
    }

    private func dismissCompactPanels() {
        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
            model.showsBinauralPanel = false
            model.showsPresetsPanel = false
            activePanelSource = nil
        }
    }

    private func openPresets(from source: PanelSource) {
        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
            if model.showsPresetsPanel, activePanelSource == source {
                dismissCompactPanels()
                return
            }
            activePanelSource = source
            model.openPresetsPanel()
        }
    }

    private func openBinaural(from source: PanelSource) {
        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
            if model.showsBinauralPanel, activePanelSource == source {
                dismissCompactPanels()
                return
            }
            activePanelSource = source
            model.openBinauralPanel()
        }
    }

    private var showsPaywallSheet: Binding<Bool> {
        Binding(
            get: { model.showsPaywall },
            set: {
                model.showsPaywall = $0
                if !$0 {
                    model.purchaseErrorMessage = nil
                }
            }
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AnimatedBackdrop()

                ScrollView {
                    LazyVStack(spacing: 8) {
                        MixerBoardSectionView()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, proxy.safeAreaInsets.top + 126)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 104)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
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
                        onOpenPresets: { openPresets(from: .headerPresets) },
                        onOpenBinaural: { openBinaural(from: .headerBinaural) },
                        presetSourceID: PanelSource.headerPresets.transitionID,
                        binauralSourceID: PanelSource.headerBinaural.transitionID,
                        activeSourceID: activePanelSource?.transitionID,
                        panelTransition: panelTransition
                    )
                    .environmentObject(model)
                    .padding(.top, proxy.safeAreaInsets.top + 4)
                    .padding(.horizontal, 18)

                    Spacer(minLength: 0)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    BottomBarView(
                        onOpenPresets: { openPresets(from: .dockPresets) },
                        onOpenBinaural: { openBinaural(from: .dockBinaural) },
                        presetSourceID: PanelSource.dockPresets.transitionID,
                        binauralSourceID: PanelSource.dockBinaural.transitionID,
                        activeSourceID: activePanelSource?.transitionID,
                        panelTransition: panelTransition
                    )
                    .environmentObject(model)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom - 2, 10))
                }
                .padding(.horizontal, 18)

                if model.showsPresetsPanel || model.showsBinauralPanel {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissCompactPanels()
                        }
                        .zIndex(2)
                }

                if model.showsPresetsPanel, let activePanelSource {
                    ContextPanelOverlay(
                        edge: activePanelSource.edge,
                        topInset: proxy.safeAreaInsets.top + 108,
                        bottomInset: max(proxy.safeAreaInsets.bottom, 12) + 82
                    ) {
                        PresetsPanel(
                            sourceID: activePanelSource.transitionID,
                            panelTransition: panelTransition
                        )
                        .environmentObject(model)
                    }
                    .zIndex(3)
                }

                if model.showsBinauralPanel, let activePanelSource {
                    ContextPanelOverlay(
                        edge: activePanelSource.edge,
                        topInset: proxy.safeAreaInsets.top + 108,
                        bottomInset: max(proxy.safeAreaInsets.bottom, 12) + 82
                    ) {
                        BinauralPanel(
                            sourceID: activePanelSource.transitionID,
                            panelTransition: panelTransition
                        )
                        .environmentObject(model)
                    }
                    .zIndex(4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.clear)
            .ignoresSafeArea()
            .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: showsPaywallSheet) {
            PaywallOverlay()
                .environmentObject(model)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(36)
                .presentationBackground(.clear)
        }
        .preferredColorScheme(.dark)
        .animation(.snappy(duration: 0.28), value: model.isPlaying)
        .task {
            model.bootstrapIfNeeded()
        }
    }
}
