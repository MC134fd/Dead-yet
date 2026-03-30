# Dead-Yet MVP Design Spec

## Product Summary

Dead-Yet is a daily proof-of-life app for people who live alone. One check-in per day. Miss it, and someone who cares about you gets a text.

On the surface: dark, minimal, screenshot-worthy. Underneath: a genuine safety net for the growing population of solo-living young adults who realize nobody would notice for days if something happened to them.

**What it is:** A daily check-in app with real consequences (SMS escalation to an emergency contact).

**What it is not:** A medical app, a meme joke, an elderly safety device, or a social app.

## Core User

Age 22-35, lives alone (or functionally alone), urban, digitally native. Probably moved to a new city for work. Has maybe 1-2 people they'd want notified if something happened. Downloads the app half-ironically after seeing a dark-humor screenshot on social media, then quietly keeps using it because it solves a real anxiety.

## MVP Feature Breakdown

### 1. Daily Check-In

**Purpose:** The single core action. User confirms they're alive.

**Behavior:**
- One large "I'M ALIVE" button dominates the home screen
- Tapping it records the check-in with a timestamp
- Button state changes to confirmed (acid green pulse/flash, then settles)
- Only one check-in needed per day; additional taps are a no-op or show "Already checked in"
- Resets at the user's configured deadline time

**Edge cases:**
- User opens app after already checking in: show confirmed state, no action needed
- User checks in 1 minute before deadline: still counts, resets normally
- App is force-quit or phone is off: check-in state persists locally

**Out of scope for V1:** Check-in via notification action, Apple Watch, widgets.

### 2. Countdown / Status

**Purpose:** Create tension and awareness. Show where the user stands.

**Behavior:**
- Prominent countdown showing time remaining until deadline
- Last check-in timestamp (e.g. "Last: Yesterday, 8:42 AM")
- Next deadline display (e.g. "Due by: 10:00 AM")
- Countdown color shifts as time decreases: off-white -> yellow -> red

**Edge cases:**
- First launch (no prior check-in): show "No check-ins yet" with deadline info
- Timezone changes (travel): deadlines follow device local time (see Timezone Rules below)

**Out of scope for V1:** Animated countdown ring, widget.

### 3. Setup (Emergency Contact)

**Purpose:** Define who gets alerted.

**Behavior:**
- One emergency contact: name + phone number
- Stored locally and synced to backend for SMS sending
- Editable/replaceable in settings
- Phone number validated for SMS format

**Edge cases:**
- No contact set: app works, but escalation is disabled; show persistent banner nudging setup
- Invalid phone number: validation error, don't save

**Out of scope for V1:** Multiple contacts, email, contact photo, relationship labels.

### 4. Missed Check-In Flow

**Purpose:** The consequence engine. This is what makes the app real.

**State flow:**
1. **Safe** - user checked in, countdown running
2. **Due Soon** - within 1 hour of deadline (notifications intensify)
3. **Overdue** - deadline passed, grace period active (2 hours default, configurable in settings)
4. **Escalation Pending** - grace period expired, SMS queued
5. **Escalated** - SMS sent to emergency contact

**Behavior during overdue:**
- App UI shifts to urgent state (red tones, pulsing)
- Aggressive local notifications every 15 minutes during grace period
- User can still check in during grace period to cancel escalation
- Once SMS is sent, app shows "Contact notified" state

**Edge cases:**
- Check in during grace period: cancels escalation, returns to Safe
- Check in after SMS sent: records check-in, shows "Contact was notified" for that day
- Phone is dead/off during grace period: backend handles SMS on its own timer (no device dependency)

**Post-escalation behavior:**
- When user opens app after SMS was sent:
  - Status text: "Your emergency contact was notified"
  - Subtext: "[Contact name] was texted at [time]"
  - "I'M ALIVE" button remains active
  - No visual panic (no flashing red) — the damage is done, keep it factual
- When user checks in after escalation:
  - State returns to SAFE
  - Day marked as "missed + escalated" in history
  - "Contact was notified" info persists until next deadline reset
  - No follow-up "they're OK" SMS sent to contact

**Out of scope for V1:** Snooze button, pause/vacation mode, multi-step escalation, auto follow-up SMS.

### SMS Content

**Purpose:** Define the message the emergency contact receives.

**SMS copy:**
> [Name] hasn't checked into Dead-Yet in over [X] hours. You are listed as their emergency contact. This is probably nothing — but you might want to check on them.

**Rules:**
- User's display name from Apple Sign-In or settings
- Hours elapsed, rounded down (e.g., "14 hours" not "14 hours 12 minutes")
- One SMS per missed day — no repeats, no follow-up
- No app links, no marketing content in the SMS
- No follow-up "they're OK" SMS when user eventually checks in

### 5. Notifications

**Purpose:** Make sure the user doesn't miss their deadline by accident.

**Schedule:**
- **Daily reminder** - configurable, default 1 hour before deadline ("You haven't checked in today")
- **Urgent reminder** - at deadline time ("Deadline reached. Check in now.")
- **Overdue warnings** - every 15 minutes during grace period ("45 minutes until your emergency contact is notified.")

**Tone:** Direct, not cute. No emoji. No exclamation energy.

**Edge cases:**
- Notifications disabled: show in-app banner urging enable
- Do Not Disturb: notifications still scheduled, iOS may suppress

**Out of scope for V1:** Critical alerts (requires Apple entitlement), sound customization.

### Notification Copy

| Trigger | Timing | Copy |
|---------|--------|------|
| Daily reminder | Configurable (default 1hr before deadline) | "You haven't checked in today." |
| Deadline reached | At deadline | "Deadline passed. Check in now." |
| Overdue warning 1 | 15 min into grace | "1h 45m until your emergency contact is notified." |
| Overdue warning 2 | 30 min into grace | "1h 30m until your emergency contact is notified." |
| Overdue warning 3 | 60 min into grace | "1h until your emergency contact is notified." |
| Overdue warning 4 | 90 min into grace | "30 minutes." |
| Final warning | 105 min into grace | "15 minutes." |
| Escalated | After SMS sent | "Your emergency contact has been notified." |

**Tone rules:** No emoji. No exclamation marks. Gets terser as time runs out. Never say "please." Periods only.

### 6. Simple History / Streak

**Purpose:** Light engagement loop. Factual, not gamified.

**Behavior:**
- Current streak (consecutive days checked in)
- Total check-ins (all-time count)
- Missed days (total missed deadlines)
- Displayed on a secondary screen (not home)
- Last 30 days of activity, scrollable list
- Each row: date + check-in time OR status
- Color-coded indicators: green (checked in), yellow (missed, caught in grace), red (escalated)
- Summary stats at top: current streak / total check-ins / missed days
- Fewer than 30 days of data: show all available

**Edge cases:**
- First day: streak is 0 until first check-in
- Missed day: streak resets to 0
- Escalated day: red indicator + "Missed — contact notified"

**Out of scope for V1:** Calendar heatmap, weekly/monthly views, streak rewards, sharing.

## App Structure

**4 screens. No tab bar. No navigation clutter.**

1. **First Launch Setup** - one-time modal (shown once, never again):
   - Time picker: "When should we check if you're alive?" (default position 10:00 AM)
   - Optional emergency contact: "Who should we tell?" (name + phone fields)
   - Button: "GET STARTED"
   - Contact fields are optional — user can skip and add later in settings
   - If user force-quits during setup: show it again next launch

2. **Home** - the main screen:
   - "I'M ALIVE" button (dominant, center)
   - Countdown timer to next deadline
   - Last check-in timestamp
   - Current state indicator (safe / due soon / overdue)
   - Current streak (small, bottom)

3. **Settings** - modal sheet from home:
   - Emergency contact (name + phone)
   - Daily deadline time picker
   - Grace period duration (preset: 30 min / 1 hr / 2 hr / 4 hr)
   - Notification preferences

4. **History** - modal sheet from home:
   - Summary stats: current streak / total check-ins / missed days
   - Last 30 days scrollable list with color-coded indicators

**Navigation:** Home is the app. Settings and History are modal sheets that slide up from bottom. First Launch Setup is shown once before Home on first open.

## UX / Visual Direction

### Color Palette

| Role | Color | Hex |
|------|-------|-----|
| Background | Pure black (OLED void) | `#000000` |
| Primary text | Warm off-white | `#E8E8E3` |
| Accent | Acid green | `#AAFF00` |
| Danger | System red | `#FF3B30` |
| Warning | Muted yellow | `#FFD60A` |

### Typography

- **Space Grotesk Bold** - hero elements: button label, countdown, state text. All caps for button. 48-72pt for countdown. 2-4pt letter-spacing.
- **Inter Regular/Medium** - secondary text: timestamps, labels, settings UI. Clean, legible.
- Tabular/monospace figures for countdown digits.

### Button

- "I'M ALIVE" button: massive, at least 50% screen width
- Acid green fill (`#AAFF00`) with black text (`#000000`) — solid, bold, unmissable
- Slight glow or border pulse in idle state (subtle)
- On press: haptic feedback (medium impact) + brief flash

### Countdown

- Large tabular figures in Space Grotesk
- Format: `14:32:07` (HH:MM:SS)
- Color shifts: off-white -> yellow -> red as time decreases
- Below: "until deadline" in small Inter off-white

### Spacing & Layout

- Extreme vertical spacing between elements
- Screen should feel 60% empty
- Content centered vertically, not top-aligned
- No cards, no containers, no borders on info elements
- Floating text on black void

### What to Avoid

- Rounded, bubbly buttons
- Gradients
- Illustrations or decorative icons
- Colors outside the defined palette
- Drop shadows
- Busy layouts (if it feels "full," remove something)

## Tone System

Using the **Dark** tier for V1:

| Element | Copy |
|---------|------|
| Button | "I'M ALIVE" |
| Overdue | "You haven't confirmed you're alive" |
| Escalation warning | "Your emergency contact will be alerted" |
| Streak | "X days alive" |
| Empty state (no contact) | "Nobody knows you're alive yet" |

Not the "very dark" tier (too edgy for daily use), not the "safe" tier (too generic for the brand).

## State Model

```
SAFE
  |
  | time passes
  v
DUE SOON (1 hour before deadline)
  |
  | deadline passes
  v
OVERDUE (grace period: 2hr default, configurable)
  |                          \
  | grace period expires      | user checks in -> SAFE
  v                          /
ESCALATION PENDING
  |                          \
  | SMS sent (backend)        | user checks in -> SAFE
  v                          /
ESCALATED
  |
  | user checks in -> SAFE (but SMS already sent, shown for that day)
```

**State transitions are time-driven, not user-driven** (except for check-in). The backend timer is the authority. If the device is off, the backend still escalates on schedule.

## Architecture Decisions (V1)

1. **Backend: Firebase Cloud Functions + Twilio** - Firebase has first-class Swift SDK, built-in APNs support, and Firebase Auth supports Apple Sign-In. Twilio handles SMS. This is the most natural stack for an iOS-only app.

2. **Single emergency contact only** - one contact, no trees, no groups.

3. **Minimal first-launch setup (one screen, not a flow)** - single modal on first open with time picker + optional emergency contact. Not onboarding — no welcome screens, no feature tours, no slides. One functional setup screen, then straight to home. If no contact is set after setup, persistent banner nudges setup on home screen.

4. **Local-first, backend-synced** - check-in state lives on device. Backend receives sync of check-in events and runs escalation timer independently. If phone is dead, backend still fires.

5. **Authentication: Apple Sign-In** - required for the backend to know which user's timer to run. iOS-native, minimal friction.

6. **No pause/vacation mode in V1** - users either check in or they don't.

## Timezone Rules

- Deadline stored as **wall-clock time** (e.g., "10:00 AM"), not a UTC offset
- Travel: 10 AM means 10 AM in whatever timezone the device is in
- If user flies NYC → LA: deadline becomes 10:00 AM Pacific (they gain 3 hours)
- If user flies LA → NYC: deadline becomes 10:00 AM Eastern (they lose 3 hours)
- Backend uses user's **last-known timezone**, synced on each app open and check-in
- If timezone changes mid-grace-period: grace period continues from original start (no extension/reduction)

## Backend Escalation Details

- Backend timer starts at **deadline time** (not at last check-in)
- On each check-in sync: backend records timestamp and resets the next escalation window
- Phone dead all day: backend fires based on deadline + grace period using last-known timezone
- Twilio failure: retry 3 times over 10 minutes, then log as "escalation failed" (monitor)
- Late device sync (check-in arrives after SMS already sent): record check-in, no SMS undo
- Cloud Function: per-user scheduled trigger, not global polling

## Settings Defaults

| Setting | Default | Options |
|---------|---------|---------|
| Daily deadline | User picks at first launch (picker starts at 10:00 AM) | Any time, 15-min increments |
| Grace period | 2 hours | 30 min / 1 hr / 2 hr / 4 hr |
| Daily reminder | 1 hour before deadline | 30 min / 1 hr / 2 hr / off |
| Emergency contact | None (set at first launch or settings) | Name + phone |

**Notes:**
- No notification sound setting in V1
- Reminder "off" disables daily nudge only — overdue warnings are always on
- Grace period is preset picker, not free-form

---

## Clarified Product Requirements

- Daily check-in app with one primary action ("I'M ALIVE") per day
- User-configurable deadline time (picked at first launch, changeable in settings)
- 2-hour default grace period after missed deadline, configurable (30min / 1hr / 2hr / 4hr)
- Single emergency contact (name + phone number), set at first launch or settings
- SMS escalation via Twilio when grace period expires without check-in
- Defined SMS copy: measured tone, hours elapsed, "probably nothing" framing
- No follow-up SMS when user eventually checks in after escalation
- Backend-driven escalation timer (device-independent, per-user scheduled trigger)
- Simple streak/history tracking (streak, total check-ins, missed days, last 30 days list)
- History color-coded: green (checked in), yellow (missed, caught in grace), red (escalated)
- Local notifications with defined copy: daily reminder, deadline, overdue warnings (get terser), escalation confirmation
- Dark tier tone: serious, provocative, not goofy
- Minimal first-launch setup (one screen: time picker + optional contact), no multi-screen onboarding
- No pause mode, no multi-contact, no social features

## Technical Requirements

- **Platform:** iOS (SwiftUI)
- **Minimum iOS version:** iOS 17 (for latest SwiftUI features)
- **Backend:** Firebase Cloud Functions (Node.js/TypeScript)
- **SMS:** Twilio Programmable SMS
- **Auth:** Firebase Auth with Apple Sign-In
- **Database:** Firestore (check-in records, user config, emergency contact)
- **Notifications:** Local notifications (UNUserNotificationCenter) for reminders; push notifications as backup
- **Custom fonts:** Space Grotesk (Bold), Inter (Regular, Medium) - embedded via asset catalog
- **Haptics:** UIImpactFeedbackGenerator (medium)
- **Data sync:** Device writes check-in to Firestore; Cloud Function runs escalation timer server-side

## Engineering Principles

- **Local-first:** Check-in state and history stored on device. Backend is for escalation reliability, not for the primary UX.
- **Offline-capable:** User can check in without connectivity. Sync when connection resumes. Backend timer starts from last known check-in.
- **Minimal surface area:** 4 screens (setup + home + settings + history), no tab bar, no complex navigation. Every screen earns its existence.
- **State-driven UI:** The 5-state model drives all UI changes. No ad-hoc conditional rendering.
- **No feature creep:** If it's not in this spec, it doesn't exist in V1.

## Hard Constraints

- No multi-screen onboarding (one functional setup screen only)
- No multiple emergency contacts
- No pause/vacation mode
- No widgets, Watch app, or notification actions for check-in
- No social features, sharing, or feed
- No AI, chat, or wearable integrations
- No charts, calendars, or analytics beyond streak/total/missed/30-day list
- No monetization logic in V1 codebase
- SMS is the only escalation channel in V1 (no WhatsApp, Telegram, email). Data model should store contact as a structured object (not just a phone string) to support adding email in V2 without migration.
- No follow-up "they're OK" SMS after escalation
- One check-in per day (no multiple check-ins)
- Backend must be able to escalate independently of device state
- Deadlines use wall-clock time (not UTC offsets)
