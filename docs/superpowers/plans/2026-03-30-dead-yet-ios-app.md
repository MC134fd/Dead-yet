# Dead-Yet iOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Dead-Yet iOS app — a daily proof-of-life check-in app with countdown timer, emergency contact setup, local notifications, streak tracking, and a dark/minimal UI.

**Architecture:** SwiftUI app targeting iOS 17+, structured as a Swift Package for testability. Local-first data with SwiftData for persistence. State machine drives all UI. Firebase/backend integration is a separate plan — this plan stubs the sync layer with a protocol so the app is fully functional offline.

**Tech Stack:** Swift 6.2, SwiftUI, SwiftData, UNUserNotificationCenter, Swift Package Manager. Custom fonts: Space Grotesk Bold, Inter Regular/Medium.

**Environment note:** No Xcode IDE is installed (only Command Line Tools + SPM). All code is built and tested via `swift build` / `swift test`. The Xcode project wrapper (for device builds, asset catalogs, entitlements) will be created when Xcode is available. This plan builds all logic, models, and views as a testable Swift package.

---

## File Structure

```
DeadYet/
├── Package.swift
├── Sources/
│   └── DeadYet/
│       ├── App/
│       │   └── DeadYetApp.swift              # App entry point, setup flow gate
│       ├── Models/
│       │   ├── CheckInRecord.swift           # SwiftData model for a single check-in
│       │   ├── UserSettings.swift            # SwiftData model for user config (deadline, grace, contact)
│       │   ├── EmergencyContact.swift        # Codable struct (name + phone), embedded in UserSettings
│       │   ├── AppState.swift                # Enum: safe/dueSoon/overdue/escalationPending/escalated
│       │   └── GracePeriod.swift             # Enum for grace period options (30m/1h/2h/4h)
│       ├── State/
│       │   ├── CheckInEngine.swift           # Pure logic: state computation from time + last check-in + deadline
│       │   └── StreakCalculator.swift         # Pure logic: streak/total/missed from [CheckInRecord]
│       ├── Services/
│       │   ├── NotificationService.swift     # Schedule/cancel local notifications
│       │   └── BackendSyncProtocol.swift     # Protocol for future Firebase sync (stubbed)
│       ├── Theme/
│       │   ├── DeadYetColors.swift           # Color palette constants
│       │   ├── DeadYetFonts.swift            # Font definitions (Space Grotesk, Inter)
│       │   └── DeadYetStyle.swift            # Shared modifiers, button styles
│       └── Views/
│           ├── SetupView.swift               # First-launch: time picker + optional contact
│           ├── HomeView.swift                # Main screen: button, countdown, status, streak
│           ├── HomeViewModel.swift           # Timer-driven state updates for HomeView
│           ├── SettingsView.swift            # Modal: contact, deadline, grace period, reminders
│           ├── HistoryView.swift             # Modal: stats + 30-day list
│           └── Components/
│               ├── AliveButton.swift         # The big green "I'M ALIVE" button
│               ├── CountdownDisplay.swift    # HH:MM:SS countdown with color shifting
│               ├── StatusBanner.swift        # Contextual banner (no contact, overdue, escalated)
│               └── HistoryRow.swift          # Single row in history list
├── Tests/
│   └── DeadYetTests/
│       ├── CheckInEngineTests.swift          # State machine logic tests
│       ├── StreakCalculatorTests.swift        # Streak/total/missed calculation tests
│       └── EmergencyContactTests.swift       # Phone validation tests
```

---

## Task 1: Swift Package Setup

**Files:**
- Create: `DeadYet/Package.swift`
- Create: `DeadYet/Sources/DeadYet/App/DeadYetApp.swift`
- Create: `DeadYet/Tests/DeadYetTests/PlaceholderTest.swift`

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DeadYet",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DeadYet",
            path: "Sources/DeadYet"
        ),
        .testTarget(
            name: "DeadYetTests",
            dependencies: ["DeadYet"],
            path: "Tests/DeadYetTests"
        ),
    ]
)
```

Note: `macOS(.v14)` included so `swift build` and `swift test` work on this machine without Xcode/simulator. SwiftUI views won't render but all logic compiles and tests run.

- [ ] **Step 2: Create minimal app entry point**

```swift
// Sources/DeadYet/App/DeadYetApp.swift
import SwiftUI

@main
struct DeadYetApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Dead Yet?")
        }
    }
}
```

- [ ] **Step 3: Create placeholder test**

```swift
// Tests/DeadYetTests/PlaceholderTest.swift
import Testing

@Test func packageBuilds() {
    #expect(true)
}
```

- [ ] **Step 4: Verify build and tests pass**

Run from `DeadYet/` directory:
```bash
swift build
swift test
```
Expected: Both succeed.

- [ ] **Step 5: Commit**

```bash
git add DeadYet/
git commit -m "feat: initialize Swift package for Dead-Yet iOS app"
```

---

## Task 2: Core Models

**Files:**
- Create: `DeadYet/Sources/DeadYet/Models/AppState.swift`
- Create: `DeadYet/Sources/DeadYet/Models/GracePeriod.swift`
- Create: `DeadYet/Sources/DeadYet/Models/EmergencyContact.swift`
- Create: `DeadYet/Sources/DeadYet/Models/CheckInRecord.swift`
- Create: `DeadYet/Sources/DeadYet/Models/UserSettings.swift`

- [ ] **Step 1: Create AppState enum**

```swift
// Sources/DeadYet/Models/AppState.swift
import Foundation

enum AppState: String, Sendable {
    case safe
    case dueSoon
    case overdue
    case escalationPending
    case escalated
}
```

- [ ] **Step 2: Create GracePeriod enum**

```swift
// Sources/DeadYet/Models/GracePeriod.swift
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
```

- [ ] **Step 3: Create EmergencyContact**

```swift
// Sources/DeadYet/Models/EmergencyContact.swift
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
```

- [ ] **Step 4: Create CheckInRecord**

```swift
// Sources/DeadYet/Models/CheckInRecord.swift
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
    var status: String // CheckInStatus rawValue
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
```

- [ ] **Step 5: Create UserSettings**

```swift
// Sources/DeadYet/Models/UserSettings.swift
import Foundation
import SwiftData

@Model
final class UserSettings {
    var deadlineHour: Int
    var deadlineMinute: Int
    var gracePeriodSeconds: Int
    var reminderOffsetSeconds: Int // seconds before deadline; -1 means off
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
```

- [ ] **Step 6: Verify build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 7: Commit**

```bash
git add DeadYet/Sources/DeadYet/Models/
git commit -m "feat: add core models — AppState, GracePeriod, EmergencyContact, CheckInRecord, UserSettings"
```

---

## Task 3: CheckInEngine (State Machine)

**Files:**
- Create: `DeadYet/Sources/DeadYet/State/CheckInEngine.swift`
- Create: `DeadYet/Tests/DeadYetTests/CheckInEngineTests.swift`
- Delete: `DeadYet/Tests/DeadYetTests/PlaceholderTest.swift`

- [ ] **Step 1: Write failing tests for CheckInEngine**

```swift
// Tests/DeadYetTests/CheckInEngineTests.swift
import Testing
import Foundation
@testable import DeadYet

struct CheckInEngineTests {
    // Helper: create a date at specific hour:minute today
    private func todayAt(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(
            bySettingHour: hour, minute: minute, second: 0, of: Date.now
        )!
    }

    @Test func safeAfterCheckIn() {
        let now = todayAt(hour: 8)
        let deadline = todayAt(hour: 10)
        let lastCheckIn = todayAt(hour: 7, minute: 30)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: lastCheckIn,
            gracePeriod: .twoHours,
            escalatedAt: nil
        )
        #expect(state == .safe)
    }

    @Test func dueSoonWithinOneHour() {
        let now = todayAt(hour: 9, minute: 15)
        let deadline = todayAt(hour: 10)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: nil,
            gracePeriod: .twoHours,
            escalatedAt: nil
        )
        #expect(state == .dueSoon)
    }

    @Test func overdueAfterDeadline() {
        let now = todayAt(hour: 10, minute: 30)
        let deadline = todayAt(hour: 10)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: nil,
            gracePeriod: .twoHours,
            escalatedAt: nil
        )
        #expect(state == .overdue)
    }

    @Test func escalationPendingAfterGracePeriod() {
        let now = todayAt(hour: 12, minute: 1)
        let deadline = todayAt(hour: 10)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: nil,
            gracePeriod: .twoHours,
            escalatedAt: nil
        )
        #expect(state == .escalationPending)
    }

    @Test func escalatedWhenSmsWasSent() {
        let now = todayAt(hour: 13)
        let deadline = todayAt(hour: 10)
        let escalatedAt = todayAt(hour: 12, minute: 5)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: nil,
            gracePeriod: .twoHours,
            escalatedAt: escalatedAt
        )
        #expect(state == .escalated)
    }

    @Test func safeBeforeDueSoonWindow() {
        let now = todayAt(hour: 6)
        let deadline = todayAt(hour: 10)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: nil,
            gracePeriod: .twoHours,
            escalatedAt: nil
        )
        #expect(state == .safe)
    }

    @Test func checkInDuringGracePeriodReturnsSafe() {
        let now = todayAt(hour: 11)
        let deadline = todayAt(hour: 10)
        let lastCheckIn = todayAt(hour: 10, minute: 45)

        let state = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: lastCheckIn,
            gracePeriod: .twoHours,
            escalatedAt: nil
        )
        #expect(state == .safe)
    }

    @Test func nextDeadlineCalculation() {
        let now = todayAt(hour: 8)
        let deadline = CheckInEngine.nextDeadline(
            from: now, hour: 10, minute: 0
        )
        #expect(Calendar.current.component(.hour, from: deadline) == 10)
        #expect(Calendar.current.component(.minute, from: deadline) == 0)
        #expect(deadline > now)
    }

    @Test func nextDeadlineWrapsToTomorrowIfPast() {
        let now = todayAt(hour: 14)
        let deadline = CheckInEngine.nextDeadline(
            from: now, hour: 10, minute: 0
        )
        #expect(deadline > now)

        let dayDiff = Calendar.current.dateComponents(
            [.day], from: now, to: deadline
        ).day!
        #expect(dayDiff == 0 || dayDiff == 1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
swift test
```
Expected: Compilation error — `CheckInEngine` does not exist.

- [ ] **Step 3: Implement CheckInEngine**

```swift
// Sources/DeadYet/State/CheckInEngine.swift
import Foundation

enum CheckInEngine {
    /// Compute current app state from the given inputs.
    /// All parameters are explicit — no global state, fully testable.
    static func computeState(
        now: Date,
        deadline: Date,
        lastCheckIn: Date?,
        gracePeriod: GracePeriod,
        escalatedAt: Date?
    ) -> AppState {
        // If already escalated this cycle, stay escalated
        if let escalatedAt, escalatedAt > deadline {
            // Check if user checked in after escalation
            if let lastCheckIn, lastCheckIn > escalatedAt {
                return .safe
            }
            return .escalated
        }

        // If user checked in after the most recent deadline reset point,
        // they're safe for this cycle
        let cycleStart = previousDeadline(before: deadline)
        if let lastCheckIn, lastCheckIn > cycleStart {
            return .safe
        }

        // Time-based transitions
        let timeToDeadline = deadline.timeIntervalSince(now)
        let graceEnd = deadline.addingTimeInterval(gracePeriod.timeInterval)

        if now >= graceEnd {
            return .escalationPending
        } else if now >= deadline {
            return .overdue
        } else if timeToDeadline <= 3600 { // 1 hour
            return .dueSoon
        } else {
            return .safe
        }
    }

    /// Calculate the next deadline date from `now` given hour and minute.
    /// If the deadline time today has already passed, returns tomorrow's deadline.
    static func nextDeadline(from now: Date, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents(
            [.year, .month, .day], from: now
        )
        components.hour = hour
        components.minute = minute
        components.second = 0

        let todayDeadline = calendar.date(from: components)!

        if todayDeadline > now {
            return todayDeadline
        }
        return calendar.date(byAdding: .day, value: 1, to: todayDeadline)!
    }

    /// Get the deadline that just passed (for determining the current cycle).
    private static func previousDeadline(before deadline: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: -1, to: deadline)!
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
swift test
```
Expected: All 9 tests pass.

- [ ] **Step 5: Delete placeholder test and commit**

Delete `Tests/DeadYetTests/PlaceholderTest.swift`.

```bash
git add DeadYet/Sources/DeadYet/State/ DeadYet/Tests/
git rm DeadYet/Tests/DeadYetTests/PlaceholderTest.swift
git commit -m "feat: add CheckInEngine state machine with tests"
```

---

## Task 4: StreakCalculator

**Files:**
- Create: `DeadYet/Sources/DeadYet/State/StreakCalculator.swift`
- Create: `DeadYet/Tests/DeadYetTests/StreakCalculatorTests.swift`

- [ ] **Step 1: Write failing tests**

```swift
// Tests/DeadYetTests/StreakCalculatorTests.swift
import Testing
import Foundation
@testable import DeadYet

struct StreakCalculatorTests {
    private func makeRecord(
        daysAgo: Int, status: CheckInStatus
    ) -> CheckInRecord {
        let date = Calendar.current.date(
            byAdding: .day, value: -daysAgo, to: Date.now
        )!
        return CheckInRecord(
            date: date,
            status: status,
            checkInTime: status == .checkedIn ? date : nil
        )
    }

    @Test func emptyRecords() {
        let stats = StreakCalculator.compute(records: [])
        #expect(stats.currentStreak == 0)
        #expect(stats.totalCheckIns == 0)
        #expect(stats.missedDays == 0)
    }

    @Test func consecutiveStreak() {
        let records = [
            makeRecord(daysAgo: 0, status: .checkedIn),
            makeRecord(daysAgo: 1, status: .checkedIn),
            makeRecord(daysAgo: 2, status: .checkedIn),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 3)
        #expect(stats.totalCheckIns == 3)
        #expect(stats.missedDays == 0)
    }

    @Test func streakResetsOnMiss() {
        let records = [
            makeRecord(daysAgo: 0, status: .checkedIn),
            makeRecord(daysAgo: 1, status: .missed),
            makeRecord(daysAgo: 2, status: .checkedIn),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 1)
        #expect(stats.totalCheckIns == 2)
        #expect(stats.missedDays == 1)
    }

    @Test func escalatedCountsAsMissed() {
        let records = [
            makeRecord(daysAgo: 0, status: .checkedIn),
            makeRecord(daysAgo: 1, status: .escalated),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 1)
        #expect(stats.totalCheckIns == 1)
        #expect(stats.missedDays == 1)
    }

    @Test func allMissed() {
        let records = [
            makeRecord(daysAgo: 0, status: .missed),
            makeRecord(daysAgo: 1, status: .missed),
        ]
        let stats = StreakCalculator.compute(records: records)
        #expect(stats.currentStreak == 0)
        #expect(stats.totalCheckIns == 0)
        #expect(stats.missedDays == 2)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
swift test
```
Expected: Compilation error — `StreakCalculator` does not exist.

- [ ] **Step 3: Implement StreakCalculator**

```swift
// Sources/DeadYet/State/StreakCalculator.swift
import Foundation

struct StreakStats: Equatable, Sendable {
    let currentStreak: Int
    let totalCheckIns: Int
    let missedDays: Int
}

enum StreakCalculator {
    static func compute(records: [CheckInRecord]) -> StreakStats {
        guard !records.isEmpty else {
            return StreakStats(currentStreak: 0, totalCheckIns: 0, missedDays: 0)
        }

        // Sort by date descending (most recent first)
        let sorted = records.sorted { $0.date > $1.date }

        var currentStreak = 0
        var totalCheckIns = 0
        var missedDays = 0
        var streakBroken = false

        for record in sorted {
            let status = record.checkInStatus
            switch status {
            case .checkedIn:
                totalCheckIns += 1
                if !streakBroken {
                    currentStreak += 1
                }
            case .missed, .escalated:
                missedDays += 1
                streakBroken = true
            }
        }

        return StreakStats(
            currentStreak: currentStreak,
            totalCheckIns: totalCheckIns,
            missedDays: missedDays
        )
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
swift test
```
Expected: All tests pass (CheckInEngine + StreakCalculator).

- [ ] **Step 5: Commit**

```bash
git add DeadYet/Sources/DeadYet/State/StreakCalculator.swift DeadYet/Tests/DeadYetTests/StreakCalculatorTests.swift
git commit -m "feat: add StreakCalculator with tests"
```

---

## Task 5: EmergencyContact Validation Tests

**Files:**
- Create: `DeadYet/Tests/DeadYetTests/EmergencyContactTests.swift`

- [ ] **Step 1: Write tests**

```swift
// Tests/DeadYetTests/EmergencyContactTests.swift
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
        // (555) 123-4567 has 10 digits
        let contact = EmergencyContact(name: "Mom", phone: "(555) 123-4567")
        #expect(contact.isValid)
    }

    @Test func internationalPhoneIsValid() {
        let contact = EmergencyContact(name: "Mom", phone: "+44 7911 123456")
        #expect(contact.isValid)
    }
}
```

- [ ] **Step 2: Run tests**

```bash
swift test
```
Expected: All pass (existing + new).

- [ ] **Step 3: Commit**

```bash
git add DeadYet/Tests/DeadYetTests/EmergencyContactTests.swift
git commit -m "test: add EmergencyContact validation tests"
```

---

## Task 6: Theme System

**Files:**
- Create: `DeadYet/Sources/DeadYet/Theme/DeadYetColors.swift`
- Create: `DeadYet/Sources/DeadYet/Theme/DeadYetFonts.swift`
- Create: `DeadYet/Sources/DeadYet/Theme/DeadYetStyle.swift`

- [ ] **Step 1: Create color palette**

```swift
// Sources/DeadYet/Theme/DeadYetColors.swift
import SwiftUI

enum DeadYetColors {
    static let background = Color(red: 0, green: 0, blue: 0)                    // #000000
    static let primaryText = Color(red: 0.91, green: 0.91, blue: 0.89)          // #E8E8E3
    static let accent = Color(red: 0.667, green: 1.0, blue: 0.0)               // #AAFF00
    static let danger = Color(red: 1.0, green: 0.231, blue: 0.188)             // #FF3B30
    static let warning = Color(red: 1.0, green: 0.839, blue: 0.039)            // #FFD60A

    /// Returns the countdown color based on fraction of time remaining (1.0 = full, 0.0 = deadline).
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
```

- [ ] **Step 2: Create font definitions**

Note: In the SPM-only build, custom fonts can't be loaded from a bundle yet (no asset catalog). We define the font names so they're ready when the Xcode project wraps this package. Fall back to system monospaced for now.

```swift
// Sources/DeadYet/Theme/DeadYetFonts.swift
import SwiftUI

enum DeadYetFonts {
    // Custom font names — will resolve when fonts are embedded in Xcode project.
    // Falls back to system equivalents when custom font is not available.

    static func hero(size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Bold", size: size, relativeTo: .largeTitle)
    }

    static func body(size: CGFloat) -> Font {
        .custom("Inter-Regular", size: size, relativeTo: .body)
    }

    static func bodyMedium(size: CGFloat) -> Font {
        .custom("Inter-Medium", size: size, relativeTo: .body)
    }

    /// Monospaced figures for countdown digits.
    static func countdown(size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Bold", size: size, relativeTo: .largeTitle)
            .monospacedDigit()
    }
}
```

- [ ] **Step 3: Create shared styles**

```swift
// Sources/DeadYet/Theme/DeadYetStyle.swift
import SwiftUI

struct AliveButtonStyle: ButtonStyle {
    let isCheckedIn: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DeadYetFonts.hero(size: 24))
            .tracking(3)
            .foregroundStyle(DeadYetColors.background)
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
            .background(
                isCheckedIn
                    ? DeadYetColors.accent.opacity(0.3)
                    : DeadYetColors.accent
            )
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func deadYetBackground() -> some View {
        self.background(DeadYetColors.background)
    }
}
```

- [ ] **Step 4: Verify build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 5: Commit**

```bash
git add DeadYet/Sources/DeadYet/Theme/
git commit -m "feat: add theme system — colors, fonts, button style"
```

---

## Task 7: Backend Sync Protocol (Stub)

**Files:**
- Create: `DeadYet/Sources/DeadYet/Services/BackendSyncProtocol.swift`

- [ ] **Step 1: Create protocol and stub**

```swift
// Sources/DeadYet/Services/BackendSyncProtocol.swift
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

/// Offline stub — used until Firebase backend plan is implemented.
struct OfflineSyncService: BackendSyncService {
    func syncCheckIn(at time: Date) async throws {
        // No-op: local only
    }

    func syncSettings(
        deadlineHour: Int,
        deadlineMinute: Int,
        gracePeriodSeconds: Int,
        timezone: String,
        contact: EmergencyContact?
    ) async throws {
        // No-op: local only
    }

    func fetchEscalationStatus() async throws -> EscalationStatus {
        EscalationStatus(escalatedAt: nil, smsSent: false)
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 3: Commit**

```bash
git add DeadYet/Sources/DeadYet/Services/BackendSyncProtocol.swift
git commit -m "feat: add BackendSyncService protocol with offline stub"
```

---

## Task 8: NotificationService

**Files:**
- Create: `DeadYet/Sources/DeadYet/Services/NotificationService.swift`

- [ ] **Step 1: Implement NotificationService**

```swift
// Sources/DeadYet/Services/NotificationService.swift
import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

enum NotificationService {
    private static let dailyReminderId = "deadyet.reminder.daily"
    private static let deadlineId = "deadyet.reminder.deadline"
    private static let overduePrefix = "deadyet.overdue."
    private static let escalatedId = "deadyet.escalated"

    static func requestPermission() async -> Bool {
        #if canImport(UserNotifications)
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    /// Schedule all notifications for the current cycle.
    /// Call this after check-in state changes or settings change.
    static func scheduleAll(
        deadline: Date,
        gracePeriodSeconds: Int,
        reminderOffsetSeconds: Int
    ) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        // Clear existing
        center.removeAllPendingNotificationRequests()

        // Daily reminder (if not off)
        if reminderOffsetSeconds > 0 {
            let reminderDate = deadline.addingTimeInterval(
                -TimeInterval(reminderOffsetSeconds)
            )
            scheduleNotification(
                id: dailyReminderId,
                body: "You haven't checked in today.",
                at: reminderDate
            )
        }

        // Deadline notification
        scheduleNotification(
            id: deadlineId,
            body: "Deadline passed. Check in now.",
            at: deadline
        )

        // Overdue warnings during grace period (every 15 min)
        let gracePeriod = TimeInterval(gracePeriodSeconds)
        let overdueMessages: [(offset: TimeInterval, body: String)] = {
            let total = gracePeriod
            var messages: [(TimeInterval, String)] = []
            // Every 15 minutes
            var elapsed: TimeInterval = 900 // 15 min
            while elapsed < total {
                let remaining = total - elapsed
                let mins = Int(remaining) / 60
                let hours = mins / 60
                let remMins = mins % 60
                let body: String
                if hours > 0 && remMins > 0 {
                    body = "\(hours)h \(remMins)m until your emergency contact is notified."
                } else if hours > 0 {
                    body = "\(hours)h until your emergency contact is notified."
                } else {
                    body = "\(mins) minutes."
                }
                messages.append((elapsed, body))
                elapsed += 900
            }
            return messages
        }()

        for (index, msg) in overdueMessages.enumerated() {
            let fireDate = deadline.addingTimeInterval(msg.offset)
            scheduleNotification(
                id: "\(overduePrefix)\(index)",
                body: msg.body,
                at: fireDate
            )
        }

        // Escalation notification (at grace period end)
        scheduleNotification(
            id: escalatedId,
            body: "Your emergency contact has been notified.",
            at: deadline.addingTimeInterval(gracePeriod)
        )
        #endif
    }

    /// Cancel all scheduled notifications (e.g., after check-in).
    static func cancelAll() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
        #endif
    }

    private static func scheduleNotification(
        id: String, body: String, at date: Date
    ) {
        #if canImport(UserNotifications)
        guard date > Date.now else { return }

        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: date
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components, repeats: false
        )
        let request = UNNotificationRequest(
            identifier: id, content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
        #endif
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: Succeeds (UserNotifications available on macOS too).

- [ ] **Step 3: Commit**

```bash
git add DeadYet/Sources/DeadYet/Services/NotificationService.swift
git commit -m "feat: add NotificationService for local notification scheduling"
```

---

## Task 9: UI Components

**Files:**
- Create: `DeadYet/Sources/DeadYet/Views/Components/AliveButton.swift`
- Create: `DeadYet/Sources/DeadYet/Views/Components/CountdownDisplay.swift`
- Create: `DeadYet/Sources/DeadYet/Views/Components/StatusBanner.swift`
- Create: `DeadYet/Sources/DeadYet/Views/Components/HistoryRow.swift`

- [ ] **Step 1: Create AliveButton**

```swift
// Sources/DeadYet/Views/Components/AliveButton.swift
import SwiftUI

struct AliveButton: View {
    let isCheckedIn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(isCheckedIn ? "ALIVE" : "I'M ALIVE")
        }
        .buttonStyle(AliveButtonStyle(isCheckedIn: isCheckedIn))
        .disabled(isCheckedIn)
        .sensoryFeedback(.impact(weight: .medium), trigger: isCheckedIn)
    }
}
```

- [ ] **Step 2: Create CountdownDisplay**

```swift
// Sources/DeadYet/Views/Components/CountdownDisplay.swift
import SwiftUI

struct CountdownDisplay: View {
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval

    private var fractionRemaining: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalDuration))
    }

    private var formattedTime: String {
        let total = max(0, Int(timeRemaining))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(formattedTime)
                .font(DeadYetFonts.countdown(size: 56))
                .tracking(2)
                .foregroundStyle(
                    DeadYetColors.countdownColor(
                        fractionRemaining: fractionRemaining
                    )
                )
            Text("until deadline")
                .font(DeadYetFonts.body(size: 13))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.5))
        }
    }
}
```

- [ ] **Step 3: Create StatusBanner**

```swift
// Sources/DeadYet/Views/Components/StatusBanner.swift
import SwiftUI

struct StatusBanner: View {
    let state: AppState
    let contactName: String?
    let escalatedTime: String?
    let hasContact: Bool

    var body: some View {
        Group {
            if !hasContact {
                bannerView(
                    text: "Nobody knows you're alive yet",
                    color: DeadYetColors.warning
                )
            } else {
                switch state {
                case .safe:
                    EmptyView()
                case .dueSoon:
                    EmptyView()
                case .overdue:
                    bannerView(
                        text: "You haven't confirmed you're alive",
                        color: DeadYetColors.danger
                    )
                case .escalationPending:
                    bannerView(
                        text: "Your emergency contact will be alerted",
                        color: DeadYetColors.danger
                    )
                case .escalated:
                    VStack(spacing: 2) {
                        bannerView(
                            text: "Your emergency contact was notified",
                            color: DeadYetColors.danger
                        )
                        if let contactName, let escalatedTime {
                            Text("\(contactName) was texted at \(escalatedTime)")
                                .font(DeadYetFonts.body(size: 12))
                                .foregroundStyle(
                                    DeadYetColors.primaryText.opacity(0.5)
                                )
                        }
                    }
                }
            }
        }
    }

    private func bannerView(text: String, color: Color) -> some View {
        Text(text)
            .font(DeadYetFonts.bodyMedium(size: 14))
            .foregroundStyle(color)
    }
}
```

- [ ] **Step 4: Create HistoryRow**

```swift
// Sources/DeadYet/Views/Components/HistoryRow.swift
import SwiftUI

struct HistoryRow: View {
    let record: CheckInRecord

    private var indicatorColor: Color {
        switch record.checkInStatus {
        case .checkedIn: DeadYetColors.accent
        case .missed: DeadYetColors.warning
        case .escalated: DeadYetColors.danger
        }
    }

    private var statusText: String {
        switch record.checkInStatus {
        case .checkedIn:
            if let time = record.checkInTime {
                return time.formatted(date: .omitted, time: .shortened)
            }
            return "Checked in"
        case .missed:
            return "Missed"
        case .escalated:
            return "Missed — contact notified"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 8, height: 8)

            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                .font(DeadYetFonts.body(size: 14))
                .foregroundStyle(DeadYetColors.primaryText)

            Spacer()

            Text(statusText)
                .font(DeadYetFonts.body(size: 14))
                .foregroundStyle(
                    record.checkInStatus == .checkedIn
                        ? DeadYetColors.primaryText.opacity(0.6)
                        : indicatorColor
                )
        }
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 5: Verify build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 6: Commit**

```bash
git add DeadYet/Sources/DeadYet/Views/Components/
git commit -m "feat: add UI components — AliveButton, CountdownDisplay, StatusBanner, HistoryRow"
```

---

## Task 10: SetupView (First Launch)

**Files:**
- Create: `DeadYet/Sources/DeadYet/Views/SetupView.swift`

- [ ] **Step 1: Implement SetupView**

```swift
// Sources/DeadYet/Views/SetupView.swift
import SwiftUI

struct SetupView: View {
    @Binding var deadlineHour: Int
    @Binding var deadlineMinute: Int
    @Binding var contactName: String
    @Binding var contactPhone: String
    let onComplete: () -> Void

    @State private var selectedTime = Calendar.current.date(
        bySettingHour: 10, minute: 0, second: 0, of: .now
    )!

    var body: some View {
        ZStack {
            DeadYetColors.background.ignoresSafeArea()

            VStack(spacing: 48) {
                Spacer()

                // Deadline picker
                VStack(spacing: 12) {
                    Text("When should we check\nif you're alive?")
                        .font(DeadYetFonts.bodyMedium(size: 18))
                        .foregroundStyle(DeadYetColors.primaryText)
                        .multilineTextAlignment(.center)

                    DatePicker(
                        "",
                        selection: $selectedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: 200)
                    .onChange(of: selectedTime) { _, newValue in
                        let components = Calendar.current.dateComponents(
                            [.hour, .minute], from: newValue
                        )
                        deadlineHour = components.hour ?? 10
                        deadlineMinute = (components.minute ?? 0) / 15 * 15
                    }
                }

                // Optional contact
                VStack(spacing: 12) {
                    Text("Who should we tell?")
                        .font(DeadYetFonts.bodyMedium(size: 18))
                        .foregroundStyle(DeadYetColors.primaryText)

                    VStack(spacing: 8) {
                        TextField("Name", text: $contactName)
                            .textFieldStyle(.plain)
                            .font(DeadYetFonts.body(size: 16))
                            .foregroundStyle(DeadYetColors.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        DeadYetColors.primaryText.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )

                        TextField("Phone number", text: $contactPhone)
                            .textFieldStyle(.plain)
                            .font(DeadYetFonts.body(size: 16))
                            .foregroundStyle(DeadYetColors.primaryText)
                            .keyboardType(.phonePad)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(
                                        DeadYetColors.primaryText.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                // GET STARTED button
                Button(action: onComplete) {
                    Text("GET STARTED")
                        .font(DeadYetFonts.hero(size: 18))
                        .tracking(3)
                        .foregroundStyle(DeadYetColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(DeadYetColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 3: Commit**

```bash
git add DeadYet/Sources/DeadYet/Views/SetupView.swift
git commit -m "feat: add SetupView — first-launch time picker and optional contact"
```

---

## Task 11: HomeViewModel

**Files:**
- Create: `DeadYet/Sources/DeadYet/Views/HomeViewModel.swift`

- [ ] **Step 1: Implement HomeViewModel**

```swift
// Sources/DeadYet/Views/HomeViewModel.swift
import SwiftUI
import SwiftData
import Combine

@Observable
@MainActor
final class HomeViewModel {
    var appState: AppState = .safe
    var timeRemaining: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var isCheckedIn: Bool = false
    var lastCheckInText: String = "No check-ins yet"
    var deadlineText: String = ""
    var streakCount: Int = 0
    var contactName: String?
    var escalatedTime: String?
    var hasContact: Bool = false

    private var timer: Timer?
    private var modelContext: ModelContext?
    private let syncService: BackendSyncService

    init(syncService: BackendSyncService = OfflineSyncService()) {
        self.syncService = syncService
    }

    func start(modelContext: ModelContext) {
        self.modelContext = modelContext
        startTimer()
        updateState()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func checkIn() {
        guard let modelContext, !isCheckedIn else { return }

        let now = Date.now
        let record = CheckInRecord(
            date: now, status: .checkedIn, checkInTime: now
        )
        modelContext.insert(record)
        try? modelContext.save()

        isCheckedIn = true

        // Cancel overdue notifications
        NotificationService.cancelAll()

        // Reschedule for next cycle
        if let settings = fetchSettings() {
            let nextDeadline = CheckInEngine.nextDeadline(
                from: now,
                hour: settings.deadlineHour,
                minute: settings.deadlineMinute
            )
            NotificationService.scheduleAll(
                deadline: nextDeadline,
                gracePeriodSeconds: settings.gracePeriodSeconds,
                reminderOffsetSeconds: settings.reminderOffsetSeconds
            )
        }

        // Fire-and-forget sync
        Task {
            try? await syncService.syncCheckIn(at: now)
        }

        updateState()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0, repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateState()
            }
        }
    }

    func updateState() {
        guard let settings = fetchSettings() else { return }

        let now = Date.now
        let deadline = CheckInEngine.nextDeadline(
            from: Calendar.current.startOfDay(for: now),
            hour: settings.deadlineHour,
            minute: settings.deadlineMinute
        )

        // Find today's check-in
        let todayStart = Calendar.current.startOfDay(for: now)
        let lastCheckIn = fetchLastCheckIn(since: todayStart)

        // Update checked-in state
        if let lastCheckIn {
            isCheckedIn = lastCheckIn.checkInTime != nil
                && lastCheckIn.checkInStatus == .checkedIn
        } else {
            isCheckedIn = false
        }

        // Compute state
        appState = CheckInEngine.computeState(
            now: now,
            deadline: deadline,
            lastCheckIn: lastCheckIn?.checkInTime,
            gracePeriod: settings.gracePeriod,
            escalatedAt: nil // TODO: fetch from backend
        )

        // Update countdown
        let nextDeadline: Date
        if now > deadline {
            nextDeadline = CheckInEngine.nextDeadline(
                from: now,
                hour: settings.deadlineHour,
                minute: settings.deadlineMinute
            )
        } else {
            nextDeadline = deadline
        }
        timeRemaining = max(0, nextDeadline.timeIntervalSince(now))
        totalDuration = 24 * 3600 // Full day cycle

        // Format texts
        deadlineText = "Due by: \(nextDeadline.formatted(date: .omitted, time: .shortened))"

        if let checkInTime = lastCheckIn?.checkInTime {
            lastCheckInText = "Last: \(checkInTime.formatted(date: .abbreviated, time: .shortened))"
        } else {
            lastCheckInText = "No check-ins yet"
        }

        // Contact
        hasContact = settings.emergencyContact != nil
        contactName = settings.contactName

        // Streak
        let records = fetchAllRecords()
        streakCount = StreakCalculator.compute(records: records).currentStreak
    }

    private func fetchSettings() -> UserSettings? {
        guard let modelContext else { return nil }
        let descriptor = FetchDescriptor<UserSettings>()
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchLastCheckIn(since date: Date) -> CheckInRecord? {
        guard let modelContext else { return nil }
        var descriptor = FetchDescriptor<CheckInRecord>(
            predicate: #Predicate { $0.date >= date },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchAllRecords() -> [CheckInRecord] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<CheckInRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 3: Commit**

```bash
git add DeadYet/Sources/DeadYet/Views/HomeViewModel.swift
git commit -m "feat: add HomeViewModel — timer-driven state updates"
```

---

## Task 12: HomeView

**Files:**
- Create: `DeadYet/Sources/DeadYet/Views/HomeView.swift`

- [ ] **Step 1: Implement HomeView**

```swift
// Sources/DeadYet/Views/HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HomeViewModel()
    @State private var showSettings = false
    @State private var showHistory = false

    var body: some View {
        ZStack {
            DeadYetColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with settings and history icons
                HStack {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                DeadYetColors.primaryText.opacity(0.5)
                            )
                    }
                    Spacer()
                    Button(action: { showHistory = true }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                DeadYetColors.primaryText.opacity(0.5)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Status banner
                StatusBanner(
                    state: viewModel.appState,
                    contactName: viewModel.contactName,
                    escalatedTime: viewModel.escalatedTime,
                    hasContact: viewModel.hasContact
                )
                .padding(.bottom, 32)

                // Countdown
                if !viewModel.isCheckedIn {
                    CountdownDisplay(
                        timeRemaining: viewModel.timeRemaining,
                        totalDuration: viewModel.totalDuration
                    )
                    .padding(.bottom, 48)
                }

                // The button
                AliveButton(
                    isCheckedIn: viewModel.isCheckedIn,
                    action: { viewModel.checkIn() }
                )

                if viewModel.isCheckedIn {
                    Text("You're good for today")
                        .font(DeadYetFonts.body(size: 14))
                        .foregroundStyle(
                            DeadYetColors.primaryText.opacity(0.4)
                        )
                        .padding(.top, 16)
                }

                Spacer()

                // Bottom info
                VStack(spacing: 8) {
                    Text(viewModel.lastCheckInText)
                        .font(DeadYetFonts.body(size: 13))
                        .foregroundStyle(
                            DeadYetColors.primaryText.opacity(0.4)
                        )

                    Text(viewModel.deadlineText)
                        .font(DeadYetFonts.body(size: 13))
                        .foregroundStyle(
                            DeadYetColors.primaryText.opacity(0.4)
                        )

                    if viewModel.streakCount > 0 {
                        Text("\(viewModel.streakCount) days alive")
                            .font(DeadYetFonts.bodyMedium(size: 13))
                            .foregroundStyle(DeadYetColors.accent.opacity(0.6))
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear { viewModel.start(modelContext: modelContext) }
        .onDisappear { viewModel.stop() }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .onDisappear { viewModel.updateState() }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView()
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: Will fail because SettingsView and HistoryView don't exist yet. That's expected — they're built in the next two tasks.

- [ ] **Step 3: Commit (wait for Task 13 and 14)**

This will be committed together with SettingsView and HistoryView.

---

## Task 13: SettingsView

**Files:**
- Create: `DeadYet/Sources/DeadYet/Views/SettingsView.swift`

- [ ] **Step 1: Implement SettingsView**

```swift
// Sources/DeadYet/Views/SettingsView.swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }

    @State private var deadlineTime = Date.now
    @State private var selectedGracePeriod = GracePeriod.twoHours
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var reminderOffset = 3600 // 1 hour
    @State private var phoneError = false

    private let reminderOptions: [(String, Int)] = [
        ("30 min before", 1800),
        ("1 hour before", 3600),
        ("2 hours before", 7200),
        ("Off", -1),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DeadYetColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Deadline
                        settingsSection("Daily deadline") {
                            DatePicker(
                                "",
                                selection: $deadlineTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                        }

                        // Grace period
                        settingsSection("Grace period") {
                            Picker("", selection: $selectedGracePeriod) {
                                ForEach(
                                    GracePeriod.allCases, id: \.self
                                ) { period in
                                    Text(period.displayName).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }

                        // Reminder
                        settingsSection("Daily reminder") {
                            Picker("", selection: $reminderOffset) {
                                ForEach(
                                    reminderOptions, id: \.1
                                ) { option in
                                    Text(option.0).tag(option.1)
                                }
                            }
                            .pickerStyle(.segmented)
                            .colorScheme(.dark)
                        }

                        // Emergency contact
                        settingsSection("Emergency contact") {
                            VStack(spacing: 8) {
                                TextField("Name", text: $contactName)
                                    .textFieldStyle(.plain)
                                    .font(DeadYetFonts.body(size: 16))
                                    .foregroundStyle(DeadYetColors.primaryText)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                DeadYetColors.primaryText
                                                    .opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )

                                TextField("Phone number", text: $contactPhone)
                                    .textFieldStyle(.plain)
                                    .font(DeadYetFonts.body(size: 16))
                                    .foregroundStyle(DeadYetColors.primaryText)
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(
                                                phoneError
                                                    ? DeadYetColors.danger
                                                    : DeadYetColors.primaryText
                                                        .opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )

                                if phoneError {
                                    Text("Enter a valid phone number")
                                        .font(DeadYetFonts.body(size: 12))
                                        .foregroundStyle(DeadYetColors.danger)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .foregroundStyle(DeadYetColors.accent)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DeadYetColors.primaryText)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { loadSettings() }
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(DeadYetFonts.bodyMedium(size: 12))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                .tracking(1.5)
            content()
        }
    }

    private func loadSettings() {
        guard let settings else { return }
        var components = DateComponents()
        components.hour = settings.deadlineHour
        components.minute = settings.deadlineMinute
        deadlineTime = Calendar.current.date(from: components) ?? .now
        selectedGracePeriod = settings.gracePeriod
        contactName = settings.contactName ?? ""
        contactPhone = settings.contactPhone ?? ""
        reminderOffset = settings.reminderOffsetSeconds
    }

    private func save() {
        // Validate phone if entered
        if !contactPhone.isEmpty
            && !EmergencyContact.isValidPhone(contactPhone) {
            phoneError = true
            return
        }
        phoneError = false

        guard let settings else { return }
        let components = Calendar.current.dateComponents(
            [.hour, .minute], from: deadlineTime
        )
        settings.deadlineHour = components.hour ?? 10
        settings.deadlineMinute = (components.minute ?? 0) / 15 * 15
        settings.gracePeriodSeconds = selectedGracePeriod.rawValue
        settings.reminderOffsetSeconds = reminderOffset
        settings.contactName = contactName.isEmpty ? nil : contactName
        settings.contactPhone = contactPhone.isEmpty ? nil : contactPhone
        try? modelContext.save()
        dismiss()
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: May still fail (HistoryView needed).

---

## Task 14: HistoryView

**Files:**
- Create: `DeadYet/Sources/DeadYet/Views/HistoryView.swift`

- [ ] **Step 1: Implement HistoryView**

```swift
// Sources/DeadYet/Views/HistoryView.swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(
        sort: \CheckInRecord.date,
        order: .reverse
    ) private var allRecords: [CheckInRecord]

    private var recentRecords: [CheckInRecord] {
        let cutoff = Calendar.current.date(
            byAdding: .day, value: -30, to: .now
        )!
        return allRecords.filter { $0.date >= cutoff }
    }

    private var stats: StreakStats {
        StreakCalculator.compute(records: allRecords)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DeadYetColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Summary stats
                        HStack(spacing: 32) {
                            statBlock(
                                value: "\(stats.currentStreak)",
                                label: "STREAK"
                            )
                            statBlock(
                                value: "\(stats.totalCheckIns)",
                                label: "CHECK-INS"
                            )
                            statBlock(
                                value: "\(stats.missedDays)",
                                label: "MISSED"
                            )
                        }
                        .padding(.top, 24)

                        // Day list
                        if recentRecords.isEmpty {
                            Text("No history yet")
                                .font(DeadYetFonts.body(size: 14))
                                .foregroundStyle(
                                    DeadYetColors.primaryText.opacity(0.4)
                                )
                                .padding(.top, 48)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(recentRecords, id: \.date) { record in
                                    HistoryRow(record: record)
                                    Divider()
                                        .background(
                                            DeadYetColors.primaryText
                                                .opacity(0.1)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DeadYetColors.primaryText)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DeadYetFonts.hero(size: 28))
                .foregroundStyle(DeadYetColors.primaryText)
            Text(label)
                .font(DeadYetFonts.body(size: 11))
                .foregroundStyle(DeadYetColors.primaryText.opacity(0.4))
                .tracking(1.5)
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
swift build
```
Expected: Succeeds — all views now exist.

- [ ] **Step 3: Commit HomeView + SettingsView + HistoryView together**

```bash
git add DeadYet/Sources/DeadYet/Views/HomeView.swift DeadYet/Sources/DeadYet/Views/SettingsView.swift DeadYet/Sources/DeadYet/Views/HistoryView.swift
git commit -m "feat: add HomeView, SettingsView, HistoryView screens"
```

---

## Task 15: App Entry Point (Wire Everything Together)

**Files:**
- Modify: `DeadYet/Sources/DeadYet/App/DeadYetApp.swift`

- [ ] **Step 1: Update DeadYetApp with setup gate and SwiftData**

```swift
// Sources/DeadYet/App/DeadYetApp.swift
import SwiftUI
import SwiftData

@main
struct DeadYetApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(
            for: [UserSettings.self, CheckInRecord.self]
        )
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [UserSettings]

    private var settings: UserSettings? { allSettings.first }

    @State private var deadlineHour = 10
    @State private var deadlineMinute = 0
    @State private var contactName = ""
    @State private var contactPhone = ""

    var body: some View {
        Group {
            if let settings, settings.hasCompletedSetup {
                HomeView()
            } else {
                SetupView(
                    deadlineHour: $deadlineHour,
                    deadlineMinute: $deadlineMinute,
                    contactName: $contactName,
                    contactPhone: $contactPhone,
                    onComplete: completeSetup
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private func completeSetup() {
        let newSettings: UserSettings
        if let existing = settings {
            newSettings = existing
        } else {
            newSettings = UserSettings()
            modelContext.insert(newSettings)
        }

        newSettings.deadlineHour = deadlineHour
        newSettings.deadlineMinute = deadlineMinute / 15 * 15
        newSettings.hasCompletedSetup = true

        if !contactName.isEmpty {
            newSettings.contactName = contactName
        }
        if !contactPhone.isEmpty
            && EmergencyContact.isValidPhone(contactPhone) {
            newSettings.contactPhone = contactPhone
        }

        try? modelContext.save()

        // Request notification permission and schedule
        Task {
            await NotificationService.requestPermission()
            let deadline = CheckInEngine.nextDeadline(
                from: .now,
                hour: newSettings.deadlineHour,
                minute: newSettings.deadlineMinute
            )
            NotificationService.scheduleAll(
                deadline: deadline,
                gracePeriodSeconds: newSettings.gracePeriodSeconds,
                reminderOffsetSeconds: newSettings.reminderOffsetSeconds
            )
        }
    }
}
```

- [ ] **Step 2: Verify full build**

```bash
swift build
```
Expected: Succeeds.

- [ ] **Step 3: Run all tests**

```bash
swift test
```
Expected: All tests pass (CheckInEngine, StreakCalculator, EmergencyContact).

- [ ] **Step 4: Commit**

```bash
git add DeadYet/Sources/DeadYet/App/DeadYetApp.swift
git commit -m "feat: wire app entry point with setup gate and SwiftData"
```

---

## Task 16: Final Verification

- [ ] **Step 1: Full clean build**

```bash
cd DeadYet && swift package clean && swift build
```
Expected: Clean build succeeds.

- [ ] **Step 2: Run all tests**

```bash
swift test
```
Expected: All tests pass.

- [ ] **Step 3: Verify file structure matches plan**

```bash
find DeadYet/Sources DeadYet/Tests -name "*.swift" | sort
```

Expected output:
```
DeadYet/Sources/DeadYet/App/DeadYetApp.swift
DeadYet/Sources/DeadYet/Models/AppState.swift
DeadYet/Sources/DeadYet/Models/CheckInRecord.swift
DeadYet/Sources/DeadYet/Models/EmergencyContact.swift
DeadYet/Sources/DeadYet/Models/GracePeriod.swift
DeadYet/Sources/DeadYet/Models/UserSettings.swift
DeadYet/Sources/DeadYet/Services/BackendSyncProtocol.swift
DeadYet/Sources/DeadYet/Services/NotificationService.swift
DeadYet/Sources/DeadYet/State/CheckInEngine.swift
DeadYet/Sources/DeadYet/State/StreakCalculator.swift
DeadYet/Sources/DeadYet/Theme/DeadYetColors.swift
DeadYet/Sources/DeadYet/Theme/DeadYetFonts.swift
DeadYet/Sources/DeadYet/Theme/DeadYetStyle.swift
DeadYet/Sources/DeadYet/Views/Components/AliveButton.swift
DeadYet/Sources/DeadYet/Views/Components/CountdownDisplay.swift
DeadYet/Sources/DeadYet/Views/Components/HistoryRow.swift
DeadYet/Sources/DeadYet/Views/Components/StatusBanner.swift
DeadYet/Sources/DeadYet/Views/HistoryView.swift
DeadYet/Sources/DeadYet/Views/HomeView.swift
DeadYet/Sources/DeadYet/Views/HomeViewModel.swift
DeadYet/Sources/DeadYet/Views/SetupView.swift
DeadYet/Sources/DeadYet/Views/SettingsView.swift
DeadYet/Tests/DeadYetTests/CheckInEngineTests.swift
DeadYet/Tests/DeadYetTests/EmergencyContactTests.swift
DeadYet/Tests/DeadYetTests/StreakCalculatorTests.swift
```

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "chore: Dead-Yet iOS app V1 — all screens, state machine, tests complete"
```

---

## What This Plan Does NOT Cover (Separate Plans)

1. **Firebase Backend** — Cloud Functions, Twilio SMS integration, Firestore schema, escalation timer, Apple Sign-In backend
2. **Xcode Project Wrapper** — .xcodeproj, asset catalog (custom fonts, app icon), entitlements, Info.plist, signing
3. **Firebase iOS SDK Integration** — replacing `OfflineSyncService` with real Firestore calls
4. **Push Notifications** — APNs entitlement, Firebase Cloud Messaging setup
