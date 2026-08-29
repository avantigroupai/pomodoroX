import Foundation
import UserNotifications

public final class NotificationManager: @unchecked Sendable {
    public static let shared = NotificationManager()

    private var isSupported: Bool {
        // UNUserNotificationCenter requires a running application bundle
        guard let bundleId = Bundle.main.bundleIdentifier,
              !bundleId.isEmpty,
              !bundleId.contains("xctest"),
              !bundleId.contains("PomodoroXPackageTests"),
              Bundle.main.bundlePath.hasSuffix(".app") else {
            return false
        }
        return true
    }

    public init() {}

    public func requestAuthorization() {
        guard isSupported else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    public func scheduleSessionCompletionNotification(phase: PomodoroPhase, in seconds: TimeInterval) {
        guard isSupported, seconds > 0 else { return }

        // Cancel previous pending requests
        cancelPendingNotifications()

        let content = UNMutableNotificationContent()
        switch phase {
        case .focus:
            content.title = "Focus Session Finished! 🍅"
            content.body = "Great work! Time for a well-deserved break."
        case .shortBreak:
            content.title = "Break Over! ⚡️"
            content.body = "Ready to jump back into the zone?"
        case .longBreak:
            content.title = "Long Break Finished! 🌟"
            content.body = "Energized and refreshed for the next cycle."
        }
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoro.completion", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    public func cancelPendingNotifications() {
        guard isSupported else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pomodoro.completion"])
    }
}
