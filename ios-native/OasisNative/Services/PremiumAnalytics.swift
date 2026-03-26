import Foundation
import OSLog

enum PremiumAnalyticsEvent: Sendable {
    case bannerShown
    case bannerDismissed
    case inlineShown(source: String)
    case paywallShown(source: String)
    case paywallLoading(source: String)
    case paywallRetry(source: String)
    case purchaseStarted(source: String)
    case purchaseCancelled(source: String)
    case purchaseSucceeded(source: String)
    case restoreStarted(source: String)
    case restoreSucceeded(source: String)
    case previewStarted
    case previewFinished

    var logMessage: String {
        switch self {
        case .bannerShown:
            return "banner_shown"
        case .bannerDismissed:
            return "banner_dismissed"
        case let .inlineShown(source):
            return "inline_shown:\(source)"
        case let .paywallShown(source):
            return "paywall_shown:\(source)"
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
