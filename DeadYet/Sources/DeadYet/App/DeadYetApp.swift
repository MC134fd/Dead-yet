import SwiftUI
import SwiftData

@main
struct DeadYetApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserSettings.self, CheckInRecord.self])
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }

    @State private var deadlineHour = 10
    @State private var deadlineMinute = 0
    @State private var contactName = ""
    @State private var contactPhone = ""

    var body: some View {
        Group {
            if let settings, settings.hasCompletedSetup {
                HomeView()
            } else {
                SetupView(
                    deadlineHour: $deadlineHour,
                    deadlineMinute: $deadlineMinute,
                    contactName: $contactName,
                    contactPhone: $contactPhone,
                    onComplete: completeSetup
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func completeSetup() {
        let newSettings: UserSettings
        if let existing = settings {
            newSettings = existing
        } else {
            newSettings = UserSettings()
            modelContext.insert(newSettings)
        }

        newSettings.deadlineHour = deadlineHour
        newSettings.deadlineMinute = deadlineMinute / 15 * 15
        newSettings.hasCompletedSetup = true

        if !contactName.isEmpty {
            newSettings.contactName = contactName
        }
        if !contactPhone.isEmpty && EmergencyContact.isValidPhone(contactPhone) {
            newSettings.contactPhone = contactPhone
        }

        try? modelContext.save()

        Task {
            await NotificationService.requestPermission()
            let deadline = CheckInEngine.nextDeadline(
                from: .now,
                hour: newSettings.deadlineHour,
                minute: newSettings.deadlineMinute
            )
            NotificationService.scheduleAll(
                deadline: deadline,
                gracePeriodSeconds: newSettings.gracePeriodSeconds,
                reminderOffsetSeconds: newSettings.reminderOffsetSeconds
            )
        }
    }
}
