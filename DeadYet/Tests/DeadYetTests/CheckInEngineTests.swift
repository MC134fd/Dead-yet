import Testing
import Foundation
@testable import DeadYet

struct CheckInEngineTests {
    private func todayAt(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date.now)!
    }

    @Test func safeAfterCheckIn() {
        let now = todayAt(hour: 8)
        let deadline = todayAt(hour: 10)
        let lastCheckIn = todayAt(hour: 7, minute: 30)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: lastCheckIn, gracePeriod: .twoHours, escalatedAt: nil)
        #expect(state == .safe)
    }

    @Test func dueSoonWithinOneHour() {
        let now = todayAt(hour: 9, minute: 15)
        let deadline = todayAt(hour: 10)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: nil, gracePeriod: .twoHours, escalatedAt: nil)
        #expect(state == .dueSoon)
    }

    @Test func overdueAfterDeadline() {
        let now = todayAt(hour: 10, minute: 30)
        let deadline = todayAt(hour: 10)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: nil, gracePeriod: .twoHours, escalatedAt: nil)
        #expect(state == .overdue)
    }

    @Test func escalationPendingAfterGracePeriod() {
        let now = todayAt(hour: 12, minute: 1)
        let deadline = todayAt(hour: 10)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: nil, gracePeriod: .twoHours, escalatedAt: nil)
        #expect(state == .escalationPending)
    }

    @Test func escalatedWhenSmsWasSent() {
        let now = todayAt(hour: 13)
        let deadline = todayAt(hour: 10)
        let escalatedAt = todayAt(hour: 12, minute: 5)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: nil, gracePeriod: .twoHours, escalatedAt: escalatedAt)
        #expect(state == .escalated)
    }

    @Test func safeBeforeDueSoonWindow() {
        let now = todayAt(hour: 6)
        let deadline = todayAt(hour: 10)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: nil, gracePeriod: .twoHours, escalatedAt: nil)
        #expect(state == .safe)
    }

    @Test func checkInDuringGracePeriodReturnsSafe() {
        let now = todayAt(hour: 11)
        let deadline = todayAt(hour: 10)
        let lastCheckIn = todayAt(hour: 10, minute: 45)
        let state = CheckInEngine.computeState(now: now, deadline: deadline, lastCheckIn: lastCheckIn, gracePeriod: .twoHours, escalatedAt: nil)
        #expect(state == .safe)
    }

    @Test func nextDeadlineCalculation() {
        let now = todayAt(hour: 8)
        let deadline = CheckInEngine.nextDeadline(from: now, hour: 10, minute: 0)
        #expect(Calendar.current.component(.hour, from: deadline) == 10)
        #expect(Calendar.current.component(.minute, from: deadline) == 0)
        #expect(deadline > now)
    }

    @Test func nextDeadlineWrapsToTomorrowIfPast() {
        let now = todayAt(hour: 14)
        let deadline = CheckInEngine.nextDeadline(from: now, hour: 10, minute: 0)
        #expect(deadline > now)
    }
}
