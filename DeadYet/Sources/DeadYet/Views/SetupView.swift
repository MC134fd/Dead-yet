import SwiftUI

struct SetupView: View {
    @Binding var deadlineHour: Int
    @Binding var deadlineMinute: Int
    @Binding var contactName: String
    @Binding var contactPhone: String
    let onComplete: () -> Void

    @State private var selectedTime = Calendar.current.date(
        bySettingHour: 10, minute: 0, second: 0, of: .now
    )!

    var body: some View {
        ZStack {
            DeadYetColors.background.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

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

                        TextField("Phone number", text: $contactPhone)
                            .textFieldStyle(.plain)
                            .font(DeadYetFonts.body(size: 16))
                            .foregroundStyle(DeadYetColors.primaryText)
                            #if os(iOS)
                            .keyboardType(.phonePad)
                            #endif
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        DeadYetColors.primaryText.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                Button(action: onComplete) {
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
