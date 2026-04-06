import Foundation

struct EmergencyContact: Codable, Sendable, Equatable {
    var name: String
    var phone: String

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Self.isValidPhone(phone)
    }

    /// Validates E.164 format: +[country code][number], 7-15 digits total
    static func isValidPhone(_ phone: String) -> Bool {
        if phone.hasPrefix("+") {
            let digits = phone.dropFirst().filter(\.isNumber)
            return digits.count >= 7 && digits.count <= 15
        }
        // Legacy: accept bare 10-15 digit numbers
        let digits = phone.filter(\.isNumber)
        return digits.count >= 10 && digits.count <= 15
    }
}
