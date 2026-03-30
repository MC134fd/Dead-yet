import Foundation
import UserNotifications

enum NotificationService {
    private static let dailyReminderId = "deadyet.reminder.daily"
    private static let deadlineId = "deadyet.reminder.deadline"
    private static let overduePrefix = "deadyet.overdue."
    private static let escalatedId = "deadyet.escalated"

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleAll(
        deadline: Date,
        gracePeriodSeconds: Int,
        reminderOffsetSeconds: Int
    ) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Daily reminder (if not off)
        if reminderOffsetSeconds > 0 {
            let reminderDate = deadline.addingTimeInterval(
                -TimeInterval(reminderOffsetSeconds)
            )
            scheduleNotification(
                id: dailyReminderId,
                body: "You haven't checked in today.",
                at: reminderDate
            )
        }

        // Deadline notification
        scheduleNotification(
            id: deadlineId,
            body: "Deadline passed. Check in now.",
            at: deadline
        )

        // Overdue warnings during grace period (every 15 min)
        let gracePeriod = TimeInterval(gracePeriodSeconds)
        var elapsed: TimeInterval = 900
        var index = 0
        while elapsed < gracePeriod {
            let remaining = gracePeriod - elapsed
            let mins = Int(remaining) / 60
            let hours = mins / 60
            let remMins = mins % 60
            let body: String
            if hours > 0 && remMins > 0 {
                body = "\(hours)h \(remMins)m until your emergency contact is notified."
            } else if hours > 0 {
                body = "\(hours)h until your emergency contact is notified."
            } else {
                body = "\(mins) minutes."
            }
            let fireDate = deadline.addingTimeInterval(elapsed)
            scheduleNotification(
                id: "\(overduePrefix)\(index)",
                body: body,
                at: fireDate
            )
            elapsed += 900
            index += 1
        }

        // Escalation notification
        scheduleNotification(
            id: escalatedId,
            body: "Your emergency contact has been notified.",
            at: deadline.addingTimeInterval(gracePeriod)
        )
    }

    static func cancelAll() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }

    private static func scheduleNotification(
        id: String, body: String, at date: Date
    ) {
        guard date > Date.now else { return }

        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
