import SwiftUI
import GoogleSignIn

struct SetupView: View {
    @Binding var deadlineHour: Int
    @Binding var deadlineMinute: Int
    @Binding var contactName: String
    @Binding var contactPhone: String
    let onComplete: () -> Void
    let onGoogleSignIn: (String?, String?, URL?) -> Void

    @State private var authService = AuthenticationService()
    @State private var selectedTime = Calendar.current.date(
        bySettingHour: 10, minute: 0, second: 0, of: .now
    )!

    var body: some View {
        ZStack {
            DeadYetColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 36) {
                    Spacer().frame(height: 40)

                    // Google Sign-In
                    VStack(spacing: 12) {
                        Button(action: {
                            authService.signIn()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 20))
                                Text("Sign in with Google")
                                    .font(DeadYetFonts.bodyMedium(size: 16))
                            }
                            .foregroundStyle(DeadYetColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(DeadYetColors.primaryText.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 32)

                        if authService.isSignedIn, let name = authService.userName {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DeadYetColors.accent)
                                Text("Signed in as \(name)")
                                    .font(DeadYetFonts.body(size: 14))
                                    .foregroundStyle(DeadYetColors.primaryText.opacity(0.6))
                            }
                        }

                        if let error = authService.errorMessage {
                            Text(error)
                                .font(DeadYetFonts.body(size: 12))
                                .foregroundStyle(DeadYetColors.danger)
                                .padding(.horizontal, 32)
                        }
                    }

                    // Time picker
                    VStack(spacing: 12) {
                        Text("When should we check\nif you're alive?")
                            .font(DeadYetFonts.bodyMedium(size: 18))
                            .foregroundStyle(DeadYetColors.primaryText)
                            .multilineTextAlignment(.center)

                        DatePicker(
                            "",
                            selection: $selectedTime,
                            displayedComponents: .hourAndMinute
                        )
                        #if os(iOS)
                        .datePickerStyle(.wheel)
                        #endif
                        .labelsHidden()
                        .colorScheme(.dark)
                        .frame(maxWidth: 200)
                        .onChange(of: selectedTime) { _, newValue in
                            let components = Calendar.current.dateComponents(
                                [.hour, .minute], from: newValue
                            )
                            deadlineHour = components.hour ?? 10
                            deadlineMinute = (components.minute ?? 0) / 15 * 15
                        }
                    }

                    // Emergency contact
                    VStack(spacing: 12) {
                        Text("Who should we tell?")
                            .font(DeadYetFonts.bodyMedium(size: 18))
                            .foregroundStyle(DeadYetColors.primaryText)

                        VStack(spacing: 8) {
                            TextField("Name", text: $contactName)
                                .textFieldStyle(.plain)
                                .font(DeadYetFonts.body(size: 16))
                                .foregroundStyle(DeadYetColors.primaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(
                                            DeadYetColors.primaryText.opacity(0.2),
                                            lineWidth: 1
                                        )
                                )

                            PhoneInputField(fullPhone: $contactPhone)
                        }
                        .padding(.horizontal, 32)
                    }

                    // GET STARTED button
                    Button(action: {
                        if authService.isSignedIn {
                            onGoogleSignIn(
                                authService.userName,
                                authService.userEmail,
                                authService.userPhotoURL
                            )
                        }
                        onComplete()
                    }) {
                        Text("GET STARTED")
                            .font(DeadYetFonts.hero(size: 18))
                            .tracking(3)
                            .foregroundStyle(DeadYetColors.background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(DeadYetColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
        }
    }
}
