import Foundation
import Observation
import RevenueCat
import StoreKit
import SwiftUI
import UIKit

@MainActor
@Observable
final class AppModel {
    var isPlaying = false
    var timerDurationMinutes: Int?
    var timerEndDate: Date?
    var timerRemainingWhenPaused: TimeInterval?
    var currentPresetID: String?

    var isPremium = AppConfiguration.forcedPremiumAccess ?? false
    var activePaywallContext: PremiumPaywallContext?
    var activeInlineUpsell: PremiumInlineUpsellContext?
    var showsBinauralPanel = false
    var showsPresetsPanel = false
    var showsSpatialPanel = false
    var showsOnlyActiveChannels = false
    var showsPremiumHomeBanner = false
    var isSignaturePreviewActive = false
    var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "oasis.onboarding.completed")

    var isBinauralActive = false
    var activeBinauralTrack: BinauralTrack = .delta
    var binauralVolume = 0.5

    /// Atmospheric tonal bed toggle. Defaults to off — the pad is an opt-in flavour that
    /// users enable from the binaural panel when they want a quiet harmonic layer under
    /// the mix. The flag is persisted across launches.
    var isTonalBedEnabled = false

    var channels: [SoundChannel: ChannelState] = .initialChannels
    var presets: [Preset] = .defaultPresets()
    var premiumBannerLastDismissedAt: Date?
    var signaturePreviewLastPlayedAt: Date?

    var timerDisplayValue: TimeInterval?
    private(set) var variationDisplayVolumes: [SoundChannel: Double] = [:]

    @ObservationIgnored private let audioEngine = AudioMixerEngine()
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
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume,
            previewUnlockedChannels: previewUnlockedChannels,
            previewUnlockedTracks: previewUnlockedTracks,
            isTonalBedEnabled: isTonalBedEnabled
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

    var paywallPresentation: PremiumPaywallPresentation? {
        guard let context = activePaywallContext else { return nil }
        return paywallPresentation(for: context.entryPoint)
    }

    var isSignaturePreviewAvailable: Bool {
        premiumCoordinator.canStartSignaturePreview(lastPlayedAt: signaturePreviewLastPlayedAt)
    }

    init() {
        let didLoadPersistedState = loadPersistedState()

        if !didLoadPersistedState && !AppConfiguration.shouldResetStateOnLaunch {
            channels = .starterChannels
            persistState()
        }

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

    func channelName(_ channel: SoundChannel) -> String {
        channel.localizedName
    }

    func presetDisplayName(_ preset: Preset) -> String {
        switch preset.id {
        case "preset_default_starter":
            return L10n.string(L10n.Presets.defaultStarter)
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

    func isAmbientChannelActive(_ channel: SoundChannel) -> Bool {
        guard let state = channels[channel] else { return false }
        return !state.isMuted && hasAmbientPlaybackAccess(to: channel)
    }

    var activeAmbientChannelsCount: Int {
        SoundChannel.allCases.filter(isAmbientChannelActive(_:)).count
    }

    /// Ordered palette of channel tints for every unmuted ambient channel, shaped for the
    /// liquid aura that breathes inside the main play/pause button.
    var activePlaybackPalette: [Color] {
        let colors = SoundChannel.allCases.compactMap { channel -> Color? in
            guard let state = channels[channel], !state.isMuted else { return nil }
            return channel.tint
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
            schedulePremiumBannerIfNeeded()
        } else if let endDate = timerEndDate {
            endListeningSession()
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
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        state.volume = value
        channels[channel] = state
        currentPresetID = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func toggleMute(_ channel: SoundChannel) {
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        state.isMuted.toggle()
        channels[channel] = state
        if state.isMuted {
            variationDisplayVolumes.removeValue(forKey: channel)
        }
        currentPresetID = nil

        if handleNoActiveChannelsIfNeeded() {
            return
        }

        schedulePersistence()
        synchronizeAudio()
    }

    func toggleAutoVariation(_ channel: SoundChannel) {
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .sound(channel))
            return
        }

        state.autoVariationEnabled.toggle()
        channels[channel] = state
        if state.autoVariationEnabled {
            variationDisplayVolumes[channel] = state.volume
        } else {
            variationDisplayVolumes.removeValue(forKey: channel)
        }
        currentPresetID = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func setChannelSpatialPosition(_ channel: SoundChannel, value: SpatialPoint) {
        guard var state = channels[channel], !isChannelLocked(channel) else {
            requestPremiumAccess(from: .spatial(channel))
            return
        }

        state.spatialPosition = value.clamped()
        channels[channel] = state
        currentPresetID = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func resetChannelSpatialPosition(_ channel: SoundChannel) {
        setChannelSpatialPosition(channel, value: .center)
    }

    func setBinauralEnabled(_ enabled: Bool) {
        guard isBinauralActive != enabled else { return }
        if enabled {
            audioEngine.preloadBinauralTrack(activeBinauralTrack)
        }
        isBinauralActive = enabled
        schedulePersistence()
        synchronizeAudio()
    }

    @discardableResult
    func selectBinauralTrack(_ track: BinauralTrack) -> Bool {
        guard isPremium || !track.isPremium else {
            requestPremiumAccess(from: .binaural(track))
            return false
        }

        activeBinauralTrack = track
        audioEngine.preloadBinauralTrack(track)
        schedulePersistence()
        synchronizeAudio()
        return true
    }

    func setBinauralVolume(_ value: Double) {
        binauralVolume = value
        schedulePersistence()
        synchronizeAudio()
    }

    func setTonalBedEnabled(_ enabled: Bool) {
        guard isTonalBedEnabled != enabled else { return }
        isTonalBedEnabled = enabled
        schedulePersistence()
        synchronizeAudio()
    }

    func loadPreset(_ preset: Preset) {
        guard !isPresetLocked(preset) else {
            requestPremiumAccess(from: .presetLoad)
            return
        }

        finishSignaturePreview(restoreState: false, shouldPromotePaywall: false)

        channels = preset.channels
        variationDisplayVolumes.removeAll()
        currentPresetID = preset.id

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
    func savePreset(named name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }

        guard isPremium || canSaveFreePreset else {
            requestPremiumAccess(from: .presetSave)
            return false
        }

        let preset = Preset(
            id: "preset_user_\(Int(Date().timeIntervalSince1970 * 1000))",
            name: trimmedName,
            channels: channels
        )

        presets.append(preset)
        currentPresetID = preset.id
        premiumAnalytics.track(.presetSaved(kind: isPremium ? "premium" : "free"))
        schedulePersistence()
        return true
    }

    func deletePreset(_ preset: Preset) {
        presets.removeAll { $0.id == preset.id }
        if currentPresetID == preset.id {
            currentPresetID = nil
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
        let benefitRows: [String]

        switch entryPoint.category {
        case .manual:
            title = L10n.string(L10n.Paywall.titleGeneric)
            subtitle = L10n.string(L10n.Paywall.subtitleGeneric)
            benefitRows = [
                L10n.string(L10n.Paywall.benefitSounds),
                L10n.string(L10n.Paywall.benefitPresets),
                L10n.string(L10n.Paywall.benefitBinaural),
                L10n.string(L10n.Paywall.benefitUpdates)
            ]

        case .sound, .spatial:
            title = L10n.string(L10n.Paywall.titleSounds)
            subtitle = L10n.string(L10n.Paywall.subtitleSounds)
            benefitRows = [
                L10n.string(L10n.Paywall.benefitSounds),
                L10n.string(L10n.Paywall.benefitPresets),
                L10n.string(L10n.Paywall.benefitBinaural),
                L10n.string(L10n.Paywall.benefitUpdates)
            ]

        case .timer:
            title = L10n.string(L10n.Paywall.titleTimer)
            subtitle = L10n.string(L10n.Paywall.subtitleTimer)
            benefitRows = [
                L10n.string(L10n.Paywall.benefitTimer),
                L10n.string(L10n.Paywall.benefitSounds),
                L10n.string(L10n.Paywall.benefitPresets),
                L10n.string(L10n.Paywall.benefitBinaural)
            ]

        case .preset:
            title = L10n.string(L10n.Paywall.titlePresets)
            subtitle = L10n.string(L10n.Paywall.subtitlePresets)
            benefitRows = [
                L10n.string(L10n.Paywall.benefitPresets),
                L10n.string(L10n.Paywall.benefitSounds),
                L10n.string(L10n.Paywall.benefitBinaural),
                L10n.string(L10n.Paywall.benefitUpdates)
            ]

        case .binaural:
            title = L10n.string(L10n.Paywall.titleBinaural)
            subtitle = L10n.string(L10n.Paywall.subtitleBinaural)
            benefitRows = [
                L10n.string(L10n.Paywall.benefitBinaural),
                L10n.string(L10n.Paywall.benefitSounds),
                L10n.string(L10n.Paywall.benefitPresets),
                L10n.string(L10n.Paywall.benefitUpdates)
            ]

        case .preview:
            title = L10n.string(L10n.Paywall.titlePreview)
            subtitle = L10n.string(L10n.Paywall.subtitlePreview)
            benefitRows = [
                L10n.string(L10n.Paywall.benefitPresets),
                L10n.string(L10n.Paywall.benefitSounds),
                L10n.string(L10n.Paywall.benefitBinaural),
                L10n.string(L10n.Paywall.benefitUpdates)
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

    func completeOnboarding(fromPage page: Int = -1, skipped: Bool = false) {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "oasis.onboarding.completed")
        if skipped {
            premiumAnalytics.track(.onboardingSkipped(page: page))
        } else {
            premiumAnalytics.track(.onboardingCompleted(page: page))
        }
    }

    func closeOverlays() {
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
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
        else { return }

        defaults.set(true, forKey: EngagementDefaults.didRequestReviewKey)
        premiumAnalytics.track(.reviewPromptRequested(reason: reason))
        AppStore.requestReview(in: scene)
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
            guard !self.showsPresetsPanel, !self.showsBinauralPanel, !self.showsSpatialPanel else { return }

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
            presets = mergeMissingDefaultPresets(into: persisted.presets)
            currentPresetID = persisted.currentPresetID
            isBinauralActive = persisted.isBinauralActive
            activeBinauralTrack = persisted.activeBinauralTrack
            binauralVolume = persisted.binauralVolume
            premiumBannerLastDismissedAt = persisted.premiumBannerLastDismissedAt
            signaturePreviewLastPlayedAt = persisted.signaturePreviewLastPlayedAt
            // Missing field in older builds → default to off so upgrading users land on
            // the same opt-in baseline as fresh installs.
            isTonalBedEnabled = persisted.isTonalBedEnabled ?? false

            enforcePremiumAccess()
            return true
        } catch {
            print("Failed to decode persisted mixer state: \(error)")
            return false
        }
    }

    private func persistState() {
        guard AppConfiguration.shouldPersistState else { return }
        let persisted = PersistedMixerState(
            channels: channels,
            presets: presets,
            currentPresetID: currentPresetID,
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume,
            selectedLanguage: nil,
            premiumBannerLastDismissedAt: premiumBannerLastDismissedAt,
            signaturePreviewLastPlayedAt: signaturePreviewLastPlayedAt,
            isTonalBedEnabled: isTonalBedEnabled
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
                partialResult[entry.key] = entry.value.volume
            }
        }
        currentPresetID = nil

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
        guard activeAmbientChannelsCount == 0 else { return false }

        if showsOnlyActiveChannels {
            showsOnlyActiveChannels = false
        }

        guard isPlaying else { return false }

        setPlayback(false)
        return true
    }

    private func mergeMissingDefaultPresets(into storedPresets: [Preset]) -> [Preset] {
        var mergedPresets = storedPresets
        let existingIDs = Set(storedPresets.map(\.id))

        for preset in Array.defaultPresets() where !existingIDs.contains(preset.id) {
            mergedPresets.append(preset)
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

private final class RevenueCatObserver: NSObject, PurchasesDelegate {
    var onCustomerInfoChange: (@Sendable (CustomerInfo) -> Void)?

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        onCustomerInfoChange?(customerInfo)
    }
}
