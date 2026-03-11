import AVFoundation
import MediaPlayer
import Foundation

final class AudioMixerEngine: @unchecked Sendable {
    var onVariationChanged: (@MainActor @Sendable (SoundChannel, Double?) -> Void)?
    var onRemotePlaybackChange: (@MainActor @Sendable (Bool) -> Void)?

    private let queue = DispatchQueue(label: "com.jonathanluquet.oasis.audio-engine", qos: .userInitiated)

    private var ambientPlayers: [SoundChannel: AVAudioPlayer] = [:]
    private var binauralPlayers: [BinauralTrack: AVAudioPlayer] = [:]
    private var variationTasks: [SoundChannel: Task<Void, Never>] = [:]
    private var randomizedOffsets: Set<SoundChannel> = []
    private var fadeTask: Task<Void, Never>?
    private var masterFade: Double = 0
    private var previousPlayingState = false
    private var previousNowPlayingRate: Double?
    private var latestSnapshot = MixerSnapshot(
        isPlaying: false,
        isPremium: false,
        channels: .initialChannels,
        isBinauralActive: false,
        activeBinauralTrack: .delta,
        binauralVolume: 0.5
    )
    private var liveVariationVolumes: [SoundChannel: Double] = [:]
    private var remoteCommandsConfigured = false

    init() {
        configureRemoteCommands()
        queue.async { [weak self] in
            self?.configureAudioSession()
        }
    }

    deinit {
        fadeTask?.cancel()
        variationTasks.values.forEach { $0.cancel() }
    }

    func sync(with snapshot: MixerSnapshot) {
        queue.async { [weak self] in
            guard let self else { return }

            self.latestSnapshot = snapshot
            self.synchronizeVariationTasks(for: snapshot)

            if snapshot.isPlaying != self.previousPlayingState {
                self.previousPlayingState = snapshot.isPlaying
                self.transitionPlayback(to: snapshot.isPlaying)
            }

            self.refreshPlayerStates()
            self.updateNowPlayingInfo()
        }
    }

    func setMasterFade(_ value: Double) {
        queue.async { [weak self] in
            guard let self else { return }
            self.masterFade = value
            self.refreshPlayerVolumes()
        }
    }

    func preloadBinauralTrack(_ track: BinauralTrack) {
        queue.async { [weak self] in
            guard let self else { return }
            _ = self.binauralPlayer(for: track)
        }
    }

    private func makePlayer(filename: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0
            player.prepareToPlay()
            return player
        } catch {
            print("Failed to load audio file \(filename): \(error)")
            return nil
        }
    }

    private func ambientPlayer(for channel: SoundChannel) -> AVAudioPlayer? {
        if let player = ambientPlayers[channel] {
            return player
        }

        let player = makePlayer(filename: channel.filename)
        if let player {
            ambientPlayers[channel] = player
        }
        return player
    }

    private func binauralPlayer(for track: BinauralTrack) -> AVAudioPlayer? {
        if let player = binauralPlayers[track] {
            return player
        }

        let player = makePlayer(filename: track.filename)
        if let player {
            binauralPlayers[track] = player
        }
        return player
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setPreferredSampleRate(44_100)
            try session.setPreferredIOBufferDuration(0.046)
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func configureRemoteCommands() {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let callback = self?.onRemotePlaybackChange else { return .success }
            Task { @MainActor in
                callback(true)
            }
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let callback = self?.onRemotePlaybackChange else { return .success }
            Task { @MainActor in
                callback(false)
            }
            return .success
        }
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            let shouldPlay = !self.latestSnapshot.isPlaying
            guard let callback = self.onRemotePlaybackChange else { return .success }
            Task { @MainActor in
                callback(shouldPlay)
            }
            return .success
        }
    }

    private func transitionPlayback(to isPlaying: Bool) {
        fadeTask?.cancel()

        if isPlaying {
            startActivePlayersIfNeeded()
            fadeTask = animateFade(from: masterFade, to: 1, duration: 1.6)
        } else {
            fadeTask = animateFade(from: masterFade, to: 0, duration: 0.9, completion: { [weak self] in
                self?.pauseAllPlayers()
            })
        }
    }

    private func animateFade(
        from start: Double,
        to target: Double,
        duration: TimeInterval,
        completion: (@Sendable () -> Void)? = nil
    ) -> Task<Void, Never> {
        Task(priority: .utility) { [weak self] in
            guard let self else { return }
            let steps = max(Int(duration / 0.12), 1)

            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(120))
                guard !Task.isCancelled else { return }

                let progress = Double(step) / Double(steps)
                let value = start + (target - start) * progress
                self.queue.async { [weak self] in
                    guard let self else { return }
                    self.masterFade = value
                    self.refreshPlayerVolumes()
                }
            }

            self.queue.async { [weak self] in
                guard let self else { return }
                self.masterFade = target
                self.refreshPlayerStates()
                completion?()
            }
        }
    }

    private func startActivePlayersIfNeeded() {
        for channel in SoundChannel.allCases where shouldPlayAmbient(channel) {
            guard let player = ambientPlayer(for: channel) else { continue }

            if randomizedOffsets.contains(channel) == false {
                player.currentTime = Double.random(in: 0..<max(player.duration, 0.01))
                randomizedOffsets.insert(channel)
            }

            if !player.isPlaying {
                player.play()
            }
        }

        for track in BinauralTrack.allCases where shouldPlayBinaural(track) {
            guard let player = binauralPlayer(for: track), !player.isPlaying else { continue }
            player.play()
        }
    }

    private func pauseAllPlayers() {
        ambientPlayers.values.forEach { $0.pause() }
        binauralPlayers.values.forEach { $0.pause() }
    }

    private func refreshPlayerStates() {
        if latestSnapshot.isPlaying {
            startActivePlayersIfNeeded()
        }

        for channel in SoundChannel.allCases {
            guard let player = ambientPlayers[channel] ?? (shouldPlayAmbient(channel) ? ambientPlayer(for: channel) : nil) else { continue }

            let volume = targetAmbientVolume(for: channel)
            player.volume = Float(volume)

            if volume <= 0.0001, !latestSnapshot.isPlaying || !shouldPlayAmbient(channel) {
                player.pause()
            } else if latestSnapshot.isPlaying, shouldPlayAmbient(channel), !player.isPlaying {
                player.play()
            }
        }

        for track in BinauralTrack.allCases {
            guard let player = binauralPlayers[track] ?? (shouldPlayBinaural(track) ? binauralPlayer(for: track) : nil) else { continue }

            let volume = targetBinauralVolume(for: track)
            player.volume = Float(volume)

            if volume <= 0.0001 || !latestSnapshot.isPlaying || !shouldPlayBinaural(track) {
                player.pause()
            } else if !player.isPlaying {
                player.play()
            }
        }
    }

    private func refreshPlayerVolumes() {
        for channel in SoundChannel.allCases {
            if let player = ambientPlayers[channel] {
                player.volume = Float(targetAmbientVolume(for: channel))
            }
        }

        for track in BinauralTrack.allCases {
            if let player = binauralPlayers[track] {
                player.volume = Float(targetBinauralVolume(for: track))
            }
        }
    }

    private func targetAmbientVolume(for channel: SoundChannel) -> Double {
        guard let state = latestSnapshot.channels[channel], state.isMuted == false else { return 0 }
        guard latestSnapshot.isPremium || SoundChannel.freeChannels.contains(channel) else { return 0 }

        let sourceVolume = state.autoVariationEnabled
            ? (liveVariationVolumes[channel] ?? state.volume)
            : state.volume

        return min(max(sourceVolume, 0), 1) * masterFade
    }

    private func targetBinauralVolume(for track: BinauralTrack) -> Double {
        guard latestSnapshot.isBinauralActive else { return 0 }
        guard latestSnapshot.activeBinauralTrack == track else { return 0 }
        guard latestSnapshot.isPremium || !track.isPremium else { return 0 }
        return latestSnapshot.binauralVolume * masterFade
    }

    private func shouldPlayAmbient(_ channel: SoundChannel) -> Bool {
        guard latestSnapshot.isPlaying else { return false }
        guard let state = latestSnapshot.channels[channel] else { return false }
        return !state.isMuted && (latestSnapshot.isPremium || SoundChannel.freeChannels.contains(channel))
    }

    private func shouldPlayBinaural(_ track: BinauralTrack) -> Bool {
        latestSnapshot.isPlaying
            && latestSnapshot.isBinauralActive
            && latestSnapshot.activeBinauralTrack == track
            && (latestSnapshot.isPremium || !track.isPremium)
    }

    private func synchronizeVariationTasks(for snapshot: MixerSnapshot) {
        for channel in SoundChannel.allCases {
            guard let state = snapshot.channels[channel] else { continue }
            let shouldVary = snapshot.isPlaying
                && !state.isMuted
                && state.autoVariationEnabled
                && (snapshot.isPremium || SoundChannel.freeChannels.contains(channel))

            if shouldVary {
                if variationTasks[channel] == nil {
                    variationTasks[channel] = startVariationTask(for: channel, initialValue: state.volume)
                }
            } else {
                variationTasks[channel]?.cancel()
                variationTasks[channel] = nil
                liveVariationVolumes[channel] = nil
                dispatchVariationChange(for: channel, value: nil)
            }
        }
    }

    private func startVariationTask(for channel: SoundChannel, initialValue: Double) -> Task<Void, Never> {
        Task(priority: .utility) { [weak self] in
            guard let self else { return }
            var currentValue = initialValue
            let startingValue = currentValue

            self.queue.async { [weak self] in
                guard let self else { return }
                self.liveVariationVolumes[channel] = startingValue
                self.refreshPlayerVolumes()
            }
            self.dispatchVariationChange(for: channel, value: startingValue)

            while !Task.isCancelled {
                let target = Double.random(in: 0...1)
                let steps = 20

                for step in 1...steps {
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !Task.isCancelled else { return }

                    let progress = Double(step) / Double(steps)
                    let nextValue = currentValue + (target - currentValue) * progress
                    let valueToApply = nextValue

                    self.queue.async { [weak self] in
                        guard let self else { return }
                        self.liveVariationVolumes[channel] = valueToApply
                        self.refreshPlayerVolumes()
                    }

                    if step.isMultiple(of: 2) {
                        self.dispatchVariationChange(for: channel, value: valueToApply)
                    }
                }

                currentValue = target
                self.dispatchVariationChange(for: channel, value: currentValue)

                let pauseMilliseconds = Int.random(in: 4_000...10_000)
                try? await Task.sleep(for: .milliseconds(pauseMilliseconds))
            }
        }
    }

    private func dispatchVariationChange(for channel: SoundChannel, value: Double?) {
        guard let callback = onVariationChanged else { return }
        Task { @MainActor in
            callback(channel, value)
        }
    }

    private func updateNowPlayingInfo() {
        let playbackRate = latestSnapshot.isPlaying ? 1.0 : 0.0
        guard previousNowPlayingRate != playbackRate else { return }
        previousNowPlayingRate = playbackRate

        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: "Oasis",
                MPMediaItemPropertyArtist: "Binaural Nature",
                MPNowPlayingInfoPropertyPlaybackRate: playbackRate
            ]
        }
    }
}
