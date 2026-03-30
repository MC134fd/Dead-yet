import SwiftUI

struct HistoryRow: View {
    let record: CheckInRecord

    private var indicatorColor: Color {
        switch record.checkInStatus {
        case .checkedIn: DeadYetColors.accent
        case .missed: DeadYetColors.warning
        case .escalated: DeadYetColors.danger
        }
    }

    private var statusText: String {
        switch record.checkInStatus {
        case .checkedIn:
            if let time = record.checkInTime {
                return time.formatted(date: .omitted, time: .shortened)
            }
            return "Checked in"
        case .missed:
            return "Missed"
        case .escalated:
            return "Missed — contact notified"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)

            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                .font(DeadYetFonts.body(size: 14))
                .foregroundStyle(DeadYetColors.primaryText)

            Spacer()

            Text(statusText)
                .font(DeadYetFonts.body(size: 14))
                .foregroundStyle(
                    record.checkInStatus == .checkedIn
                        ? DeadYetColors.primaryText.opacity(0.6)
                        : indicatorColor
                )
        }
        .padding(.vertical, 8)
    }
}
