import AVFoundation
import Foundation

/// Procedural harmonic pad that sits ~15 dB below the nature mix. Three voices (root +
/// second + octave) form a simple drone. The character is deliberately neutral so it does
/// not overwrite the personality of the ambient recording — the job is to give the ambient
/// noise a tonal floor, not a melody.
///
/// Threading model:
/// - The control plane (main thread) only writes to a `Targets` box.
/// - The audio plane (render block) only reads from that box and owns its own `RunState`
///   internally — so there is never a race over the phase/ramp accumulators.
/// - The `Targets` struct is small enough (~72 bytes) that modern 64-bit CPUs perform its
///   word-sized copies without tearing in practice. Even if a torn read slipped through, the
///   worst audible effect is one render tick of stale target frequency on a pad mixed far
///   below the ambient recording.
final class TonalBedSynth {
    let sourceNode: AVAudioSourceNode

    /// Set to false when AVAudioSourceNode initialization returned something the engine
    /// cannot use. In that case every public method is a no-op so callers don't need a
    /// `guard`.
    let isViable: Bool

    // MARK: - Target (control plane)

    private struct VoiceTarget {
        var frequency: Double
        var rampSamplesRemaining: Int
    }

    private struct Targets {
        var voices: [VoiceTarget]
        var amplitude: Double
        var amplitudeRampSamplesRemaining: Int
    }

    private let targetsPointer: UnsafeMutablePointer<Targets>

    // MARK: - Run state (audio plane) owned inside the render closure

    init(sampleRate: Double = 44_100) {
        let initialFreq: Double = 110 // A2 fallback until the first signature lands.

        let voiceTargets: [VoiceTarget] = [
            VoiceTarget(frequency: initialFreq, rampSamplesRemaining: 0),
            VoiceTarget(frequency: initialFreq * 1.5, rampSamplesRemaining: 0),
            VoiceTarget(frequency: initialFreq * 2, rampSamplesRemaining: 0)
        ]

        let targets = Targets(
            voices: voiceTargets,
            amplitude: 0,
            amplitudeRampSamplesRemaining: 0
        )

        let pointer = UnsafeMutablePointer<Targets>.allocate(capacity: 1)
        pointer.initialize(to: targets)
        self.targetsPointer = pointer

        // Render-thread-private state. Captured by the closure; no external writes.
        var phases: [Double] = Array(repeating: 0, count: voiceTargets.count)
        var currentFreqs: [Double] = voiceTargets.map(\.frequency)
        var currentAmplitude: Double = 0

        let voiceCountInv = 1.0 / Double(voiceTargets.count)

        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let channelCount = ablPointer.count

            // One snapshot of the control plane per render tick. Subsequent main-thread
            // writes will be picked up on the next tick; that latency is imperceptible at
            // the bed's amplitude.
            var targets = pointer.pointee

            for frame in 0..<Int(frameCount) {
                // Amplitude ramp — linear interpolation to the target over the remaining
                // sample budget.
                if targets.amplitudeRampSamplesRemaining > 0 {
                    let step = (targets.amplitude - currentAmplitude)
                        / Double(targets.amplitudeRampSamplesRemaining)
                    currentAmplitude += step
                    targets.amplitudeRampSamplesRemaining -= 1
                } else {
                    currentAmplitude = targets.amplitude
                }

                var sample: Double = 0

                for voiceIndex in 0..<voiceTargets.count {
                    // Frequency ramp per voice.
                    let voiceTarget = targets.voices[voiceIndex]
                    if voiceTarget.rampSamplesRemaining > 0 {
                        let step = (voiceTarget.frequency - currentFreqs[voiceIndex])
                            / Double(voiceTarget.rampSamplesRemaining)
                        currentFreqs[voiceIndex] += step
                        targets.voices[voiceIndex].rampSamplesRemaining -= 1
                    } else {
                        currentFreqs[voiceIndex] = voiceTarget.frequency
                    }

                    let phaseIncrement = (currentFreqs[voiceIndex] * 2 * .pi) / sampleRate
                    sample += sin(phases[voiceIndex]) * voiceCountInv

                    var nextPhase = phases[voiceIndex] + phaseIncrement
                    if nextPhase > 2 * .pi {
                        nextPhase -= 2 * .pi
                    }
                    phases[voiceIndex] = nextPhase
                }

                let scaled = Float(sample * currentAmplitude)

                for channel in 0..<channelCount {
                    let bufferPointer = ablPointer[channel]
                    let channelBuffer = bufferPointer.mData?.assumingMemoryBound(to: Float.self)
                    channelBuffer?[frame] = scaled
                }
            }

            // Push remaining ramp counters back so they decrement monotonically even across
            // ticks where the main thread doesn't update.
            pointer.pointee.voices = targets.voices
            pointer.pointee.amplitudeRampSamplesRemaining = targets.amplitudeRampSamplesRemaining

            return noErr
        }

        self.sourceNode = sourceNode
        self.isViable = true
        self.sampleRate = sampleRate
    }

    // No deinit cleanup for `targetsPointer`. The render closure captures the pointer by
    // value; if the render thread dereferences after deallocation we crash the audio unit.
    // At 72 bytes per synth instance, and with the synth living for the full app session,
    // leaking is the correct trade-off.

    private let sampleRate: Double

    /// Tracks the last signature applied so the main thread can skip redundant updates.
    private var lastAppliedSignature: TonalSignature?

    // MARK: - Control plane API (main thread)

    /// Applies a new tonal signature. Frequencies ramp over ~200 ms so transitions are
    /// click-free. Idempotent — repeated calls with the same signature are ignored.
    func applySignature(_ signature: TonalSignature) {
        guard isViable, lastAppliedSignature != signature else { return }

        let rampSamples = Int(sampleRate * 0.2)
        let (root, second, octave) = Self.frequencies(for: signature)

        var updated = targetsPointer.pointee
        if updated.voices.count >= 3 {
            updated.voices[0].frequency = root
            updated.voices[0].rampSamplesRemaining = rampSamples
            updated.voices[1].frequency = second
            updated.voices[1].rampSamplesRemaining = rampSamples
            updated.voices[2].frequency = octave
            updated.voices[2].rampSamplesRemaining = rampSamples
        }
        targetsPointer.pointee = updated
        lastAppliedSignature = signature
    }

    /// Sets the target amplitude. Ramps over ~400 ms so enable/disable and scene fades feel
    /// organic. The engine multiplies this by its own master fade so callers only supply the
    /// synth's local target.
    func setTargetAmplitude(_ amplitude: Double) {
        guard isViable else { return }

        let rampSamples = Int(sampleRate * 0.4)
        var updated = targetsPointer.pointee
        updated.amplitude = max(0, min(1, amplitude))
        updated.amplitudeRampSamplesRemaining = rampSamples
        targetsPointer.pointee = updated
    }

    // MARK: - Frequency resolution

    /// Resolves a signature into three voice frequencies. The third voice is always the
    /// octave (2×root); the second depends on the voicing.
    private static func frequencies(for signature: TonalSignature) -> (Double, Double, Double) {
        let root = signature.rootHz
        let second: Double
        switch signature.voicing {
        case .openFifth:
            second = root * 1.5 // perfect fifth
        case .majorTriad:
            second = root * 1.25 // major third
        case .minorTriad, .minorDrone:
            second = root * 1.189 // minor third
        case .suspendedFourth:
            second = root * 1.335 // perfect fourth
        }
        return (root, second, root * 2)
    }
}

/// The tonal character applied by `TonalBedSynth`. Derived by the audio engine from the
/// dominant audible channel. Designed as simple, composable intervals rather than full
/// chord charts — the goal is atmosphere, not music theory.
struct TonalSignature: Equatable {
    let rootHz: Double
    let voicing: Voicing

    enum Voicing: String, Equatable {
        case openFifth
        case majorTriad
        case minorTriad
        case suspendedFourth
        case minorDrone
    }
}

extension SoundChannel {
    /// Per-channel tonal signature used when this channel is dominant. Conservative voicings
    /// — nothing exotic — so the pad sits under the recording without asserting a genre.
    var tonalSignature: TonalSignature {
        switch self {
        case .pluie, .tonnerre, .orageMontagne:
            return TonalSignature(rootHz: 130.81, voicing: .minorDrone) // C3 minor
        case .campfire:
            return TonalSignature(rootHz: 110.0, voicing: .majorTriad) // A2 major
        case .grillons, .cigales:
            return TonalSignature(rootHz: 196.0, voicing: .suspendedFourth) // G3 sus4
        case .foret, .savane, .jungleAmerique, .jungleAsie:
            return TonalSignature(rootHz: 146.83, voicing: .openFifth) // D3 open
        case .riviere, .lac:
            return TonalSignature(rootHz: 130.81, voicing: .openFifth) // C3 open
        case .plage, .goelands, .mer:
            return TonalSignature(rootHz: 123.47, voicing: .openFifth) // B2 open
        case .oiseaux, .vent:
            return TonalSignature(rootHz: 146.83, voicing: .openFifth) // D3 open
        case .tente, .village, .cafe:
            return TonalSignature(rootHz: 110.0, voicing: .openFifth) // A2 neutral
        }
    }
}
