import Foundation
import UserNotifications

final class GentleReminderScheduler: @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    private enum Constants {
        static let reminderIdentifier = "oasis.gentle-reopen-reminder"
        static let reminderThreadIdentifier = "oasis.gentle-reminders"
        static let daysBeforeReminder = 3
        static let deliveryHour = 18
        static let deliveryMinute = 30
        static let authorizationOptions: UNAuthorizationOptions = [.alert, .provisional]
    }

    func appBecameActive(onboardingCompleted: Bool) {
        guard isEligible(onboardingCompleted: onboardingCompleted) else { return }
        cancelPendingReminder()
        requestAuthorizationIfNeeded()
    }

    func appEnteredBackground(onboardingCompleted: Bool) {
        guard isEligible(onboardingCompleted: onboardingCompleted) else { return }

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.scheduleReminder()
            case .notDetermined:
                self.requestAuthorization { granted in
                    guard granted else { return }
                    self.scheduleReminder()
                }
            case .denied:
                self.cancelPendingReminder()
            @unknown default:
                self.cancelPendingReminder()
            }
        }
    }

    func requestAuthorizationAfterOnboarding() {
        guard AppConfiguration.shouldPersistState else { return }
        requestAuthorizationIfNeeded()
    }

    private func isEligible(onboardingCompleted: Bool) -> Bool {
        AppConfiguration.shouldPersistState && onboardingCompleted
    }

    private func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            guard settings.authorizationStatus == .notDetermined else { return }
            self.requestAuthorization { _ in }
        }
    }

    private func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        center.requestAuthorization(options: Constants.authorizationOptions) { granted, error in
            if let error {
                print("Failed to request notification permission: \(error)")
            }
            completion(granted)
        }
    }

    private func scheduleReminder() {
        let content = UNMutableNotificationContent()
        content.title = L10n.string(L10n.GentleReminder.title)
        content.body = L10n.string(L10n.GentleReminder.body)
        content.threadIdentifier = Constants.reminderThreadIdentifier

        let request = UNNotificationRequest(
            identifier: Constants.reminderIdentifier,
            content: content,
            trigger: reminderTrigger()
        )

        center.removePendingNotificationRequests(withIdentifiers: [Constants.reminderIdentifier])
        center.add(request) { error in
            if let error {
                print("Failed to schedule gentle reminder notification: \(error)")
            }
        }
    }

    private func reminderTrigger() -> UNNotificationTrigger {
        let calendar = Calendar.current
        let now = Date()
        let fallbackDelivery = now.addingTimeInterval(TimeInterval(Constants.daysBeforeReminder * 24 * 60 * 60))
        let baseDate = calendar.date(byAdding: .day, value: Constants.daysBeforeReminder, to: now) ?? fallbackDelivery
        let deliveryDate = calendar.date(
            bySettingHour: Constants.deliveryHour,
            minute: Constants.deliveryMinute,
            second: 0,
            of: baseDate
        ) ?? fallbackDelivery

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deliveryDate)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    private func cancelPendingReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Constants.reminderIdentifier])
    }
}
