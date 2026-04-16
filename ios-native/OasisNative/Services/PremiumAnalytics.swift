import Foundation
import OSLog

enum PremiumAnalyticsEvent: Sendable {
    case appSession(index: Int)
    case firstPlay
    case listened60s
    case timerSet(minutes: Int?)
    case presetSaved(kind: String)
    case lockedFeatureTapped(source: String)
    case reviewPromptRequested(reason: String)
    case bannerShown
    case bannerDismissed
    case inlineShown(source: String)
    case paywallShown(source: String)
    case paywallDismissed(source: String)
    case paywallLoading(source: String)
    case paywallRetry(source: String)
    case purchaseStarted(source: String)
    case purchaseCancelled(source: String)
    case purchaseSucceeded(source: String)
    case restoreStarted(source: String)
    case restoreSucceeded(source: String)
    case previewStarted
    case previewFinished
    case onboardingCompleted(page: Int)
    case onboardingSkipped(page: Int)

    var logMessage: String {
        switch self {
        case let .appSession(index):
            return "app_session:\(index)"
        case .firstPlay:
            return "first_play"
        case .listened60s:
            return "listened_60s"
        case let .timerSet(minutes):
            return "timer_set:\(minutes.map(String.init) ?? "off")"
        case let .presetSaved(kind):
            return "preset_saved:\(kind)"
        case let .lockedFeatureTapped(source):
            return "locked_feature_tap:\(source)"
        case let .reviewPromptRequested(reason):
            return "review_prompt_requested:\(reason)"
        case .bannerShown:
            return "banner_shown"
        case .bannerDismissed:
            return "banner_dismissed"
        case let .inlineShown(source):
            return "inline_shown:\(source)"
        case let .paywallShown(source):
            return "paywall_shown:\(source)"
        case let .paywallDismissed(source):
            return "paywall_dismissed:\(source)"
        case let .paywallLoading(source):
            return "paywall_loading:\(source)"
        case let .paywallRetry(source):
            return "paywall_retry:\(source)"
        case let .purchaseStarted(source):
            return "purchase_started:\(source)"
        case let .purchaseCancelled(source):
            return "purchase_cancelled:\(source)"
        case let .purchaseSucceeded(source):
            return "purchase_succeeded:\(source)"
        case let .restoreStarted(source):
            return "restore_started:\(source)"
        case let .restoreSucceeded(source):
            return "restore_succeeded:\(source)"
        case .previewStarted:
            return "preview_started"
        case .previewFinished:
            return "preview_finished"
        case let .onboardingCompleted(page):
            return "onboarding_completed:\(page)"
        case let .onboardingSkipped(page):
            return "onboarding_skipped:\(page)"
        }
    }
}

protocol PremiumAnalyticsSink: Sendable {
    func track(_ event: PremiumAnalyticsEvent)
}

struct LoggerPremiumAnalyticsSink: PremiumAnalyticsSink {
    private let logger = Logger(subsystem: "com.jonathanluquet.oasis", category: "premium")

    func track(_ event: PremiumAnalyticsEvent) {
        logger.debug("\(event.logMessage, privacy: .public)")
    }
}
