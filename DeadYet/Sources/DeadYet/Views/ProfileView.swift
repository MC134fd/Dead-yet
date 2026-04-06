import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }

    @State private var showSettings = false
    @State private var showLogoutConfirm = false
    @State private var authService = AuthenticationService()

    var body: some View {
        NavigationStack {
            ZStack {
                DeadYetColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Profile photo + name
                        VStack(spacing: 16) {
                            if let photoURL = settings?.profilePhotoURL,
                               let url = URL(string: photoURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    profilePlaceholder
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                            } else {
                                profilePlaceholder
                            }

                            VStack(spacing: 4) {
                                Text(settings?.displayName ?? "No name set")
                                    .font(DeadYetFonts.bodyMedium(size: 20))
                                    .foregroundStyle(DeadYetColors.primaryText)

                                if let email = settings?.email {
                                    Text(email)
                                        .font(DeadYetFonts.body(size: 14))
                                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                                }
                            }
                        }
                        .padding(.top, 24)

                        // Emergency contact
                        profileSection("Emergency Contact") {
                            if let contact = settings?.emergencyContact {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(contact.name)
                                            .font(DeadYetFonts.bodyMedium(size: 16))
                                            .foregroundStyle(DeadYetColors.primaryText)
                                        Text(contact.phone)
                                            .font(DeadYetFonts.body(size: 14))
                                            .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(DeadYetColors.accent)
                                }
                            } else {
                                HStack {
                                    Text("Not set")
                                        .font(DeadYetFonts.body(size: 16))
                                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(DeadYetColors.warning)
                                }
                            }
                        }

                        // SMS Escalation status
                        profileSection("SMS Escalation") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                                    Text("Not configured — requires backend setup")
                                        .font(DeadYetFonts.body(size: 14))
                                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                                }

                                if let phone = settings?.contactPhone, !phone.isEmpty {
                                    Button(action: sendTestMessage) {
                                        HStack {
                                            Image(systemName: "message")
                                            Text("Send Test Message")
                                                .font(DeadYetFonts.bodyMedium(size: 14))
                                        }
                                        .foregroundStyle(DeadYetColors.accent)
                                    }
                                }
                            }
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button(action: { showSettings = true }) {
                                HStack {
                                    Image(systemName: "gearshape")
                                    Text("Edit Settings")
                                        .font(DeadYetFonts.bodyMedium(size: 16))
                                }
                                .foregroundStyle(DeadYetColors.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(DeadYetColors.primaryText.opacity(0.2), lineWidth: 1)
                                )
                            }

                            Button(action: { showLogoutConfirm = true }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Log Out")
                                        .font(DeadYetFonts.bodyMedium(size: 16))
                                }
                                .foregroundStyle(DeadYetColors.danger)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(DeadYetColors.danger.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DeadYetColors.primaryText)
                }
            }
            #if os(iOS)
            .toolbarColorScheme(.dark, for: .navigationBar)
            #endif
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Log Out", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) { logout() }
            } message: {
                Text("This will erase all your data and return to setup.")
            }
        }
    }

    private var profilePlaceholder: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: 70))
            .foregroundStyle(DeadYetColors.primaryText.opacity(0.3))
            .frame(width: 80, height: 80)
    }

    private func profileSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(DeadYetFonts.bodyMedium(size: 12))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                .tracking(1.5)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DeadYetColors.primaryText.opacity(0.05))
                )
        }
        .padding(.horizontal, 24)
    }

    private func sendTestMessage() {
        guard let phone = settings?.contactPhone,
              let url = URL(string: "sms:\(phone)&body=Test message from Dead Yet app") else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #endif
    }

    private func logout() {
        authService.signOut()
        // Delete all settings and check-in records
        do {
            try modelContext.delete(model: UserSettings.self)
            try modelContext.delete(model: CheckInRecord.self)
            try modelContext.save()
        } catch {
            // fallback: clear settings manually
            if let settings {
                settings.hasCompletedSetup = false
                try? modelContext.save()
            }
        }
        NotificationService.cancelAll()
        dismiss()
    }
}
