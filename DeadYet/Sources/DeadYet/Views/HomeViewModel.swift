import SwiftUI
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var appState: AppState = .safe
    var timeRemaining: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var isCheckedIn: Bool = false
    var lastCheckInText: String = "No check-ins yet"
    var deadlineText: String = ""
    var streakCount: Int = 0
    var contactName: String?
    var escalatedTime: String?
    var hasContact: Bool = false

    private var timer: Timer?
    private var modelContext: ModelContext?
    private let syncService: any BackendSyncService

    init(syncService: any BackendSyncService = OfflineSyncService()) {
        self.syncService = syncService
    }

    func start(modelContext: ModelContext) {
        self.modelContext = modelContext
        startTimer()
        updateState()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func checkIn() {
        guard let modelContext, !isCheckedIn else { return }

        let now = Date.now
        let record = CheckInRecord(
            date: now, status: .checkedIn, checkInTime: now
        )
        modelContext.insert(record)
        try? modelContext.save()

        isCheckedIn = true

        NotificationService.cancelAll()

        if let settings = fetchSettings() {
            let nextDeadline = CheckInEngine.nextDeadline(
                from: now,
                hour: settings.deadlineHour,
                minute: settings.deadlineMinute
            )
            NotificationService.scheduleAll(
                deadline: nextDeadline,
                gracePeriodSeconds: settings.gracePeriodSeconds,
                reminderOffsetSeconds: settings.reminderOffsetSeconds
            )
        }

        Task {
            try? await syncService.syncCheckIn(at: now)
        }

        updateState()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateState()
            }
        }
    }

    func updateState() {
        guard let settings = fetchSettings() else { return }

        let now = Date.now
        let deadline = CheckInEngine.nextDeadline(
            from: Calendar.current.startOfDay(for: now),
            hour: settings.deadlineHour,
            minute: settings.deadlineMinute
        )

        let todayStart = Calendar.current.startOfDay(for: now)
        let lastCheckIn = fetchLastCheckIn(since: todayStart)

        if let lastCheckIn {
            isCheckedIn = lastCheckIn.checkInTime != nil
                && lastCheckIn.checkInStatus == .checkedIn
        } else {
            isCheckedIn = false
        }

        appState = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: lastCheckIn?.checkInTime,
            gracePeriod: settings.gracePeriod,
            escalatedAt: nil
        )

        let nextDeadline: Date
        if now > deadline {
            nextDeadline = CheckInEngine.nextDeadline(
                from: now,
                hour: settings.deadlineHour,
                minute: settings.deadlineMinute
            )
        } else {
            nextDeadline = deadline
        }
        timeRemaining = max(0, nextDeadline.timeIntervalSince(now))
        totalDuration = 24 * 3600

        deadlineText = "Due by: \(nextDeadline.formatted(date: .omitted, time: .shortened))"

        if let checkInTime = lastCheckIn?.checkInTime {
            lastCheckInText = "Last: \(checkInTime.formatted(date: .abbreviated, time: .shortened))"
        } else {
            lastCheckInText = "No check-ins yet"
        }

        hasContact = settings.emergencyContact != nil
        contactName = settings.contactName

        let records = fetchAllRecords()
        streakCount = StreakCalculator.compute(records: records).currentStreak
    }

    private func fetchSettings() -> UserSettings? {
        guard let modelContext else { return nil }
        let descriptor = FetchDescriptor<UserSettings>()
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchLastCheckIn(since date: Date) -> CheckInRecord? {
        guard let modelContext else { return nil }
        var descriptor = FetchDescriptor<CheckInRecord>(
            predicate: #Predicate { $0.date >= date },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchAllRecords() -> [CheckInRecord] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<CheckInRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
