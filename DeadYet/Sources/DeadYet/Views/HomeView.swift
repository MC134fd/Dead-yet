import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showProfile = false
    @State private var showHistory = false

    var body: some View {
        ZStack {
            DeadYetColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { showProfile = true }) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                    }
                    Spacer()
                    Button(action: { showHistory = true }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20))
                            .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                StatusBanner(
                    state: viewModel.appState,
                    contactName: viewModel.contactName,
                    escalatedTime: viewModel.escalatedTime,
                    hasContact: viewModel.hasContact
                )
                .padding(.bottom, 32)

                if !viewModel.isCheckedIn {
                    CountdownDisplay(
                        timeRemaining: viewModel.timeRemaining,
                        totalDuration: viewModel.totalDuration
                    )
                    .padding(.bottom, 48)
                }

                AliveButton(
                    isCheckedIn: viewModel.isCheckedIn,
                    action: { viewModel.checkIn() }
                )

                if viewModel.isCheckedIn {
                    Text("You're good for today")
                        .font(DeadYetFonts.body(size: 14))
                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                        .padding(.top, 16)
                }

                Spacer()

                VStack(spacing: 8) {
                    Text(viewModel.lastCheckInText)
                        .font(DeadYetFonts.body(size: 13))
                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))

                    Text(viewModel.deadlineText)
                        .font(DeadYetFonts.body(size: 13))
                        .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))

                    if viewModel.streakCount > 0 {
                        Text("\(viewModel.streakCount) days alive")
                            .font(DeadYetFonts.bodyMedium(size: 13))
                            .foregroundStyle(DeadYetColors.accent.opacity(0.6))
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear { viewModel.start(modelContext: modelContext) }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .onDisappear { viewModel.updateState() }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
    }
}
