import Foundation

enum CheckInEngine {
    static func computeState(
        now: Date,
        deadline: Date,
        lastCheckIn: Date?,
        gracePeriod: GracePeriod,
        escalatedAt: Date?
    ) -> AppState {
        // If already escalated this cycle
        if let escalatedAt, escalatedAt > deadline {
            if let lastCheckIn, lastCheckIn > escalatedAt {
                return .safe
            }
            return .escalated
        }

        // If user checked in after the most recent cycle start
        let cycleStart = previousDeadline(before: deadline)
        if let lastCheckIn, lastCheckIn > cycleStart {
            return .safe
        }

        // Time-based transitions
        let timeToDeadline = deadline.timeIntervalSince(now)
        let graceEnd = deadline.addingTimeInterval(gracePeriod.timeInterval)

        if now >= graceEnd {
            return .escalationPending
        } else if now >= deadline {
            return .overdue
        } else if timeToDeadline <= 3600 {
            return .dueSoon
        } else {
            return .safe
        }
    }

    static func nextDeadline(from now: Date, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        let todayDeadline = calendar.date(from: components)!

        if todayDeadline > now {
            return todayDeadline
        }
        return calendar.date(byAdding: .day, value: 1, to: todayDeadline)!
    }

    private static func previousDeadline(before deadline: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: deadline)!
    }
}
