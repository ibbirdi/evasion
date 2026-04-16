import Foundation

@MainActor
final class PremiumCoordinator {
    static let homeBannerDelay: Duration = .seconds(20)
    static let homeBannerCooldown: TimeInterval = 24 * 60 * 60
    static let signaturePreviewCooldown: TimeInterval = 24 * 60 * 60
    static let signaturePreviewDuration: Duration = .seconds(45)

    private var inlineShownCategories = Set<PremiumEntryPoint.Category>()

    func route(for entryPoint: PremiumEntryPoint) -> PremiumRouteDecision {
        switch entryPoint.category {
        case .preset, .binaural:
            let wasInserted = inlineShownCategories.insert(entryPoint.category).inserted
            if wasInserted {
                return .inline(PremiumInlineUpsellContext(entryPoint: entryPoint))
            }
            return .paywall(PremiumPaywallContext(entryPoint: entryPoint))

        case .manual, .sound, .timer, .spatial, .preview:
            return .paywall(PremiumPaywallContext(entryPoint: entryPoint))
        }
    }

    func canShowHomeBanner(lastDismissedAt: Date?, now: Date = Date()) -> Bool {
        guard let lastDismissedAt else { return true }
        return now.timeIntervalSince(lastDismissedAt) >= Self.homeBannerCooldown
    }

    func canStartSignaturePreview(lastPlayedAt: Date?, now: Date = Date()) -> Bool {
        guard let lastPlayedAt else { return true }
        return now.timeIntervalSince(lastPlayedAt) >= Self.signaturePreviewCooldown
    }

    func resetInlineHistory() {
        inlineShownCategories.removeAll()
    }
}

enum PremiumRouteDecision {
    case inline(PremiumInlineUpsellContext)
    case paywall(PremiumPaywallContext)
}
