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

    init(
        deadlineHour: Int = 10,
        deadlineMinute: Int = 0,
        gracePeriodSeconds: Int = GracePeriod.twoHours.rawValue,
        reminderOffsetSeconds: Int = 3600,
        contactName: String? = nil,
        contactPhone: String? = nil,
        hasCompletedSetup: Bool = false
    ) {
        self.deadlineHour = deadlineHour
        self.deadlineMinute = deadlineMinute
        self.gracePeriodSeconds = gracePeriodSeconds
        self.reminderOffsetSeconds = reminderOffsetSeconds
        self.contactName = contactName
        self.contactPhone = contactPhone
        self.hasCompletedSetup = hasCompletedSetup
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
