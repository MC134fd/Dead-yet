import Foundation

struct EmergencyContact: Codable, Sendable, Equatable {
    var name: String
    var phone: String

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Self.isValidPhone(phone)
    }

    static func isValidPhone(_ phone: String) -> Bool {
        let digits = phone.filter(\.isNumber)
        return digits.count >= 10 && digits.count <= 15
    }
}
