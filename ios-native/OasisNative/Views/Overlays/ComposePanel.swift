import SwiftUI

private struct PromptSuggestion: Identifiable {
    let kind: GuidedRoutineKind
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let intent: AmbienceIntent
    let backdrop: SoundBackdrop

    var id: String { kind.id }
    var requiresPremium: Bool { kind.requiresPremium }

    static let builtIns: [PromptSuggestion] = [
        PromptSuggestion(
            kind: .nap,
            title: L10n.Compose.routineNapTitle,
            subtitle: L10n.Compose.routineNapSubtitle,
            intent: .sleep,
            backdrop: OrganicBackdrop.darkSatin
        ),
        PromptSuggestion(
            kind: .reset,
            title: L10n.Compose.routineResetTitle,
            subtitle: L10n.Compose.routineResetSubtitle,
            intent: .reset,
            backdrop: OrganicBackdrop.warmFabric
        ),
        PromptSuggestion(
            kind: .deepSleep,
            title: L10n.Compose.routineDeepSleepTitle,
            subtitle: L10n.Compose.routineDeepSleepSubtitle,
            intent: .sleep,
            backdrop: OrganicBackdrop.darkWater
        ),
        PromptSuggestion(
            kind: .deepWork,
            title: L10n.Compose.routineDeepWorkTitle,
            subtitle: L10n.Compose.routineDeepWorkSubtitle,
            intent: .focus,
            backdrop: OrganicBackdrop.blueFlow
        ),
        PromptSuggestion(
            kind: .noisyHotel,
            title: L10n.Compose.routineNoisyHotelTitle,
            subtitle: L10n.Compose.routineNoisyHotelSubtitle,
            intent: .travel,
            backdrop: OrganicBackdrop.blueFabric
        ),
        PromptSuggestion(
            kind: .reading,
            title: L10n.Compose.routineReadingTitle,
            subtitle: L10n.Compose.routineReadingSubtitle,
            intent: .reading,
            backdrop: OrganicBackdrop.warmFabric
        ),
        PromptSuggestion(
            kind: .rainCabin,
            title: L10n.Compose.routineRainCabinTitle,
            subtitle: L10n.Compose.routineRainCabinSubtitle,
            intent: .sleep,
            backdrop: OrganicBackdrop.darkSatin
        ),
        PromptSuggestion(
            kind: .morning,
            title: L10n.Compose.routineMorningTitle,
            subtitle: L10n.Compose.routineMorningSubtitle,
            intent: .reset,
            backdrop: OrganicBackdrop.blueFlow
        )
    ]
}

struct ComposePanel: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSuggestionID = PromptSuggestion.builtIns[0].id
    @State private var startingSuggestionID: String?
    @State private var didSeedSelectionFromActiveRoutine = false

    private let selectorColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var selectedSuggestion: PromptSuggestion {
        PromptSuggestion.builtIns.first { $0.id == selectedSuggestionID } ?? PromptSuggestion.builtIns[0]
    }

    private var selectedRecipe: AmbienceRecipe {
        model.composeGuidedRoutine(selectedSuggestion.kind)
    }

    private var selectedRoutineIsActive: Bool {
        model.activeComposerRecipeTitle == selectedRecipe.title
    }

    private var selectedRoutineIsLocked: Bool {
        selectedSuggestion.requiresPremium && !model.isPremium
    }

    private var routineCTA: (title: LocalizedStringResource, systemImage: String, isDisabled: Bool) {
        if startingSuggestionID == selectedSuggestion.id {
            return (L10n.HomeActive.listening, "checkmark", true)
        }

        if selectedRoutineIsActive {
            return (L10n.HomeActive.stopRoutine, "stop.fill", false)
        }

        if selectedRoutineIsLocked {
            return (L10n.Premium.inlineUnlock, "lock.fill", false)
        }

        if model.activeComposerRecipeTitle != nil {
            return (L10n.Compose.routineReplace, "arrow.triangle.2.circlepath", false)
        }

        return (L10n.Compose.routineStart, "play.fill", false)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ComposePanelBackground()

                VStack(spacing: 0) {
                    header

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            composerInlineUpsell
                            routineSelector

                            RoutineDetailCard(
                                suggestion: selectedSuggestion,
                                recipe: selectedRecipe,
                                isLocked: selectedRoutineIsLocked
                            )
                            .id(selectedSuggestion.id)
                            .transition(.opacity.combined(with: .scale(scale: 0.985, anchor: .top)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 112)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    startRoutineBar
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear(perform: seedSelectionFromActiveRoutine)
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

    private var routineSelector: some View {
        LazyVGrid(columns: selectorColumns, alignment: .leading, spacing: 8) {
            ForEach(PromptSuggestion.builtIns) { suggestion in
                RoutineSelectorButton(
                    suggestion: suggestion,
                    isSelected: selectedSuggestionID == suggestion.id,
                    isLocked: suggestion.requiresPremium && !model.isPremium
                ) {
                    withAnimation(.smooth(duration: 0.24, extraBounce: 0.02)) {
                        selectedSuggestionID = suggestion.id
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compose.routine.selector")
    }

    @ViewBuilder
    private var composerInlineUpsell: some View {
        if let presentation = model.composerUpsellPresentation {
            PremiumInlineUpsellCard(
                presentation: presentation,
                onPrimaryAction: {
                    if let entryPoint = model.activeInlineUpsell?.entryPoint {
                        model.presentPaywall(from: entryPoint)
                    }
                },
                onSecondaryAction: {
                    model.dismissInlineUpsell()
                },
                onDismiss: {
                    model.dismissInlineUpsell()
                }
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var startRoutineBar: some View {
        VStack(spacing: 0) {
            Button {
                startGuidedSuggestion(selectedSuggestion)
            } label: {
                Label(routineCTA.title, systemImage: routineCTA.systemImage)
                .oasisFont(size: 15, weight: .bold, design: .default, relativeTo: .headline)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ComposePrimaryButtonStyle(tint: selectedSuggestion.intent.tint))
            .disabled(routineCTA.isDisabled)
            .accessibilityIdentifier("compose.routine.start")
            .animation(.smooth(duration: 0.20), value: selectedRoutineIsActive)
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

    private func startGuidedSuggestion(_ suggestion: PromptSuggestion) {
        let guidedRecipe = model.composeGuidedRoutine(suggestion.kind)

        if model.activeComposerRecipeTitle == guidedRecipe.title {
            withAnimation(.smooth(duration: 0.24)) {
                model.stopGuidedRoutine()
                dismiss()
            }
            return
        }

        withAnimation(.smooth(duration: 0.24)) {
            let didApply = model.applyAmbienceRecipe(guidedRecipe)
            if didApply {
                startingSuggestionID = suggestion.id
                Task {
                    try? await Task.sleep(nanoseconds: 420_000_000)
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        }
    }

    private func seedSelectionFromActiveRoutine() {
        guard !didSeedSelectionFromActiveRoutine else { return }
        didSeedSelectionFromActiveRoutine = true

        guard let activeTitle = model.activeComposerRecipeTitle else { return }
        guard let activeSuggestion = PromptSuggestion.builtIns.first(where: { suggestion in
            model.composeGuidedRoutine(suggestion.kind).title == activeTitle
        }) else { return }

        selectedSuggestionID = activeSuggestion.id
    }
}

private struct RoutineSelectorButton: View {
    let suggestion: PromptSuggestion
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                OasisGlyphImage(glyph: suggestion.intent.oasisGlyph)
                    .foregroundStyle(isSelected ? Color(red: 0.05, green: 0.06, blue: 0.09) : suggestion.intent.tint)
                    .frame(width: 16, height: 16)
                    .frame(width: 30, height: 30)
                    .background {
                        Circle()
                            .fill(isSelected ? .white.opacity(0.90) : suggestion.intent.tint.opacity(0.13))
                    }

                Text(suggestion.title)
                    .oasisFont(size: 12, weight: .semibold, relativeTo: .subheadline)
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.68))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Spacer(minLength: 0)

                if isLocked {
                    Image(systemName: "lock.fill")
                        .oasisFont(size: 9, weight: .bold, design: .default, relativeTo: .caption2)
                        .foregroundStyle(Color(red: 0.96, green: 0.83, blue: 0.45).opacity(isSelected ? 0.96 : 0.72))
                        .accessibilityHidden(true)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .background {
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.105 : 0.040))
                    .overlay {
                        Capsule(style: .continuous)
                            .fill(suggestion.intent.tint.opacity(isSelected ? 0.13 : 0.04))
                    }
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(
                        isSelected ? suggestion.intent.tint.opacity(0.42) : Color.white.opacity(0.07),
                        lineWidth: 1
                    )
            }
        }
        .oasisMinimumHitTarget()
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(Text(suggestion.subtitle))
        .accessibilityValue(isLocked ? Text(L10n.Compose.premium) : Text(L10n.Compose.free))
        .accessibilityIdentifier("compose.guided.\(suggestion.id)")
    }
}

private struct RoutineDetailCard: View {
    let suggestion: PromptSuggestion
    let recipe: AmbienceRecipe
    let isLocked: Bool

    private var planRows: [RoutinePlanRow] {
        var rows: [RoutinePlanRow] = []

        let ambience = compactLayerList(recipe.activeChannels.map(\.localizedName), visibleLimit: 4)
        if !ambience.isEmpty {
            rows.append(
                RoutinePlanRow(
                    id: "ambience",
                    title: L10n.Compose.routineLayerAmbience,
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
                RoutinePlanRow(
                    id: "mask",
                    title: L10n.Compose.routineLayerMask,
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
                OrganicBackdropImage(backdrop: suggestion.backdrop, opacity: 1, bottomShadeOpacity: 0.42)

                LinearGradient(
                    colors: [
                        suggestion.intent.tint.opacity(0.26),
                        Color.black.opacity(0.06),
                        Color.black.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RoutineSpatialPreview(recipe: recipe)
                    .padding(.top, 18)
                    .padding(.trailing, 18)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                VStack(alignment: .leading, spacing: 13) {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            OasisGlyphImage(glyph: suggestion.intent.oasisGlyph)
                                .frame(width: 13, height: 13)

                            Text(verbatim: suggestion.intent.title)
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
                            Text("\(L10n.string(L10n.Compose.routineLayerEnd)) · \(L10n.timerOptionLabel(minutes: timerMinutes))")
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
                    Text(L10n.Compose.routinePlan)
                        .oasisFont(size: 16, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(.white.opacity(0.96))
                        .accessibilityIdentifier("compose.routine.plan")

                    Text(L10n.Compose.routineContext)
                        .oasisFont(size: 12, weight: .medium, relativeTo: .subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 9) {
                    ForEach(planRows) { row in
                        RoutinePlanRowView(row: row)
                    }
                }
            }
            .padding(16)
            .background {
                Color(red: 0.035, green: 0.045, blue: 0.075)
                    .overlay {
                        LinearGradient(
                            colors: [
                                suggestion.intent.tint.opacity(0.15),
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
        .shadow(color: suggestion.intent.tint.opacity(0.18), radius: 24, y: 14)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compose.routine.detail")
    }
}

private struct RoutineSpatialPreview: View {
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

private struct RoutinePlanRow: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let value: String
    let glyph: OasisGlyph
    let tint: Color
}

private struct RoutinePlanRowView: View {
    let row: RoutinePlanRow

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

private struct ComposePrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let tint: Color

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
                                tint.opacity(isEnabled ? 0.98 : 0.44),
                                tint.opacity(isEnabled ? 0.74 : 0.30)
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
