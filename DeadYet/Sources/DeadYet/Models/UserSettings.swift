import Foundation
import SwiftData

@Model
final class UserSettings {
    var deadlineHour: Int
    var deadlineMinute: Int
    var gracePeriodSeconds: Int
    var reminderOffsetSeconds: Int
    var contactName: String?
    var contactPhone: String?
    var hasCompletedSetup: Bool
    var displayName: String?
    var email: String?
    var profilePhotoURL: String?
    var authProvider: String?

    init(
        deadlineHour: Int = 10,
        deadlineMinute: Int = 0,
        gracePeriodSeconds: Int = GracePeriod.twoHours.rawValue,
        reminderOffsetSeconds: Int = 3600,
        contactName: String? = nil,
        contactPhone: String? = nil,
        hasCompletedSetup: Bool = false,
        displayName: String? = nil,
        email: String? = nil,
        profilePhotoURL: String? = nil,
        authProvider: String? = nil
    ) {
        self.deadlineHour = deadlineHour
        self.deadlineMinute = deadlineMinute
        self.gracePeriodSeconds = gracePeriodSeconds
        self.reminderOffsetSeconds = reminderOffsetSeconds
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.hasCompletedSetup = hasCompletedSetup
        self.displayName = displayName
        self.email = email
        self.profilePhotoURL = profilePhotoURL
        self.authProvider = authProvider
    }

    var emergencyContact: EmergencyContact? {
        guard let name = contactName, let phone = contactPhone else { return nil }
        let contact = EmergencyContact(name: name, phone: phone)
        return contact.isValid ? contact : nil
    }

    var gracePeriod: GracePeriod {
        GracePeriod(rawValue: gracePeriodSeconds) ?? .twoHours
    }

    var deadlineTimeComponents: DateComponents {
        var components = DateComponents()
        components.hour = deadlineHour
        components.minute = deadlineMinute
        return components
    }
}
