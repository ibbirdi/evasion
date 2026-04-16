import SwiftUI

struct PresetsPanel: View {
    @Environment(AppModel.self) private var model
    @FocusState private var isNamingPreset: Bool
    @State private var newPresetName = ""
    @State private var activeDragPresetID: String?
    @State private var lastReorderTargetID: String?
    @State private var rowMidpoints: [String: CGFloat] = [:]

    private var canReorderPresets: Bool {
        model.isPremium
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: model.currentPresetID == nil ? "bookmark" : "bookmark.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LiquidActivityPalette.preset[0])

                Text(L10n.Presets.panelTitle)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.Presets.panelSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .multilineTextAlignment(.center)

                if model.isSignaturePreviewActive {
                    Text(L10n.Premium.previewPlaying)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LiquidActivityPalette.preset[0].opacity(0.90))
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)

            if let presentation = model.presetsUpsellPresentation {
                PremiumInlineUpsellCard(
                    presentation: presentation,
                    onPrimaryAction: {
                        if let entryPoint = model.activeInlineUpsell?.entryPoint {
                            model.presentPaywall(from: entryPoint)
                        }
                    },
                    onSecondaryAction: {
                        if model.isSignaturePreviewAvailable {
                            model.startSignaturePreview()
                        } else {
                            model.dismissInlineUpsell()
                        }
                    },
                    onDismiss: {
                        model.dismissInlineUpsell()
                    }
                )
                .padding(.horizontal, 20)
            }

            presetsList
                .padding(.horizontal, 20)

            saveComposer
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.presets.container")
        .onDisappear {
            isNamingPreset = false
        }
    }

    @ViewBuilder
    private var presetsList: some View {
        if model.presets.count <= 4 {
            VStack(spacing: 8) {
                presetRows
            }
            .coordinateSpace(name: "presetPanel")
            .onPreferenceChange(PresetRowMidpointKey.self) { value in
                rowMidpoints = value
            }
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    presetRows
                }
            }
            .coordinateSpace(name: "presetPanel")
            .scrollDismissesKeyboard(.never)
            .onPreferenceChange(PresetRowMidpointKey.self) { value in
                rowMidpoints = value
            }
            .frame(maxHeight: 320)
        }
    }

    @ViewBuilder
    private var presetRows: some View {
        ForEach(model.presets) { preset in
            PresetRow(
                preset: preset,
                isLocked: model.isPresetLocked(preset),
                isDragging: activeDragPresetID == preset.id,
                showsReorderControl: canReorderPresets,
                isReorderEnabled: canReorderPresets && !isNamingPreset,
                isDeleteEnabled: canDelete(preset) && !isNamingPreset,
                onSelect: {
                    guard !model.isPresetLocked(preset) else {
                        model.requestPremiumAccess(from: .presetLoad)
                        return
                    }

                    withAnimation(.smooth(duration: 0.22)) {
                        model.loadPreset(preset)
                    }
                },
                onDelete: { delete(preset) },
                onReorderChanged: { locationY in
                    handleReorderDrag(for: preset, locationY: locationY)
                },
                onReorderEnded: {
                    activeDragPresetID = nil
                    lastReorderTargetID = nil
                }
            )
            .background {
                if activeDragPresetID != nil && !isNamingPreset {
                    GeometryReader { proxy in
                        Color.clear
                            .preference(
                                key: PresetRowMidpointKey.self,
                                value: [preset.id: proxy.frame(in: .named("presetPanel")).midY]
                            )
                    }
                }
            }
        }
    }

    private var saveComposer: some View {
        HStack(spacing: 8) {
            TextField("", text: $newPresetName, prompt: Text(L10n.Presets.namePrompt))
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .textContentType(nil)
                .focused($isNamingPreset)
                .submitLabel(.done)
                .onSubmit(savePreset)
                .accessibilityIdentifier("presets.name")
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.02))
                        }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }

            Button(action: savePreset) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background {
                        Circle()
                            .fill(.regularMaterial)
                            .overlay {
                                Circle()
                                    .fill(Color.white.opacity(0.02))
                            }
                    }
            }
            .accessibilityIdentifier("presets.save")
            .buttonStyle(PresetButtonScaleStyle())
            .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        }
    }

    private func savePreset() {
        let trimmed = newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let didSave = withAnimation(.smooth(duration: 0.22)) {
            model.savePreset(named: trimmed)
        }
        guard didSave else { return }
        newPresetName = ""
        isNamingPreset = false
    }

    private func delete(_ preset: Preset) {
        guard canDelete(preset) else { return }

        withAnimation(.smooth(duration: 0.22)) {
            model.deletePreset(preset)
        }
    }

    private func movePresets(fromOffsets: IndexSet, toOffset: Int) {
        withAnimation(.smooth(duration: 0.22)) {
            model.movePresets(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }

    private func handleReorderDrag(for preset: Preset, locationY: CGFloat) {
        if activeDragPresetID != preset.id {
            activeDragPresetID = preset.id
            lastReorderTargetID = nil
        }

        guard
            let target = rowMidpoints.min(by: { abs($0.value - locationY) < abs($1.value - locationY) })?.key,
            target != preset.id,
            target != lastReorderTargetID
        else {
            return
        }

        lastReorderTargetID = target

        guard
            let fromIndex = model.presets.firstIndex(where: { $0.id == preset.id }),
            let toIndex = model.presets.firstIndex(where: { $0.id == target })
        else {
            return
        }

        movePresets(
            fromOffsets: IndexSet(integer: fromIndex),
            toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
        )
    }

    private func canDelete(_ preset: Preset) -> Bool {
        model.isPremium || preset.isUser
    }

}

private struct PresetRow: View {
    @Environment(AppModel.self) private var model
    let preset: Preset
    let isLocked: Bool
    let isDragging: Bool
    let showsReorderControl: Bool
    let isReorderEnabled: Bool
    let isDeleteEnabled: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onReorderChanged: (CGFloat) -> Void
    let onReorderEnded: () -> Void

    private var isActive: Bool {
        model.currentPresetID == preset.id
    }

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSelect) {
                rowContent
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("presets.row.\(preset.id)")
            }
            .accessibilityIdentifier("presets.row.\(preset.id)")
            .buttonStyle(PresetButtonScaleStyle())

            if showsReorderControl {
                reorderHandle
            }

            if isDeleteEnabled {
                deleteButton
            }
        }
        .opacity(isDragging ? 0.92 : 1)
    }

    private var rowContent: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(model.presetDisplayName(preset))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(isLocked ? .white.opacity(0.62) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                if isLocked {
                    Text(L10n.Mixer.statusPremium)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.42))
                        .tracking(1.0)
                }
            }

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.44))
            } else if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(rowTint)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isActive ? rowTint.opacity(0.14) : Color.white.opacity(0.018))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isActive ? rowTint.opacity(0.30) : Color.white.opacity(0.06), lineWidth: 1)
        }
        .opacity(isLocked ? 0.88 : 1)
    }

    private var reorderHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(isReorderEnabled ? 0.72 : 0.32))
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
            .allowsHitTesting(isReorderEnabled)
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .named("presetPanel"))
                    .onChanged { value in
                        guard isReorderEnabled else { return }
                        onReorderChanged(value.location.y)
                    }
                    .onEnded { _ in
                        guard isReorderEnabled else { return }
                        onReorderEnded()
                    }
            )
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.84))
                .frame(width: 34, height: 34)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                        .overlay {
                            Circle()
                                .fill(Color.white.opacity(0.02))
                        }
                }
        }
        .buttonStyle(PresetButtonScaleStyle())
        .disabled(!isDeleteEnabled)
        .opacity(isDeleteEnabled ? 1 : 0.36)
    }

    private var rowTint: Color {
        let palette = SoundChannel.allCases.map(\.tint)
        let index = max(model.presets.firstIndex(where: { $0.id == preset.id }) ?? 0, 0)
        return palette[index % palette.count]
    }
}

private struct PresetButtonScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        if AppConfiguration.supportsSensoryFeedback {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
                .sensoryFeedback(.impact(weight: .heavy, intensity: 1.0), trigger: configuration.isPressed) { _, isPressed in
                    isPressed
                }
        } else {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
        }
    }
}

private struct PresetRowMidpointKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
