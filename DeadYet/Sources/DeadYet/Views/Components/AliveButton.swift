import SwiftUI

struct AliveButton: View {
    let isCheckedIn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isCheckedIn ? "ALIVE" : "I'M ALIVE")
        }
        .buttonStyle(AliveButtonStyle(isCheckedIn: isCheckedIn))
        .disabled(isCheckedIn)
        .sensoryFeedback(.impact(weight: .medium), trigger: isCheckedIn)
    }
}

struct AliveButtonStyle: ButtonStyle {
    let isCheckedIn: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DeadYetFonts.hero(size: 24))
            .tracking(3)
            .foregroundStyle(DeadYetColors.background)
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
            .background(
                isCheckedIn
                    ? DeadYetColors.accent.opacity(0.3)
                    : DeadYetColors.accent
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
