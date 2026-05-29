import Foundation
import Observation
import RevenueCat
import StoreKit
import SwiftUI

@MainActor
@Observable
final class AppModel {
    var isPlaying = false
    var timerDurationMinutes: Int?
    var timerEndDate: Date?
    var timerRemainingWhenPaused: TimeInterval?
    var currentPresetID: String?
    var activeComposerRecipeTitle: String?
    var activeNoiseBlendTitle: String?

    var isPremium = AppConfiguration.forcedPremiumAccess ?? false
    var activePaywallContext: PremiumPaywallContext?
    var activeInlineUpsell: PremiumInlineUpsellContext?
    var showsComposePanel = false
    var showsBinauralPanel = false
    var showsPresetsPanel = false
    var showsSpatialPanel = false
    var showsOnlyActiveChannels = false
    var showsPremiumHomeBanner = false
    var isSignaturePreviewActive = false
    var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: OnboardingDefaults.completedKey)

    var isBinauralActive = false
    var activeBinauralTrack: BinauralTrack = .delta
    var binauralVolume = 0.5

    /// Global opt-in rendering mode that pushes ambient channels farther into the
    /// AVAudioEnvironment scene without touching the separate binaural player path.
    var immersiveAudioEnabled = false

    var channels: [SoundChannel: ChannelState] = .initialChannels
    var proceduralNoises: [ProceduralNoise: ProceduralNoiseState] = .initialNoises
    var presets: [Preset] = .defaultPresets()
    var activeRitualSession: ActiveRitualSession?
    var premiumBannerLastDismissedAt: Date?
    var signaturePreviewLastPlayedAt: Date?
    var deletedDefaultPresetIDs = Set<String>()

    var timerDisplayValue: TimeInterval?
    private(set) var variationDisplayVolumes: [SoundChannel: Double] = [:]

    @ObservationIgnored private let audioEngine = AudioMixerEngine()
    @ObservationIgnored private let gentleReminderScheduler = GentleReminderScheduler()
    @ObservationIgnored private let revenueCatObserver = RevenueCatObserver()
    @ObservationIgnored private let premiumCoordinator = PremiumCoordinator()
    @ObservationIgnored private let premiumRevenueCatService = PremiumRevenueCatService()
    @ObservationIgnored private let premiumAnalytics: any PremiumAnalyticsSink = {
        #if canImport(TelemetryDeck)
        if AppConfiguration.isTelemetryDeckConfigured {
            return TelemetryDeckAnalyticsSink()
        }
        #endif
        return LoggerPremiumAnalyticsSink()
    }()
    @ObservationIgnored private var timerTicker: Timer?
    @ObservationIgnored private var bootstrapTask: Task<Void, Never>?
    @ObservationIgnored private var persistenceTask: Task<Void, Never>?
    @ObservationIgnored private var premiumBannerTask: Task<Void, Never>?
    @ObservationIgnored private var signaturePreviewTask: Task<Void, Never>?
    @ObservationIgnored private var ritualTask: Task<Void, Never>?
    @ObservationIgnored private var activeRitualPreset: RitualPreset?
    @ObservationIgnored private var listened60sTask: Task<Void, Never>?
    @ObservationIgnored private var reviewPromptTask: Task<Void, Never>?
    @ObservationIgnored private var listeningStartedAt: Date?
    @ObservationIgnored private var didBootstrap = false
    @ObservationIgnored private var revenueCatHasPremium = false
    @ObservationIgnored private var screenshotShuffleIndex = 0
    @ObservationIgnored private var previewUnlockedChannels = Set<SoundChannel>()
    @ObservationIgnored private var previewUnlockedTracks = Set<BinauralTrack>()
    @ObservationIgnored private var signaturePreviewRestoreState: SignaturePreviewRestoreState?

    var mixerSnapshot: MixerSnapshot {
        MixerSnapshot(
            isPlaying: isPlaying,
            isPremium: isPremium,
            channels: channels,
            proceduralNoises: proceduralNoises,
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume,
            previewUnlockedChannels: previewUnlockedChannels,
            previewUnlockedTracks: previewUnlockedTracks,
            immersiveAudioEnabled: immersiveAudioEnabled
        )
    }

    var homeBannerPresentation: PremiumHomeBannerPresentation {
        PremiumHomeBannerPresentation(
            title: L10n.string(L10n.Premium.bannerTitle),
            message: L10n.string(L10n.Premium.bannerSubtitle),
            ctaTitle: L10n.string(L10n.Premium.bannerCTA)
        )
    }

    var libraryTeaserPresentation: PremiumLibraryTeaserPresentation {
        let lockedCount = max(SoundChannel.allCases.count - SoundChannel.freeChannels.count, 0)

        return PremiumLibraryTeaserPresentation(
            title: L10n.string(L10n.Premium.libraryTitle),
            badgeTitle: "+\(lockedCount)",
            message: L10n.string(L10n.Premium.librarySubtitle),
            ctaTitle: L10n.string(L10n.Premium.libraryCTA),
            expandTitle: L10n.string(L10n.Premium.libraryExpand),
            collapseTitle: L10n.string(L10n.Premium.libraryCollapse),
            lockedCount: lockedCount
        )
    }

    var presetsUpsellPresentation: PremiumInlineUpsellPresentation? {
        guard activeInlineUpsell?.entryPoint.category == .preset else { return nil }

        let secondaryActionTitle = isSignaturePreviewAvailable
            ? L10n.string(L10n.Premium.previewCTA)
            : L10n.string(L10n.Premium.inlineNotNow)
        let footnote: String?
        if isSignaturePreviewActive {
            footnote = L10n.string(L10n.Premium.previewPlaying)
        } else if !isSignaturePreviewAvailable {
            footnote = L10n.string(L10n.Premium.previewLimit)
        } else {
            footnote = nil
        }

        return PremiumInlineUpsellPresentation(
            title: L10n.string(L10n.Premium.inlinePresetTitle),
            message: L10n.string(L10n.Premium.inlinePresetSubtitle),
            primaryActionTitle: L10n.string(L10n.Premium.inlineUnlock),
            secondaryActionTitle: secondaryActionTitle,
            footnote: footnote,
            symbolName: "bookmark.fill",
            accentToken: .preset
        )
    }

    var binauralUpsellPresentation: PremiumInlineUpsellPresentation? {
        guard activeInlineUpsell?.entryPoint.category == .binaural else { return nil }

        return PremiumInlineUpsellPresentation(
            title: L10n.string(L10n.Premium.inlineBinauralTitle),
            message: L10n.string(L10n.Premium.inlineBinauralSubtitle),
            primaryActionTitle: L10n.string(L10n.Premium.inlineUnlock),
            secondaryActionTitle: L10n.string(L10n.Premium.inlineNotNow),
            footnote: nil,
            symbolName: "waveform.path",
            accentToken: .binaural
        )
    }

    var composerUpsellPresentation: PremiumInlineUpsellPresentation? {
        guard let entryPoint = activeInlineUpsell?.entryPoint else { return nil }

        switch entryPoint.category {
        case .composer, .ritual, .noise:
            return PremiumInlineUpsellPresentation(
                title: L10n.string(L10n.Paywall.titleComposer),
                message: L10n.string(L10n.Paywall.subtitleComposer),
                primaryActionTitle: L10n.string(L10n.Premium.inlineUnlock),
                secondaryActionTitle: L10n.string(L10n.Premium.inlineNotNow),
                footnote: nil,
                symbolName: entryPoint.symbolName,
                accentToken: .composer
            )
        case .manual, .onboarding, .sound, .timer, .preset, .binaural, .spatial, .preview:
            return nil
        }
    }

    var paywallPresentation: PremiumPaywallPresentation? {
        guard let context = activePaywallContext else { return nil }
        return paywallPresentation(for: context.entryPoint)
    }

    var isSignaturePreviewAvailable: Bool {
        guard presets.contains(where: \.isSignature) else { return false }
        return premiumCoordinator.canStartSignaturePreview(lastPlayedAt: signaturePreviewLastPlayedAt)
    }

    init() {
        resetOnboardingIfRequested()
        let didLoadPersistedState = loadPersistedState()

        if !didLoadPersistedState && !AppConfiguration.shouldResetStateOnLaunch {
            channels = .starterChannels
            persistState()
        }

        applyLaunchArgumentOverrides()
        configureCallbacks()
        trackAppSession()
        handleNoActiveChannelsIfNeeded()
        updateTimerDisplayValue()
        synchronizeAudio()
    }

    func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true

        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else {
            applyEffectivePremiumAccess()
            return
        }

        Purchases.shared.delegate = revenueCatObserver

        bootstrapTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshPremiumStatus()
        }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            gentleReminderScheduler.appBecameActive(onboardingCompleted: hasCompletedOnboarding)
        case .background:
            gentleReminderScheduler.appEnteredBackground(onboardingCompleted: hasCompletedOnboarding)
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func channelName(_ channel: SoundChannel) -> String {
        channel.localizedName
    }

    func presetDisplayName(_ preset: Preset) -> String {
        if preset.isDefault,
           let defaultPreset = Array.defaultPresets().first(where: { $0.id == preset.id }),
           preset.name != defaultPreset.name {
            return preset.name
        }

        switch preset.id {
        case "preset_default_nap":
            return L10n.string(L10n.Presets.defaultNap)
        case "preset_default_reset":
            return L10n.string(L10n.Presets.defaultReset)
        case "preset_default_starter":
            return L10n.string(L10n.Presets.defaultStarter)
        case "preset_default_deep_sleep":
            return L10n.string(L10n.Presets.defaultDeepSleep)
        case "preset_default_deep_work":
            return L10n.string(L10n.Presets.defaultDeepWork)
        case "preset_default_travel":
            return L10n.string(L10n.Presets.defaultTravel)
        case "preset_default_reading":
            return L10n.string(L10n.Presets.defaultReading)
        case "preset_default_rain_cabin":
            return L10n.string(L10n.Presets.defaultRainCabin)
        case "preset_default_morning":
            return L10n.string(L10n.Presets.defaultMorning)
        case "preset_default_calm":
            return L10n.string(L10n.Presets.defaultCalm)
        case "preset_default_storm":
            return L10n.string(L10n.Presets.defaultStorm)
        case "preset_signature_oasis":
            return L10n.string(L10n.Presets.afterTheRain)
        default:
            return preset.name
        }
    }

    func isChannelLocked(_ channel: SoundChannel) -> Bool {
        !isPremium && !SoundChannel.freeChannels.contains(channel)
    }

    func isPresetLocked(_ preset: Preset) -> Bool {
        !isPremium && preset.requiresPremium
    }

    func canEditPreset(_: Preset) -> Bool {
        isPremium
    }

    func canDeletePreset(_ preset: Preset) -> Bool {
        isPremium || preset.isUser
    }

    var userCreatedPresets: [Preset] {
        presets.filter(\.isUser)
    }

    func exportUserPresetsData() throws -> Data {
        let archive = PresetExportArchive(
            exportedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "",
            presets: userCreatedPresets
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(archive)
    }

    func isAmbientChannelActive(_ channel: SoundChannel) -> Bool {
        guard let state = channels[channel] else { return false }
        return !state.isMuted && hasAmbientPlaybackAccess(to: channel)
    }

    var activeAmbientChannelsCount: Int {
        SoundChannel.allCases.filter(isAmbientChannelActive(_:)).count
    }

    func isProceduralNoiseLocked(_ noise: ProceduralNoise) -> Bool {
        !isPremium && noise.isPremium
    }

    func isProceduralNoiseActive(_ noise: ProceduralNoise) -> Bool {
        guard let state = proceduralNoises[noise] else { return false }
        return !state.isMuted && !isProceduralNoiseLocked(noise)
    }

    var activeProceduralNoiseCount: Int {
        ProceduralNoise.allCases.filter(isProceduralNoiseActive(_:)).count
    }

    var activeAudioSourceCount: Int {
        activeAmbientChannelsCount + activeProceduralNoiseCount + (isBinauralActive ? 1 : 0)
    }

    var activeRitualNextPhaseTitle: String? {
        guard let session = activeRitualSession else { return nil }
        let nextIndex = session.phaseIndex + 1
        let ritual = activeRitualDefinition(for: session)

        guard let ritual, ritual.phases.indices.contains(nextIndex) else { return nil }
        return ritual.phases[nextIndex].title
    }

    var activeRitualCurrentPhaseSubtitle: String? {
        guard
            let session = activeRitualSession,
            let ritual = activeRitualDefinition(for: session),
            ritual.phases.indices.contains(session.phaseIndex)
        else { return nil }

        return ritual.phases[session.phaseIndex].subtitle
    }

    var activeRitualCurrentPhaseRecipe: AmbienceRecipe? {
        guard
            let session = activeRitualSession,
            let ritual = activeRitualDefinition(for: session),
            ritual.phases.indices.contains(session.phaseIndex)
        else { return nil }

        return ritual.phases[session.phaseIndex].recipe
    }

    /// Ordered palette of channel tints for every unmuted ambient channel, shaped for the
    /// liquid aura that breathes inside the main play/pause button.
    var activePlaybackPalette: [Color] {
        let colors = SoundChannel.allCases.compactMap { channel -> Color? in
            guard let state = channels[channel], !state.isMuted else { return nil }
            return channel.tint
        } + ProceduralNoise.allCases.compactMap { noise -> Color? in
            guard let state = proceduralNoises[noise], !state.isMuted else { return nil }
            return noise.tint
        }
        return LiquidActivityPalette.playback(from: colors)
    }

    var timerToolbarTitle: String {
        if let timerDisplayValue {
            return formatTimer(timerDisplayValue)
        }

        if let timerDurationMinutes {
            return L10n.timerOptionLabel(minutes: timerDurationMinutes)
        }

        return L10n.string(L10n.Header.timer)
    }

    var activePreset: Preset? {
        guard let currentPresetID else { return nil }
        return presets.first { $0.id == currentPresetID }
    }

    var isAmbiencePlaybackLocked: Bool {
        activeComposerRecipeTitle != nil
    }

    var canSaveFreePreset: Bool {
        guard !isPremium else { return true }
        guard currentMixUsesOnlyFreeChannels else { return false }
        return presets.filter(\.isUser).isEmpty
    }

    func channelState(for channel: SoundChannel) -> ChannelState {
        channels[channel] ?? ChannelState()
    }

    func displayVolume(for channel: SoundChannel) -> Double {
        guard let state = channels[channel] else { return 0.5 }

        if state.autoVariationEnabled, !state.isMuted, let liveValue = variationDisplayVolumes[channel] {
            return liveValue
        }

        return state.volume
    }

    func openBinauralPanel() {
        prepareBinauralPanel()
        showsPresetsPanel = false
        showsBinauralPanel = true
    }

    func prepareBinauralPanel() {
        audioEngine.preloadBinauralTrack(activeBinauralTrack)
    }

    func openPresetsPanel() {
        showsBinauralPanel = false
        showsPresetsPanel = true
    }

    func togglePlayback() {
        setPlayback(!isPlaying)
    }

    func setPlayback(_ shouldPlay: Bool) {
        guard isPlaying != shouldPlay else { return }
        isPlaying = shouldPlay

        if shouldPlay {
            beginListeningSession()
            if let pausedRemaining = timerRemainingWhenPaused, timerDurationMinutes != nil {
                timerEndDate = Date().addingTimeInterval(pausedRemaining)
            }
            resumeActiveRitualIfNeeded()
            schedulePremiumBannerIfNeeded()
        } else if let endDate = timerEndDate {
            endListeningSession()
            pauseActiveRitualIfNeeded()
            timerRemainingWhenPaused = max(endDate.timeIntervalSinceNow, 0)
            timerEndDate = nil
            cancelPremiumBannerScheduling()
        } else {
            endListeningSession()
            cancelPremiumBannerScheduling()
        }

        startTimerTickerIfNeeded()
        updateTimerDisplayValue()
        schedulePersistence()
        synchronizeAudio()
    }

    func canUseTimer(minutes: Int?) -> Bool {
        isPremium || minutes == nil || minutes == 15 || minutes == 30
    }

    func setTimer(_ minutes: Int?) {
        guard canUseTimer(minutes: minutes) else {
            requestPremiumAccess(from: .timer)
            return
        }

        cancelActiveRitual()
        currentPresetID = nil
        timerDurationMinutes = minutes
        timerRemainingWhenPaused = minutes.map { Double($0 * 60) }
        timerEndDate = minutes.map { Date().addingTimeInterval(Double($0 * 60)) }
        startTimerTickerIfNeeded()
        updateTimerDisplayValue()
        premiumAnalytics.track(.timerSet(minutes: minutes))
        persistState()
    }

    func randomizeMix() {
        let availableChannels = isPremium ? SoundChannel.allCases : Array(SoundChannel.freeChannels)
        if AppConfiguration.isRunningScreenshotAutomation {
            applyScreenshotShuffle(availableChannels: availableChannels)
            return
        }

        finishSignaturePreview(restoreState: false, shouldPromotePaywall: false)
        cancelActiveRitual()

        var newChannels = [SoundChannel: ChannelState].initialChannels
        let maxActive = min(8, availableChannels.count)
        let minActive = min(2, availableChannels.count)
        let count = Int.random(in: minActive...maxActive)
        let selection = availableChannels.shuffled().prefix(count)

        for channel in selection {
            newChannels[channel] = ChannelState(
                volume: Double.random(in: 0.3...0.8),
                isMuted: false,
                autoVariationEnabled: Bool.random()
            )
        }

        channels = newChannels
        variationDisplayVolumes.removeAll()
        currentPresetID = nil
        activeComposerRecipeTitle = nil

        if !isPlaying {
            isPlaying = true
            beginListeningSession()
            if let minutes = timerDurationMinutes {
                let remaining = timerRemainingWhenPaused ?? Double(minutes * 60)
                timerEndDate = Date().addingTimeInterval(remaining)
            }
            startTimerTickerIfNeeded()
            schedulePremiumBannerIfNeeded()
        }

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        persistState()
        updateTimerDisplayValue()
        synchronizeAudio()
    }

    func setChannelVolume(_ channel: SoundChannel, value: Double) {
        guard !isAmbiencePlaybackLocked else { return }
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        let clampedValue = AutoVariationRange.unitValue(value, fallback: state.volume)
        cancelActiveRitual()
        state.volume = clampedValue
        if !state.autoVariationEnabled {
            state.autoVariationRange = .defaultRange(around: clampedValue)
        }
        channels[channel] = state
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func setChannelAutoVariationRange(_ channel: SoundChannel, range: AutoVariationRange) {
        guard !isAmbiencePlaybackLocked else { return }
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        let clampedRange = range.clamped()
        cancelActiveRitual()
        let liveVolume = variationDisplayVolumes[channel] ?? state.volume
        let clampedLiveVolume = clampedRange.clampedValue(liveVolume)

        state.autoVariationRange = clampedRange
        state.volume = clampedRange.clampedValue(state.volume)
        channels[channel] = state

        if state.autoVariationEnabled, !state.isMuted {
            variationDisplayVolumes[channel] = clampedLiveVolume
        }

        currentPresetID = nil
        activeComposerRecipeTitle = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func toggleMute(_ channel: SoundChannel) {
        guard !isAmbiencePlaybackLocked else { return }
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        cancelActiveRitual()
        state.isMuted.toggle()
        channels[channel] = state
        if state.isMuted {
            variationDisplayVolumes.removeValue(forKey: channel)
        } else if state.autoVariationEnabled {
            variationDisplayVolumes[channel] = state.autoVariationRange.clampedValue(state.volume)
        }
        currentPresetID = nil
        activeComposerRecipeTitle = nil

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        schedulePersistence()
        synchronizeAudio()
    }

    func toggleAutoVariation(_ channel: SoundChannel) {
        guard !isAmbiencePlaybackLocked else { return }
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        cancelActiveRitual()
        state.autoVariationEnabled.toggle()
        if state.autoVariationEnabled {
            state.volume = state.autoVariationRange.clampedValue(state.volume)
        } else if let liveValue = variationDisplayVolumes[channel] {
            state.volume = min(max(liveValue, 0), 1)
        }
        channels[channel] = state
        if state.autoVariationEnabled {
            variationDisplayVolumes[channel] = state.volume
        } else {
            variationDisplayVolumes.removeValue(forKey: channel)
        }
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func setChannelSpatialPosition(_ channel: SoundChannel, value: SpatialPoint) {
        guard !isAmbiencePlaybackLocked else { return }
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .spatial(channel))
            return
        }

        cancelActiveRitual()
        state.spatialPosition = value.clamped()
        channels[channel] = state
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func setBinauralEnabled(_ enabled: Bool) {
        guard !isAmbiencePlaybackLocked else { return }
        guard isBinauralActive != enabled else { return }
        cancelActiveRitual()
        activeComposerRecipeTitle = nil
        if enabled {
            audioEngine.preloadBinauralTrack(activeBinauralTrack)
        }
        isBinauralActive = enabled
        schedulePersistence()
        synchronizeAudio()
    }

    @discardableResult
    func selectBinauralTrack(_ track: BinauralTrack) -> Bool {
        guard !isAmbiencePlaybackLocked else { return false }
        guard isPremium || !track.isPremium else {
            requestPremiumAccess(from: .binaural(track))
            return false
        }

        cancelActiveRitual()
        activeComposerRecipeTitle = nil
        activeBinauralTrack = track
        audioEngine.preloadBinauralTrack(track)
        schedulePersistence()
        synchronizeAudio()
        return true
    }

    func setBinauralVolume(_ value: Double) {
        guard !isAmbiencePlaybackLocked else { return }
        cancelActiveRitual()
        activeComposerRecipeTitle = nil
        binauralVolume = value
        schedulePersistence()
        synchronizeAudio()
    }

    func toggleImmersiveAudio() {
        setImmersiveAudioEnabled(!immersiveAudioEnabled)
    }

    func setImmersiveAudioEnabled(_ enabled: Bool) {
        guard !isAmbiencePlaybackLocked else { return }
        guard immersiveAudioEnabled != enabled else { return }
        cancelActiveRitual()
        activeComposerRecipeTitle = nil
        immersiveAudioEnabled = enabled
        schedulePersistence()
        synchronizeAudio()
    }

    func composeAmbience(intent: AmbienceIntent, prompt: String) -> AmbienceRecipe {
        AmbienceComposer.compose(intent: intent, prompt: prompt, premium: isPremium)
    }

    @discardableResult
    func applyAmbienceRecipe(_ recipe: AmbienceRecipe) -> Bool {
        let didApply = applyAmbienceRecipe(recipe, startPlayback: true, cancelRitual: true, appliesTimer: true)
        if didApply {
            activeComposerRecipeTitle = recipe.title
            activeNoiseBlendTitle = nil
            schedulePersistence()
        }
        return didApply
    }

    func stopActiveAmbience() {
        guard activeComposerRecipeTitle != nil else { return }
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil
        showsOnlyActiveChannels = false
        timerDurationMinutes = nil
        timerEndDate = nil
        timerRemainingWhenPaused = nil
        updateTimerDisplayValue()
        schedulePersistence()
        synchronizeAudio()
    }

    func proceduralNoiseState(for noise: ProceduralNoise) -> ProceduralNoiseState {
        proceduralNoises[noise] ?? ProceduralNoiseState()
    }

    func setProceduralNoiseVolume(_ noise: ProceduralNoise, value: Double) {
        guard !isAmbiencePlaybackLocked else { return }
        guard !isProceduralNoiseLocked(noise) else {
            requestPremiumAccess(from: .noise(noise))
            return
        }

        cancelActiveRitual()
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil
        var state = proceduralNoises[noise] ?? ProceduralNoiseState()
        state.volume = AutoVariationRange.unitValue(value, fallback: state.volume)
        proceduralNoises[noise] = state
        schedulePersistence()
        synchronizeAudio()
    }

    func toggleProceduralNoise(_ noise: ProceduralNoise) {
        guard !isAmbiencePlaybackLocked else { return }
        guard !isProceduralNoiseLocked(noise) else {
            requestPremiumAccess(from: .noise(noise))
            return
        }

        cancelActiveRitual()
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil
        var state = proceduralNoises[noise] ?? ProceduralNoiseState()
        state.isMuted.toggle()
        proceduralNoises[noise] = state

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        schedulePersistence()
        synchronizeAudio()
    }

    @discardableResult
    func applyProceduralNoiseBlend(
        _ blend: [ProceduralNoise: Double],
        title: String? = nil,
        startPlayback: Bool = true
    ) -> Bool {
        if let lockedNoise = blend.keys.first(where: isProceduralNoiseLocked(_:)) {
            requestPremiumAccess(from: .noise(lockedNoise))
            return false
        }

        cancelActiveRitual()
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = title

        for noise in ProceduralNoise.allCases {
            var state = proceduralNoises[noise] ?? ProceduralNoiseState()

            if let volume = blend[noise] {
                state.volume = AutoVariationRange.unitValue(volume, fallback: state.volume)
                state.isMuted = false
            } else {
                state.isMuted = true
            }

            proceduralNoises[noise] = state
        }

        if handleNoActiveChannelsIfNeeded() {
            return true
        }

        if startPlayback, !isPlaying {
            setPlayback(true)
        } else {
            schedulePersistence()
            synchronizeAudio()
        }
        return true
    }

    func clearProceduralNoises() {
        guard !isAmbiencePlaybackLocked else { return }
        guard activeProceduralNoiseCount > 0 else { return }

        cancelActiveRitual()
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil

        for noise in ProceduralNoise.allCases {
            guard var state = proceduralNoises[noise], !state.isMuted else { continue }
            state.isMuted = true
            proceduralNoises[noise] = state
        }

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        schedulePersistence()
        synchronizeAudio()
    }

    func startRitual(_ ritual: RitualPreset) {
        guard isPremium || !ritual.requiresPremium else {
            requestPremiumAccess(from: .ritual(ritual.id))
            return
        }
        guard let firstPhase = ritual.phases.first else { return }

        finishSignaturePreview(restoreState: false, shouldPromotePaywall: false)
        ritualTask?.cancel()
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil
        activeRitualPreset = ritual

        let now = Date()
        let totalEndDate = now.addingTimeInterval(ritual.totalDurationSeconds)
        activeRitualSession = ActiveRitualSession(
            ritualID: ritual.id,
            ritualTitle: ritual.title,
            intent: firstPhase.recipe.intent,
            phaseIndex: 0,
            phaseCount: ritual.phases.count,
            phaseTitle: firstPhase.title,
            phaseStartDate: now,
            phaseEndDate: now.addingTimeInterval(firstPhase.durationSeconds),
            phaseDurationSeconds: firstPhase.durationSeconds,
            totalEndDate: totalEndDate,
            phaseRemainingWhenPaused: nil,
            totalRemainingWhenPaused: nil
        )

        timerDurationMinutes = ritual.totalMinutes
        timerRemainingWhenPaused = ritual.totalDurationSeconds
        timerEndDate = isPlaying ? totalEndDate : nil

        applyRitualPhase(ritual, index: 0, totalEndDate: totalEndDate)
        scheduleRitualAdvancement(ritual, totalEndDate: totalEndDate)
    }

    func cancelActiveRitual() {
        let hadActiveRitual = activeRitualSession != nil || activeRitualPreset != nil || ritualTask != nil
        ritualTask?.cancel()
        ritualTask = nil
        activeRitualPreset = nil
        activeRitualSession = nil
        if hadActiveRitual {
            schedulePersistence()
        }
    }

    func advanceActiveRitualToNextPhase() {
        guard
            let session = activeRitualSession,
            let ritual = activeRitualDefinition(for: session)
        else { return }

        let nextIndex = session.phaseIndex + 1
        guard ritual.phases.indices.contains(nextIndex) else { return }

        let remainingDuration = ritual.phases[nextIndex...].reduce(0) { partialResult, phase in
            partialResult + phase.durationSeconds
        }
        let totalEndDate = Date().addingTimeInterval(remainingDuration)
        let shouldKeepPlaying = isPlaying

        activeRitualPreset = ritual
        ritualTask?.cancel()
        ritualTask = nil
        applyRitualPhase(
            ritual,
            index: nextIndex,
            totalEndDate: totalEndDate,
            shouldStartPlayback: shouldKeepPlaying
        )

        if shouldKeepPlaying {
            scheduleRitualAdvancement(
                ritual,
                from: nextIndex,
                initialDelay: ritual.phases[nextIndex].durationSeconds,
                totalEndDate: totalEndDate
            )
        }
    }

    func loadPreset(_ preset: Preset) {
        guard !isPresetLocked(preset) else {
            requestPremiumAccess(from: .presetLoad)
            return
        }

        finishSignaturePreview(restoreState: false, shouldPromotePaywall: false)
        cancelActiveRitual()

        channels = preset.channels
        proceduralNoises = preset.proceduralNoises ?? .initialNoises
        variationDisplayVolumes.removeAll()
        currentPresetID = preset.id
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil
        isBinauralActive = preset.isBinauralActive ?? false
        activeBinauralTrack = preset.activeBinauralTrack ?? .delta
        binauralVolume = AutoVariationRange.unitValue(preset.binauralVolume ?? 0.5, fallback: 0.5)
        immersiveAudioEnabled = preset.immersiveAudioEnabled ?? false
        timerDurationMinutes = preset.timerDurationMinutes
        timerRemainingWhenPaused = preset.timerDurationMinutes.map { Double($0 * 60) }
        timerEndDate = isPlaying
            ? preset.timerDurationMinutes.map { Date().addingTimeInterval(Double($0 * 60)) }
            : nil

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        schedulePersistence()

        guard activeAmbientChannelsCount > 0 else { return }

        if isPlaying {
            synchronizeAudio()
        } else {
            setPlayback(true)
        }
    }

    @discardableResult
    func savePreset(named name: String, backdropAssetName: String? = nil) -> Bool {
        savePreset(
            named: name,
            preset: Preset(
                id: "preset_user_\(Int(Date().timeIntervalSince1970 * 1000))",
                name: name,
                channels: channels,
                proceduralNoises: proceduralNoises,
                isBinauralActive: isBinauralActive,
                activeBinauralTrack: activeBinauralTrack,
                binauralVolume: binauralVolume,
                timerDurationMinutes: timerDurationMinutes,
                immersiveAudioEnabled: immersiveAudioEnabled,
                backdropAssetName: backdropAssetName
            ),
            activateSavedPreset: true,
            preserveActiveSceneTitle: activeComposerRecipeTitle != nil
        )
    }

    @discardableResult
    func saveCurrentScene(named name: String) -> Bool {
        savePreset(
            named: name,
            preset: Preset(
                id: "preset_user_\(Int(Date().timeIntervalSince1970 * 1000))",
                name: name,
                channels: channels,
                proceduralNoises: proceduralNoises,
                isBinauralActive: isBinauralActive,
                activeBinauralTrack: activeBinauralTrack,
                binauralVolume: binauralVolume,
                timerDurationMinutes: timerDurationMinutes,
                immersiveAudioEnabled: immersiveAudioEnabled
            ),
            activateSavedPreset: true,
            preserveActiveSceneTitle: true
        )
    }

    @discardableResult
    func savePreset(named name: String, from recipe: AmbienceRecipe) -> Bool {
        savePreset(
            named: name,
            preset: Preset(
                id: "preset_user_\(Int(Date().timeIntervalSince1970 * 1000))",
                name: name,
                channels: recipe.channels,
                proceduralNoises: recipe.proceduralNoises,
                isBinauralActive: recipe.isBinauralActive,
                activeBinauralTrack: recipe.binauralTrack,
                binauralVolume: recipe.binauralVolume,
                timerDurationMinutes: recipe.timerMinutes,
                immersiveAudioEnabled: recipe.immersiveAudioEnabled
            ),
            activateSavedPreset: false
        )
    }

    @discardableResult
    private func savePreset(
        named name: String,
        preset draftPreset: Preset,
        activateSavedPreset: Bool,
        preserveActiveSceneTitle: Bool = false
    ) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        guard isPremium else {
            requestPremiumAccess(from: .presetSave)
            return false
        }

        var preset = draftPreset
        preset.name = trimmedName

        presets.append(preset)
        if activateSavedPreset {
            currentPresetID = preset.id
            if !preserveActiveSceneTitle {
                activeComposerRecipeTitle = nil
                activeNoiseBlendTitle = nil
            }
        }
        premiumAnalytics.track(.presetSaved(kind: isPremium ? "premium" : "free"))
        schedulePersistence()
        return true
    }

    @discardableResult
    func updatePreset(_ preset: Preset, name: String, backdropAssetName: String?) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        guard isPremium else {
            requestPremiumAccess(from: .presetSave)
            return false
        }

        guard let index = presets.firstIndex(where: { $0.id == preset.id }) else { return false }
        presets[index].name = trimmedName
        presets[index].backdropAssetName = backdropAssetName
        schedulePersistence()
        return true
    }

    func deletePreset(_ preset: Preset) {
        guard canDeletePreset(preset) else { return }

        presets.removeAll { $0.id == preset.id }
        if preset.isDefault {
            deletedDefaultPresetIDs.insert(preset.id)
        }
        if currentPresetID == preset.id {
            currentPresetID = nil
            activeComposerRecipeTitle = nil
        }
        schedulePersistence()
    }

    func movePresets(fromOffsets: IndexSet, toOffset: Int) {
        presets.move(fromOffsets: fromOffsets, toOffset: toOffset)
        schedulePersistence()
    }

    func requestPremiumAccess(from entryPoint: PremiumEntryPoint) {
        guard !isPremium else { return }

        premiumAnalytics.track(.lockedFeatureTapped(source: entryPoint.analyticsSource))

        switch premiumCoordinator.route(for: entryPoint) {
        case let .inline(context):
            activeInlineUpsell = context
            premiumAnalytics.track(.inlineShown(source: entryPoint.analyticsSource))

        case let .paywall(context):
            activeInlineUpsell = nil
            activePaywallContext = context
            premiumAnalytics.track(.paywallShown(source: entryPoint.analyticsSource))
        }
    }

    func paywallPresentation(for entryPoint: PremiumEntryPoint) -> PremiumPaywallPresentation {
        let title: String
        let subtitle: String
        let benefitRows: [PremiumPaywallBenefit]

        switch entryPoint.category {
        case .manual, .onboarding:
            title = L10n.string(L10n.Paywall.titleGeneric)
            subtitle = L10n.string(L10n.Paywall.subtitleGeneric)
            benefitRows = [
                paywallBenefit(.sounds),
                paywallBenefit(.noise),
                paywallBenefit(.presets),
                paywallBenefit(.binaural)
            ]

        case .sound, .spatial:
            title = L10n.string(L10n.Paywall.titleSounds)
            subtitle = L10n.string(L10n.Paywall.subtitleSounds)
            benefitRows = [
                paywallBenefit(.sounds),
                paywallBenefit(.noise),
                paywallBenefit(.presets),
                paywallBenefit(.binaural)
            ]

        case .timer:
            title = L10n.string(L10n.Paywall.titleTimer)
            subtitle = L10n.string(L10n.Paywall.subtitleTimer)
            benefitRows = [
                paywallBenefit(.timer),
                paywallBenefit(.sounds),
                paywallBenefit(.noise),
                paywallBenefit(.binaural)
            ]

        case .preset:
            title = L10n.string(L10n.Paywall.titlePresets)
            subtitle = L10n.string(L10n.Paywall.subtitlePresets)
            benefitRows = [
                paywallBenefit(.presets),
                paywallBenefit(.sounds),
                paywallBenefit(.noise),
                paywallBenefit(.binaural)
            ]

        case .binaural:
            title = L10n.string(L10n.Paywall.titleBinaural)
            subtitle = L10n.string(L10n.Paywall.subtitleBinaural)
            benefitRows = [
                paywallBenefit(.binaural),
                paywallBenefit(.sounds),
                paywallBenefit(.noise),
                paywallBenefit(.presets)
            ]

        case .preview:
            title = L10n.string(L10n.Paywall.titlePreview)
            subtitle = L10n.string(L10n.Paywall.subtitlePreview)
            benefitRows = [
                paywallBenefit(.presets),
                paywallBenefit(.sounds),
                paywallBenefit(.noise),
                paywallBenefit(.binaural)
            ]

        case .composer, .ritual, .noise:
            title = L10n.string(L10n.Paywall.titleComposer)
            subtitle = L10n.string(L10n.Paywall.subtitleComposer)
            benefitRows = [
                paywallBenefit(.presets, text: L10n.string(L10n.Paywall.benefitComposer)),
                paywallBenefit(.noise),
                paywallBenefit(.binaural),
                paywallBenefit(.sounds)
            ]
        }

        return PremiumPaywallPresentation(
            title: title,
            subtitle: subtitle,
            benefitRows: benefitRows,
            symbolName: entryPoint.symbolName,
            accentToken: entryPoint.accentToken
        )
    }

    private func paywallBenefit(_ kind: PremiumBenefitKind, text overrideText: String? = nil) -> PremiumPaywallBenefit {
        let text: String
        if let overrideText {
            text = overrideText
        } else {
            switch kind {
            case .sounds:
                text = L10n.string(L10n.Paywall.benefitSounds)
            case .noise:
                text = L10n.string(L10n.Paywall.benefitNoiseLab)
            case .presets:
                text = L10n.string(L10n.Paywall.benefitPresets)
            case .binaural:
                text = L10n.string(L10n.Paywall.benefitBinaural)
            case .timer:
                text = L10n.string(L10n.Paywall.benefitTimer)
            case .updates:
                text = L10n.string(L10n.Paywall.benefitUpdates)
            }
        }

        return PremiumPaywallBenefit(kind: kind, text: text)
    }

    func presentPaywall(from entryPoint: PremiumEntryPoint) {
        guard !isPremium else { return }
        activeInlineUpsell = nil
        activePaywallContext = PremiumPaywallContext(entryPoint: entryPoint)
        premiumAnalytics.track(.paywallShown(source: entryPoint.analyticsSource))
    }

    func dismissPaywall() {
        if let source = activePaywallContext?.entryPoint.analyticsSource, !isPremium {
            recordPaywallInteraction()
            premiumAnalytics.track(.paywallDismissed(source: source))
        }
        activePaywallContext = nil
    }

    func dismissInlineUpsell() {
        activeInlineUpsell = nil
    }

    func dismissPremiumHomeBanner() {
        showsPremiumHomeBanner = false
        premiumBannerLastDismissedAt = Date()
        premiumAnalytics.track(.bannerDismissed)
        persistState()
    }

    func startSignaturePreview() {
        guard !isPremium, isSignaturePreviewAvailable else { return }
        guard let preset = presets.first(where: \.isSignature) else { return }

        premiumAnalytics.track(.previewStarted)
        signaturePreviewTask?.cancel()
        signaturePreviewRestoreState = SignaturePreviewRestoreState(
            channels: channels,
            currentPresetID: currentPresetID,
            activeComposerRecipeTitle: activeComposerRecipeTitle,
            isPlaying: isPlaying,
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume,
            timerDurationMinutes: timerDurationMinutes,
            timerEndDate: timerEndDate,
            timerRemainingWhenPaused: timerRemainingWhenPaused,
            timerDisplayValue: timerDisplayValue
        )

        signaturePreviewLastPlayedAt = Date()
        isSignaturePreviewActive = true
        activeInlineUpsell = nil

        channels = preset.channels
        variationDisplayVolumes.removeAll()
        currentPresetID = preset.id
        activeComposerRecipeTitle = nil
        previewUnlockedChannels = Set(
            preset.channels.compactMap { channel, state in
                guard !state.isMuted, !SoundChannel.freeChannels.contains(channel) else { return nil }
                return channel
            }
        )
        previewUnlockedTracks.removeAll()

        if !isPlaying {
            isPlaying = true
            beginListeningSession()
            startTimerTickerIfNeeded()
        }

        updateTimerDisplayValue()
        schedulePersistence()
        synchronizeAudio()

        signaturePreviewTask = Task { [weak self] in
            try? await Task.sleep(for: PremiumCoordinator.signaturePreviewDuration)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.finishSignaturePreview(restoreState: true, shouldPromotePaywall: true)
            }
        }
    }

    func finishSignaturePreview(restoreState: Bool, shouldPromotePaywall: Bool) {
        guard isSignaturePreviewActive || !previewUnlockedChannels.isEmpty else { return }

        premiumAnalytics.track(.previewFinished)
        signaturePreviewTask?.cancel()
        signaturePreviewTask = nil
        previewUnlockedChannels.removeAll()
        previewUnlockedTracks.removeAll()
        isSignaturePreviewActive = false

        if restoreState, !isPremium, let restoreState = signaturePreviewRestoreState {
            channels = restoreState.channels
            currentPresetID = restoreState.currentPresetID
            activeComposerRecipeTitle = restoreState.activeComposerRecipeTitle
            isPlaying = restoreState.isPlaying
            isBinauralActive = restoreState.isBinauralActive
            activeBinauralTrack = restoreState.activeBinauralTrack
            binauralVolume = restoreState.binauralVolume
            timerDurationMinutes = restoreState.timerDurationMinutes
            timerEndDate = restoreState.timerEndDate
            timerRemainingWhenPaused = restoreState.timerRemainingWhenPaused
            timerDisplayValue = restoreState.timerDisplayValue
            variationDisplayVolumes.removeAll()
        }

        signaturePreviewRestoreState = nil
        startTimerTickerIfNeeded()
        updateTimerDisplayValue()

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        schedulePersistence()
        synchronizeAudio()

        if shouldPromotePaywall, !isPremium {
            presentPaywall(from: .previewEnd)
        }
    }

    func completeOnboarding(fromPage page: Int = -1, skipped: Bool = false, presentPaywall: Bool = false) {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: OnboardingDefaults.completedKey)
        gentleReminderScheduler.requestAuthorizationAfterOnboarding()
        if skipped {
            premiumAnalytics.track(.onboardingSkipped(page: page))
        } else {
            premiumAnalytics.track(.onboardingCompleted(page: page))
        }

        if presentPaywall {
            self.presentPaywall(from: .onboarding)
        }
    }

    func closeOverlays() {
        showsComposePanel = false
        showsBinauralPanel = false
        showsPresetsPanel = false
        showsSpatialPanel = false
        activePaywallContext = nil
        activeInlineUpsell = nil
    }

    func applyRevenueCatCustomerInfo(_ customerInfo: CustomerInfo) {
        applyCustomerInfo(customerInfo)
    }

    func currentLifetimePackage() async throws -> Package {
        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else {
            throw PremiumRevenueCatError.missingOffering
        }

        if let source = activePaywallContext?.entryPoint.analyticsSource {
            premiumAnalytics.track(.paywallLoading(source: source))
        }

        return try await premiumRevenueCatService.currentLifetimePackage()
    }

    func currentLifetimePackageCustomerInfo() async throws -> CustomerInfo {
        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else {
            throw PremiumRevenueCatError.missingOffering
        }

        return try await premiumRevenueCatService.customerInfo()
    }

    func purchaseLifetime(package: Package) async throws -> PremiumPurchaseResult {
        let source = activePaywallContext?.entryPoint.analyticsSource ?? "manual"
        premiumAnalytics.track(.purchaseStarted(source: source))

        let result = try await premiumRevenueCatService.purchase(package: package)
        applyCustomerInfo(result.customerInfo)

        if result.userCancelled {
            recordPaywallInteraction()
            premiumAnalytics.track(.purchaseCancelled(source: source))
        } else if result.customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
            premiumAnalytics.track(.purchaseSucceeded(source: source))
        }

        return result
    }

    func restorePurchases() async {
        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else { return }
        let source = activePaywallContext?.entryPoint.analyticsSource ?? "manual"
        premiumAnalytics.track(.restoreStarted(source: source))

        do {
            let customerInfo = try await premiumRevenueCatService.restorePurchases()
            applyCustomerInfo(customerInfo)

            if customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil {
                premiumAnalytics.track(.restoreSucceeded(source: source))
            }
        } catch {
            print("RevenueCat restore failed: \(error)")
        }
    }

    private var currentMixUsesOnlyFreeChannels: Bool {
        channels.allSatisfy { channel, state in
            state.isMuted || SoundChannel.freeChannels.contains(channel)
        }
            && proceduralNoises.allSatisfy { noise, state in
                state.isMuted || !noise.isPremium
            }
            && (!isBinauralActive || !activeBinauralTrack.isPremium)
            && (timerDurationMinutes ?? 0) <= 30
    }

    @discardableResult
    private func applyAmbienceRecipe(
        _ recipe: AmbienceRecipe,
        startPlayback: Bool,
        cancelRitual shouldCancelRitual: Bool,
        appliesTimer: Bool
    ) -> Bool {
        guard isPremium || !recipe.requiresPremium else {
            requestPremiumAccess(from: .composer)
            return false
        }

        if shouldCancelRitual {
            cancelActiveRitual()
        }
        finishSignaturePreview(restoreState: false, shouldPromotePaywall: false)

        channels = recipe.channels
        proceduralNoises = recipe.proceduralNoises
        variationDisplayVolumes.removeAll()
        currentPresetID = nil
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil
        isBinauralActive = recipe.isBinauralActive
        activeBinauralTrack = recipe.binauralTrack
        binauralVolume = AutoVariationRange.unitValue(recipe.binauralVolume, fallback: binauralVolume)
        immersiveAudioEnabled = recipe.immersiveAudioEnabled

        if appliesTimer {
            timerDurationMinutes = recipe.timerMinutes
            timerRemainingWhenPaused = recipe.timerMinutes.map { Double($0 * 60) }
            timerEndDate = isPlaying
                ? recipe.timerMinutes.map { Date().addingTimeInterval(Double($0 * 60)) }
                : nil
        }

        if handleNoActiveChannelsIfNeeded() {
            return true
        }

        if startPlayback, !isPlaying {
            setPlayback(true)
        } else {
            startTimerTickerIfNeeded()
            updateTimerDisplayValue()
            schedulePersistence()
            synchronizeAudio()
        }

        return true
    }

    private func applyRitualPhase(
        _ ritual: RitualPreset,
        index: Int,
        totalEndDate: Date,
        shouldStartPlayback: Bool = true
    ) {
        guard ritual.phases.indices.contains(index) else { return }
        let phase = ritual.phases[index]
        let now = Date()
        let totalRemaining = max(totalEndDate.timeIntervalSince(now), 0)

        activeRitualSession = ActiveRitualSession(
            ritualID: ritual.id,
            ritualTitle: ritual.title,
            intent: phase.recipe.intent,
            phaseIndex: index,
            phaseCount: ritual.phases.count,
            phaseTitle: phase.title,
            phaseStartDate: now,
            phaseEndDate: now.addingTimeInterval(phase.durationSeconds),
            phaseDurationSeconds: phase.durationSeconds,
            totalEndDate: totalEndDate,
            phaseRemainingWhenPaused: shouldStartPlayback ? nil : phase.durationSeconds,
            totalRemainingWhenPaused: shouldStartPlayback ? nil : totalRemaining
        )

        _ = applyAmbienceRecipe(
            phase.recipe,
            startPlayback: shouldStartPlayback,
            cancelRitual: false,
            appliesTimer: false
        )

        timerDurationMinutes = ritual.totalMinutes
        timerEndDate = isPlaying ? totalEndDate : nil
        timerRemainingWhenPaused = totalRemaining
        startTimerTickerIfNeeded()
        updateTimerDisplayValue()
        schedulePersistence()
    }

    private func activeRitualDefinition(for session: ActiveRitualSession) -> RitualPreset? {
        activeRitualPreset ?? RitualPreset.builtIns.first { $0.id == session.ritualID }
    }

    private func scheduleRitualAdvancement(_ ritual: RitualPreset, totalEndDate: Date) {
        ritualTask?.cancel()
        ritualTask = Task { [weak self] in
            await self?.runRitualAdvancement(
                ritual,
                from: 0,
                initialDelay: ritual.phases.first?.durationSeconds ?? 0,
                totalEndDate: totalEndDate
            )
        }
    }

    private func scheduleRitualAdvancement(
        _ ritual: RitualPreset,
        from currentIndex: Int,
        initialDelay: TimeInterval,
        totalEndDate: Date
    ) {
        ritualTask?.cancel()
        ritualTask = Task { [weak self] in
            await self?.runRitualAdvancement(
                ritual,
                from: currentIndex,
                initialDelay: initialDelay,
                totalEndDate: totalEndDate
            )
        }
    }

    private func runRitualAdvancement(
        _ ritual: RitualPreset,
        from currentIndex: Int,
        initialDelay: TimeInterval,
        totalEndDate: Date
    ) async {
        var delay = initialDelay

        for nextIndex in ritual.phases.indices where nextIndex > currentIndex {
            try? await Task.sleep(for: .milliseconds(max(Int(delay * 1000), 1)))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard
                    activeRitualSession?.ritualID == ritual.id,
                    isPlaying
                else { return }

                withAnimation(.smooth(duration: 0.35)) {
                    applyRitualPhase(ritual, index: nextIndex, totalEndDate: totalEndDate)
                }
            }

            guard !Task.isCancelled else { return }
            delay = ritual.phases[nextIndex].durationSeconds
        }
    }

    private func pauseActiveRitualIfNeeded() {
        guard var session = activeRitualSession else { return }

        ritualTask?.cancel()
        ritualTask = nil

        let now = Date()
        session.phaseRemainingWhenPaused = max(session.phaseEndDate.timeIntervalSince(now), 0)
        session.totalRemainingWhenPaused = max(session.totalEndDate.timeIntervalSince(now), 0)
        activeRitualSession = session
    }

    private func resumeActiveRitualIfNeeded() {
        guard
            var session = activeRitualSession,
            let ritual = activeRitualPreset
        else { return }

        let now = Date()
        let phaseRemaining = session.phaseRemainingWhenPaused ?? max(session.phaseEndDate.timeIntervalSince(now), 0)
        let totalRemaining = session.totalRemainingWhenPaused ?? max(session.totalEndDate.timeIntervalSince(now), 0)

        session.phaseStartDate = now.addingTimeInterval(-(session.phaseDurationSeconds - phaseRemaining))
        session.phaseEndDate = now.addingTimeInterval(phaseRemaining)
        session.totalEndDate = now.addingTimeInterval(totalRemaining)
        session.phaseRemainingWhenPaused = nil
        session.totalRemainingWhenPaused = nil
        activeRitualSession = session

        scheduleRitualAdvancement(
            ritual,
            from: session.phaseIndex,
            initialDelay: phaseRemaining,
            totalEndDate: session.totalEndDate
        )
    }

    private var activeRitualSessionForPersistence: ActiveRitualSession? {
        guard let session = activeRitualSession else { return nil }

        if let totalRemainingWhenPaused = session.totalRemainingWhenPaused {
            return totalRemainingWhenPaused > 0 ? session : nil
        }

        return session.totalEndDate > Date() ? session : nil
    }

    private func restoreActiveRitualIfNeeded(from persistedSession: ActiveRitualSession?) {
        guard
            let persistedSession,
            let ritual = RitualPreset.builtIns.first(where: { $0.id == persistedSession.ritualID }),
            isPremium || !ritual.requiresPremium,
            var session = restoredRitualSession(from: persistedSession, ritual: ritual)
        else { return }

        if !isPlaying {
            session = pausedRestoredRitualSession(session)
        }

        activeRitualPreset = ritual
        activeRitualSession = session
        timerDurationMinutes = ritual.totalMinutes
        timerRemainingWhenPaused = session.totalRemainingWhenPaused ?? max(session.totalEndDate.timeIntervalSinceNow, 0)
        timerEndDate = isPlaying ? session.totalEndDate : nil

        if ritual.phases.indices.contains(session.phaseIndex) {
            let phase = ritual.phases[session.phaseIndex]
            _ = applyAmbienceRecipe(
                phase.recipe,
                startPlayback: false,
                cancelRitual: false,
                appliesTimer: false
            )
            activeRitualSession = session
        }

        updateTimerDisplayValue()

        if isPlaying {
            scheduleRitualAdvancement(
                ritual,
                from: session.phaseIndex,
                initialDelay: max(session.phaseEndDate.timeIntervalSinceNow, 0),
                totalEndDate: session.totalEndDate
            )
        }
    }

    private func restoredRitualSession(
        from session: ActiveRitualSession,
        ritual: RitualPreset,
        now: Date = Date()
    ) -> ActiveRitualSession? {
        guard ritual.phases.indices.contains(session.phaseIndex) else { return nil }

        if let totalRemainingWhenPaused = session.totalRemainingWhenPaused {
            guard totalRemainingWhenPaused > 0 else { return nil }
            let phaseRemainingWhenPaused = session.phaseRemainingWhenPaused
                ?? max(session.phaseEndDate.timeIntervalSince(session.phaseStartDate), 1)
            let phase = ritual.phases[session.phaseIndex]

            return ActiveRitualSession(
                ritualID: ritual.id,
                ritualTitle: ritual.title,
                intent: phase.recipe.intent,
                phaseIndex: session.phaseIndex,
                phaseCount: ritual.phases.count,
                phaseTitle: phase.title,
                phaseStartDate: now.addingTimeInterval(-(phase.durationSeconds - phaseRemainingWhenPaused)),
                phaseEndDate: now.addingTimeInterval(phaseRemainingWhenPaused),
                phaseDurationSeconds: phase.durationSeconds,
                totalEndDate: now.addingTimeInterval(totalRemainingWhenPaused),
                phaseRemainingWhenPaused: phaseRemainingWhenPaused,
                totalRemainingWhenPaused: totalRemainingWhenPaused
            )
        }

        guard session.totalEndDate > now else { return nil }

        let ritualStartDate = session.totalEndDate.addingTimeInterval(-ritual.totalDurationSeconds)
        var phaseStartDate = ritualStartDate

        for (index, phase) in ritual.phases.enumerated() {
            let phaseEndDate = phaseStartDate.addingTimeInterval(phase.durationSeconds)
            if now <= phaseEndDate || index == ritual.phases.index(before: ritual.phases.endIndex) {
                return ActiveRitualSession(
                    ritualID: ritual.id,
                    ritualTitle: ritual.title,
                    intent: phase.recipe.intent,
                    phaseIndex: index,
                    phaseCount: ritual.phases.count,
                    phaseTitle: phase.title,
                    phaseStartDate: phaseStartDate,
                    phaseEndDate: phaseEndDate,
                    phaseDurationSeconds: phase.durationSeconds,
                    totalEndDate: session.totalEndDate,
                    phaseRemainingWhenPaused: nil,
                    totalRemainingWhenPaused: nil
                )
            }
            phaseStartDate = phaseEndDate
        }

        return nil
    }

    private func pausedRestoredRitualSession(_ session: ActiveRitualSession, now: Date = Date()) -> ActiveRitualSession {
        var pausedSession = session
        let phaseRemaining = session.phaseRemainingWhenPaused ?? max(session.phaseEndDate.timeIntervalSince(now), 0)
        let totalRemaining = session.totalRemainingWhenPaused ?? max(session.totalEndDate.timeIntervalSince(now), 0)

        pausedSession.phaseStartDate = now.addingTimeInterval(-(session.phaseDurationSeconds - phaseRemaining))
        pausedSession.phaseEndDate = now.addingTimeInterval(phaseRemaining)
        pausedSession.totalEndDate = now.addingTimeInterval(totalRemaining)
        pausedSession.phaseRemainingWhenPaused = phaseRemaining
        pausedSession.totalRemainingWhenPaused = totalRemaining
        return pausedSession
    }

    private func trackAppSession() {
        guard AppConfiguration.shouldPersistState else { return }
        let defaults = UserDefaults.standard
        let sessionCount = defaults.integer(forKey: EngagementDefaults.sessionCountKey) + 1
        defaults.set(sessionCount, forKey: EngagementDefaults.sessionCountKey)
        premiumAnalytics.track(.appSession(index: sessionCount))
    }

    private func beginListeningSession() {
        guard AppConfiguration.shouldPersistState else { return }
        guard listeningStartedAt == nil else { return }
        listeningStartedAt = Date()

        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: EngagementDefaults.didTrackFirstPlayKey) {
            defaults.set(true, forKey: EngagementDefaults.didTrackFirstPlayKey)
            premiumAnalytics.track(.firstPlay)
        }

        scheduleListened60sTracking()
        scheduleReviewPromptIfNeeded()
    }

    private func endListeningSession() {
        guard AppConfiguration.shouldPersistState else { return }
        guard let listeningStartedAt else { return }
        let elapsed = max(Date().timeIntervalSince(listeningStartedAt), 0)
        self.listeningStartedAt = nil
        listened60sTask?.cancel()
        listened60sTask = nil
        reviewPromptTask?.cancel()
        reviewPromptTask = nil

        let defaults = UserDefaults.standard
        let total = defaults.double(forKey: EngagementDefaults.listenedSecondsKey) + elapsed
        defaults.set(total, forKey: EngagementDefaults.listenedSecondsKey)
    }

    private func scheduleListened60sTracking() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: EngagementDefaults.didTrackListened60sKey) else { return }

        listened60sTask?.cancel()
        listened60sTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.isPlaying else { return }
                let defaults = UserDefaults.standard
                defaults.set(true, forKey: EngagementDefaults.didTrackListened60sKey)
                self.premiumAnalytics.track(.listened60s)
            }
        }
    }

    private func scheduleReviewPromptIfNeeded() {
        guard AppConfiguration.shouldPersistState else { return }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: EngagementDefaults.didRequestReviewKey) else { return }

        let sessions = defaults.integer(forKey: EngagementDefaults.sessionCountKey)
        let listenedSeconds = defaults.double(forKey: EngagementDefaults.listenedSecondsKey)
        let delay = max(EngagementDefaults.reviewListenThreshold - listenedSeconds, 0)

        if sessions >= EngagementDefaults.reviewSessionThreshold {
            requestReviewAfterPositiveMoment(reason: "session")
            return
        }

        guard delay > 0 else {
            requestReviewAfterPositiveMoment(reason: "listened_5m")
            return
        }

        reviewPromptTask?.cancel()
        reviewPromptTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(Int(delay.rounded(.up))))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, self.isPlaying else { return }
                self.requestReviewAfterPositiveMoment(reason: "listened_5m")
            }
        }
    }

    private func requestReviewAfterPositiveMoment(reason: String) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: EngagementDefaults.didRequestReviewKey) else { return }
        guard !recentlyInteractedWithPaywall else { return }
        guard AppReviewRequester.requestReviewIfPossible() else { return }

        defaults.set(true, forKey: EngagementDefaults.didRequestReviewKey)
        premiumAnalytics.track(.reviewPromptRequested(reason: reason))
    }

    private var recentlyInteractedWithPaywall: Bool {
        let timestamp = UserDefaults.standard.double(forKey: EngagementDefaults.lastPaywallInteractionKey)
        guard timestamp > 0 else { return false }
        return Date().timeIntervalSince1970 - timestamp < EngagementDefaults.reviewPaywallCooldown
    }

    private func recordPaywallInteraction() {
        guard AppConfiguration.shouldPersistState else { return }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: EngagementDefaults.lastPaywallInteractionKey)
    }

    private func configureCallbacks() {
        revenueCatObserver.onCustomerInfoChange = { [weak self] customerInfo in
            Task { @MainActor [weak self] in
                self?.applyCustomerInfo(customerInfo)
            }
        }

        audioEngine.onRemotePlaybackChange = { [weak self] shouldPlay in
            guard let self else { return }
            self.setPlayback(shouldPlay)
        }

        audioEngine.onVariationChanged = { [weak self] channel, value in
            guard let self else { return }
            guard !self.showsComposePanel, !self.showsPresetsPanel, !self.showsBinauralPanel, !self.showsSpatialPanel else { return }

            if let value {
                self.variationDisplayVolumes[channel] = value
            } else {
                self.variationDisplayVolumes.removeValue(forKey: channel)
            }
        }
    }

    private func loadPersistedState() -> Bool {
        guard !AppConfiguration.shouldResetStateOnLaunch else { return false }
        guard let data = UserDefaults.standard.data(forKey: AppConfiguration.persistenceKey) else {
            return false
        }

        do {
            let persisted = try JSONDecoder().decode(PersistedMixerState.self, from: data)
            channels = persisted.channels
            proceduralNoises = persisted.proceduralNoises ?? .initialNoises
            deletedDefaultPresetIDs = persisted.deletedDefaultPresetIDs ?? []
            presets = mergeMissingDefaultPresets(into: persisted.presets)
            currentPresetID = persisted.currentPresetID
            activeComposerRecipeTitle = persisted.activeComposerRecipeTitle
            activeNoiseBlendTitle = persisted.activeNoiseBlendTitle
            isBinauralActive = persisted.isBinauralActive
            activeBinauralTrack = persisted.activeBinauralTrack
            binauralVolume = persisted.binauralVolume
            premiumBannerLastDismissedAt = persisted.premiumBannerLastDismissedAt
            signaturePreviewLastPlayedAt = persisted.signaturePreviewLastPlayedAt
            immersiveAudioEnabled = persisted.immersiveAudioEnabled ?? false
            if let currentPresetID, !presets.contains(where: { $0.id == currentPresetID }) {
                self.currentPresetID = nil
                activeComposerRecipeTitle = nil
                activeNoiseBlendTitle = nil
            }

            enforcePremiumAccess()
            restoreActiveRitualIfNeeded(from: persisted.activeRitualSession)
            return true
        } catch {
            print("Failed to decode persisted mixer state: \(error)")
            return false
        }
    }

    private func resetOnboardingIfRequested() {
        guard AppConfiguration.shouldResetOnboardingOnLaunch else { return }
        UserDefaults.standard.removeObject(forKey: OnboardingDefaults.completedKey)
        hasCompletedOnboarding = false
    }

    private func applyLaunchArgumentOverrides() {
        if let forcedImmersiveAudioEnabled = AppConfiguration.forcedImmersiveAudioEnabled {
            immersiveAudioEnabled = forcedImmersiveAudioEnabled
        }
    }

    private func persistState() {
        guard AppConfiguration.shouldPersistState else { return }
        let persisted = PersistedMixerState(
            channels: channels,
            proceduralNoises: proceduralNoises,
            presets: presets,
            currentPresetID: currentPresetID,
            activeComposerRecipeTitle: activeComposerRecipeTitle,
            activeNoiseBlendTitle: activeNoiseBlendTitle,
            activeRitualSession: activeRitualSessionForPersistence,
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume,
            selectedLanguage: nil,
            premiumBannerLastDismissedAt: premiumBannerLastDismissedAt,
            signaturePreviewLastPlayedAt: signaturePreviewLastPlayedAt,
            deletedDefaultPresetIDs: deletedDefaultPresetIDs,
            immersiveAudioEnabled: immersiveAudioEnabled
        )

        do {
            let data = try JSONEncoder().encode(persisted)
            UserDefaults.standard.set(data, forKey: AppConfiguration.persistenceKey)
        } catch {
            print("Failed to persist mixer state: \(error)")
        }
    }

    private func synchronizeAudio() {
        enforcePremiumAccess()
        audioEngine.sync(with: mixerSnapshot)
    }

    private func schedulePersistence() {
        persistenceTask?.cancel()
        persistenceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(350))
            guard let self, !Task.isCancelled else { return }
            self.persistState()
        }
    }

    private func enforcePremiumAccess() {
        guard !isPremium else { return }

        for channel in SoundChannel.allCases where !SoundChannel.freeChannels.contains(channel) {
            guard !previewUnlockedChannels.contains(channel) else { continue }
            if var state = channels[channel] {
                state.isMuted = true
                state.autoVariationEnabled = false
                channels[channel] = state
                variationDisplayVolumes.removeValue(forKey: channel)
            }
        }

        for noise in ProceduralNoise.allCases where noise.isPremium {
            if var state = proceduralNoises[noise] {
                state.isMuted = true
                proceduralNoises[noise] = state
            }
        }
        if activeProceduralNoiseCount == 0 {
            activeNoiseBlendTitle = nil
        }

        if activeBinauralTrack.isPremium && !previewUnlockedTracks.contains(activeBinauralTrack) {
            activeBinauralTrack = .delta
        }

        let shouldPreserveTimerState = isSignaturePreviewActive && signaturePreviewRestoreState?.timerDurationMinutes != nil
        if let duration = timerDurationMinutes, !canUseTimer(minutes: duration), !shouldPreserveTimerState {
            timerDurationMinutes = nil
            timerEndDate = nil
            timerRemainingWhenPaused = nil
        }
    }

    private func startTimerTickerIfNeeded() {
        timerTicker?.invalidate()
        timerTicker = nil

        guard timerDurationMinutes != nil else { return }

        timerTicker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateTimerDisplayValue()
            }
        }
    }

    private func updateTimerDisplayValue() {
        if isPlaying, let timerEndDate {
            let remaining = max(timerEndDate.timeIntervalSinceNow, 0)
            timerDisplayValue = remaining
            timerRemainingWhenPaused = remaining

            if remaining <= 0.5 {
                let wasFreeTimer = !isPremium
                audioEngine.setNextPauseFadeDuration(Self.sleepTimerFadeOutDuration)
                isPlaying = false
                endListeningSession()
                timerDurationMinutes = nil
                self.timerEndDate = nil
                timerRemainingWhenPaused = nil
                timerDisplayValue = nil
                cancelActiveRitual()
                persistState()
                synchronizeAudio()

                if wasFreeTimer {
                    // Proactive paywall after a free timer ends — suggests longer timers
                    Task { @MainActor [weak self] in
                        try? await Task.sleep(for: .seconds(1.5))
                        guard let self, !self.isPremium, self.activePaywallContext == nil else { return }
                        self.presentPaywall(from: .timer)
                    }
                }
            }
            return
        }

        if let timerRemainingWhenPaused {
            timerDisplayValue = timerRemainingWhenPaused
        } else if let timerDurationMinutes {
            timerDisplayValue = Double(timerDurationMinutes * 60)
        } else {
            timerDisplayValue = nil
        }
    }

    private func formatTimer(_ remaining: TimeInterval) -> String {
        let totalSeconds = max(Int(remaining.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func refreshPremiumStatus() async {
        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else {
            applyEffectivePremiumAccess()
            return
        }

        do {
            let customerInfo = try await premiumRevenueCatService.customerInfo()
            applyCustomerInfo(customerInfo)
        } catch {
            print("RevenueCat customer info refresh failed: \(error)")
            applyEffectivePremiumAccess()
        }
    }

    private func applyCustomerInfo(_ customerInfo: CustomerInfo) {
        revenueCatHasPremium = customerInfo.entitlements.active[AppConfiguration.revenueCatEntitlementID] != nil
        applyEffectivePremiumAccess()
    }

    private func applyEffectivePremiumAccess() {
        let effectivePremium = AppConfiguration.forcedPremiumAccess ?? revenueCatHasPremium
        let didChangePremium = isPremium != effectivePremium

        isPremium = effectivePremium

        if effectivePremium {
            activePaywallContext = nil
            activeInlineUpsell = nil
            showsPremiumHomeBanner = false
            cancelPremiumBannerScheduling()
            premiumCoordinator.resetInlineHistory()

            if isSignaturePreviewActive {
                finishSignaturePreview(restoreState: false, shouldPromotePaywall: false)
            }
        }

        guard didChangePremium else { return }

        enforcePremiumAccess()
        if handleNoActiveChannelsIfNeeded() {
            return
        }

        updateTimerDisplayValue()
        synchronizeAudio()
    }

    private func schedulePremiumBannerIfNeeded() {
        guard !isPremium else { return }
        guard !showsPremiumHomeBanner else { return }
        guard premiumCoordinator.canShowHomeBanner(lastDismissedAt: premiumBannerLastDismissedAt) else { return }

        premiumBannerTask?.cancel()
        premiumBannerTask = Task { [weak self] in
            try? await Task.sleep(for: PremiumCoordinator.homeBannerDelay)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self else { return }
                guard self.isPlaying else { return }
                guard !self.isPremium else { return }
                guard self.premiumCoordinator.canShowHomeBanner(lastDismissedAt: self.premiumBannerLastDismissedAt) else { return }

                self.showsPremiumHomeBanner = true
                self.premiumAnalytics.track(.bannerShown)
            }
        }
    }

    private func cancelPremiumBannerScheduling() {
        premiumBannerTask?.cancel()
        premiumBannerTask = nil
    }

    private func hasAmbientPlaybackAccess(to channel: SoundChannel) -> Bool {
        isPremium || SoundChannel.freeChannels.contains(channel) || previewUnlockedChannels.contains(channel)
    }

    private func applyScreenshotShuffle(availableChannels: [SoundChannel]) {
        guard !availableChannels.isEmpty else { return }

        let templates = Self.screenshotShuffleTemplates
        let template = templates[screenshotShuffleIndex % templates.count]
        screenshotShuffleIndex += 1

        var newChannels = [SoundChannel: ChannelState].initialChannels

        for (channel, state) in template where availableChannels.contains(channel) {
            newChannels[channel] = state
        }

        if !isPremium {
            for channel in SoundChannel.allCases where !SoundChannel.freeChannels.contains(channel) {
                newChannels[channel] = ChannelState()
            }
        }

        channels = newChannels
        variationDisplayVolumes = newChannels.reduce(into: [:]) { partialResult, entry in
            if entry.value.autoVariationEnabled, !entry.value.isMuted {
                partialResult[entry.key] = entry.value.autoVariationRange.clampedValue(entry.value.volume)
            }
        }
        currentPresetID = nil
        activeComposerRecipeTitle = nil

        if !isPlaying {
            isPlaying = true
            beginListeningSession()
            if let minutes = timerDurationMinutes {
                let remaining = timerRemainingWhenPaused ?? Double(minutes * 60)
                timerEndDate = Date().addingTimeInterval(remaining)
            }
            startTimerTickerIfNeeded()
        }

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        persistState()
        updateTimerDisplayValue()
        synchronizeAudio()
    }

    @discardableResult
    private func handleNoActiveChannelsIfNeeded() -> Bool {
        guard activeAudioSourceCount == 0 else { return false }

        if showsOnlyActiveChannels {
            showsOnlyActiveChannels = false
        }
        activeComposerRecipeTitle = nil
        activeNoiseBlendTitle = nil

        guard isPlaying else { return false }

        setPlayback(false)
        return true
    }

    private func mergeMissingDefaultPresets(into storedPresets: [Preset]) -> [Preset] {
        var mergedPresets = storedPresets.filter { !Preset.legacyBundledPresetIDs.contains($0.id) }

        for preset in Array.defaultPresets() {
            guard !deletedDefaultPresetIDs.contains(preset.id) else { continue }

            if let index = mergedPresets.firstIndex(where: { $0.id == preset.id }) {
                mergedPresets[index].backdropAssetName = preset.backdropAssetName
            } else {
                mergedPresets.append(preset)
            }
        }

        return mergedPresets
    }

    private static let sleepTimerFadeOutDuration: TimeInterval = 15

    // Templates used exclusively by the App Store screenshot pipeline (shuffle button in
    // screenshot mode applies these instead of a random mix). Each template deliberately
    // features one or more of the six new premium sounds so the marketing shots showcase
    // the expanded library.
    private static let screenshotShuffleTemplates: [[SoundChannel: ChannelState]] = [
        // Template 0 — "Campfire night". Warm + cosy.
        // Ten active channels spanning the full list so no matter where the capture
        // is taken (top of list or scrolled to the bottom), roughly half the visible
        // rows read as active.
        [
            .oiseaux: ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: false),
            .vent: ChannelState(volume: 0.26, isMuted: false, autoVariationEnabled: true),
            .plage: ChannelState(volume: 0.24, isMuted: false, autoVariationEnabled: false),
            .foret: ChannelState(volume: 0.28, isMuted: false, autoVariationEnabled: false),
            .pluie: ChannelState(volume: 0.20, isMuted: false, autoVariationEnabled: false),
            .tonnerre: ChannelState(volume: 0.16, isMuted: false, autoVariationEnabled: true),
            .grillons: ChannelState(volume: 0.38, isMuted: false, autoVariationEnabled: false),
            .tente: ChannelState(volume: 0.32, isMuted: false, autoVariationEnabled: false),
            .riviere: ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: true),
            .campfire: ChannelState(volume: 0.55, isMuted: false, autoVariationEnabled: false),
            .lac: ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: false)
        ],
        // Template 1 — "Exotic journey". Green/yellow palette, showcases the jungles + savanna.
        [
            .oiseaux: ChannelState(volume: 0.30, isMuted: false, autoVariationEnabled: false),
            .plage: ChannelState(volume: 0.20, isMuted: false, autoVariationEnabled: false),
            .foret: ChannelState(volume: 0.24, isMuted: false, autoVariationEnabled: true),
            .pluie: ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: true),
            .cigales: ChannelState(volume: 0.32, isMuted: false, autoVariationEnabled: false),
            .riviere: ChannelState(volume: 0.26, isMuted: false, autoVariationEnabled: false),
            .savane: ChannelState(volume: 0.40, isMuted: false, autoVariationEnabled: false),
            .jungleAmerique: ChannelState(volume: 0.50, isMuted: false, autoVariationEnabled: false),
            .jungleAsie: ChannelState(volume: 0.34, isMuted: false, autoVariationEnabled: false),
            .cafe: ChannelState(volume: 0.16, isMuted: false, autoVariationEnabled: true)
        ],
        // Template 2 — "Cafe focus". Cool palette, showcases the cafe + lake for the urban angle.
        [
            .oiseaux: ChannelState(volume: 0.20, isMuted: false, autoVariationEnabled: false),
            .vent: ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: true),
            .goelands: ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: false),
            .pluie: ChannelState(volume: 0.26, isMuted: false, autoVariationEnabled: true),
            .grillons: ChannelState(volume: 0.16, isMuted: false, autoVariationEnabled: false),
            .riviere: ChannelState(volume: 0.24, isMuted: false, autoVariationEnabled: false),
            .mer: ChannelState(volume: 0.22, isMuted: false, autoVariationEnabled: false),
            .cafe: ChannelState(volume: 0.48, isMuted: false, autoVariationEnabled: false),
            .lac: ChannelState(volume: 0.36, isMuted: false, autoVariationEnabled: false),
            .jungleAsie: ChannelState(volume: 0.18, isMuted: false, autoVariationEnabled: true)
        ]
    ]
}

private struct SignaturePreviewRestoreState {
    let channels: [SoundChannel: ChannelState]
    let currentPresetID: String?
    let activeComposerRecipeTitle: String?
    let isPlaying: Bool
    let isBinauralActive: Bool
    let activeBinauralTrack: BinauralTrack
    let binauralVolume: Double
    let timerDurationMinutes: Int?
    let timerEndDate: Date?
    let timerRemainingWhenPaused: TimeInterval?
    let timerDisplayValue: TimeInterval?
}

private enum EngagementDefaults {
    static let sessionCountKey = "oasis.engagement.sessionCount"
    static let listenedSecondsKey = "oasis.engagement.listenedSeconds"
    static let didTrackFirstPlayKey = "oasis.engagement.didTrackFirstPlay"
    static let didTrackListened60sKey = "oasis.engagement.didTrackListened60s"
    static let didRequestReviewKey = "oasis.engagement.didRequestReview"
    static let lastPaywallInteractionKey = "oasis.engagement.lastPaywallInteraction"
    static let reviewSessionThreshold = 3
    static let reviewListenThreshold: TimeInterval = 5 * 60
    static let reviewPaywallCooldown: TimeInterval = 60 * 60
}

private enum OnboardingDefaults {
    static let completedKey = "oasis.onboarding.completed"
}

private final class RevenueCatObserver: NSObject, PurchasesDelegate {
    var onCustomerInfoChange: (@Sendable (CustomerInfo) -> Void)?

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        onCustomerInfoChange?(customerInfo)
    }
}
