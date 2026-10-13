import Foundation
import UserNotifications

enum NotificationService {
    static let center = UNUserNotificationCenter.current()

    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleDailyReminder(hour: Int) {
        cancelDailyReminder()
        let content = UNMutableNotificationContent()
        content.title = "Today's Plan"
        content.body = "Your workout is ready — adjusted for today's weather."
        content.sound = .default
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
        comps.hour = hour
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }

    static func scheduleSundayReport() {
        cancelSundayReport()
        let content = UNMutableNotificationContent()
        content.title = "Weekly Report Ready"
        content.body = "This week's training summary is ready to view and share."
        content.sound = .default
        var comps = DateComponents()
        comps.weekday = 1
        comps.hour = 19
        comps.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "sundayReport", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelSundayReport() {
        center.removePendingNotificationRequests(withIdentifiers: ["sundayReport"])
    }

    static func sendRedFlagAlert(flag: HeatFlag) {
        guard flag == .red || flag == .black else { return }
        let content = UNMutableNotificationContent()
        content.title = "Heat Alert"
        content.body = "Outdoor practice is not recommended today (NATA \(flag.rawValue.capitalized) Flag). Follow your school or district heat policy."
        content.sound = .default
        let request = UNNotificationRequest(identifier: "redFlag-\(UUID().uuidString)", content: content, trigger: nil)
        center.add(request)
    }
}
