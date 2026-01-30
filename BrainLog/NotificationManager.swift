import Foundation
import UserNotifications

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    private let notificationIdentifier = "dailyReflectionReminder"
    private let enabledKey = "notificationEnabled"
    private let hourKey = "notificationHour"
    private let minuteKey = "notificationMinute"

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: enabledKey)
            if isEnabled {
                scheduleNotification()
            } else {
                cancelNotification()
            }
        }
    }

    var notificationTime: Date {
        didSet {
            let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
            UserDefaults.standard.set(components.hour ?? 19, forKey: hourKey)
            UserDefaults.standard.set(components.minute ?? 0, forKey: minuteKey)
            if isEnabled {
                scheduleNotification()
            }
        }
    }

    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: enabledKey)

        let hour = UserDefaults.standard.object(forKey: hourKey) as? Int ?? 19
        let minute = UserDefaults.standard.object(forKey: minuteKey) as? Int ?? 0

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        self.notificationTime = Calendar.current.date(from: components) ?? Date()
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func scheduleNotification() {
        cancelNotification()

        let content = UNMutableNotificationContent()
        content.title = "notification_title".localized()
        content.body = "notification_body".localized()
        content.sound = .default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationIdentifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationIdentifier])
    }
}
