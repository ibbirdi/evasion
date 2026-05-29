import SwiftUI
import UniformTypeIdentifiers

private enum AmbienceSource {
    case preset(String)
}

private enum AmbienceEditorMode: Identifiable {
    case create(initialBackdropAssetName: String)
    case edit(String)

    var id: String {
        switch self {
        case .create:
            return "create"
        case let .edit(id):
            return "edit-\(id)"
        }
    }
}

private struct AmbienceOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let intent: AmbienceIntent
    let backdrop: SoundBackdrop
    let requiresPremium: Bool
    let source: AmbienceSource
}

private struct PresetExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data = Data()) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private enum AmbienceDuration: CaseIterable, Identifiable {
    case infinite
    case fifteen
    case thirty
    case sixty
    case twoHours

    var id: String {
        minutes.map(String.init) ?? "infinite"
    }

    var minutes: Int? {
        switch self {
        case .infinite: return nil
        case .fifteen: return 15
        case .thirty: return 30
        case .sixty: return 60
        case .twoHours: return 120
        }
    }

    var label: String {
        switch self {
        case .infinite:
            return "∞"
        case .fifteen, .thirty, .sixty, .twoHours:
            return L10n.timerOptionLabel(minutes: minutes)
        }
    }
}

struct ComposePanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAmbienceID = ""
    @State private var selectedDuration: AmbienceDuration = .thirty
    @State private var startingAmbienceID: String?
    @State private var didSeedSelectionFromActiveAmbience = false
    @State private var ambienceEditorMode: AmbienceEditorMode?
    @State private var presetExportDocument = PresetExportDocument()
    @State private var isPresentingPresetExport = false

    private let selectorColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var ambienceOptions: [AmbienceOption] {
        let saved = model.presets.map { preset in
            let intent = ambienceIntent(for: preset)
            return AmbienceOption(
                id: preset.id,
                title: model.presetDisplayName(preset),
                subtitle: L10n.string(preset.isUser ? L10n.Presets.statusSaved : L10n.Presets.statusOasis),
                intent: intent,
                backdrop: AmbienceBackdropLibrary.backdrop(for: preset.backdropAssetName, fallback: fallbackBackdrop(for: preset)),
                requiresPremium: model.isPresetLocked(preset),
                source: .preset(preset.id)
            )
        }

        return saved.filter { !$0.requiresPremium }
            + saved.filter(\.requiresPremium)
    }

    private var selectedOption: AmbienceOption? {
        ambienceOptions.first { $0.id == selectedAmbienceID } ?? ambienceOptions.first
    }

    private var selectedRecipe: AmbienceRecipe? {
        guard let selectedOption else { return nil }
        guard case let .preset(id) = selectedOption.source else {
            return ambienceRecipe(for: nil, option: selectedOption)
        }

        var recipe = ambienceRecipe(for: model.presets.first { $0.id == id }, option: selectedOption)
        recipe.timerMinutes = selectedDuration.minutes
        return recipe
    }

    private var selectedAmbienceIsActive: Bool {
        guard let selectedRecipe else { return false }
        return model.activeComposerRecipeTitle == selectedRecipe.title
            && model.timerDurationMinutes == selectedDuration.minutes
    }

    private var selectedAmbienceIsLocked: Bool {
        guard let selectedRecipe else { return false }
        return !model.isPremium && selectedRecipe.requiresPremium
    }

    private var suggestedSaveBackdropAssetName: String {
        let activeChannel = model.channels
            .filter { !$0.value.isMuted }
            .max { $0.value.volume < $1.value.volume }?
            .key

        return activeChannel?.backdrop.assetName ?? selectedOption?.backdrop.assetName ?? OrganicBackdrop.darkWater.assetName
    }

    private var ambienceCTA: (title: LocalizedStringResource, systemImage: String, isDisabled: Bool) {
        guard let selectedOption else {
            return (L10n.Compose.ambienceStart, "play.fill", true)
        }

        if startingAmbienceID == selectedOption.id {
            return (L10n.HomeActive.listening, "checkmark", true)
        }

        if selectedAmbienceIsActive {
            return (L10n.HomeActive.stopAmbience, "stop.fill", false)
        }

        if selectedAmbienceIsLocked {
            return (L10n.Premium.inlineUnlock, "lock.fill", false)
        }

        if model.activeComposerRecipeTitle != nil {
            return (L10n.Compose.ambienceReplace, "arrow.triangle.2.circlepath", false)
        }

        return (L10n.Compose.ambienceStart, "play.fill", false)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ComposePanelBackground()

                VStack(spacing: 0) {
                    header

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            saveAmbienceButton
                            exportAmbiencesButton
                            composerInlineUpsell
                            if let selectedOption, let selectedRecipe {
                                ambienceSelector
                                durationSelector

                                AmbienceDetailCard(
                                    option: selectedOption,
                                    recipe: selectedRecipe,
                                    isLocked: selectedAmbienceIsLocked
                                )
                                .id("\(selectedOption.id)-\(selectedDuration.id)")
                                .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .top)))
                            } else {
                                emptyAmbienceState
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 112)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    if selectedOption != nil {
                        startAmbienceBar
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear(perform: seedSelectionFromActiveAmbience)
        .fullScreenCover(item: $ambienceEditorMode) { mode in
            ambienceEditorSheet(for: mode)
        }
        .fileExporter(
            isPresented: $isPresentingPresetExport,
            document: presetExportDocument,
            contentType: .json,
            defaultFilename: "oasis-iphone-ambiences"
        ) { _ in }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("panel.compose.container")
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.Compose.title)
                    .oasisFont(size: 28, weight: .semibold, relativeTo: .title)
                    .foregroundStyle(.white)

                Text(L10n.Compose.subtitle)
                    .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .oasisFont(size: 13, weight: .bold, design: .default, relativeTo: .body)
                    .foregroundStyle(.white.opacity(0.84))
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.001))
                            .oasisGlassEffect(in: Circle())
                            .overlay {
                                Circle().fill(Color.white.opacity(0.024))
                            }
                    }
                    .overlay {
                        Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                    }
            }
            .accessibilityLabel(Text(L10n.Presets.close))
            .accessibilityIdentifier("panel.compose.close")
            .oasisMinimumHitTarget()
            .buttonStyle(PressScaleButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var ambienceSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: selectorColumns, alignment: .leading, spacing: 8) {
                ForEach(ambienceOptions) { option in
                    AmbienceSelectorButton(
                        option: option,
                        isSelected: selectedAmbienceID == option.id,
                        isLocked: option.requiresPremium && !model.isPremium,
                        isEditable: isEditableAmbience(option),
                        onEdit: {
                            if let preset = preset(for: option), model.canEditPreset(preset) {
                                ambienceEditorMode = .edit(preset.id)
                            }
                        }
                    ) {
                        withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                            selectedAmbienceID = option.id
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("compose.ambience.selector")
        }
    }

    private var durationSelector: some View {
        let tint = selectedOption?.intent.tint ?? ComposeCTAStyle.save.primary

        return VStack(alignment: .leading, spacing: 9) {
            Label(L10n.Header.timer, systemImage: "timer")
                .oasisFont(size: 11, weight: .bold, design: .default, relativeTo: .caption)
                .foregroundStyle(.white.opacity(0.50))

            HStack(spacing: 7) {
                ForEach(AmbienceDuration.allCases) { duration in
                    Button {
                        withAnimation(.smooth(duration: 0.18)) {
                            selectedDuration = duration
                        }
                    } label: {
                        Text(duration.label)
                            .oasisFont(size: duration == .infinite ? 18 : 11, weight: .bold, relativeTo: .caption)
                            .foregroundStyle(selectedDuration == duration ? Color(red: 0.04, green: 0.06, blue: 0.10) : .white.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(selectedDuration == duration ? tint.opacity(0.92) : Color.white.opacity(0.048))
                            }
                            .overlay {
                                Capsule(style: .continuous)
                                    .strokeBorder(Color.white.opacity(selectedDuration == duration ? 0.18 : 0.07), lineWidth: 1)
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityLabel(Text(duration.minutes.map(L10n.timerOptionLabel(minutes:)) ?? duration.label))
                    .accessibilityAddTraits(selectedDuration == duration ? .isSelected : [])
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compose.ambience.duration")
    }

    private var emptyAmbienceState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.Presets.listSectionTitle, systemImage: "bookmark")
                .oasisFont(size: 11, weight: .bold, design: .default, relativeTo: .caption)
                .foregroundStyle(.white.opacity(0.50))

            Text(L10n.Presets.saveSectionSubtitle)
                .oasisFont(size: 14, weight: .medium, relativeTo: .body)
                .foregroundStyle(.white.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.045))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var saveAmbienceButton: some View {
        Button {
            if model.isPremium {
                ambienceEditorMode = .create(initialBackdropAssetName: suggestedSaveBackdropAssetName)
            } else {
                model.requestPremiumAccess(from: .presetSave)
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .oasisFont(size: 14, weight: .bold, design: .default, relativeTo: .body)

                Text(L10n.Presets.showSave)
                    .oasisFont(size: 14, weight: .bold, relativeTo: .headline)

                Spacer(minLength: 0)

                Image(systemName: model.isPremium ? "plus" : "lock.fill")
                    .oasisFont(size: 12, weight: .bold, design: .default, relativeTo: .body)
                    .foregroundStyle(Color(red: 0.04, green: 0.06, blue: 0.10).opacity(0.84))
                    .frame(width: 26, height: 26)
                    .background {
                        Circle().fill(.white.opacity(0.72))
                    }
            }
            .foregroundStyle(Color(red: 0.04, green: 0.06, blue: 0.10))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                ComposeCTAStyle.save.primary,
                                ComposeCTAStyle.save.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.white.opacity(0.11))
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: ComposeCTAStyle.save.primary.opacity(0.24), radius: 18, y: 10)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("compose.ambience.save")
    }

    private var exportAmbiencesButton: some View {
        Button {
            guard !model.userCreatedPresets.isEmpty,
                  let exportData = try? model.exportUserPresetsData()
            else {
                return
            }

            presetExportDocument = PresetExportDocument(data: exportData)
            isPresentingPresetExport = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .oasisFont(size: 13, weight: .bold, design: .default, relativeTo: .body)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Presets.exportAction)
                        .oasisFont(size: 13, weight: .bold, relativeTo: .subheadline)
                        .foregroundStyle(.white.opacity(model.userCreatedPresets.isEmpty ? 0.46 : 0.86))

                    if model.userCreatedPresets.isEmpty {
                        Text(L10n.Presets.exportUnavailable)
                            .oasisFont(size: 11, weight: .medium, relativeTo: .caption)
                            .foregroundStyle(.white.opacity(0.44))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 0)

                Text("\(model.userCreatedPresets.count)")
                    .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                    .foregroundStyle(.white.opacity(0.66))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.07))
                    }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.042))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.075), lineWidth: 1)
            }
        }
        .disabled(model.userCreatedPresets.isEmpty)
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityIdentifier("compose.ambience.export")
    }

    private func isEditableAmbience(_ option: AmbienceOption) -> Bool {
        preset(for: option).map(model.canEditPreset(_:)) == true
    }

    private func preset(for option: AmbienceOption) -> Preset? {
        guard case let .preset(id) = option.source else { return nil }
        return model.presets.first { $0.id == id }
    }

    private func ambienceIntent(for preset: Preset) -> AmbienceIntent {
        if preset.isUser {
            return preset.timerDurationMinutes == nil ? .reset : .sleep
        }

        switch preset.id {
        case "preset_default_calm", "preset_signature_oasis":
            return .reset
        case "preset_default_storm":
            return .sleep
        default:
            return .travel
        }
    }

    private func fallbackBackdrop(for preset: Preset) -> SoundBackdrop {
        if let strongestChannel = preset.channels
            .filter({ !$0.value.isMuted })
            .max(by: { $0.value.volume < $1.value.volume })?
            .key {
            return strongestChannel.backdrop
        }

        if preset.isUser {
            return OrganicBackdrop.blueFabric
        }

        return OrganicBackdrop.darkWater
    }

    private func ambienceRecipe(for preset: Preset?, option: AmbienceOption) -> AmbienceRecipe {
        guard let preset else {
            return AmbienceRecipe(
                title: option.title,
                subtitle: option.subtitle,
                intent: option.intent,
                channels: .initialChannels,
                proceduralNoises: .initialNoises,
                isBinauralActive: false,
                binauralTrack: .delta,
                binauralVolume: 0.5,
                timerMinutes: nil,
                immersiveAudioEnabled: false
            )
        }

        return AmbienceRecipe(
            title: option.title,
            subtitle: option.subtitle,
            intent: option.intent,
            channels: preset.channels,
            proceduralNoises: preset.proceduralNoises ?? .initialNoises,
            isBinauralActive: preset.isBinauralActive ?? false,
            binauralTrack: preset.activeBinauralTrack ?? .delta,
            binauralVolume: AutoVariationRange.unitValue(preset.binauralVolume ?? 0.5, fallback: 0.5),
            timerMinutes: preset.timerDurationMinutes,
            immersiveAudioEnabled: preset.immersiveAudioEnabled ?? false
        )
    }

    @ViewBuilder
    private func ambienceEditorSheet(for mode: AmbienceEditorMode) -> some View {
        switch mode {
        case let .create(initialBackdropAssetName):
            AmbienceEditorSheet(
                title: L10n.Presets.saveSectionTitle,
                initialName: "",
                initialBackdropAssetName: initialBackdropAssetName,
                choices: AmbienceBackdropLibrary.all,
                canDelete: false,
                onCancel: { ambienceEditorMode = nil },
                onSave: saveCurrentAmbience(name:backdropAssetName:),
                onDelete: nil
            )
        case let .edit(id):
            if let preset = model.presets.first(where: { $0.id == id }) {
                AmbienceEditorSheet(
                    title: L10n.Presets.editSectionTitle,
                    initialName: model.presetDisplayName(preset),
                    initialBackdropAssetName: preset.backdropAssetName ?? fallbackBackdrop(for: preset).assetName,
                    choices: AmbienceBackdropLibrary.all,
                    canDelete: model.canDeletePreset(preset),
                    onCancel: { ambienceEditorMode = nil },
                    onSave: { name, backdropAssetName in
                        updateAmbience(preset, name: name, backdropAssetName: backdropAssetName)
                    },
                    onDelete: {
                        deleteAmbience(preset)
                        ambienceEditorMode = nil
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    private func saveCurrentAmbience(name: String, backdropAssetName: String?) {
        let previousIDs = Set(model.presets.map(\.id))
        guard model.savePreset(named: name, backdropAssetName: backdropAssetName) else { return }

        if let savedAmbience = model.presets.last(where: { !previousIDs.contains($0.id) }) {
            selectedAmbienceID = savedAmbience.id
        }

        ambienceEditorMode = nil
    }

    private func updateAmbience(_ preset: Preset, name: String, backdropAssetName: String?) {
        guard model.updatePreset(preset, name: name, backdropAssetName: backdropAssetName) else { return }
        selectedAmbienceID = preset.id
        ambienceEditorMode = nil
    }

    private func deleteAmbience(_ preset: Preset) {
        withAnimation(.smooth(duration: 0.22)) {
            model.deletePreset(preset)
            if selectedAmbienceID == preset.id, let firstOption = ambienceOptions.first {
                selectedAmbienceID = firstOption.id
            }
        }
    }

    @ViewBuilder
    private var composerInlineUpsell: some View {
        if let presentation = model.composerUpsellPresentation ?? model.presetsUpsellPresentation {
            PremiumInlineUpsellCard(
                presentation: presentation,
                onPrimaryAction: {
                    if let entryPoint = model.activeInlineUpsell?.entryPoint {
                        model.presentPaywall(from: entryPoint)
                    }
                },
                onSecondaryAction: {
                    handleInlineUpsellSecondaryAction()
                },
                onDismiss: {
                    model.dismissInlineUpsell()
                }
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func handleInlineUpsellSecondaryAction() {
        guard model.activeInlineUpsell?.entryPoint.category == .preset,
              model.isSignaturePreviewAvailable else {
            model.dismissInlineUpsell()
            return
        }

        model.startSignaturePreview()
    }

    private var startAmbienceBar: some View {
        VStack(spacing: 0) {
            Button {
                startSelectedAmbience()
            } label: {
                Label(ambienceCTA.title, systemImage: ambienceCTA.systemImage)
                .oasisFont(size: 15, weight: .bold, design: .default, relativeTo: .headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ComposePrimaryButtonStyle(palette: .launch))
            .disabled(ambienceCTA.isDisabled)
            .accessibilityIdentifier("compose.ambience.start")
            .animation(.smooth(duration: 0.20), value: selectedAmbienceIsActive)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.020, green: 0.030, blue: 0.065).opacity(0),
                    Color(red: 0.020, green: 0.030, blue: 0.065).opacity(0.84),
                    Color(red: 0.020, green: 0.030, blue: 0.065)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func startSelectedAmbience() {
        guard let selectedOption, let recipe = selectedRecipe else { return }

        if selectedAmbienceIsActive {
            withAnimation(.smooth(duration: 0.24)) {
                model.stopActiveAmbience()
                dismiss()
            }
            return
        }

        withAnimation(.smooth(duration: 0.24)) {
            let didApply = model.applyAmbienceRecipe(recipe)
            if didApply {
                startingAmbienceID = selectedOption.id
                Task {
                    try? await Task.sleep(nanoseconds: 420_000_000)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        }
    }

    private func seedSelectionFromActiveAmbience() {
        guard !didSeedSelectionFromActiveAmbience else { return }
        didSeedSelectionFromActiveAmbience = true

        guard let activeTitle = model.activeComposerRecipeTitle else { return }
        guard let activeOption = ambienceOptions.first(where: { option in
            guard case let .preset(id) = option.source else { return false }
            return model.presets.first { $0.id == id }.map { model.presetDisplayName($0) == activeTitle } ?? false
        }) else { return }

        selectedAmbienceID = activeOption.id
    }
}

private struct AmbienceSelectorButton: View {
    let option: AmbienceOption
    let isSelected: Bool
    let isLocked: Bool
    let isEditable: Bool
    let onEdit: () -> Void
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onTap) {
                ZStack {
                    Image(option.backdrop.assetName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: option.backdrop.focus.alignment)
                        .saturation(0.86)
                        .brightness(isSelected ? 0.01 : -0.045)
                        .overlay {
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.14),
                                    Color.black.opacity(isSelected ? 0.34 : 0.43)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }

                    HStack(spacing: 8) {
                        Text(option.title)
                            .oasisFont(size: 12, weight: .semibold, relativeTo: .subheadline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)
                            .shadow(color: .black.opacity(0.96), radius: 14, x: 0, y: 7)
                            .shadow(color: .black.opacity(0.86), radius: 4, x: 0, y: 2)

                        Spacer(minLength: 0)

                        if isLocked && !isEditable {
                            Image(systemName: "lock.fill")
                                .oasisFont(size: 9, weight: .bold, design: .default, relativeTo: .caption2)
                                .foregroundStyle(Color(red: 0.96, green: 0.83, blue: 0.45).opacity(isSelected ? 0.96 : 0.72))
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, isEditable ? 42 : 10)
                }
                .frame(height: 46)
                .frame(maxWidth: .infinity)
                .clipShape(Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isSelected ? option.intent.tint.opacity(0.42) : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                }
            }
            .oasisMinimumHitTarget()
            .buttonStyle(PressScaleButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityHint(Text(option.subtitle))
            .accessibilityValue(isLocked ? Text(L10n.Compose.premium) : Text(L10n.Compose.free))
            .accessibilityIdentifier("compose.ambience.\(option.id)")

            if isEditable {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .oasisFont(size: 10, weight: .bold, design: .default, relativeTo: .caption)
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 28, height: 28)
                        .background {
                            Circle()
                                .fill(.black.opacity(0.30))
                                .overlay {
                                    Circle().fill(.white.opacity(0.06))
                                }
                        }
                        .overlay {
                            Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        }
                }
                .padding(.trailing, 9)
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(Text(L10n.Presets.editSectionTitle))
                .accessibilityIdentifier("compose.ambience.\(option.id).edit")
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct AmbienceEditorSheet: View {
    let title: LocalizedStringResource
    let choices: [AmbienceBackdropChoice]
    let canDelete: Bool
    let onCancel: () -> Void
    let onSave: (String, String?) -> Void
    let onDelete: (() -> Void)?

    @State private var ambienceName: String
    @State private var selectedBackdropAssetName: String
    @State private var isConfirmingDelete = false
    @FocusState private var isNameFocused: Bool

    private var trimmedAmbienceName: String {
        ambienceName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var selectedBackdrop: SoundBackdrop {
        AmbienceBackdropLibrary.backdrop(for: selectedBackdropAssetName)
    }

    init(
        title: LocalizedStringResource,
        initialName: String,
        initialBackdropAssetName: String,
        choices: [AmbienceBackdropChoice],
        canDelete: Bool,
        onCancel: @escaping () -> Void,
        onSave: @escaping (String, String?) -> Void,
        onDelete: (() -> Void)?
    ) {
        self.title = title
        self.choices = choices
        self.canDelete = canDelete
        self.onCancel = onCancel
        self.onSave = onSave
        self.onDelete = onDelete
        _ambienceName = State(initialValue: initialName)
        _selectedBackdropAssetName = State(initialValue: initialBackdropAssetName)
    }

    var body: some View {
        ZStack {
            ComposePanelBackground()

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .oasisFont(size: 28, weight: .semibold, relativeTo: .title)
                            .foregroundStyle(.white)

                        Text(L10n.Presets.saveSectionSubtitle)
                            .oasisFont(size: 13, weight: .medium, relativeTo: .subheadline)
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .oasisFont(size: 13, weight: .bold, design: .default, relativeTo: .body)
                            .foregroundStyle(.white.opacity(0.84))
                            .frame(width: 36, height: 36)
                            .background {
                                Circle()
                                    .fill(Color.white.opacity(0.001))
                                    .oasisGlassEffect(in: Circle())
                                    .overlay {
                                        Circle().fill(Color.white.opacity(0.024))
                                    }
                            }
                            .overlay {
                                Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                            }
                    }
                    .accessibilityLabel(Text(L10n.Presets.cancel))
                    .oasisMinimumHitTarget()
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        previewCard
                        nameField
                        backgroundPicker

                        if canDelete {
                            deleteButton
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 112)
                }
                .scrollDismissesKeyboard(.interactively)

                saveBar
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            Text(L10n.Presets.confirmDeleteTitle),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Text(L10n.Presets.deleteAction)
            }

            Button(role: .cancel) {
                isConfirmingDelete = false
            } label: {
                Text(L10n.Presets.cancel)
            }
        } message: {
            Text(L10n.Presets.confirmDeleteMessage)
        }
        .onAppear {
            isNameFocused = ambienceName.isEmpty
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compose.ambience.editor")
    }

    private var previewCard: some View {
        ZStack(alignment: .bottomLeading) {
            Image(selectedBackdrop.assetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 178, maxHeight: 178, alignment: selectedBackdrop.focus.alignment)
                .saturation(0.88)
                .brightness(-0.08)
                .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.74)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Group {
                if trimmedAmbienceName.isEmpty {
                    Text(L10n.Presets.namePrompt)
                } else {
                    Text(verbatim: trimmedAmbienceName)
                }
            }
            .oasisFont(size: 30, weight: .semibold, relativeTo: .largeTitle)
            .foregroundStyle(.white)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .shadow(color: .black.opacity(0.95), radius: 18, x: 0, y: 8)
            .shadow(color: .black.opacity(0.80), radius: 4, x: 0, y: 2)
            .padding(18)
        }
        .frame(height: 178)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Presets.namePrompt)
                .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                .foregroundStyle(.white.opacity(0.52))

            TextField(L10n.string(L10n.Presets.namePrompt), text: $ambienceName)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .focused($isNameFocused)
                .oasisFont(size: 16, weight: .semibold, relativeTo: .body)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.070))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                }
                .accessibilityLabel(Text(L10n.Presets.nameFieldAccessibility))
        }
    }

    private var backgroundPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Compose.ambienceBackground)
                .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                .foregroundStyle(.white.opacity(0.52))

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 9),
                    GridItem(.flexible(), spacing: 9),
                    GridItem(.flexible(), spacing: 9)
                ],
                spacing: 9
            ) {
                ForEach(Array(choices.enumerated()), id: \.element.id) { index, choice in
                    Button {
                        withAnimation(.smooth(duration: 0.18, extraBounce: 0.02)) {
                            selectedBackdropAssetName = choice.id
                        }
                    } label: {
                        AmbienceBackdropPickerTile(
                            choice: choice,
                            isSelected: choice.id == selectedBackdropAssetName
                        )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .accessibilityLabel(Text("\(L10n.string(L10n.Compose.ambienceBackground)) \(index + 1)"))
                    .accessibilityAddTraits(choice.id == selectedBackdropAssetName ? .isSelected : [])
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            isConfirmingDelete = true
        } label: {
            Text(L10n.Presets.deleteAction)
                .oasisFont(size: 13, weight: .bold, relativeTo: .subheadline)
                .foregroundStyle(Color(red: 0.98, green: 0.48, blue: 0.46))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(red: 0.98, green: 0.22, blue: 0.20).opacity(0.10))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(red: 0.98, green: 0.48, blue: 0.46).opacity(0.20), lineWidth: 1)
                }
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Button {
                onSave(trimmedAmbienceName, selectedBackdropAssetName)
            } label: {
                Text(L10n.Presets.saveAction)
                    .oasisFont(size: 15, weight: .bold, relativeTo: .headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ComposePrimaryButtonStyle(palette: .save))
            .disabled(trimmedAmbienceName.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.020, green: 0.030, blue: 0.065).opacity(0),
                    Color(red: 0.020, green: 0.030, blue: 0.065).opacity(0.84),
                    Color(red: 0.020, green: 0.030, blue: 0.065)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

private struct AmbienceBackdropPickerTile: View {
    let choice: AmbienceBackdropChoice
    let isSelected: Bool

    private let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                shape
                    .fill(Color.white.opacity(0.055))

                Image(choice.backdrop.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: choice.backdrop.focus.alignment
                    )
                    .saturation(0.88)
                    .brightness(-0.04)

                shape
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.black.opacity(0.10))
            }
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    isSelected ? .white.opacity(0.86) : .white.opacity(0.10),
                    lineWidth: isSelected ? 2 : 1
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
    }
}

private struct AmbienceDetailCard: View {
    let option: AmbienceOption
    let recipe: AmbienceRecipe
    let isLocked: Bool

    private var planRows: [AmbiencePlanRow] {
        var rows: [AmbiencePlanRow] = []

        let ambience = compactLayerList(recipe.activeChannels.map(\.localizedName), visibleLimit: 4)
        if !ambience.isEmpty {
            rows.append(
                AmbiencePlanRow(
                    id: "ambience",
                    title: L10n.Compose.ambienceLayerAmbience,
                    value: ambience,
                    glyph: .waveform,
                    tint: recipe.intent.tint
                )
            )
        }

        var maskParts = recipe.activeNoises.map(\.title)
        if recipe.isBinauralActive {
            maskParts.append(recipe.binauralTrack.localizedTitle)
        }
        let mask = compactLayerList(maskParts, visibleLimit: 3)
        if !mask.isEmpty {
            rows.append(
                AmbiencePlanRow(
                    id: "mask",
                    title: L10n.Compose.ambienceLayerMask,
                    value: mask,
                    glyph: .shieldCheck,
                    tint: maskTint
                )
            )
        }

        return rows
    }

    private var maskTint: Color {
        recipe.activeNoises.first?.tint
            ?? (recipe.isBinauralActive ? recipe.binauralTrack.tint : recipe.intent.tint)
    }

    private func compactLayerList(_ values: [String], visibleLimit: Int) -> String {
        let cleanedValues = values.filter { !$0.isEmpty }
        guard !cleanedValues.isEmpty else { return "" }
        guard cleanedValues.count > visibleLimit else {
            return cleanedValues.joined(separator: ", ")
        }

        let visibleValues = cleanedValues.prefix(visibleLimit).joined(separator: ", ")
        return "\(visibleValues) +\(cleanedValues.count - visibleLimit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                OrganicBackdropImage(backdrop: option.backdrop, opacity: 1, bottomShadeOpacity: 0.42)

                LinearGradient(
                    colors: [
                        option.intent.tint.opacity(0.26),
                        Color.black.opacity(0.06),
                        Color.black.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                AmbienceSpatialPreview(recipe: recipe)
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                VStack(alignment: .leading, spacing: 13) {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            OasisGlyphImage(glyph: option.intent.oasisGlyph)
                                .frame(width: 13, height: 13)

                            Text(verbatim: option.intent.title)
                                .oasisFont(size: 11, weight: .bold, design: .default, relativeTo: .caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background {
                            Capsule(style: .continuous)
                                .fill(.black.opacity(0.32))
                        }

                        if isLocked {
                            Label(L10n.Compose.premium, systemImage: "lock.fill")
                                .oasisFont(size: 11, weight: .bold, design: .default, relativeTo: .caption)
                                .foregroundStyle(Color(red: 0.96, green: 0.83, blue: 0.45))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background {
                                    Capsule(style: .continuous)
                                        .fill(.black.opacity(0.34))
                                }
                        }

                        if let timerMinutes = recipe.timerMinutes {
                            Text("\(L10n.string(L10n.Compose.ambienceLayerEnd)) · \(L10n.timerOptionLabel(minutes: timerMinutes))")
                                .oasisFont(size: 11, weight: .bold, relativeTo: .caption)
                                .foregroundStyle(.white.opacity(0.92))
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background {
                                    Capsule(style: .continuous)
                                        .fill(.black.opacity(0.30))
                                }
                        }

                        Spacer(minLength: 0)
                    }

                    Spacer(minLength: 18)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(recipe.title)
                            .oasisFont(size: 30, weight: .semibold, relativeTo: .largeTitle)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.80)
                            .shadow(color: .black.opacity(0.76), radius: 10, x: 0, y: 3)
                            .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)

                        Text(recipe.subtitle)
                            .oasisFont(size: 14, weight: .medium, relativeTo: .body)
                            .foregroundStyle(.white.opacity(0.74))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .shadow(color: .black.opacity(0.68), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.Compose.ambiencePlan)
                        .oasisFont(size: 16, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(.white.opacity(0.96))
                        .accessibilityIdentifier("compose.ambience.plan")

                    Text(L10n.Compose.ambienceContext)
                        .oasisFont(size: 12, weight: .medium, relativeTo: .subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 9) {
                    ForEach(planRows) { row in
                        AmbiencePlanRowView(row: row)
                    }
                }
            }
            .padding(16)
            .background {
                Color(red: 0.035, green: 0.045, blue: 0.075)
                    .overlay {
                        LinearGradient(
                            colors: [
                                option.intent.tint.opacity(0.15),
                                Color.white.opacity(0.020)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: option.intent.tint.opacity(0.18), radius: 24, y: 14)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compose.ambience.detail")
    }
}

private struct AmbienceSpatialPreview: View {
    let recipe: AmbienceRecipe

    private var previewChannels: [(channel: SoundChannel, state: ChannelState)] {
        SoundChannel.allCases.compactMap { channel in
            guard let state = recipe.channels[channel], !state.isMuted else { return nil }
            return (channel, state)
        }
    }

    private var previewNoises: [ProceduralNoise] {
        ProceduralNoise.allCases.filter { noise in
            recipe.proceduralNoises[noise]?.isMuted == false
        }
    }

    private var haloColors: [Color] {
        let channelColors = previewChannels.prefix(4).map { $0.channel.tint.opacity(0.72) }
        let noiseColors = previewNoises.prefix(2).map { $0.tint.opacity(0.52) }
        let binauralColor = recipe.isBinauralActive ? [recipe.binauralTrack.tint.opacity(0.60)] : []
        let colors = Array(channelColors + noiseColors + binauralColor)
        return colors.isEmpty ? [recipe.intent.tint.opacity(0.70), .white.opacity(0.24)] : colors
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(.black.opacity(0.22))
                    .overlay {
                        AngularGradient(
                            colors: haloColors + [haloColors.first ?? recipe.intent.tint.opacity(0.70)],
                            center: .center
                        )
                        .opacity(0.30)
                        .blur(radius: 8)
                    }

                Circle()
                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    .padding(1)

                Circle()
                    .strokeBorder(Color.white.opacity(0.11), style: StrokeStyle(lineWidth: 0.8, dash: [2.5, 4]))
                    .padding(18)

                Circle()
                    .fill(.white.opacity(0.88))
                    .frame(width: 7, height: 7)
                    .shadow(color: .white.opacity(0.24), radius: 8)

                ForEach(Array(previewChannels.prefix(5).enumerated()), id: \.element.channel.id) { index, item in
                    layerDot(channel: item.channel, index: index)
                        .position(position(for: item.state.spatialPosition, in: proxy.size, index: index))
                }

                if !previewNoises.isEmpty || recipe.isBinauralActive {
                    maskStrip
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 8)
                }
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(Circle())
        .overlay {
            Circle()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: recipe.intent.tint.opacity(0.26), radius: 18, y: 8)
        .accessibilityHidden(true)
    }

    private func layerDot(channel: SoundChannel, index: Int) -> some View {
        ZStack {
            Circle()
                .fill(channel.tint.opacity(index == 0 ? 0.96 : 0.82))
                .shadow(color: channel.tint.opacity(0.36), radius: index == 0 ? 9 : 6, y: 2)

            OasisGlyphImage(glyph: channel.oasisGlyph)
                .foregroundStyle(.black.opacity(0.78))
                .frame(width: index == 0 ? 12 : 10, height: index == 0 ? 12 : 10)
        }
        .frame(width: index == 0 ? 25 : 21, height: index == 0 ? 25 : 21)
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.35), lineWidth: 0.8)
        }
    }

    private var maskStrip: some View {
        HStack(spacing: -3) {
            ForEach(previewNoises.prefix(2)) { noise in
                Circle()
                    .fill(noise.tint.opacity(0.78))
                    .frame(width: 10, height: 10)
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.32), lineWidth: 0.6)
                    }
            }

            if recipe.isBinauralActive {
                Image(systemName: "waveform.path")
                    .oasisFont(size: 7, weight: .bold, design: .default, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(0.88))
                    .frame(width: 16, height: 16)
                    .background {
                        Circle()
                            .fill(recipe.binauralTrack.tint.opacity(0.78))
                    }
                    .overlay {
                        Circle().strokeBorder(.white.opacity(0.32), lineWidth: 0.6)
                    }
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .background {
            Capsule(style: .continuous)
                .fill(.black.opacity(0.32))
        }
    }

    private func position(for point: SpatialPoint, in size: CGSize, index: Int) -> CGPoint {
        let inset: CGFloat = 18
        let width = max(size.width - inset * 2, 1)
        let height = max(size.height - inset * 2, 1)
        let normalizedX = min(max((point.x + 1) / 2, 0), 1)
        let normalizedY = min(max((point.y + 1) / 2, 0), 1)

        let fallbackAngles: [CGFloat] = [-.pi * 0.18, .pi * 0.86, .pi * 0.38, -.pi * 0.66, .pi * 1.18]
        let distance = hypot(point.x, point.y)
        if distance < 0.04, index < fallbackAngles.count {
            let radius = min(width, height) * 0.31
            return CGPoint(
                x: size.width / 2 + cos(fallbackAngles[index]) * radius,
                y: size.height / 2 + sin(fallbackAngles[index]) * radius
            )
        }

        return CGPoint(
            x: inset + CGFloat(normalizedX) * width,
            y: inset + CGFloat(1 - normalizedY) * height
        )
    }
}

private struct AmbiencePlanRow: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let value: String
    let glyph: OasisGlyph
    let tint: Color
}

private struct AmbiencePlanRowView: View {
    let row: AmbiencePlanRow

    var body: some View {
        HStack(spacing: 10) {
            OasisGlyphImage(glyph: row.glyph)
                .foregroundStyle(row.tint)
                .frame(width: 14, height: 14)
                .frame(width: 24, height: 24)
                .background {
                    Circle()
                        .fill(row.tint.opacity(0.14))
                }
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.title)
                    .oasisFont(size: 10, weight: .bold, relativeTo: .caption2)
                    .foregroundStyle(.white.opacity(0.46))
                    .lineLimit(1)

                Text(row.value)
                    .oasisFont(size: 12, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(.white.opacity(0.90))
                    .lineLimit(2)
                    .minimumScaleFactor(0.80)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
            shape
                .fill(Color.white.opacity(0.052))
                .overlay {
                    shape.fill(
                        LinearGradient(
                            colors: [
                                row.tint.opacity(0.10),
                                Color.white.opacity(0.012)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .clipShape(shape)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.075), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ComposePanelBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.015, green: 0.025, blue: 0.060)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.15, blue: 0.24).opacity(0.52),
                    Color(red: 0.03, green: 0.05, blue: 0.10).opacity(0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AmbienceIntent.sleep.tint.opacity(0.13),
                                AmbienceIntent.focus.tint.opacity(0.06),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                    .mask(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.30), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Spacer()
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
        }
    }
}

private enum ComposeCTAStyle {
    enum Palette {
        case save
        case launch

        var primary: Color {
            switch self {
            case .save:
                return Color(red: 0.80, green: 0.70, blue: 0.98)
            case .launch:
                return Color(red: 0.68, green: 0.94, blue: 0.78)
            }
        }

        var secondary: Color {
            switch self {
            case .save:
                return Color(red: 0.54, green: 0.82, blue: 0.95)
            case .launch:
                return Color(red: 0.94, green: 0.82, blue: 0.52)
            }
        }
    }

    static let save = Palette.save
}

private struct ComposePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let palette: ComposeCTAStyle.Palette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .oasisFont(size: 15, weight: .bold, relativeTo: .headline)
            .foregroundStyle(Color(red: 0.04, green: 0.06, blue: 0.10).opacity(isEnabled ? 1 : 0.70))
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.primary.opacity(isEnabled ? 0.98 : 0.44),
                                palette.secondary.opacity(isEnabled ? 0.84 : 0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        if !isEnabled {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.13), lineWidth: 1)
                        }
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
            .animation(.smooth(duration: 0.20), value: isEnabled)
    }
}

private extension AmbienceIntent {
    var title: String {
        switch self {
        case .sleep: return L10n.string(L10n.Compose.intentSleep)
        case .focus: return L10n.string(L10n.Compose.intentFocus)
        case .travel: return L10n.string(L10n.Compose.intentTravel)
        case .reading: return L10n.string(L10n.Compose.intentReading)
        case .reset: return L10n.string(L10n.Compose.intentReset)
        }
    }
}

private extension ProceduralNoise {
    var title: String {
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
