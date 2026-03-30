import SwiftUI

struct CountdownDisplay: View {
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval

    private var fractionRemaining: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalDuration))
    }

    private var formattedTime: String {
        let total = max(0, Int(timeRemaining))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(formattedTime)
                .font(DeadYetFonts.countdown(size: 56))
                .tracking(2)
                .foregroundStyle(
                    DeadYetColors.countdownColor(fractionRemaining: fractionRemaining)
                )
            Text("until deadline")
                .font(DeadYetFonts.body(size: 13))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
        }
    }
}
