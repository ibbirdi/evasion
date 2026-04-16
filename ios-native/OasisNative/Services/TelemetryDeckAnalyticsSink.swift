#if canImport(TelemetryDeck)
import Foundation
import OSLog
import TelemetryDeck

struct TelemetryDeckAnalyticsSink: PremiumAnalyticsSink {
    private let logger = Logger(subsystem: "com.jonathanluquet.oasis", category: "premium")

    func track(_ event: PremiumAnalyticsEvent) {
        logger.debug("\(event.logMessage, privacy: .public)")

        let (signalName, parameters) = event.telemetrySignal
        TelemetryDeck.signal(signalName, parameters: parameters)
    }
}

private extension PremiumAnalyticsEvent {
    var telemetrySignal: (String, [String: String]) {
        switch self {
        case let .appSession(index):
            return ("app.session", ["index": "\(index)"])
        case .firstPlay:
            return ("app.firstPlay", [:])
        case .listened60s:
            return ("app.listened60s", [:])
        case let .timerSet(minutes):
            return ("timer.set", ["minutes": minutes.map(String.init) ?? "off"])
        case let .presetSaved(kind):
            return ("preset.saved", ["kind": kind])
        case let .lockedFeatureTapped(source):
            return ("premium.lockedTap", ["source": source])
        case let .reviewPromptRequested(reason):
            return ("app.reviewPrompt", ["reason": reason])
        case .bannerShown:
            return ("premium.bannerShown", [:])
        case .bannerDismissed:
            return ("premium.bannerDismissed", [:])
        case let .inlineShown(source):
            return ("premium.inlineShown", ["source": source])
        case let .paywallShown(source):
            return ("premium.paywallShown", ["source": source])
        case let .paywallDismissed(source):
            return ("premium.paywallDismissed", ["source": source])
        case let .paywallLoading(source):
            return ("premium.paywallLoading", ["source": source])
        case let .paywallRetry(source):
            return ("premium.paywallRetry", ["source": source])
        case let .purchaseStarted(source):
            return ("purchase.started", ["source": source])
        case let .purchaseCancelled(source):
            return ("purchase.cancelled", ["source": source])
        case let .purchaseSucceeded(source):
            return ("purchase.succeeded", ["source": source])
        case let .restoreStarted(source):
            return ("restore.started", ["source": source])
        case let .restoreSucceeded(source):
            return ("restore.succeeded", ["source": source])
        case .previewStarted:
            return ("preview.started", [:])
        case .previewFinished:
            return ("preview.finished", [:])
        case let .onboardingCompleted(page):
            return ("onboarding.completed", ["page": "\(page)"])
        case let .onboardingSkipped(page):
            return ("onboarding.skipped", ["page": "\(page)"])
        }
    }
}
#endif
