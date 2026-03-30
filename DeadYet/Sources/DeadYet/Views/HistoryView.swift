import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CheckInRecord.date, order: .reverse) private var allRecords: [CheckInRecord]

    private var recentRecords: [CheckInRecord] {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -30, to: .now
        )!
        return allRecords.filter { $0.date >= cutoff }
    }

    private var stats: StreakStats {
        StreakCalculator.compute(records: allRecords)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeadYetColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        HStack(spacing: 32) {
                            statBlock(value: "\(stats.currentStreak)", label: "STREAK")
                            statBlock(value: "\(stats.totalCheckIns)", label: "CHECK-INS")
                            statBlock(value: "\(stats.missedDays)", label: "MISSED")
                        }
                        .padding(.top, 24)

                        if recentRecords.isEmpty {
                            Text("No history yet")
                                .font(DeadYetFonts.body(size: 14))
                                .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                                .padding(.top, 48)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(recentRecords, id: \.date) { record in
                                    HistoryRow(record: record)
                                    Divider()
                                        .background(DeadYetColors.primaryText.opacity(0.1))
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }
            .navigationTitle("History")
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
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DeadYetFonts.hero(size: 28))
                .foregroundStyle(DeadYetColors.primaryText)
            Text(label)
                .font(DeadYetFonts.body(size: 11))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                .tracking(1.5)
        }
    }
}
