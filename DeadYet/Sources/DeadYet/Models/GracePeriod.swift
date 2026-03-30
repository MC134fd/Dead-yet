import Foundation

enum GracePeriod: Int, CaseIterable, Sendable {
    case thirtyMinutes = 1800
    case oneHour = 3600
    case twoHours = 7200
    case fourHours = 14400

    var displayName: String {
        switch self {
        case .thirtyMinutes: "30 min"
        case .oneHour: "1 hour"
        case .twoHours: "2 hours"
        case .fourHours: "4 hours"
        }
    }

    var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }
}
