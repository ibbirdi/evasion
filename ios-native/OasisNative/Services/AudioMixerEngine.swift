import AVFoundation
import Foundation
import MediaPlayer

private final class AmbientChannelPlayback: @unchecked Sendable {
    let channel: SoundChannel
    let node: AVAudioPlayerNode
    let url: URL
    let frameLength: AVAudioFramePosition
    let format: AVAudioFormat

    var scheduledFile: AVAudioFile?
    var isScheduled = false
    var scheduleToken = UUID()

    init(channel: SoundChannel, url: URL, file: AVAudioFile) {
        self.channel = channel
        self.node = AVAudioPlayerNode()
        self.url = url
        self.frameLength = file.length
        self.format = file.processingFormat
    }
}

final class AudioMixerEngine: @unchecked Sendable {
    var onVariationChanged: (@MainActor @Sendable (SoundChannel, Double?) -> Void)?
    var onRemotePlaybackChange: (@MainActor @Sendable (Bool) -> Void)?

    private let queue = DispatchQueue(label: "com.jonathanluquet.oasis.audio-engine", qos: .userInitiated)
    private let ambientEngine = AVAudioEngine()
    private let environmentNode = AVAudioEnvironmentNode()

    private var ambientPlayers: [SoundChannel: AmbientChannelPlayback] = [:]
    private var binauralPlayers: [BinauralTrack: AVAudioPlayer] = [:]
    private var variationTasks: [SoundChannel: Task<Void, Never>] = [:]
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
    private var isAmbientEngineConfigured = false
    private var isStopping = false
    private var routeObserver: NSObjectProtocol?

    init() {
        configureRemoteCommands()
        queue.async { [weak self] in
            self?.configureAudioSession()
            self?.configureAmbientEngineIfNeeded()
        }
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.queue.async { [weak self] in
                self?.updateEnvironmentOutputType()
            }
        }
    }

    deinit {
        fadeTask?.cancel()
        variationTasks.values.forEach { $0.cancel() }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
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

    private func ambientPlayer(for channel: SoundChannel) -> AmbientChannelPlayback? {
        if let player = ambientPlayers[channel] {
            return player
        }

        guard let url = Bundle.main.url(forResource: channel.filename, withExtension: nil) else {
            return nil
        }

        do {
            configureAmbientEngineIfNeeded()

            let file = try AVAudioFile(forReading: url)
            let playback = AmbientChannelPlayback(channel: channel, url: url, file: file)
            ambientEngine.attach(playback.node)
            playback.node.volume = 0
            ambientEngine.connect(playback.node, to: environmentNode, format: playback.format)
            applySpatialMixingConfiguration(for: channel, playback: playback)

            ambientPlayers[channel] = playback
            return playback
        } catch {
            print("Failed to prepare spatial audio for \(channel.filename): \(error)")
            return nil
        }
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
            if #available(iOS 15.0, *) {
                try session.setSupportsMultichannelContent(true)
            }
            if !AppConfiguration.isSimulator {
                try session.setPreferredSampleRate(44_100)
                try session.setPreferredIOBufferDuration(0.046)
            }
            try session.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    private func configureAmbientEngineIfNeeded() {
        guard !isAmbientEngineConfigured else { return }
        isAmbientEngineConfigured = true

        ambientEngine.attach(environmentNode)
        ambientEngine.connect(environmentNode, to: ambientEngine.mainMixerNode, format: nil)
        environmentNode.distanceAttenuationParameters.distanceAttenuationModel = .linear
        environmentNode.distanceAttenuationParameters.referenceDistance = 10
        environmentNode.distanceAttenuationParameters.maximumDistance = 10
        environmentNode.distanceAttenuationParameters.rolloffFactor = 0
        environmentNode.reverbParameters.enable = true
        environmentNode.reverbParameters.level = -18
        environmentNode.outputVolume = 1
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        updateEnvironmentOutputType()
    }

    private func startAmbientEngineIfNeeded() {
        configureAmbientEngineIfNeeded()

        guard !ambientEngine.isRunning else { return }

        do {
            try ambientEngine.start()
        } catch {
            print("Failed to start ambient engine: \(error)")
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
            isStopping = false
            startActivePlayersIfNeeded()
            fadeTask = animateFade(from: masterFade, to: 1, duration: 1.6)
        } else {
            isStopping = true
            fadeTask = animateFade(from: masterFade, to: 0, duration: 0.9, completion: { [weak self] in
                self?.pauseAllPlayers()
                self?.isStopping = false
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
        startAmbientEngineIfNeeded()

        for channel in SoundChannel.allCases where shouldPlayAmbient(channel) {
            guard let player = ambientPlayer(for: channel) else { continue }
            applySpatialMixingConfiguration(for: channel, playback: player)
            scheduleAmbientPlaybackIfNeeded(player)
            if !player.node.isPlaying {
                player.node.play()
            }
        }

        for track in BinauralTrack.allCases where shouldPlayBinaural(track) {
            guard let player = binauralPlayer(for: track), !player.isPlaying else { continue }
            player.play()
        }
    }

    private func scheduleAmbientPlaybackIfNeeded(_ playback: AmbientChannelPlayback) {
        guard !playback.isScheduled else { return }
        scheduleAmbientLoop(for: playback, randomStart: true)
    }

    private func scheduleAmbientLoop(for playback: AmbientChannelPlayback, randomStart: Bool) {
        let token = UUID()
        playback.scheduleToken = token
        playback.isScheduled = true

        do {
            let file = try AVAudioFile(forReading: playback.url)
            let maxStartFrame = max(playback.frameLength - 1, 0)
            let startFrame = randomStart && maxStartFrame > 0
                ? AVAudioFramePosition.random(in: 0..<maxStartFrame)
                : 0
            let remainingFrames = max(playback.frameLength - startFrame, 1)

            playback.scheduledFile = file
            playback.node.scheduleSegment(
                file,
                startingFrame: startFrame,
                frameCount: AVAudioFrameCount(remainingFrames),
                at: nil
            ) { [weak self, weak playback] in
                guard let self, let playback else { return }
                self.queue.async { [weak self, weak playback] in
                    guard let self, let playback else { return }
                    guard playback.scheduleToken == token else { return }

                    playback.scheduledFile = nil
                    playback.isScheduled = false

                    guard self.latestSnapshot.isPlaying, self.shouldPlayAmbient(playback.channel) else {
                        return
                    }

                    self.scheduleAmbientLoop(for: playback, randomStart: false)
                    if !playback.node.isPlaying {
                        playback.node.play()
                    }
                }
            }
        } catch {
            playback.isScheduled = false
            playback.scheduledFile = nil
            print("Failed to schedule ambient loop for \(playback.channel.filename): \(error)")
        }
    }

    private func stopAmbientPlayback(_ playback: AmbientChannelPlayback) {
        playback.scheduleToken = UUID()
        playback.isScheduled = false
        playback.scheduledFile = nil
        playback.node.stop()
        playback.node.reset()
    }

    private func pauseAllPlayers() {
        ambientPlayers.values.forEach(stopAmbientPlayback(_:))
        binauralPlayers.values.forEach { $0.pause() }
    }

    private func refreshPlayerStates() {
        if latestSnapshot.isPlaying {
            startActivePlayersIfNeeded()
        }

        for channel in SoundChannel.allCases {
            let keepAliveForFade = isStopping && (ambientPlayers[channel]?.node.isPlaying == true)
            let shouldStayActive = shouldPlayAmbient(channel) || keepAliveForFade

            guard let playback = ambientPlayers[channel] ?? (shouldStayActive ? ambientPlayer(for: channel) : nil) else { continue }

            applySpatialMixingConfiguration(for: channel, playback: playback)
            playback.node.volume = Float(targetAmbientVolume(for: channel))

            if shouldPlayAmbient(channel) {
                scheduleAmbientPlaybackIfNeeded(playback)
                if latestSnapshot.isPlaying, !playback.node.isPlaying {
                    playback.node.play()
                }
            } else if !keepAliveForFade {
                stopAmbientPlayback(playback)
            }
        }

        for track in BinauralTrack.allCases {
            let keepAliveForFade = isStopping && (binauralPlayers[track]?.isPlaying == true)
            let shouldStayActive = shouldPlayBinaural(track) || keepAliveForFade

            guard let player = binauralPlayers[track] ?? (shouldStayActive ? binauralPlayer(for: track) : nil) else { continue }

            let volume = targetBinauralVolume(for: track)
            player.volume = Float(volume)

            if shouldPlayBinaural(track) {
                if !player.isPlaying {
                    player.play()
                }
            } else if !keepAliveForFade {
                player.pause()
            }
        }
    }

    private func refreshPlayerVolumes() {
        for channel in SoundChannel.allCases {
            if let player = ambientPlayers[channel] {
                player.node.volume = Float(targetAmbientVolume(for: channel))
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
                let delta = Double.random(in: -0.22...0.22)
                let target = min(max(currentValue + delta, 0), 1)
                let distance = abs(target - currentValue)
                let stepDurationMilliseconds = 180
                let rampDurationMilliseconds = Int.random(in: 14_000...24_000) + Int(distance * 12_000)
                let steps = max(48, rampDurationMilliseconds / stepDurationMilliseconds)

                for step in 1...steps {
                    try? await Task.sleep(for: .milliseconds(stepDurationMilliseconds))
                    guard !Task.isCancelled else { return }

                    let progress = Double(step) / Double(steps)
                    let easedProgress = progress * progress * (3 - 2 * progress)
                    let nextValue = currentValue + (target - currentValue) * easedProgress
                    let valueToApply = nextValue

                    self.queue.async { [weak self] in
                        guard let self else { return }
                        self.liveVariationVolumes[channel] = valueToApply
                        self.refreshPlayerVolumes()
                    }

                    self.dispatchVariationChange(for: channel, value: valueToApply)
                }

                currentValue = target

                let pauseMilliseconds = Int.random(in: 8_000...16_000)
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

    private func applySpatialMixingConfiguration(for channel: SoundChannel, playback: AmbientChannelPlayback) {
        let point = latestSnapshot.channels[channel]?.spatialPosition ?? .center
        let clamped = point.clamped()
        let backAmount = max(clamped.y, 0)

        if playback.format.channelCount > 1 {
            playback.node.sourceMode = .ambienceBed
            playback.node.renderingAlgorithm = .auto
        } else {
            playback.node.sourceMode = .pointSource
            playback.node.pointSourceInHeadMode = .bypass
            playback.node.renderingAlgorithm = .HRTFHQ
        }

        playback.node.position = mappedSpatialPoint(for: clamped)
        playback.node.reverbBlend = Float(0.01 + (backAmount * 0.08))
        playback.node.obstruction = Float(-(backAmount * 6.0))
        playback.node.occlusion = Float(-(backAmount * 12.0))
    }

    private func mappedSpatialPoint(for point: SpatialPoint) -> AVAudio3DPoint {
        let clamped = point.clamped()
        return AVAudio3DPoint(
            x: Float(clamped.x * 4.5),
            y: 0,
            z: Float(clamped.y * 5.5)
        )
    }

    private func updateEnvironmentOutputType() {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        if outputs.contains(where: { output in
            output.portType == .headphones
                || output.portType == .headsetMic
                || output.portType == .bluetoothA2DP
                || output.portType == .bluetoothLE
                || output.portType == .bluetoothHFP
        }) {
            environmentNode.outputType = .headphones
        } else if outputs.contains(where: { $0.portType == .builtInSpeaker }) {
            environmentNode.outputType = .builtInSpeakers
        } else {
            environmentNode.outputType = .auto
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
