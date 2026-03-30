import Foundation

protocol BackendSyncService: Sendable {
    func syncCheckIn(at time: Date) async throws
    func syncSettings(
        deadlineHour: Int,
        deadlineMinute: Int,
        gracePeriodSeconds: Int,
        timezone: String,
        contact: EmergencyContact?
    ) async throws
    func fetchEscalationStatus() async throws -> EscalationStatus
}

struct EscalationStatus: Sendable {
    let escalatedAt: Date?
    let smsSent: Bool
}

struct OfflineSyncService: BackendSyncService {
    func syncCheckIn(at time: Date) async throws {}

    func syncSettings(
        deadlineHour: Int,
        deadlineMinute: Int,
        gracePeriodSeconds: Int,
        timezone: String,
        contact: EmergencyContact?
    ) async throws {}

    func fetchEscalationStatus() async throws -> EscalationStatus {
        EscalationStatus(escalatedAt: nil, smsSent: false)
    }
}
