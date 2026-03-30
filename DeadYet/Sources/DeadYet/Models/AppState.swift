import Foundation

enum AppState: String, Sendable {
    case safe
    case dueSoon
    case overdue
    case escalationPending
    case escalated
}
