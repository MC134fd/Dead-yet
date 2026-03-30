import Foundation
import SwiftData

enum CheckInStatus: String, Codable, Sendable {
    case checkedIn
    case missed
    case escalated
}

@Model
final class CheckInRecord {
    var date: Date
    var status: String
    var checkInTime: Date?

    init(date: Date, status: CheckInStatus, checkInTime: Date? = nil) {
        self.date = date
        self.status = status.rawValue
        self.checkInTime = checkInTime
    }

    var checkInStatus: CheckInStatus {
        CheckInStatus(rawValue: status) ?? .missed
    }
}
