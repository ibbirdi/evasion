import Foundation
import SwiftUI

/// Single source of truth for all user-facing narrative copy used by the Immersion Layer
/// (SceneCard, EntryRitual, and future surfaces). Every string in this file is a crafted
/// fragment of place — a one-line field note, present tense, no self-help language, no
/// marketing adjectives.
///
/// NOTE ON DRAFTS: strings tagged `// DRAFT` are first-pass proposals written by the model
/// and awaiting explicit sign-off from the product owner before ship. Do not localize or
/// ship a DRAFT line — review and rewrite in place, remove the tag, then commit.
enum SceneNarrative {
    struct PresetNarrative {
        let placeLine: String
        let detailLine: String?
        let tint: Color?
    }

    static func presetNarrative(for presetID: String) -> PresetNarrative? {
        switch presetID {
        case "preset_default_starter":
            // DRAFT — review before ship.
            return PresetNarrative(
                placeLine: String(localized: starterPlace),
                detailLine: String(localized: starterDetail),
                tint: nil
            )

        case "preset_default_calm":
            // DRAFT — review before ship.
            return PresetNarrative(
                placeLine: String(localized: calmPlace),
                detailLine: String(localized: calmDetail),
                tint: nil
            )

        case "preset_default_storm":
            // DRAFT — review before ship.
            return PresetNarrative(
                placeLine: String(localized: stormPlace),
                detailLine: String(localized: stormDetail),
                tint: nil
            )

        case "preset_signature_oasis":
            // DRAFT — review before ship.
            return PresetNarrative(
                placeLine: String(localized: signaturePlace),
                detailLine: String(localized: signatureDetail),
                tint: nil
            )

        default:
            return nil
        }
    }

    // MARK: Preset narratives — DRAFT copy

    private static let starterPlace = LocalizedStringResource(
        "scene.preset.starter.place",
        defaultValue: "Near the shore",
        bundle: .main,
        comment: "DRAFT — place line for the Sea Breeze preset. One short fragment, present tense."
    )

    private static let starterDetail = LocalizedStringResource(
        "scene.preset.starter.detail",
        defaultValue: "Wind pressing into the dunes.",
        bundle: .main,
        comment: "DRAFT — one concrete sensory detail for Sea Breeze. No adjectives of mood."
    )

    private static let calmPlace = LocalizedStringResource(
        "scene.preset.calm.place",
        defaultValue: "Deep in the forest",
        bundle: .main,
        comment: "DRAFT — place line for Quiet Forest."
    )

    private static let calmDetail = LocalizedStringResource(
        "scene.preset.calm.detail",
        defaultValue: "A bird calling, then another answering.",
        bundle: .main,
        comment: "DRAFT — sensory detail for Quiet Forest."
    )

    private static let stormPlace = LocalizedStringResource(
        "scene.preset.storm.place",
        defaultValue: "A storm, further off",
        bundle: .main,
        comment: "DRAFT — place line for Distant Storm."
    )

    private static let stormDetail = LocalizedStringResource(
        "scene.preset.storm.detail",
        defaultValue: "You can still hear it, softer now.",
        bundle: .main,
        comment: "DRAFT — sensory detail for Distant Storm."
    )

    private static let signaturePlace = LocalizedStringResource(
        "scene.preset.signature.place",
        defaultValue: "Forest, after rain",
        bundle: .main,
        comment: "DRAFT — place line for the signature preset After the Rain."
    )

    private static let signatureDetail = LocalizedStringResource(
        "scene.preset.signature.detail",
        defaultValue: "Needles dripping. A river somewhere below.",
        bundle: .main,
        comment: "DRAFT — sensory detail for After the Rain."
    )
}
