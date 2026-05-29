import SwiftUI

struct PresetsPanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var newPresetName = ""
    @State private var activeDragPresetID: String?
    @State private var lastReorderTargetID: String?
    @State private var rowMidpoints: [String: CGFloat] = [:]
    @State private var isShowingSavePresetPrompt = false
    @State private var presetPendingDeletion: Preset?
    @State private var isManagingPresets = false

    private var canReorderPresets: Bool {
        model.isPremium
    }

    private var canManagePresets: Bool {
        canReorderPresets || model.presets.contains(where: canDelete(_:))
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
            isShowingSavePresetPrompt = false
            isManagingPresets = false
        }
        .confirmationDialog(
            Text(L10n.Presets.confirmDeleteTitle),
            isPresented: Binding(
                get: { presetPendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        presetPendingDeletion = nil
                    }
                }
            ),
            titleVisibility: .visible,
            presenting: presetPendingDeletion
        ) { preset in
            Button(role: .destructive) {
                confirmDelete(preset)
            } label: {
                Text(L10n.Presets.deleteAction)
            }

            Button(role: .cancel) {
                presetPendingDeletion = nil
            } label: {
                Text(L10n.Presets.cancel)
            }
        } message: { _ in
            Text(L10n.Presets.confirmDeleteMessage)
        }
        .alert(
            Text(L10n.Presets.saveSectionTitle),
            isPresented: $isShowingSavePresetPrompt
        ) {
            TextField(L10n.string(L10n.Presets.namePrompt), text: $newPresetName)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .accessibilityLabel(Text(L10n.Presets.nameFieldAccessibility))

            Button(role: .cancel) {
                newPresetName = ""
            } label: {
                Text(L10n.Presets.cancel)
            }

            Button {
                savePreset()
            } label: {
                Text(L10n.Presets.saveAction)
            }
            .disabled(trimmedPresetName.isEmpty)
        } message: {
            Text(L10n.Presets.saveSectionSubtitle)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LiquidActivityPalette.preset[0].opacity(0.18))

                Image(systemName: model.currentPresetID == nil ? "bookmark" : "bookmark.fill")
                    .oasisFont(size: 17, weight: .semibold, design: .default, relativeTo: .headline)
                    .foregroundStyle(LiquidActivityPalette.preset[0])
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Presets.panelTitle)
                    .oasisFont(size: 28, weight: .semibold, relativeTo: .title)
                    .foregroundStyle(.white)

                Text(L10n.Presets.panelSubtitle)
                    .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .oasisFont(size: 13, weight: .bold, design: .default, relativeTo: .body)
                    .foregroundStyle(.white.opacity(0.84))
                    .frame(width: 36, height: 36)
                    .presetGlassButtonBackground(
                        in: Circle(),
                        tint: Color.white.opacity(0.025),
                        border: Color.white.opacity(0.10)
                    )
            }
            .accessibilityLabel(Text(L10n.Presets.close))
            .accessibilityIdentifier("panel.presets.close")
            .oasisMinimumHitTarget()
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
                showsReorderControl: canReorderPresets && isManagingPresets,
                isReorderEnabled: canReorderPresets && isManagingPresets && !isShowingSavePresetPrompt,
                isDeleteEnabled: canDelete(preset) && isManagingPresets && !isShowingSavePresetPrompt,
                onSelect: {
                    guard !model.isPresetLocked(preset) else {
                        model.requestPremiumAccess(from: .presetLoad)
                        return
                    }

                    withAnimation(.smooth(duration: 0.22)) {
                        model.loadPreset(preset)
                    }
                },
                onDelete: { requestDelete(preset) },
                onReorderChanged: { locationY in
                    handleReorderDrag(for: preset, locationY: locationY)
                },
                onReorderEnded: {
                    activeDragPresetID = nil
                    lastReorderTargetID = nil
                }
            )
            .background {
                if activeDragPresetID != nil && !isShowingSavePresetPrompt {
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
        Button {
            withAnimation(.smooth(duration: 0.22)) {
                newPresetName = ""
                isShowingSavePresetPrompt = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .oasisFont(size: 18, weight: .semibold, design: .default, relativeTo: .headline)
                    .foregroundStyle(LiquidActivityPalette.preset[0])
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)

                Text(L10n.Presets.showSave)
                    .oasisFont(size: 16, weight: .semibold, relativeTo: .headline)
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .oasisFont(size: 12, weight: .bold, design: .default, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.54))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .presetGlassButtonBackground(
                in: RoundedRectangle(cornerRadius: 22, style: .continuous),
                tint: LiquidActivityPalette.preset[0].opacity(0.06),
                border: Color.white.opacity(0.09),
                shadowOpacity: 0.08,
                shadowRadius: 10
            )
        }
        .buttonStyle(PresetButtonScaleStyle())
        .accessibilityIdentifier("presets.save")
        .accessibilityLabel(Text(L10n.Presets.showSave))
    }

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.Presets.listSectionTitle)
                    .oasisFont(size: 18, weight: .semibold, relativeTo: .headline)
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                Text("\(model.presets.count)")
                    .oasisFont(size: 12, weight: .bold, relativeTo: .caption)
                    .foregroundStyle(LiquidActivityPalette.preset[0])
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background {
                        Capsule()
                            .fill(LiquidActivityPalette.preset[0].opacity(0.14))
                    }

                if canManagePresets {
                    Button {
                        withAnimation(.smooth(duration: 0.22)) {
                            isManagingPresets.toggle()
                            activeDragPresetID = nil
                            lastReorderTargetID = nil
                        }
                    } label: {
                        Text(isManagingPresets ? L10n.Presets.doneManaging : L10n.Presets.manage)
                            .oasisFont(size: 12, weight: .bold, relativeTo: .caption)
                            .foregroundStyle(isManagingPresets ? Color(red: 0.05, green: 0.07, blue: 0.10) : .white.opacity(0.78))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(isManagingPresets ? LiquidActivityPalette.preset[0].opacity(0.92) : Color.white.opacity(0.055))
                            }
                            .overlay {
                                Capsule()
                                    .strokeBorder(Color.white.opacity(isManagingPresets ? 0.12 : 0.08), lineWidth: 1)
                            }
                    }
                    .buttonStyle(PresetButtonScaleStyle())
                    .accessibilityLabel(Text(isManagingPresets ? L10n.Presets.doneManaging : L10n.Presets.manage))
                }
            }

            LazyVStack(spacing: 10) {
                presetRows
            }
            .accessibilityIdentifier("presets.list")
        }
    }

    private func savePreset() {
        let trimmed = trimmedPresetName
        guard !trimmed.isEmpty else { return }

        let didSave = withAnimation(.smooth(duration: 0.22)) {
            model.savePreset(named: trimmed)
        }
        guard didSave else { return }
        newPresetName = ""
        isShowingSavePresetPrompt = false
    }

    private func requestDelete(_ preset: Preset) {
        guard canDelete(preset) else { return }
        presetPendingDeletion = preset
    }

    private func confirmDelete(_ preset: Preset) {
        guard canDelete(preset) else { return }
        presetPendingDeletion = nil

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
        model.canDeletePreset(preset)
    }

    private var trimmedPresetName: String {
        newPresetName.trimmingCharacters(in: .whitespacesAndNewlines)
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
            }
            .accessibilityIdentifier("presets.row.button.\(preset.id)")
            .accessibilityAddTraits(isActive ? .isSelected : [])
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("presets.row.\(preset.id)")
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
            visualWell

            VStack(alignment: .leading, spacing: 5) {
                Text(model.presetDisplayName(preset))
                    .oasisFont(size: 16, weight: .semibold, relativeTo: .headline)
                    .foregroundStyle(isLocked ? .white.opacity(0.62) : .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)

                if shouldShowStatusLabel {
                    Text(statusLabel)
                        .oasisFont(size: 10, weight: .semibold, relativeTo: .caption2)
                        .foregroundStyle(statusTint)
                        .tracking(0.9)
                        .textCase(.uppercase)
                        .lineLimit(1)
                }

                ambienceChips
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var visualWell: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay {
                    visualBackdrop
                }
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.34)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Circle()
                .fill(Color.black.opacity(0.22))
                .frame(width: 27, height: 27)
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                }

            Image(systemName: iconName)
                .oasisFont(size: 14, weight: .bold, design: .default, relativeTo: .caption)
                .foregroundStyle(iconTint)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
        }
        .frame(width: 46, height: 46)
        .opacity(isLocked ? 0.64 : 1)
        .shadow(color: rowTint.opacity(isLocked ? 0.0 : 0.14), radius: 10, y: 5)
    }

    @ViewBuilder
    private var visualBackdrop: some View {
        if let channel = primaryVisualChannel {
            SoundBackdropImage(backdrop: channel.backdrop, opacity: isLocked ? 0.42 : 0.82)
                .saturation(isLocked ? 0.45 : 1)
        } else {
            OrganicBackdropImage(backdrop: fallbackOrganicBackdrop, opacity: isLocked ? 0.32 : 0.74, bottomShadeOpacity: 0.44)
                .saturation(isLocked ? 0.54 : 1)
        }
    }

    private var iconName: String {
        if isLocked { return "lock.fill" }
        if isActive { return "checkmark" }
        return preset.isUser ? "bookmark.fill" : "sparkles"
    }

    private var iconTint: Color {
        if isLocked { return .white.opacity(0.42) }
        if isActive { return rowTint }
        return .white.opacity(0.86)
    }

    private var statusLabel: LocalizedStringResource {
        if isLocked { return L10n.Mixer.statusPremium }
        if isActive { return L10n.Presets.statusActive }
        if preset.isUser { return L10n.Presets.statusSaved }
        return L10n.Presets.statusOasis
    }

    private var shouldShowStatusLabel: Bool {
        isLocked || isActive || preset.isUser
    }

    private var statusTint: Color {
        if isLocked { return .white.opacity(0.42) }
        if isActive { return rowTint.opacity(0.92) }
        return .white.opacity(0.42)
    }

    private var ambienceChips: some View {
        let chips = previewChips
        let visibleChips = Array(chips.prefix(4))
        let hiddenCount = max(chips.count - visibleChips.count, 0)

        return HStack(spacing: 5) {
            ForEach(visibleChips) { chip in
                PresetPreviewChip(chip: chip, isLocked: isLocked)
            }

            if hiddenCount > 0 {
                Text("+\(hiddenCount)")
                    .oasisFont(size: 9, weight: .bold, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(isLocked ? 0.40 : 0.66))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background {
                        Capsule().fill(Color.white.opacity(isLocked ? 0.035 : 0.07))
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    private var previewChips: [PresetPreviewChip.Model] {
        let channelChips = SoundChannel.allCases.compactMap { channel -> PresetPreviewChip.Model? in
            guard preset.channels[channel]?.isMuted == false else { return nil }
            return PresetPreviewChip.Model(
                id: "channel-\(channel.id)",
                title: channel.localizedName,
                glyph: channel.oasisGlyph,
                tint: channel.tint
            )
        }

        let noiseChips = ProceduralNoise.allCases.compactMap { noise -> PresetPreviewChip.Model? in
            guard preset.proceduralNoises?[noise]?.isMuted == false else { return nil }
            return PresetPreviewChip.Model(
                id: "noise-\(noise.id)",
                title: noise.presetPreviewTitle,
                systemImage: noise.systemImage,
                tint: noise.tint
            )
        }

        let timerChip = preset.timerDurationMinutes.map { timerDurationMinutes in
            PresetPreviewChip.Model(
                id: "timer-\(timerDurationMinutes)",
                title: L10n.timerOptionLabel(minutes: timerDurationMinutes),
                systemImage: "timer",
                tint: rowTint
            )
        }

        let binauralChip: PresetPreviewChip.Model? = {
            guard preset.isBinauralActive == true, let track = preset.activeBinauralTrack else {
                return nil
            }
            return PresetPreviewChip.Model(
                id: "binaural-\(track.id)",
                title: track.localizedTitle,
                systemImage: "waveform.path",
                tint: track.tint
            )
        }()

        var chips = Array(channelChips.prefix(2))
        chips += Array(noiseChips.prefix(1))

        if let timerChip {
            chips.append(timerChip)
        }

        if let binauralChip {
            chips.append(binauralChip)
        }

        chips += Array(noiseChips.dropFirst())
        chips += Array(channelChips.dropFirst(2))

        return chips
    }

    private var reorderHandle: some View {
        Image(systemName: "line.3.horizontal")
            .oasisFont(size: 14, weight: .semibold, design: .default, relativeTo: .caption)
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
            .oasisMinimumHitTarget()
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
                .oasisFont(size: 12, weight: .bold, design: .default, relativeTo: .caption)
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
        .oasisMinimumHitTarget()
        .disabled(!isDeleteEnabled)
        .opacity(isDeleteEnabled ? 1 : 0.36)
    }

    private var rowTint: Color {
        if let primaryVisualChannel {
            return primaryVisualChannel.tint
        }
        if let primaryNoiseTint {
            return primaryNoiseTint
        }
        if preset.isBinauralActive == true, let track = preset.activeBinauralTrack {
            return track.tint
        }
        let palette = SoundChannel.allCases.map(\.tint)
        let index = max(model.presets.firstIndex(where: { $0.id == preset.id }) ?? 0, 0)
        return palette[index % palette.count]
    }

    private var primaryVisualChannel: SoundChannel? {
        activeChannelStates.max { lhs, rhs in
            lhs.state.volume < rhs.state.volume
        }?.channel
    }

    private var activeChannelStates: [(channel: SoundChannel, state: ChannelState)] {
        SoundChannel.allCases.compactMap { channel in
            guard let state = preset.channels[channel], !state.isMuted else { return nil }
            return (channel, state)
        }
    }

    private var primaryNoiseTint: Color? {
        ProceduralNoise.allCases.compactMap { noise -> Color? in
            guard preset.proceduralNoises?[noise]?.isMuted == false else { return nil }
            return noise.tint
        }
        .first
    }

    private var fallbackOrganicBackdrop: SoundBackdrop {
        if preset.isBinauralActive == true {
            return OrganicBackdrop.darkWater
        }
        if primaryNoiseTint != nil {
            return OrganicBackdrop.blueFabric
        }
        return OrganicBackdrop.warmFabric
    }
}

private struct PresetPreviewChip: View {
    struct Model: Identifiable {
        let id: String
        let title: String
        var systemImage: String? = nil
        var glyph: OasisGlyph? = nil
        let tint: Color
    }

    let chip: Model
    let isLocked: Bool

    var body: some View {
        HStack(spacing: 4) {
            if let glyph = chip.glyph {
                OasisGlyphImage(glyph: glyph)
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)
            } else if let systemImage = chip.systemImage {
                Image(systemName: systemImage)
                    .oasisFont(size: 8, weight: .bold, design: .default, relativeTo: .caption2)
                    .accessibilityHidden(true)
            }

            Text(chip.title)
                .oasisFont(size: 9, weight: .bold, relativeTo: .caption2)
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(isLocked ? 0.44 : 0.78))
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background {
            Capsule().fill(chip.tint.opacity(isLocked ? 0.06 : 0.13))
        }
        .overlay {
            Capsule().strokeBorder(chip.tint.opacity(isLocked ? 0.08 : 0.18), lineWidth: 1)
        }
    }
}

private extension ProceduralNoise {
    var presetPreviewTitle: String {
        switch self {
        case .white: return L10n.string(L10n.NoiseLab.white)
        case .brown: return L10n.string(L10n.NoiseLab.brown)
        case .pink: return L10n.string(L10n.NoiseLab.pink)
        case .green: return L10n.string(L10n.NoiseLab.green)
        case .fan: return L10n.string(L10n.NoiseLab.fan)
        case .aircraft: return L10n.string(L10n.NoiseLab.aircraft)
        }
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
