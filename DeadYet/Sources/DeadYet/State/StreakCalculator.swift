import Foundation

struct StreakStats: Equatable, Sendable {
    let currentStreak: Int
    let totalCheckIns: Int
    let missedDays: Int
}

enum StreakCalculator {
    static func compute(records: [CheckInRecord]) -> StreakStats {
        guard !records.isEmpty else {
            return StreakStats(currentStreak: 0, totalCheckIns: 0, missedDays: 0)
        }

        let sorted = records.sorted { $0.date > $1.date }

        var currentStreak = 0
        var totalCheckIns = 0
        var missedDays = 0
        var streakBroken = false

        for record in sorted {
            let status = record.checkInStatus
            switch status {
            case .checkedIn:
                totalCheckIns += 1
                if !streakBroken {
                    currentStreak += 1
                }
            case .missed, .escalated:
                missedDays += 1
                streakBroken = true
            }
        }

        return StreakStats(
            currentStreak: currentStreak,
            totalCheckIns: totalCheckIns,
            missedDays: missedDays
        )
    }
}
