import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var scrollOffset: CGFloat = 0

    private var showsPresetsSheet: Binding<Bool> {
        Binding(
            get: { model.showsPresetsPanel },
            set: { newValue in
                model.showsPresetsPanel = newValue
            }
        )
    }

    private var showsBinauralSheet: Binding<Bool> {
        Binding(
            get: { model.showsBinauralPanel },
            set: { newValue in
                model.showsBinauralPanel = newValue
            }
        )
    }

    private func openPresets() {
        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
            model.openPresetsPanel()
        }
    }

    private func openBinaural() {
        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
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
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    AnimatedBackdrop()

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            MixerBoardSectionView()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, proxy.safeAreaInsets.top + 156)
                        .padding(.bottom, 110)
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
        .sheet(isPresented: showsPresetsSheet) {
            PresetsPanel()
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
                .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: showsBinauralSheet) {
            BinauralPanel()
                .presentationDetents([.height(378), .medium])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
                .presentationBackground(.thinMaterial)
        }
        .sheet(isPresented: showsPaywallSheet) {
            PaywallOverlay()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(36)
                .presentationBackground(.clear)
        }
        .preferredColorScheme(.dark)
        .task {
            model.bootstrapIfNeeded()
        }
    }
}
