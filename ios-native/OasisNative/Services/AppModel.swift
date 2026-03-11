import Combine
import StoreKit
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var isPlaying = false
    @Published var timerDurationMinutes: Int?
    @Published var timerEndDate: Date?
    @Published var timerRemainingWhenPaused: TimeInterval?
    @Published var currentPresetID: String?

    @Published var isPremium = AppConfiguration.simulatesPremium
    @Published var showsPaywall = false
    @Published var showsBinauralPanel = false
    @Published var showsPresetsPanel = false

    @Published var isBinauralActive = false
    @Published var activeBinauralTrack: BinauralTrack = .delta
    @Published var binauralVolume = 0.5

    @Published var channels: [SoundChannel: ChannelState] = .initialChannels
    @Published var presets: [Preset] = .defaultPresets()
    @Published var selectedLanguage = AppLanguage.resolved()

    @Published var premiumPriceText = "..."
    @Published var isLoadingPremiumProduct = false
    @Published var isPurchasingPremium = false
    @Published var isRestoringPurchases = false
    @Published var purchaseErrorMessage: String?

    @Published var timerDisplayValue: TimeInterval?
    @Published private(set) var variationDisplayVolumes: [SoundChannel: Double] = [:]

    private let audioEngine = AudioMixerEngine()
    private var premiumProduct: Product?
    private var timerTicker: Timer?
    private var bootstrapTask: Task<Void, Never>?
    private var transactionUpdatesTask: Task<Void, Never>?
    private var persistenceTask: Task<Void, Never>?
    private var didBootstrap = false

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
        loadPersistedState()

        audioEngine.onRemotePlaybackChange = { [weak self] shouldPlay in
            guard let self else { return }
            self.setPlayback(shouldPlay)
        }

        audioEngine.onVariationChanged = { [weak self] channel, value in
            guard let self else { return }
            guard !self.showsPresetsPanel, !self.showsBinauralPanel else { return }

            if let value {
                self.variationDisplayVolumes[channel] = value
            } else {
                self.variationDisplayVolumes.removeValue(forKey: channel)
            }
        }

        updateTimerDisplayValue()
        synchronizeAudio()
    }

    func bootstrapIfNeeded() {
        guard !didBootstrap else { return }
        didBootstrap = true
        guard !AppConfiguration.simulatesPremium else { return }

        bootstrapTask = Task { [weak self] in
            guard let self else { return }
            await self.loadPremiumProduct()
            await self.refreshPremiumStatus()
            self.startTransactionListener()
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
        audioEngine.preloadBinauralTrack(activeBinauralTrack)
        showsPresetsPanel = false
        showsBinauralPanel = true
    }

    func openPresetsPanel() {
        if isPremium {
            showsBinauralPanel = false
            showsPresetsPanel = true
        } else {
            showsPaywall = true
        }
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
        var newChannels = [SoundChannel: ChannelState].initialChannels

        let maxActive = min(4, availableChannels.count)
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
        synchronizeAudio()
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
        showsPaywall = false
        purchaseErrorMessage = nil
    }

    func purchasePremium() async {
        guard !AppConfiguration.simulatesPremium else {
            applyPremiumStatus(true)
            showsPaywall = false
            return
        }

        purchaseErrorMessage = nil

        if premiumProduct == nil {
            await loadPremiumProduct()
        }

        guard let premiumProduct else {
            purchaseErrorMessage = "Store unavailable."
            return
        }

        isPurchasingPremium = true
        defer { isPurchasingPremium = false }

        do {
            let result = try await premiumProduct.purchase()

            switch result {
            case .success(let verificationResult):
                let transaction = try checkVerified(verificationResult)
                await transaction.finish()
                applyPremiumStatus(true)
                showsPaywall = false
            case .userCancelled:
                break
            case .pending:
                purchaseErrorMessage = "Purchase pending approval."
            @unknown default:
                break
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        guard !AppConfiguration.simulatesPremium else {
            applyPremiumStatus(true)
            showsPaywall = false
            return
        }

        purchaseErrorMessage = nil
        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            try await AppStore.sync()
            await refreshPremiumStatus()
            if isPremium {
                showsPaywall = false
            } else {
                purchaseErrorMessage = "No purchase found to restore."
            }
        } catch {
            purchaseErrorMessage = error.localizedDescription
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

    private func startTransactionListener() {
        guard transactionUpdatesTask == nil else { return }

        transactionUpdatesTask = Task { [weak self] in
            guard let self else { return }

            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.refreshPremiumStatus()
                } catch {
                    continue
                }
            }
        }
    }

    private func loadPersistedState() {
        guard let data = UserDefaults.standard.data(forKey: AppConfiguration.persistenceKey) else {
            return
        }

        do {
            let persisted = try JSONDecoder().decode(PersistedMixerState.self, from: data)
            channels = persisted.channels
            presets = persisted.presets
            currentPresetID = persisted.currentPresetID
            isPremium = AppConfiguration.simulatesPremium ? true : persisted.isPremium
            isBinauralActive = persisted.isBinauralActive
            activeBinauralTrack = persisted.activeBinauralTrack
            binauralVolume = persisted.binauralVolume
            if let selectedLanguage = persisted.selectedLanguage {
                self.selectedLanguage = selectedLanguage
            }
            enforcePremiumAccess()
        } catch {
            print("Failed to decode persisted mixer state: \(error)")
        }
    }

    private func persistState() {
        let persisted = PersistedMixerState(
            channels: channels,
            presets: presets,
            currentPresetID: currentPresetID,
            isPremium: isPremium,
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

    private func loadPremiumProduct() async {
        guard !AppConfiguration.simulatesPremium else {
            premiumPriceText = "Simulated"
            return
        }

        guard !AppConfiguration.premiumProductID.isEmpty else { return }

        isLoadingPremiumProduct = true
        defer { isLoadingPremiumProduct = false }

        do {
            premiumProduct = try await Product.products(for: [AppConfiguration.premiumProductID]).first
            premiumPriceText = premiumProduct?.displayPrice ?? "..."
        } catch {
            premiumPriceText = "..."
        }
    }

    private func refreshPremiumStatus() async {
        guard !AppConfiguration.simulatesPremium else {
            applyPremiumStatus(true)
            return
        }

        guard !AppConfiguration.premiumProductID.isEmpty else { return }

        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }

            if transaction.productID == AppConfiguration.premiumProductID, transaction.revocationDate == nil {
                hasPremium = true
                break
            }
        }

        applyPremiumStatus(hasPremium)
    }

    private func applyPremiumStatus(_ isPremium: Bool) {
        self.isPremium = AppConfiguration.simulatesPremium ? true : isPremium
        enforcePremiumAccess()
        updateTimerDisplayValue()
        synchronizeAudio()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.failedVerification
        }
    }
}

private enum StoreError: Error {
    case failedVerification
}
