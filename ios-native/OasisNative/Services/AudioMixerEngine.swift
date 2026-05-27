import AVFoundation
import Foundation

#if os(iOS)
import MediaPlayer
#endif

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

private final class ProceduralNoisePlayback: @unchecked Sendable {
    let noise: ProceduralNoise
    let node: AVAudioSourceNode

    init(noise: ProceduralNoise, sampleRate: Double) {
        self.noise = noise
        let generator = ProceduralNoiseGenerator(noise: noise, sampleRate: sampleRate)

        self.node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frameTotal = Int(frameCount)

            for frame in 0..<frameTotal {
                let sample = generator.nextSample()
                for buffer in buffers {
                    guard let data = buffer.mData else { continue }
                    data.assumingMemoryBound(to: Float.self)[frame] = sample
                }
            }

            return noErr
        }
    }
}

private final class ProceduralNoiseGenerator: @unchecked Sendable {
    let noise: ProceduralNoise
    let sampleRate: Float

    private var seed: UInt64
    private var brown: Float = 0
    private var greenLow: Float = 0
    private var greenHigh: Float = 0
    private var pinkB0: Float = 0
    private var pinkB1: Float = 0
    private var pinkB2: Float = 0
    private var pinkB3: Float = 0
    private var pinkB4: Float = 0
    private var pinkB5: Float = 0
    private var pinkB6: Float = 0
    private var phaseA: Float = 0
    private var phaseB: Float = 0
    private var phaseC: Float = 0

    init(noise: ProceduralNoise, sampleRate: Double) {
        self.noise = noise
        self.sampleRate = Float(sampleRate)
        self.seed = UInt64(abs(noise.rawValue.hashValue)) &+ 0x9E37_79B9_7F4A_7C15
    }

    func nextSample() -> Float {
        switch noise {
        case .white:
            return white() * 0.24
        case .brown:
            brown = (brown * 0.985) + (white() * 0.040)
            return clamp(brown * 2.6)
        case .pink:
            return pink() * 0.34
        case .green:
            let sample = white()
            greenLow = (greenLow * 0.992) + (sample * 0.008)
            greenHigh = (greenHigh * 0.84) + ((sample - greenLow) * 0.16)
            return clamp((greenHigh + pink() * 0.28) * 0.50)
        case .fan:
            let rumble = brownSample() * 0.46
            let blade = oscillator(frequency: 118, phase: &phaseA) * 0.050
            let motor = oscillator(frequency: 236, phase: &phaseB) * 0.028
            let slow = 0.92 + (oscillator(frequency: 0.42, phase: &phaseC) * 0.08)
            return clamp((rumble + blade + motor) * slow)
        case .aircraft:
            let rumble = brownSample() * 0.58
            let cabin = pink() * 0.24
            let engine = oscillator(frequency: 88, phase: &phaseA) * 0.036
            let pressure = oscillator(frequency: 0.18, phase: &phaseB) * 0.055
            return clamp(rumble + cabin + engine + pressure)
        }
    }

    private func brownSample() -> Float {
        brown = (brown * 0.992) + (white() * 0.032)
        return clamp(brown * 2.4)
    }

    private func pink() -> Float {
        let white = white()
        pinkB0 = 0.99886 * pinkB0 + white * 0.0555179
        pinkB1 = 0.99332 * pinkB1 + white * 0.0750759
        pinkB2 = 0.96900 * pinkB2 + white * 0.1538520
        pinkB3 = 0.86650 * pinkB3 + white * 0.3104856
        pinkB4 = 0.55000 * pinkB4 + white * 0.5329522
        pinkB5 = -0.7616 * pinkB5 - white * 0.0168980
        let output = pinkB0 + pinkB1 + pinkB2 + pinkB3 + pinkB4 + pinkB5 + pinkB6 + white * 0.5362
        pinkB6 = white * 0.115926
        return clamp(output * 0.11)
    }

    private func oscillator(frequency: Float, phase: inout Float) -> Float {
        let value = sin(phase)
        phase += (2 * .pi * frequency) / sampleRate
        if phase > 2 * .pi {
            phase -= 2 * .pi
        }
        return value
    }

    private func white() -> Float {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        let bits = UInt32((seed >> 32) & 0xFFFF_FFFF)
        return (Float(bits) / Float(UInt32.max) * 2) - 1
    }

    private func clamp(_ value: Float) -> Float {
        min(max(value, -0.94), 0.94)
    }
}

private enum AmbientImmersiveProfile {
    case closeCozy
    case naturalOutdoor
    case farWeather
    case wideAtmosphere
    case smallPointSource

    var configuration: AmbientImmersiveProfileConfiguration {
        switch self {
        case .closeCozy:
            return AmbientImmersiveProfileConfiguration(
                baseDistance: 2.4,
                depthSpread: 2.1,
                lateralSpread: 3.4,
                elevation: 0.15,
                reverbBlend: 0.035,
                backReverbBoost: 0.025,
                obstruction: -0.8,
                occlusion: -1.2,
                backOcclusionBoost: 1.6,
                sourceMode: .pointSource,
                renderingAlgorithm: .HRTFHQ
            )
        case .naturalOutdoor:
            return AmbientImmersiveProfileConfiguration(
                baseDistance: 5.2,
                depthSpread: 4.4,
                lateralSpread: 5.7,
                elevation: 0.35,
                reverbBlend: 0.075,
                backReverbBoost: 0.045,
                obstruction: -1.8,
                occlusion: -2.8,
                backOcclusionBoost: 2.4,
                sourceMode: .pointSource,
                renderingAlgorithm: .HRTFHQ
            )
        case .farWeather:
            return AmbientImmersiveProfileConfiguration(
                baseDistance: 8.8,
                depthSpread: 7.6,
                lateralSpread: 7.4,
                elevation: 0.65,
                reverbBlend: 0.155,
                backReverbBoost: 0.075,
                obstruction: -4.2,
                occlusion: -6.2,
                backOcclusionBoost: 3.2,
                sourceMode: .pointSource,
                renderingAlgorithm: .HRTFHQ
            )
        case .wideAtmosphere:
            return AmbientImmersiveProfileConfiguration(
                baseDistance: 6.6,
                depthSpread: 5.2,
                lateralSpread: 8.0,
                elevation: 0.45,
                reverbBlend: 0.13,
                backReverbBoost: 0.06,
                obstruction: -2.8,
                occlusion: -4.0,
                backOcclusionBoost: 2.6,
                sourceMode: .ambienceBed,
                renderingAlgorithm: .auto
            )
        case .smallPointSource:
            return AmbientImmersiveProfileConfiguration(
                baseDistance: 6.8,
                depthSpread: 5.0,
                lateralSpread: 6.4,
                elevation: 1.85,
                reverbBlend: 0.055,
                backReverbBoost: 0.035,
                obstruction: -1.2,
                occlusion: -2.0,
                backOcclusionBoost: 2.0,
                sourceMode: .pointSource,
                renderingAlgorithm: .HRTFHQ
            )
        }
    }
}

private struct AmbientImmersiveProfileConfiguration {
    let baseDistance: Float
    let depthSpread: Float
    let lateralSpread: Float
    let elevation: Float
    let reverbBlend: Float
    let backReverbBoost: Float
    let obstruction: Float
    let occlusion: Float
    let backOcclusionBoost: Float
    let sourceMode: AVAudio3DMixingSourceMode
    let renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm
}

private extension SoundChannel {
    var immersiveProfile: AmbientImmersiveProfile {
        switch self {
        case .campfire, .tente, .pluieFenetre, .pluieCabane, .cafe:
            return .closeCozy
        case .plage, .riviere, .village, .lac, .savane, .crueMontagne, .cascade:
            return .naturalOutdoor
        case .vent, .tonnerre, .orageMontagne, .fortePluie, .ventNuit:
            return .farWeather
        case .foret, .pluie, .mer, .jungleAmerique, .jungleAsie, .pluieForet, .foretNuit, .neigeVille, .foretChiloe, .aubeJungle, .port:
            return .wideAtmosphere
        case .oiseaux, .goelands, .cigales, .grillons, .chevres, .carillons, .cloches:
            return .smallPointSource
        }
    }
}

final class AudioMixerEngine: @unchecked Sendable {
    var onVariationChanged: (@MainActor @Sendable (SoundChannel, Double?) -> Void)?
    var onRemotePlaybackChange: (@MainActor @Sendable (Bool) -> Void)?

    private let queue = DispatchQueue(label: "com.jonathanluquet.oasis.audio-engine", qos: .userInitiated)
    private let ambientEngine = AVAudioEngine()
    private let environmentNode = AVAudioEnvironmentNode()
    private let proceduralFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)

    private var ambientPlayers: [SoundChannel: AmbientChannelPlayback] = [:]
    private var proceduralPlayers: [ProceduralNoise: ProceduralNoisePlayback] = [:]
    private var binauralPlayers: [BinauralTrack: AVAudioPlayer] = [:]
    private var variationTasks: [SoundChannel: Task<Void, Never>] = [:]
    private var fadeTask: Task<Void, Never>?
    private var immersiveTransitionTask: Task<Void, Never>?
    private var masterFade: Double = 0
    private var immersiveBlend: Double = 0
    private var nextPauseFadeDuration: TimeInterval?
    private var previousPlayingState = false
    private var previousImmersiveAudioEnabled = false

    private var previousNowPlayingRate: Double?
    private var latestSnapshot = MixerSnapshot(
        isPlaying: false,
        isPremium: false,
        channels: .initialChannels,
        proceduralNoises: .initialNoises,
        isBinauralActive: false,
        activeBinauralTrack: .delta,
        binauralVolume: 0.5,
        previewUnlockedChannels: [],
        previewUnlockedTracks: [],
        immersiveAudioEnabled: false
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

        #if os(iOS)
        routeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.queue.async { [weak self] in
                self?.updateEnvironmentOutputType()
            }
        }
        #endif
    }

    deinit {
        fadeTask?.cancel()
        immersiveTransitionTask?.cancel()
        variationTasks.values.forEach { $0.cancel() }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
    }

    func sync(with snapshot: MixerSnapshot) {
        queue.async { [weak self] in
            guard let self else { return }

            self.latestSnapshot = snapshot
            self.transitionImmersiveAudioIfNeeded(to: snapshot.immersiveAudioEnabled)
            self.synchronizeVariationTasks(for: snapshot)

            if snapshot.isPlaying != self.previousPlayingState {
                self.previousPlayingState = snapshot.isPlaying
                self.transitionPlayback(to: snapshot.isPlaying)
            }

            self.refreshPlayerStates()
            if !snapshot.isPlaying {
                self.prewarmPausedSnapshot(snapshot)
            }
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

    /// Request a custom fade-out duration for the NEXT pause transition only.
    /// Resets to default (0.9s) after being consumed. Used for the gentle
    /// sleep-timer wind-down so audio doesn't cut abruptly at t=0.
    func setNextPauseFadeDuration(_ duration: TimeInterval) {
        queue.async { [weak self] in
            guard let self else { return }
            self.nextPauseFadeDuration = duration
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

    private func proceduralPlayer(for noise: ProceduralNoise) -> ProceduralNoisePlayback? {
        if let player = proceduralPlayers[noise] {
            return player
        }

        guard let proceduralFormat else { return nil }
        configureAmbientEngineIfNeeded()

        let playback = ProceduralNoisePlayback(noise: noise, sampleRate: proceduralFormat.sampleRate)
        ambientEngine.attach(playback.node)
        playback.node.volume = 0
        ambientEngine.connect(playback.node, to: environmentNode, format: proceduralFormat)
        proceduralPlayers[noise] = playback
        return playback
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
        #if os(iOS)
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
        #endif
    }

    private func configureAmbientEngineIfNeeded() {
        guard !isAmbientEngineConfigured else { return }
        isAmbientEngineConfigured = true

        ambientEngine.attach(environmentNode)
        ambientEngine.connect(environmentNode, to: ambientEngine.mainMixerNode, format: nil)
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        applyEnvironmentConfiguration()
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
        #if os(iOS)
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
        #else
        remoteCommandsConfigured = true
        #endif
    }

    private func transitionPlayback(to isPlaying: Bool) {
        fadeTask?.cancel()

        if isPlaying {
            isStopping = false
            startActivePlayersIfNeeded()
            fadeTask = animateFade(from: masterFade, to: 1, duration: 1.6)
        } else {
            isStopping = true
            let pauseDuration = nextPauseFadeDuration ?? 0.9
            nextPauseFadeDuration = nil
            fadeTask = animateFade(from: masterFade, to: 0, duration: pauseDuration, completion: { [weak self] in
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

        for noise in ProceduralNoise.allCases where shouldPlayProceduralNoise(noise) {
            _ = proceduralPlayer(for: noise)
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
            // The next segment is chained directly here without any fade in/out,
            // so the loop seam stays as inaudible as possible.
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
        proceduralPlayers.values.forEach { $0.node.volume = 0 }
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

        for noise in ProceduralNoise.allCases {
            guard let playback = proceduralPlayers[noise] ?? (shouldPlayProceduralNoise(noise) ? proceduralPlayer(for: noise) : nil) else {
                continue
            }

            playback.node.volume = Float(targetProceduralVolume(for: noise))
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

    private func prewarmPausedSnapshot(_ snapshot: MixerSnapshot) {
        configureAudioSession()
        let ambientChannelsToPrime = SoundChannel.allCases.filter { channel in
            guard let state = snapshot.channels[channel], !state.isMuted else { return false }
            return snapshot.hasAmbientAccess(to: channel)
        }

        if !ambientChannelsToPrime.isEmpty {
            configureAmbientEngineIfNeeded()
            startAmbientEngineIfNeeded()
        }

        let proceduralNoisesToPrime = ProceduralNoise.allCases.filter { noise in
            guard let state = snapshot.proceduralNoises[noise], !state.isMuted else { return false }
            return snapshot.hasProceduralNoiseAccess(to: noise)
        }

        if !proceduralNoisesToPrime.isEmpty {
            configureAmbientEngineIfNeeded()
            startAmbientEngineIfNeeded()
        }

        for channel in ambientChannelsToPrime {
            guard let playback = ambientPlayer(for: channel) else { continue }

            applySpatialMixingConfiguration(for: channel, playback: playback)
            scheduleAmbientPlaybackIfNeeded(playback)
        }

        for noise in proceduralNoisesToPrime {
            _ = proceduralPlayer(for: noise)
        }

        if snapshot.hasBinauralAccess(to: snapshot.activeBinauralTrack) {
            _ = binauralPlayer(for: snapshot.activeBinauralTrack)
        }
    }

    private func refreshPlayerVolumes() {
        for channel in SoundChannel.allCases {
            if let player = ambientPlayers[channel] {
                player.node.volume = Float(targetAmbientVolume(for: channel))
            }
        }

        for noise in ProceduralNoise.allCases {
            if let player = proceduralPlayers[noise] {
                player.node.volume = Float(targetProceduralVolume(for: noise))
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
        guard latestSnapshot.hasAmbientAccess(to: channel) else { return 0 }

        let sourceVolume = state.autoVariationEnabled
            ? (liveVariationVolumes[channel] ?? state.volume)
            : state.volume

        return min(max(sourceVolume, 0), 1) * masterFade
    }

    private func targetProceduralVolume(for noise: ProceduralNoise) -> Double {
        guard let state = latestSnapshot.proceduralNoises[noise], state.isMuted == false else { return 0 }
        guard latestSnapshot.hasProceduralNoiseAccess(to: noise) else { return 0 }
        return min(max(state.volume, 0), 1) * masterFade
    }

    private func targetBinauralVolume(for track: BinauralTrack) -> Double {
        guard latestSnapshot.isBinauralActive else { return 0 }
        guard latestSnapshot.activeBinauralTrack == track else { return 0 }
        guard latestSnapshot.hasBinauralAccess(to: track) else { return 0 }
        return latestSnapshot.binauralVolume * masterFade
    }

    private func shouldPlayAmbient(_ channel: SoundChannel) -> Bool {
        guard latestSnapshot.isPlaying else { return false }
        guard let state = latestSnapshot.channels[channel] else { return false }
        return !state.isMuted && latestSnapshot.hasAmbientAccess(to: channel)
    }

    private func shouldPlayProceduralNoise(_ noise: ProceduralNoise) -> Bool {
        guard latestSnapshot.isPlaying else { return false }
        guard let state = latestSnapshot.proceduralNoises[noise] else { return false }
        return !state.isMuted && latestSnapshot.hasProceduralNoiseAccess(to: noise)
    }

    private func shouldPlayBinaural(_ track: BinauralTrack) -> Bool {
        latestSnapshot.isPlaying
            && latestSnapshot.isBinauralActive
            && latestSnapshot.activeBinauralTrack == track
            && latestSnapshot.hasBinauralAccess(to: track)
    }

    private func synchronizeVariationTasks(for snapshot: MixerSnapshot) {
        for channel in SoundChannel.allCases {
            guard let state = snapshot.channels[channel] else { continue }
            let shouldVary = snapshot.isPlaying
                && !state.isMuted
                && state.autoVariationEnabled
                && snapshot.hasAmbientAccess(to: channel)

            if shouldVary {
                let clampedLiveValue = state.autoVariationRange.clampedValue(liveVariationVolumes[channel] ?? state.volume)
                if liveVariationVolumes[channel] != clampedLiveValue {
                    liveVariationVolumes[channel] = clampedLiveValue
                    dispatchVariationChange(for: channel, value: clampedLiveValue)
                }

                if variationTasks[channel] == nil {
                    variationTasks[channel] = startVariationTask(for: channel, initialValue: clampedLiveValue)
                }
            } else {
                variationTasks[channel]?.cancel()
                variationTasks[channel] = nil
                liveVariationVolumes[channel] = nil
                dispatchVariationChange(for: channel, value: nil)
            }
        }
    }

    private func transitionImmersiveAudioIfNeeded(to enabled: Bool) {
        guard enabled != previousImmersiveAudioEnabled else {
            applyEnvironmentConfiguration()
            return
        }

        previousImmersiveAudioEnabled = enabled
        immersiveTransitionTask?.cancel()

        let start = immersiveBlend
        let target = enabled ? 1.0 : 0.0
        let stepDurationMilliseconds = 80
        let steps = 10

        immersiveTransitionTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }

            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(stepDurationMilliseconds))
                guard !Task.isCancelled else { return }

                let progress = Double(step) / Double(steps)
                let easedProgress = progress * progress * (3 - 2 * progress)
                let value = start + (target - start) * easedProgress

                self.queue.async { [weak self] in
                    guard let self else { return }
                    self.immersiveBlend = value
                    self.applyEnvironmentConfiguration()
                    self.refreshSpatialMixingConfigurations()
                }
            }
        }
    }

    private func startVariationTask(for channel: SoundChannel, initialValue: Double) -> Task<Void, Never> {
        Task(priority: .utility) { [weak self] in
            guard let self else { return }
            var currentValue = self.autoVariationRange(for: channel).clampedValue(initialValue)
            let startingValue = currentValue

            self.queue.async { [weak self] in
                guard let self else { return }
                self.liveVariationVolumes[channel] = startingValue
                self.refreshPlayerVolumes()
            }
            self.dispatchVariationChange(for: channel, value: startingValue)

            while !Task.isCancelled {
                let range = self.autoVariationRange(for: channel)
                currentValue = range.clampedValue(currentValue)
                let target = Double.random(in: range.lowerBound...range.upperBound)
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

    private func autoVariationRange(for channel: SoundChannel) -> AutoVariationRange {
        queue.sync {
            guard let state = latestSnapshot.channels[channel] else {
                return .defaultRange(around: 0.5)
            }
            return state.autoVariationRange.clamped()
        }
    }

    private func dispatchVariationChange(for channel: SoundChannel, value: Double?) {
        guard let callback = onVariationChanged else { return }
        Task { @MainActor in
            callback(channel, value)
        }
    }

    private func refreshSpatialMixingConfigurations() {
        for playback in ambientPlayers.values {
            applySpatialMixingConfiguration(for: playback.channel, playback: playback)
        }
    }

    private func applyEnvironmentConfiguration() {
        let blend = Float(min(max(immersiveBlend, 0), 1))
        environmentNode.distanceAttenuationParameters.distanceAttenuationModel = .linear
        environmentNode.distanceAttenuationParameters.referenceDistance = 10
        environmentNode.distanceAttenuationParameters.maximumDistance = 18
        environmentNode.distanceAttenuationParameters.rolloffFactor = 0
        environmentNode.reverbParameters.enable = true
        environmentNode.reverbParameters.level = -18 + (5 * blend)
        environmentNode.outputVolume = 1
    }

    private func applySpatialMixingConfiguration(for channel: SoundChannel, playback: AmbientChannelPlayback) {
        let point = latestSnapshot.channels[channel]?.spatialPosition ?? .center
        let clamped = point.clamped()
        let blend = min(max(immersiveBlend, 0), 1)
        let backAmount = Float(max(clamped.y, 0))

        let classicPoint = mappedClassicSpatialPoint(for: clamped)
        let classicReverbBlend = Float(0.01 + (Double(backAmount) * 0.08))
        let classicObstruction = -(backAmount * 6.0)
        let classicOcclusion = -(backAmount * 12.0)

        if blend > 0.5 {
            applyImmersiveRenderingMode(for: channel, playback: playback)
        } else {
            applyClassicRenderingMode(for: playback)
        }

        let profile = channel.immersiveProfile.configuration
        let immersivePoint = mappedImmersiveSpatialPoint(for: clamped, profile: profile)
        let immersiveReverbBlend = min(profile.reverbBlend + (backAmount * profile.backReverbBoost), 0.28)
        let immersiveObstruction = profile.obstruction - (backAmount * 1.2)
        let immersiveOcclusion = profile.occlusion - (backAmount * profile.backOcclusionBoost)

        playback.node.position = interpolate(from: classicPoint, to: immersivePoint, progress: Float(blend))
        playback.node.reverbBlend = interpolate(from: classicReverbBlend, to: immersiveReverbBlend, progress: Float(blend))
        playback.node.obstruction = interpolate(from: classicObstruction, to: immersiveObstruction, progress: Float(blend))
        playback.node.occlusion = interpolate(from: classicOcclusion, to: immersiveOcclusion, progress: Float(blend))
    }

    private func applyClassicRenderingMode(for playback: AmbientChannelPlayback) {
        if playback.format.channelCount > 1 {
            playback.node.sourceMode = .ambienceBed
            playback.node.renderingAlgorithm = .auto
        } else {
            playback.node.sourceMode = .pointSource
            playback.node.pointSourceInHeadMode = .bypass
            playback.node.renderingAlgorithm = .HRTFHQ
        }
    }

    private func applyImmersiveRenderingMode(for channel: SoundChannel, playback: AmbientChannelPlayback) {
        let profile = channel.immersiveProfile.configuration
        playback.node.sourceMode = profile.sourceMode
        playback.node.pointSourceInHeadMode = .bypass
        playback.node.renderingAlgorithm = profile.renderingAlgorithm
    }

    private func mappedClassicSpatialPoint(for point: SpatialPoint) -> AVAudio3DPoint {
        let clamped = point.clamped()
        return AVAudio3DPoint(
            x: Float(clamped.x * 4.5),
            y: 0,
            z: Float(clamped.y * 5.5)
        )
    }

    private func mappedImmersiveSpatialPoint(
        for point: SpatialPoint,
        profile: AmbientImmersiveProfileConfiguration
    ) -> AVAudio3DPoint {
        let clamped = point.clamped()
        let horizontal = Float(clamped.x) * profile.lateralSpread
        let vertical = profile.elevation
        let y = Float(clamped.y)
        let depth = profile.baseDistance + (abs(y) * profile.depthSpread)
        let isBehind = y > 0.12
        let z = isBehind ? depth : -depth

        return AVAudio3DPoint(x: horizontal, y: vertical, z: z)
    }

    private func interpolate(from start: Float, to end: Float, progress: Float) -> Float {
        start + ((end - start) * progress)
    }

    private func interpolate(
        from start: AVAudio3DPoint,
        to end: AVAudio3DPoint,
        progress: Float
    ) -> AVAudio3DPoint {
        AVAudio3DPoint(
            x: interpolate(from: start.x, to: end.x, progress: progress),
            y: interpolate(from: start.y, to: end.y, progress: progress),
            z: interpolate(from: start.z, to: end.z, progress: progress)
        )
    }

    private func updateEnvironmentOutputType() {
        #if os(iOS)
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
        #else
        environmentNode.outputType = .auto
        #endif
    }

    private func updateNowPlayingInfo() {
        #if os(iOS)
        let playbackRate = latestSnapshot.isPlaying ? 1.0 : 0.0
        guard previousNowPlayingRate != playbackRate else { return }
        previousNowPlayingRate = playbackRate

        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: L10n.string(L10n.App.title),
                MPMediaItemPropertyArtist: L10n.string(L10n.App.nowPlayingArtist),
                MPNowPlayingInfoPropertyPlaybackRate: playbackRate
            ]
        }
        #endif
    }
}
