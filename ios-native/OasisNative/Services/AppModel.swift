import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class AppModel {
    var isPlaying = false
    var timerDurationMinutes: Int?
    var timerEndDate: Date?
    var timerRemainingWhenPaused: TimeInterval?
    var currentPresetID: String?

    var isPremium = AppConfiguration.forcedPremiumAccess ?? false
    var showsPaywall = false
    var showsBinauralPanel = false
    var showsPresetsPanel = false
    var showsSpatialPanel = false
    var showsOnlyActiveChannels = false

    var isBinauralActive = false
    var activeBinauralTrack: BinauralTrack = .delta
    var binauralVolume = 0.5

    var channels: [SoundChannel: ChannelState] = .initialChannels
    var presets: [Preset] = .defaultPresets()
    var selectedLanguage = AppLanguage.resolved()

    var timerDisplayValue: TimeInterval?
    private(set) var variationDisplayVolumes: [SoundChannel: Double] = [:]

    @ObservationIgnored private let audioEngine = AudioMixerEngine()
    @ObservationIgnored private let revenueCatObserver = RevenueCatObserver()
    @ObservationIgnored private var timerTicker: Timer?
    @ObservationIgnored private var bootstrapTask: Task<Void, Never>?
    @ObservationIgnored private var persistenceTask: Task<Void, Never>?
    @ObservationIgnored private var didBootstrap = false
    @ObservationIgnored private var revenueCatHasPremium = false
    @ObservationIgnored private var screenshotShuffleIndex = 0

    var copy: AppStrings {
        AppTranslations.all[selectedLanguage] ?? AppTranslations.all[.en]!
    }

    var mixerSnapshot: MixerSnapshot {
        MixerSnapshot(
            isPlaying: isPlaying,
            isPremium: isPremium,
            channels: channels,
            isBinauralActive: isBinauralActive,
            activeBinauralTrack: activeBinauralTrack,
            binauralVolume: binauralVolume
        )
    }

    init() {
        let didLoadPersistedState = loadPersistedState()

        if !didLoadPersistedState && !AppConfiguration.shouldResetStateOnLaunch {
            channels = .starterChannels
            persistState()
        }

        configureCallbacks()
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
        copy.channels[channel]
    }

    func presetDisplayName(_ preset: Preset) -> String {
        switch preset.id {
        case "preset_default_calm":
            return copy.presets.defaultCalm
        case "preset_default_storm":
            return copy.presets.defaultStorm
        default:
            return preset.name
        }
    }

    func isChannelLocked(_ channel: SoundChannel) -> Bool {
        !isPremium && !SoundChannel.freeChannels.contains(channel)
    }

    func isAmbientChannelActive(_ channel: SoundChannel) -> Bool {
        guard let state = channels[channel] else { return false }
        return !state.isMuted && !isChannelLocked(channel)
    }

    var activeAmbientChannelsCount: Int {
        SoundChannel.allCases.filter(isAmbientChannelActive(_:)).count
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
            if let pausedRemaining = timerRemainingWhenPaused, timerDurationMinutes != nil {
                timerEndDate = Date().addingTimeInterval(pausedRemaining)
            }
        } else if let endDate = timerEndDate {
            timerRemainingWhenPaused = max(endDate.timeIntervalSinceNow, 0)
            timerEndDate = nil
        }

        startTimerTickerIfNeeded()
        updateTimerDisplayValue()
        schedulePersistence()
        synchronizeAudio()
    }

    func setTimer(_ minutes: Int?) {
        guard isPremium else {
            showsPaywall = true
            return
        }

        timerDurationMinutes = minutes
        timerRemainingWhenPaused = minutes.map { Double($0 * 60) }
        timerEndDate = minutes.map { Date().addingTimeInterval(Double($0 * 60)) }
        startTimerTickerIfNeeded()
        updateTimerDisplayValue()
        persistState()
    }

    func randomizeMix() {
        let availableChannels = isPremium ? SoundChannel.allCases : Array(SoundChannel.freeChannels)
        if AppConfiguration.isRunningScreenshotAutomation {
            applyScreenshotShuffle(availableChannels: availableChannels)
            return
        }

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
        persistState()

        if !isPlaying {
            isPlaying = true
            if let minutes = timerDurationMinutes {
                let remaining = timerRemainingWhenPaused ?? Double(minutes * 60)
                timerEndDate = Date().addingTimeInterval(remaining)
            }
            startTimerTickerIfNeeded()
        }

        updateTimerDisplayValue()
        synchronizeAudio()
    }

    func setChannelVolume(_ channel: SoundChannel, value: Double) {
        guard var state = channels[channel], !isChannelLocked(channel) else {
            showsPaywall = true
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
            showsPaywall = true
            return
        }

        state.isMuted.toggle()
        channels[channel] = state
        if state.isMuted {
            variationDisplayVolumes.removeValue(forKey: channel)
        }
        currentPresetID = nil
        schedulePersistence()
        synchronizeAudio()
    }

    func toggleAutoVariation(_ channel: SoundChannel) {
        guard var state = channels[channel], !isChannelLocked(channel) else {
            showsPaywall = true
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
            showsPaywall = true
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
            showsBinauralPanel = false
            showsPaywall = true
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

    func loadPreset(_ preset: Preset) {
        channels = preset.channels
        variationDisplayVolumes.removeAll()
        currentPresetID = preset.id
        schedulePersistence()

        if isPlaying {
            synchronizeAudio()
        } else {
            setPlayback(true)
        }
    }

    func savePreset(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let preset = Preset(
            id: "preset_user_\(Int(Date().timeIntervalSince1970 * 1000))",
            name: trimmedName,
            channels: channels
        )

        presets.append(preset)
        currentPresetID = preset.id
        schedulePersistence()
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

    func closeOverlays() {
        showsBinauralPanel = false
        showsPresetsPanel = false
        showsSpatialPanel = false
        showsPaywall = false
    }

    func applyRevenueCatCustomerInfo(_ customerInfo: CustomerInfo) {
        applyCustomerInfo(customerInfo)
    }

    func restorePurchases() async {
        guard AppConfiguration.shouldUseRevenueCatAccess, AppConfiguration.isRevenueCatConfigured else { return }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(customerInfo)
        } catch {
            print("RevenueCat restore failed: \(error)")
        }
    }

    var timerToolbarTitle: String {
        if let timerDisplayValue {
            return formatTimer(timerDisplayValue)
        }

        if let timerDurationMinutes {
            return "\(timerDurationMinutes)m"
        }

        return copy.header.timer
    }

    var activePreset: Preset? {
        guard let currentPresetID else { return nil }
        return presets.first { $0.id == currentPresetID }
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
            presets = persisted.presets
            currentPresetID = persisted.currentPresetID
            isBinauralActive = persisted.isBinauralActive
            activeBinauralTrack = persisted.activeBinauralTrack
            binauralVolume = persisted.binauralVolume
            if let selectedLanguage = persisted.selectedLanguage {
                self.selectedLanguage = selectedLanguage
            }
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
            selectedLanguage: selectedLanguage
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
            if var state = channels[channel] {
                state.isMuted = true
                state.autoVariationEnabled = false
                channels[channel] = state
                variationDisplayVolumes.removeValue(forKey: channel)
            }
        }

        if activeBinauralTrack.isPremium {
            activeBinauralTrack = .delta
        }

        if timerDurationMinutes != nil {
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
                isPlaying = false
                timerDurationMinutes = nil
                self.timerEndDate = nil
                timerRemainingWhenPaused = nil
                timerDisplayValue = nil
                persistState()
                synchronizeAudio()
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
            let customerInfo = try await Purchases.shared.customerInfo()
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
            showsPaywall = false
        }

        guard didChangePremium else { return }

        enforcePremiumAccess()
        updateTimerDisplayValue()
        synchronizeAudio()
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
        persistState()

        if !isPlaying {
            isPlaying = true
            if let minutes = timerDurationMinutes {
                let remaining = timerRemainingWhenPaused ?? Double(minutes * 60)
                timerEndDate = Date().addingTimeInterval(remaining)
            }
            startTimerTickerIfNeeded()
        }

        updateTimerDisplayValue()
        synchronizeAudio()
    }

    private static let screenshotShuffleTemplates: [[SoundChannel: ChannelState]] = [
        [
            .oiseaux: ChannelState(volume: 0.58, isMuted: false, autoVariationEnabled: false),
            .vent: ChannelState(volume: 0.34, isMuted: false, autoVariationEnabled: true),
            .plage: ChannelState(volume: 0.42, isMuted: false, autoVariationEnabled: false),
            .foret: ChannelState(volume: 0.55, isMuted: false, autoVariationEnabled: false)
        ],
        [
            .pluie: ChannelState(volume: 0.62, isMuted: false, autoVariationEnabled: false),
            .tonnerre: ChannelState(volume: 0.48, isMuted: false, autoVariationEnabled: true),
            .vent: ChannelState(volume: 0.31, isMuted: false, autoVariationEnabled: false),
            .grillons: ChannelState(volume: 0.36, isMuted: false, autoVariationEnabled: false),
            .riviere: ChannelState(volume: 0.52, isMuted: false, autoVariationEnabled: false)
        ],
        [
            .train: ChannelState(volume: 0.44, isMuted: false, autoVariationEnabled: false),
            .voiture: ChannelState(volume: 0.37, isMuted: false, autoVariationEnabled: true),
            .village: ChannelState(volume: 0.29, isMuted: false, autoVariationEnabled: false),
            .tente: ChannelState(volume: 0.50, isMuted: false, autoVariationEnabled: false),
            .cigales: ChannelState(volume: 0.40, isMuted: false, autoVariationEnabled: true),
            .grillons: ChannelState(volume: 0.33, isMuted: false, autoVariationEnabled: false)
        ]
    ]
}

private final class RevenueCatObserver: NSObject, PurchasesDelegate {
    var onCustomerInfoChange: (@Sendable (CustomerInfo) -> Void)?

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        onCustomerInfoChange?(customerInfo)
    }
}
