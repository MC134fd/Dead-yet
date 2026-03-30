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
