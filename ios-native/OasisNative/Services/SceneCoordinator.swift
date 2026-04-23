import Foundation
import SwiftUI

/// Projects the audible state of the mixer onto a `CurrentScene` — a lightweight snapshot of
/// "where the user is" used by the SceneCard and the EntryRitual.
///
/// Derivation rules, in order:
/// 1. If an `activePreset` is loaded and has a curated narrative, use it.
/// 2. Otherwise, fall back to the dominant unmuted channel's documented location.
/// 3. When no channel is audible, the scene is nil.
///
/// Scene updates are coalesced on a ~1-second debounce so rapid slider moves don't make the
/// card flicker. The coordinator is a pure projection — `AppModel` remains the single source
/// of truth for audio/UI state. Results are pushed to the owner via `onSceneChange`.
@MainActor
final class SceneCoordinator {
    /// Called whenever the derived scene changes. Owner (AppModel) stores the value in its
    /// own `@Observable` property so SwiftUI views can observe it normally.
    var onSceneChange: (@MainActor (CurrentScene?) -> Void)?

    private var debounceTask: Task<Void, Never>?
    private var lastEmittedID: String?

    /// Call whenever `channels` or `activePreset` changes. Debounced so rapid updates don't
    /// thrash the UI. Safe to call on every state mutation — the debounce absorbs it.
    func requestUpdate(
        channels: [SoundChannel: ChannelState],
        activePreset: Preset?,
        date: Date = Date()
    ) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(Self.debounceMilliseconds))
            guard !Task.isCancelled, let self else { return }
            self.emit(Self.derive(channels: channels, activePreset: activePreset, date: date))
        }
    }

    /// Forces an immediate derivation without debounce. Used on explicit user-driven events
    /// such as loading a preset, where waiting a second would feel laggy.
    func forceUpdate(
        channels: [SoundChannel: ChannelState],
        activePreset: Preset?,
        date: Date = Date()
    ) {
        debounceTask?.cancel()
        debounceTask = nil
        emit(Self.derive(channels: channels, activePreset: activePreset, date: date))
    }

    private func emit(_ scene: CurrentScene?) {
        // Skip redundant emission so the SceneCard's "appear" animation only fires when the
        // place actually changes.
        if scene?.id == lastEmittedID {
            return
        }
        lastEmittedID = scene?.id
        onSceneChange?(scene)
    }

    static func derive(
        channels: [SoundChannel: ChannelState],
        activePreset: Preset?,
        date: Date
    ) -> CurrentScene? {
        let dominant = dominantChannel(channels: channels)
        let particleStyle = dominant?.particleStyle ?? .none

        if let activePreset, let narrative = SceneNarrative.presetNarrative(for: activePreset.id) {
            return CurrentScene(
                id: "preset:\(activePreset.id)",
                placeLine: narrative.placeLine,
                detailLine: narrative.detailLine,
                capturedAt: date,
                timeOfDay: TimeOfDay.current(at: date),
                tint: narrative.tint ?? dominant?.tint ?? .white,
                particleStyle: particleStyle
            )
        }

        guard let dominant else {
            return nil
        }

        let location = dominant.location
        return CurrentScene(
            id: "channel:\(dominant.rawValue)",
            placeLine: location.rowLabel,
            detailLine: nil,
            capturedAt: date,
            timeOfDay: TimeOfDay.current(at: date),
            tint: dominant.tint,
            particleStyle: particleStyle
        )
    }

    private static func dominantChannel(channels: [SoundChannel: ChannelState]) -> SoundChannel? {
        // Iterate `allCases` so ties break deterministically on declaration order — prevents
        // the scene from flickering between two channels with identical volumes.
        var bestChannel: SoundChannel?
        var bestVolume: Double = 0

        for channel in SoundChannel.allCases {
            guard let state = channels[channel], !state.isMuted else { continue }
            if state.volume > bestVolume {
                bestVolume = state.volume
                bestChannel = channel
            }
        }

        return bestChannel
    }

    private static let debounceMilliseconds = 1000
}
