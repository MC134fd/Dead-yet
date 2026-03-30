import SwiftUI

struct StatusBanner: View {
    let state: AppState
    let contactName: String?
    let escalatedTime: String?
    let hasContact: Bool

    var body: some View {
        Group {
            if !hasContact {
                bannerView(
                    text: "Nobody knows you're alive yet",
                    color: DeadYetColors.warning
                )
            } else {
                switch state {
                case .safe, .dueSoon:
                    EmptyView()
                case .overdue:
                    bannerView(
                        text: "You haven't confirmed you're alive",
                        color: DeadYetColors.danger
                    )
                case .escalationPending:
                    bannerView(
                        text: "Your emergency contact will be alerted",
                        color: DeadYetColors.danger
                    )
                case .escalated:
                    VStack(spacing: 2) {
                        bannerView(
                            text: "Your emergency contact was notified",
                            color: DeadYetColors.danger
                        )
                        if let contactName, let escalatedTime {
                            Text("\(contactName) was texted at \(escalatedTime)")
                                .font(DeadYetFonts.body(size: 12))
                                .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                        }
                    }
                }
            }
        }
    }

    private func bannerView(text: String, color: Color) -> some View {
        Text(text)
            .font(DeadYetFonts.bodyMedium(size: 14))
            .foregroundStyle(color)
    }
}
