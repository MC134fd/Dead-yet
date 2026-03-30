import SwiftUI

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

extension View {
    func deadYetBackground() -> some View {
        self.background(DeadYetColors.background)
    }
}
