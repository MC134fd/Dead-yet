import Testing
import Foundation
@testable import DeadYet

struct StreakCalculatorTests {
    private func makeRecord(daysAgo: Int, status: CheckInStatus) -> CheckInRecord {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date.now)!
        return CheckInRecord(
            date: date,
            status: status,
            checkInTime: status == .checkedIn ? date : nil
        )
    }

    @Test func emptyRecords() {
        let stats = StreakCalculator.compute(records: [])
        #expect(stats.currentStreak == 0)
        #expect(stats.totalCheckIns == 0)
        #expect(stats.missedDays == 0)
    }

    @Test func consecutiveStreak() {
        let records = [
            makeRecord(daysAgo: 0, status: .checkedIn),
            makeRecord(daysAgo: 1, status: .checkedIn),
            makeRecord(daysAgo: 2, status: .checkedIn),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 3)
        #expect(stats.totalCheckIns == 3)
        #expect(stats.missedDays == 0)
    }

    @Test func streakResetsOnMiss() {
        let records = [
            makeRecord(daysAgo: 0, status: .checkedIn),
            makeRecord(daysAgo: 1, status: .missed),
            makeRecord(daysAgo: 2, status: .checkedIn),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 1)
        #expect(stats.totalCheckIns == 2)
        #expect(stats.missedDays == 1)
    }

    @Test func escalatedCountsAsMissed() {
        let records = [
            makeRecord(daysAgo: 0, status: .checkedIn),
            makeRecord(daysAgo: 1, status: .escalated),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 1)
        #expect(stats.totalCheckIns == 1)
        #expect(stats.missedDays == 1)
    }

    @Test func allMissed() {
        let records = [
            makeRecord(daysAgo: 0, status: .missed),
            makeRecord(daysAgo: 1, status: .missed),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 0)
        #expect(stats.totalCheckIns == 0)
        #expect(stats.missedDays == 2)
    }
}
