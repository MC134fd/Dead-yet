import Testing
@testable import DeadYet

struct EmergencyContactTests {
    @Test func validContact() {
        let contact = EmergencyContact(name: "Mom", phone: "+1234567890")
        #expect(contact.isValid)
    }

    @Test func emptyNameIsInvalid() {
        let contact = EmergencyContact(name: "", phone: "+1234567890")
        #expect(!contact.isValid)
    }

    @Test func whitespaceOnlyNameIsInvalid() {
        let contact = EmergencyContact(name: "   ", phone: "+1234567890")
        #expect(!contact.isValid)
    }

    @Test func tooShortPhoneIsInvalid() {
        let contact = EmergencyContact(name: "Mom", phone: "12345")
        #expect(!contact.isValid)
    }

    @Test func formattedPhoneIsValid() {
        let contact = EmergencyContact(name: "Mom", phone: "(555) 123-4567")
        #expect(contact.isValid)
    }

    @Test func internationalPhoneIsValid() {
        let contact = EmergencyContact(name: "Mom", phone: "+44 7911 123456")
        #expect(contact.isValid)
    }
}
