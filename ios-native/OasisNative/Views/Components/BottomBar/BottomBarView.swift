import SwiftUI

struct BottomToolbarItemLabel: View {
    let systemImage: String
    let tint: Color
    let isActivated: Bool
    let palette: [Color]

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .frame(width: 48, height: 48)
            .background {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(isActivated ? tint.opacity(0.18) : Color.white.opacity(0.022))
                        }
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(activeBorderStyle, lineWidth: 1.25)
            }
            .contentShape(Circle())
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

struct PlaybackToolbarLabel: View {
    @Environment(AppModel.self) private var model

    private var activePlaybackPalette: [Color] {
        let colors = SoundChannel.allCases.compactMap { channel -> Color? in
            let state = model.channelState(for: channel)
            return state.isMuted ? nil : channel.tint
        }

        return LiquidActivityPalette.playback(from: colors)
    }

    var body: some View {
        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
            .symbolRenderingMode(.hierarchical)
            .shadow(
                color: .black.opacity(model.isPlaying ? 0.26 : 0.12),
                radius: model.isPlaying ? 4 : 2,
                y: model.isPlaying ? 1.5 : 1
            )
            .symbolEffect(.bounce, value: model.isPlaying)
            .frame(width: 58, height: 58)
            .background {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(model.isPlaying ? 0.04 : 0.022))
                        }

                    if model.isPlaying {
                        AnimatedLiquidAura(
                            palette: activePlaybackPalette,
                            shape: Circle(),
                            intensity: 0.78,
                            blurRadius: 5,
                            baseBlendOpacity: 0.04,
                            speedMultiplier: 2.65,
                            frameRate: 24,
                            isAnimated: true,
                            animationKey: "playback-\(model.isPlaying)-\(activePlaybackPalette.count)",
                            coverage: 1.05,
                            accentMixAmount: 0.0,
                            colorSeparation: 4.2
                        )
                        .padding(1)
                    }

                    Circle()
                        .fill(model.isPlaying ? Color.white.opacity(0.05) : Color.clear)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(playbackBorderStyle, lineWidth: 1.3)
            }
            .animation(.smooth(duration: 0.22), value: model.isPlaying)
    }

    private var playbackBorderStyle: AnyShapeStyle {
        if model.isPlaying {
            AnyShapeStyle(
                LinearGradient(
                    colors: activePlaybackPalette.map { $0.opacity(0.42) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
}

struct BottomBarView: View {
    @Environment(AppModel.self) private var model
    let transitionNamespace: Namespace.ID
    let onOpenPresets: (PanelTransitionSource) -> Void
    let onOpenBinaural: (PanelTransitionSource) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.smooth(duration: 0.24)) {
                    model.randomizeMix()
                }
            } label: {
                BottomToolbarItemLabel(
                    systemImage: "shuffle",
                    tint: .white,
                    isActivated: false,
                    palette: []
                )
            }
            .accessibilityIdentifier("home.bottom.shuffle")
            .buttonStyle(PressScaleButtonStyle())

            Button {
                onOpenPresets(.bottomPresets)
            } label: {
                BottomToolbarItemLabel(
                    systemImage: model.currentPresetID == nil ? "bookmark" : "bookmark.fill",
                    tint: LiquidActivityPalette.preset[0],
                    isActivated: model.activePreset != nil,
                    palette: LiquidActivityPalette.preset
                )
            }
            .accessibilityIdentifier("home.bottom.presets")
            .buttonStyle(PressScaleButtonStyle())
            .matchedTransitionSource(id: PanelTransitionSource.bottomPresets.transitionID, in: transitionNamespace) { source in
                source
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }

            Button {
                model.togglePlayback()
            } label: {
                PlaybackToolbarLabel()
            }
            .accessibilityIdentifier("home.bottom.playback")
            .buttonStyle(PressScaleButtonStyle())

            Button {
                onOpenBinaural(.bottomBinaural)
            } label: {
                BottomToolbarItemLabel(
                    systemImage: "waveform.path",
                    tint: model.activeBinauralTrack.tint,
                    isActivated: model.isBinauralActive,
                    palette: LiquidActivityPalette.binaural(for: model.activeBinauralTrack.tint)
                )
            }
            .accessibilityIdentifier("home.bottom.binaural")
            .buttonStyle(PressScaleButtonStyle())
            .matchedTransitionSource(id: PanelTransitionSource.bottomBinaural.transitionID, in: transitionNamespace) { source in
                source
                    .background(.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }

            RoutePickerView()
                .frame(width: 22, height: 22)
                .foregroundStyle(.white)
                .padding(13)
                .accessibilityIdentifier("home.bottom.routepicker")
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .glassEffect(.regular, in: Circle())
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(0.022))
                        }
                }
                .overlay {
                    Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1.25)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 412)
        .frame(maxWidth: .infinity)
    }
}
