import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }

    @State private var deadlineTime = Date.now
    @State private var selectedGracePeriod = GracePeriod.twoHours
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var reminderOffset = 3600
    @State private var phoneError = false

    private let reminderOptions: [(String, Int)] = [
        ("30 min before", 1800),
        ("1 hour before", 3600),
        ("2 hours before", 7200),
        ("Off", -1),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DeadYetColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        settingsSection("Daily deadline") {
                            DatePicker(
                                "",
                                selection: $deadlineTime,
                                displayedComponents: .hourAndMinute
                            )
                            #if os(iOS)
                            .datePickerStyle(.wheel)
                            #endif
                            .labelsHidden()
                            .colorScheme(.dark)
                        }

                        settingsSection("Grace period") {
                            Picker("", selection: $selectedGracePeriod) {
                                ForEach(GracePeriod.allCases, id: \.self) { period in
                                    Text(period.displayName).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }

                        settingsSection("Daily reminder") {
                            Picker("", selection: $reminderOffset) {
                                ForEach(reminderOptions, id: \.1) { option in
                                    Text(option.0).tag(option.1)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }

                        settingsSection("Emergency contact") {
                            VStack(spacing: 8) {
                                TextField("Name", text: $contactName)
                                    .textFieldStyle(.plain)
                                    .font(DeadYetFonts.body(size: 16))
                                    .foregroundStyle(DeadYetColors.primaryText)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                DeadYetColors.primaryText.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )

                                TextField("Phone number", text: $contactPhone)
                                    .textFieldStyle(.plain)
                                    .font(DeadYetFonts.body(size: 16))
                                    .foregroundStyle(DeadYetColors.primaryText)
                                    #if os(iOS)
                                    .keyboardType(.phonePad)
                                    #endif
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                phoneError
                                                    ? DeadYetColors.danger
                                                    : DeadYetColors.primaryText.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )

                                if phoneError {
                                    Text("Enter a valid phone number")
                                        .font(DeadYetFonts.body(size: 12))
                                        .foregroundStyle(DeadYetColors.danger)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(DeadYetColors.accent)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DeadYetColors.primaryText)
                }
            }
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .onAppear { loadSettings() }
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(DeadYetFonts.bodyMedium(size: 12))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                .tracking(1.5)
            content()
        }
    }

    private func loadSettings() {
        guard let settings else { return }
        var components = DateComponents()
        components.hour = settings.deadlineHour
        components.minute = settings.deadlineMinute
        deadlineTime = Calendar.current.date(from: components) ?? .now
        selectedGracePeriod = settings.gracePeriod
        contactName = settings.contactName ?? ""
        contactPhone = settings.contactPhone ?? ""
        reminderOffset = settings.reminderOffsetSeconds
    }

    private func save() {
        if !contactPhone.isEmpty && !EmergencyContact.isValidPhone(contactPhone) {
            phoneError = true
            return
        }
        phoneError = false

        guard let settings else { return }
        let components = Calendar.current.dateComponents(
            [.hour, .minute], from: deadlineTime
        )
        settings.deadlineHour = components.hour ?? 10
        settings.deadlineMinute = (components.minute ?? 0) / 15 * 15
        settings.gracePeriodSeconds = selectedGracePeriod.rawValue
        settings.reminderOffsetSeconds = reminderOffset
        settings.contactName = contactName.isEmpty ? nil : contactName
        settings.contactPhone = contactPhone.isEmpty ? nil : contactPhone
        try? modelContext.save()
        dismiss()
    }
}
