import SwiftUI

enum DeadYetColors {
    static let background = Color(red: 0, green: 0, blue: 0)
    static let primaryText = Color(red: 0.91, green: 0.91, blue: 0.89)
    static let accent = Color(red: 0.667, green: 1.0, blue: 0.0)
    static let danger = Color(red: 1.0, green: 0.231, blue: 0.188)
    static let warning = Color(red: 1.0, green: 0.839, blue: 0.039)

    static func countdownColor(fractionRemaining: Double) -> Color {
        if fractionRemaining > 0.25 {
            return primaryText
        } else if fractionRemaining > 0.08 {
            return warning
        } else {
            return danger
        }
    }
}
