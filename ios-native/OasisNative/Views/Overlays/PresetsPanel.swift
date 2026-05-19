import SwiftUI

struct PresetsPanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNamingPreset: Bool
    @State private var newPresetName = ""
    @State private var activeDragPresetID: String?
    @State private var lastReorderTargetID: String?
    @State private var rowMidpoints: [String: CGFloat] = [:]

    private var canReorderPresets: Bool {
        model.isPremium
    }

    var body: some View {
        ZStack {
            PresetsPanelBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
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
                        }

                        saveSection
                        presetsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
                }
                .coordinateSpace(name: "presetPanel")
                .scrollDismissesKeyboard(.interactively)
                .onPreferenceChange(PresetRowMidpointKey.self) { value in
                    rowMidpoints = value
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.presets.container")
        .onDisappear {
            isNamingPreset = false
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LiquidActivityPalette.preset[0].opacity(0.18))

                Image(systemName: model.currentPresetID == nil ? "bookmark" : "bookmark.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(LiquidActivityPalette.preset[0])
                    .symbolRenderingMode(.hierarchical)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Presets.panelTitle)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(L10n.Presets.panelSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.84))
                    .frame(width: 36, height: 36)
                    .presetGlassButtonBackground(
                        in: Circle(),
                        tint: Color.white.opacity(0.025),
                        border: Color.white.opacity(0.10)
                    )
            }
            .accessibilityLabel(Text(L10n.Presets.close))
            .buttonStyle(PresetButtonScaleStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 8)
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

    private var saveSection: some View {
        GlassSurface(
            tint: LiquidActivityPalette.preset[0].opacity(0.08),
            cornerRadius: 26,
            padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundStyle(LiquidActivityPalette.preset[0])
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.Presets.saveSectionTitle)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(L10n.Presets.saveSectionSubtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.52))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 10) {
                    TextField("", text: $newPresetName, prompt: Text(L10n.Presets.namePrompt))
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .textContentType(nil)
                        .focused($isNamingPreset)
                        .submitLabel(.done)
                        .onSubmit(savePreset)
                        .accessibilityIdentifier("presets.name")
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .fill(Color.black.opacity(0.18))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .strokeBorder(Color.white.opacity(isNamingPreset ? 0.18 : 0.08), lineWidth: 1)
                        }

                    Button(action: savePreset) {
                        Label {
                            Text(L10n.Presets.saveAction)
                        } icon: {
                            Image(systemName: "plus")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .presetGlassButtonBackground(
                            in: Capsule(),
                            tint: LiquidActivityPalette.preset[0].opacity(0.22),
                            border: LiquidActivityPalette.preset[0].opacity(0.34),
                            shadowOpacity: 0.12
                        )
                    }
                    .accessibilityIdentifier("presets.save")
                    .buttonStyle(PresetButtonScaleStyle())
                    .disabled(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(newPresetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.48 : 1)
                }
            }
        }
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.Presets.listSectionTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                Text("\(model.presets.count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LiquidActivityPalette.preset[0])
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .fill(LiquidActivityPalette.preset[0].opacity(0.14))
                    }
            }

            LazyVStack(spacing: 10) {
                presetRows
            }
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
        HStack(spacing: 10) {
            Button(action: onSelect) {
                rowContent
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("presets.row.\(preset.id)")
            }
            .accessibilityIdentifier("presets.row.\(preset.id)")
            .buttonStyle(PresetButtonScaleStyle())
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsReorderControl {
                reorderHandle
            }

            if isDeleteEnabled {
                deleteButton
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .presetGlassButtonBackground(
            in: RoundedRectangle(cornerRadius: 22, style: .continuous),
            tint: isActive ? rowTint.opacity(0.13) : Color.white.opacity(0.018),
            border: isActive ? rowTint.opacity(0.36) : Color.white.opacity(0.07),
            shadowOpacity: isActive ? 0.18 : 0.08,
            shadowRadius: isActive ? 18 : 10
        )
        .opacity(isDragging ? 0.92 : 1)
        .opacity(isLocked ? 0.90 : 1)
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            iconWell

            VStack(alignment: .leading, spacing: 5) {
                Text(model.presetDisplayName(preset))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isLocked ? .white.opacity(0.62) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                Text(statusLabel)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(statusTint)
                    .tracking(0.9)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var iconWell: some View {
        ZStack {
            Circle()
                .fill(iconTint.opacity(isLocked ? 0.10 : 0.18))

            Image(systemName: iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(iconTint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: 38, height: 38)
    }

    private var iconName: String {
        if isLocked { return "lock.fill" }
        if isActive { return "checkmark" }
        return preset.isUser ? "bookmark.fill" : "sparkles"
    }

    private var iconTint: Color {
        if isLocked { return .white.opacity(0.42) }
        if isActive { return rowTint }
        return .white.opacity(0.72)
    }

    private var statusLabel: LocalizedStringResource {
        if isLocked { return L10n.Mixer.statusPremium }
        if isActive { return L10n.Presets.statusActive }
        if preset.isUser { return L10n.Presets.statusSaved }
        return L10n.Presets.statusOasis
    }

    private var statusTint: Color {
        if isLocked { return .white.opacity(0.42) }
        if isActive { return rowTint.opacity(0.92) }
        return .white.opacity(0.42)
    }

    private var reorderHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(isReorderEnabled ? 0.72 : 0.32))
            .frame(width: 34, height: 34)
            .presetGlassButtonBackground(
                in: Circle(),
                tint: Color.white.opacity(isReorderEnabled ? 0.045 : 0.018),
                border: Color.white.opacity(isReorderEnabled ? 0.10 : 0.045),
                shadowOpacity: 0.06,
                shadowRadius: 8
            )
            .contentShape(Circle())
            .allowsHitTesting(isReorderEnabled)
            .accessibilityLabel(Text(L10n.Presets.reorderAction))
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
                .presetGlassButtonBackground(
                    in: Circle(),
                    tint: Color.white.opacity(0.035),
                    border: Color.white.opacity(0.10),
                    shadowOpacity: 0.08,
                    shadowRadius: 8
                )
        }
        .buttonStyle(PresetButtonScaleStyle())
        .accessibilityLabel(Text(L10n.Presets.deleteAction))
        .disabled(!isDeleteEnabled)
        .opacity(isDeleteEnabled ? 1 : 0.36)
    }

    private var rowTint: Color {
        let palette = SoundChannel.allCases.map(\.tint)
        let index = max(model.presets.firstIndex(where: { $0.id == preset.id }) ?? 0, 0)
        return palette[index % palette.count]
    }
}

private extension View {
    func presetGlassButtonBackground<S: InsettableShape>(
        in shape: S,
        tint: Color,
        border: Color,
        shadowOpacity: Double = 0.10,
        shadowRadius: CGFloat = 12
    ) -> some View {
        background {
            shape
                .fill(Color.white.opacity(0.001))
                .oasisGlassEffect(in: shape)
                .overlay {
                    shape
                        .fill(tint)
                }
        }
        .overlay {
            shape
                .strokeBorder(border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, y: 6)
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

private struct PresetsPanelBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.034, blue: 0.032)

            LinearGradient(
                colors: [
                    LiquidActivityPalette.preset[0].opacity(0.18),
                    LiquidActivityPalette.preset[1].opacity(0.08),
                    Color.black.opacity(0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.30),
                    Color.black.opacity(0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

private struct PresetRowMidpointKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
